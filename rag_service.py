import json
from constants import (
    ANSWER_RESPONSE_KEY,
    CAR_RELATED_KEYWORDS,
    DEFAULT_MODEL,
    FILENAME_RESPONSE_KEY,
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


class RagService:
    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_store: VectorStore,
        openai_service: OpenAIService,
    ):
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.openai_service = openai_service

    async def answer_question(self, question: str, session_id: str) -> dict:
        if not self._should_search_documents(question):
            return await self._fallback_answer(question, session_id)

        try:
            query_vector = (await self.embedding_service.embed_texts([question]))[0]
            matches = self.vector_store.search(query_vector, limit=RAG_TOP_K)
            usable_matches = [match for match in matches if match.score >= RAG_MIN_SCORE]
        except Exception:
            return await self._fallback_answer(question, session_id)

        if not usable_matches:
            return await self._fallback_answer(question, session_id)

        context = self._build_context(usable_matches)
        document_result = await self._answer_from_context(question, context)

        if not document_result.get("can_answer_from_context"):
            return await self._fallback_answer(question, session_id)

        return {
            ANSWER_RESPONSE_KEY: document_result.get("answer", ""),
            FROM_DOCUMENT_RESPONSE_KEY: True,
            SOURCES_RESPONSE_KEY: [
                {
                    FILENAME_RESPONSE_KEY: match.payload[FILENAME_RESPONSE_KEY],
                    CHUNK_INDEX_RESPONSE_KEY: match.payload[CHUNK_INDEX_RESPONSE_KEY],
                    SCORE_RESPONSE_KEY: match.score,
                }
                for match in usable_matches
            ],
        }

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

    async def _fallback_answer(self, question: str, session_id: str) -> dict:
        answer = await self.openai_service.get_chat_response(
            question=question,
            session_id=session_id,
        )
        return {
            ANSWER_RESPONSE_KEY: answer,
            FROM_DOCUMENT_RESPONSE_KEY: False,
            SOURCES_RESPONSE_KEY: [],
        }

    async def stream_answer_question(self, question: str, session_id: str):
        if not self._should_search_documents(question):
            async for chunk in self.openai_service.stream_chat_response(
                question=question,
                session_id=session_id,
            ):
                yield chunk
            return

        try:
            query_vector = (await self.embedding_service.embed_texts([question]))[0]
            matches = self.vector_store.search(query_vector, limit=RAG_TOP_K)
            usable_matches = [match for match in matches if match.score >= RAG_MIN_SCORE]
        except Exception:
            async for chunk in self.openai_service.stream_chat_response(
                question=question,
                session_id=session_id,
            ):
                yield chunk
            return

        if not usable_matches:
            async for chunk in self.openai_service.stream_chat_response(
                question=question,
                session_id=session_id,
            ):
                yield chunk
            return

        context = self._build_context(usable_matches)
        document_result = await self._answer_from_context(question, context)

        if not document_result.get("can_answer_from_context"):
            async for chunk in self.openai_service.stream_chat_response(
                question=question,
                session_id=session_id,
            ):
                yield chunk
            return

        yield document_result.get("answer", "")

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
