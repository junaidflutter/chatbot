import json
from time import perf_counter
from constants import (
    ANSWER_RESPONSE_KEY,
    ANONYMOUS_USER_ID,
    CAR_RELATED_KEYWORDS,
    DEFAULT_MODEL,
    FILENAME_RESPONSE_KEY,
    CITATIONS_RESPONSE_KEY,
    EXCERPT_RESPONSE_KEY,
    FROM_DOCUMENT_RESPONSE_KEY,
    CHUNK_INDEX_RESPONSE_KEY,
    MESSAGE_CONTENT_KEY,
    MESSAGE_KEY,
    MESSAGE_ROLE_KEY,
    OPENAI_MAX_TOKENS,
    OPENAI_TEMPERATURE,
    RAG_MIN_SCORE,
    RAG_SYSTEM_PROMPT,
    RAG_TOP_K,
    SCORE_RESPONSE_KEY,
    SOURCES_RESPONSE_KEY,
    SYSTEM_ROLE,
    USER_ROLE,
)
from embedding_service import EmbeddingService
from services import OpenAIService
from vector_store import VectorStore


def _elapsed_ms(start: float) -> int:
    return int((perf_counter() - start) * 1000)


class RagService:
    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_store: VectorStore,
        openai_service: OpenAIService,
        chat_history_service=None,
    ):
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.openai_service = openai_service
        self.chat_history_service = chat_history_service

    async def answer_question(self, question: str, session_id: str, user_id: str = ANONYMOUS_USER_ID) -> dict:
        started_at = perf_counter()
        print(
            f"[rag] answer start session_id={session_id} user_id={user_id} question_len={len(question)}"
        )
        document_result = await self._get_document_answer(question, user_id)
        if document_result:
            print(
                f"[rag] answer document done session_id={session_id} ms={_elapsed_ms(started_at)} answer_len={len(document_result.get(ANSWER_RESPONSE_KEY, ''))}"
            )
            return document_result

        result = await self._fallback_answer(question, session_id, user_id)
        print(
            f"[rag] answer fallback done session_id={session_id} ms={_elapsed_ms(started_at)} answer_len={len(result.get(ANSWER_RESPONSE_KEY, ''))}"
        )
        return result

    async def _answer_from_context(self, question: str, context: str) -> dict:
        response = await self.openai_service.client.chat.completions.create(
            model=DEFAULT_MODEL,
            messages=[
                {MESSAGE_ROLE_KEY: SYSTEM_ROLE, MESSAGE_CONTENT_KEY: RAG_SYSTEM_PROMPT},
                {
                    MESSAGE_ROLE_KEY: USER_ROLE,
                    MESSAGE_CONTENT_KEY: f"Document context:\n{context}\n\nQuestion:\n{question}",
                },
            ],
            temperature=OPENAI_TEMPERATURE,
            max_tokens=OPENAI_MAX_TOKENS,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content or "{}"
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return {"can_answer_from_context": False, "answer": ""}

    async def _fallback_answer(self, question: str, session_id: str, user_id: str) -> dict:
        started_at = perf_counter()
        print(f"[rag] fallback start session_id={session_id} user_id={user_id}")
        answer = await self.openai_service.get_chat_response(
            question=question,
            session_id=session_id,
            user_id=user_id,
        )
        print(
            f"[rag] fallback done session_id={session_id} ms={_elapsed_ms(started_at)}"
        )
        return {
            ANSWER_RESPONSE_KEY: answer,
            FROM_DOCUMENT_RESPONSE_KEY: False,
            SOURCES_RESPONSE_KEY: [],
            CITATIONS_RESPONSE_KEY: [],
        }

    async def stream_answer_question(self, question: str, session_id: str, user_id: str = ANONYMOUS_USER_ID):
        try:
            document_result = await self._get_document_answer(question, user_id)
            if document_result:
                yield document_result.get(ANSWER_RESPONSE_KEY, "")
                return

            async for chunk in self.openai_service.stream_chat_response(
                question=question,
                session_id=session_id,
                user_id=user_id,
            ):
                yield chunk
        except Exception:
            fallback = await self._fallback_answer(question, session_id, user_id)
            yield fallback.get(ANSWER_RESPONSE_KEY, "")

    def _should_search_documents(self, question: str) -> bool:
        normalized_question = question.lower()
        return any(keyword in normalized_question for keyword in CAR_RELATED_KEYWORDS)

    def _build_context(self, matches) -> str:
        context_parts = []
        for match in matches:
            payload = match.payload or {}
            filename = payload.get(FILENAME_RESPONSE_KEY, "unknown")
            chunk_index = payload.get(CHUNK_INDEX_RESPONSE_KEY, 0)
            text = payload.get(MESSAGE_KEY, "")
            context_parts.append(f"[{filename} - chunk {chunk_index}]\n{text}")

        return "\n\n".join(context_parts)

    async def _get_document_answer(self, question: str, user_id: str) -> dict | None:
        if not self._should_search_documents(question):
            print("[rag] document skip reason=no_keyword")
            return None

        started_at = perf_counter()
        try:
            query_vector = (await self.embedding_service.embed_texts([question]))[0]
            matches = self.vector_store.search(query_vector, limit=RAG_TOP_K, user_id=user_id)
            usable_matches = [match for match in matches if match.score >= RAG_MIN_SCORE]
            print(
                f"[rag] document search done user_id={user_id} matches={len(matches)} usable={len(usable_matches)} ms={_elapsed_ms(started_at)}"
            )
        except Exception as exc:
            print(
                f"[rag] document search fail user_id={user_id} ms={_elapsed_ms(started_at)} error={exc}"
            )
            return None

        if not usable_matches:
            return None

        answer_started_at = perf_counter()
        context = self._build_context(usable_matches)
        document_result = await self._answer_from_context(question, context)
        print(
            f"[rag] document answer check done user_id={user_id} ms={_elapsed_ms(answer_started_at)} total_ms={_elapsed_ms(started_at)} can_answer={bool(document_result.get('can_answer_from_context'))}"
        )
        if not document_result.get("can_answer_from_context"):
            return None

        citations = [
            {
                "document_id": match.payload.get("document_id", ""),
                FILENAME_RESPONSE_KEY: match.payload.get(FILENAME_RESPONSE_KEY, ""),
                CHUNK_INDEX_RESPONSE_KEY: match.payload.get(CHUNK_INDEX_RESPONSE_KEY, 0),
                SCORE_RESPONSE_KEY: match.score,
                EXCERPT_RESPONSE_KEY: (match.payload.get(MESSAGE_KEY, "") or "")[:240],
            }
            for match in usable_matches
        ]
        return {
            ANSWER_RESPONSE_KEY: document_result.get("answer", ""),
            FROM_DOCUMENT_RESPONSE_KEY: True,
            SOURCES_RESPONSE_KEY: citations,
            CITATIONS_RESPONSE_KEY: citations,
        }
