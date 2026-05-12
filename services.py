import os
from io import BytesIO
from openai import AsyncOpenAI
from dotenv import load_dotenv
from constants import (
    ASSISTANT_ROLE,
    ANONYMOUS_USER_ID,
    CAR_SELLING_SYSTEM_PROMPT,
    CHAT_HISTORY_LIMIT,
    DEFAULT_MODEL,
    DEFAULT_SESSION_ID,
    ENGLISH_ONLY_PROMPT,
    MESSAGE_CONTENT_KEY,
    MESSAGE_ROLE_KEY,
    OPENAI_API_KEY_ENV,
    OPENAI_API_KEY_MISSING_ERROR,
    OPENAI_MAX_TOKENS,
    OPENAI_TEMPERATURE,
    MESSAGE_KEY,
    SYSTEM_ROLE,
    USER_ROLE,
    VOICE_TRANSCRIPTION_PROMPT,
)

load_dotenv()


class OpenAIService:
    def __init__(self, chat_history_service=None):

        api_key = os.getenv(OPENAI_API_KEY_ENV)

        if not api_key:

            raise ValueError(OPENAI_API_KEY_MISSING_ERROR)

        self.client = AsyncOpenAI(api_key=api_key)
        self.chat_history_service = chat_history_service

    async def _load_history(self, user_id: str, session_id: str):
        if self.chat_history_service is None:
            return []

        entries = await self.chat_history_service.get_recent_messages(
            user_id=user_id or ANONYMOUS_USER_ID,
            session_id=session_id,
            limit=CHAT_HISTORY_LIMIT * 2,
        )
        return [
            {MESSAGE_ROLE_KEY: entry[MESSAGE_ROLE_KEY], MESSAGE_CONTENT_KEY: entry[MESSAGE_KEY]}
            for entry in entries
        ]

    async def _append_history(self, user_id: str, session_id: str, question: str, answer: str):
        if self.chat_history_service is None:
            return

        user_key = user_id or ANONYMOUS_USER_ID
        await self.chat_history_service.add_message(user_key, session_id, USER_ROLE, question)
        await self.chat_history_service.add_message(user_key, session_id, ASSISTANT_ROLE, answer)

    async def get_chat_response(
        self,
        question: str,
        session_id: str = DEFAULT_SESSION_ID,
        user_id: str = ANONYMOUS_USER_ID,
        model: str = DEFAULT_MODEL,
    ):
        history = await self._load_history(user_id, session_id)

        messages = [
            {MESSAGE_ROLE_KEY: SYSTEM_ROLE, MESSAGE_CONTENT_KEY: CAR_SELLING_SYSTEM_PROMPT},
            *history,
            {MESSAGE_ROLE_KEY: SYSTEM_ROLE, MESSAGE_CONTENT_KEY: ENGLISH_ONLY_PROMPT},
            {MESSAGE_ROLE_KEY: USER_ROLE, MESSAGE_CONTENT_KEY: question},
        ]

        response = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=OPENAI_TEMPERATURE,
            max_tokens=OPENAI_MAX_TOKENS,
        )

        assistant_reply = response.choices[0].message.content
        await self._append_history(user_id, session_id, question, assistant_reply)

        return assistant_reply

    async def transcribe_audio_bytes(
        self,
        audio_bytes: bytes,
        filename: str = "voice.webm",
    ) -> str:
        buffer = BytesIO(audio_bytes)
        buffer.name = filename

        for model in ("gpt-4o-transcribe", "gpt-4o-mini-transcribe", "whisper-1"):
            try:
                response = await self.client.audio.transcriptions.create(
                    model=model,
                    file=buffer,
                    language="en",
                    prompt=VOICE_TRANSCRIPTION_PROMPT,
                )
                return (response.text or "").strip()
            except Exception:
                buffer.seek(0)

        return ""

    async def stream_chat_response(
        self,
        question: str,
        session_id: str = DEFAULT_SESSION_ID,
        user_id: str = ANONYMOUS_USER_ID,
        model: str = DEFAULT_MODEL,
    ):
        history = await self._load_history(user_id, session_id)

        messages = [
            {MESSAGE_ROLE_KEY: SYSTEM_ROLE, MESSAGE_CONTENT_KEY: CAR_SELLING_SYSTEM_PROMPT},
            *history,
            {MESSAGE_ROLE_KEY: SYSTEM_ROLE, MESSAGE_CONTENT_KEY: ENGLISH_ONLY_PROMPT},
            {MESSAGE_ROLE_KEY: USER_ROLE, MESSAGE_CONTENT_KEY: question},
        ]

        stream = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=OPENAI_TEMPERATURE,
            max_tokens=OPENAI_MAX_TOKENS,
            stream=True,
        )

        chunks = []
        async for event in stream:
            chunk = event.choices[0].delta.content or ""
            if not chunk:
                continue

            chunks.append(chunk)
            yield chunk

        assistant_reply = "".join(chunks)
        await self._append_history(user_id, session_id, question, assistant_reply)
