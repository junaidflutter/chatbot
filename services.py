import os
from openai import AsyncOpenAI
from dotenv import load_dotenv
from constants import (
    ASSISTANT_ROLE,
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
    SYSTEM_ROLE,
    USER_ROLE,
)

load_dotenv()


class OpenAIService:

    def __init__(self):

        api_key = os.getenv(OPENAI_API_KEY_ENV)

        if not api_key:

            raise ValueError(OPENAI_API_KEY_MISSING_ERROR)

        self.client = AsyncOpenAI(api_key=api_key)

        self.chat_history = {}

    async def get_chat_response(
        self,
        question: str,
        session_id: str = DEFAULT_SESSION_ID,
        model: str = DEFAULT_MODEL,
    ):

        history = self.chat_history.get(session_id, [])

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
        updated_history = [
            *history,
            {MESSAGE_ROLE_KEY: USER_ROLE, MESSAGE_CONTENT_KEY: question},
            {MESSAGE_ROLE_KEY: ASSISTANT_ROLE, MESSAGE_CONTENT_KEY: assistant_reply},
        ]

        self.chat_history[session_id] = updated_history[-CHAT_HISTORY_LIMIT:]

        return assistant_reply

    async def stream_chat_response(
        self,
        question: str,
        session_id: str = DEFAULT_SESSION_ID,
        model: str = DEFAULT_MODEL,
    ):
        history = self.chat_history.get(session_id, [])

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
        updated_history = [
            *history,
            {MESSAGE_ROLE_KEY: USER_ROLE, MESSAGE_CONTENT_KEY: question},
            {MESSAGE_ROLE_KEY: ASSISTANT_ROLE, MESSAGE_CONTENT_KEY: assistant_reply},
        ]

        self.chat_history[session_id] = updated_history[-CHAT_HISTORY_LIMIT:]
