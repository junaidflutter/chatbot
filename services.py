import os
import asyncio
from io import BytesIO
from time import perf_counter
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

OPENAI_TRANSCRIPTION_MODEL_ENV = "OPENAI_TRANSCRIPTION_MODEL"
OPENAI_TTS_MODEL_ENV = "OPENAI_TTS_MODEL"
OPENAI_TTS_TIMEOUT_ENV = "OPENAI_TTS_TIMEOUT_SECONDS"
OPENAI_TRANSCRIBE_TIMEOUT_ENV = "OPENAI_TRANSCRIBE_TIMEOUT_SECONDS"
OPENAI_CHAT_TIMEOUT_ENV = "OPENAI_CHAT_TIMEOUT_SECONDS"
DEFAULT_TRANSCRIPTION_MODELS = (
    "gpt-4o-mini-transcribe",
)
DEFAULT_TTS_MODEL = "tts-1"
DEFAULT_TTS_TIMEOUT_SECONDS = 15.0
DEFAULT_TRANSCRIBE_TIMEOUT_SECONDS = 15.0
DEFAULT_CHAT_TIMEOUT_SECONDS = 20.0


def _elapsed_ms(start: float) -> int:
    return int((perf_counter() - start) * 1000)


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, "").strip() or default)
    except ValueError:
        return default


class OpenAIService:
    def __init__(self, chat_history_service=None):

        api_key = os.getenv(OPENAI_API_KEY_ENV)

        if not api_key:

            raise ValueError(OPENAI_API_KEY_MISSING_ERROR)

        self.client = AsyncOpenAI(api_key=api_key, timeout=25.0)
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

        started_at = perf_counter()
        print(
            f"[openai] chat start model={model} question_len={len(question)} history_messages={len(history)}"
        )
        response = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=OPENAI_TEMPERATURE,
            max_tokens=OPENAI_MAX_TOKENS,
            timeout=_env_float(OPENAI_CHAT_TIMEOUT_ENV, DEFAULT_CHAT_TIMEOUT_SECONDS),
        )

        assistant_reply = response.choices[0].message.content
        print(
            f"[openai] chat done model={model} answer_len={len(assistant_reply or '')} ms={_elapsed_ms(started_at)}"
        )
        await self._append_history(user_id, session_id, question, assistant_reply)

        return assistant_reply

    async def transcribe_audio_bytes(
        self,
        audio_bytes: bytes,
        filename: str = "voice.webm",
    ) -> str:
        buffer = BytesIO(audio_bytes)
        buffer.name = filename
        configured_model = os.getenv(OPENAI_TRANSCRIPTION_MODEL_ENV, "").strip()
        models = (configured_model,) if configured_model else DEFAULT_TRANSCRIPTION_MODELS
        overall_started_at = perf_counter()
        print(
            f"[openai] transcribe start filename={filename} bytes={len(audio_bytes)} models={models}"
        )

        for model in models:
            try:
                buffer.seek(0)
                model_started_at = perf_counter()
                print(f"[openai] transcribe try model={model}")
                response = await self.client.audio.transcriptions.create(
                    model=model,
                    file=buffer,
                    language="en",
                    prompt=VOICE_TRANSCRIPTION_PROMPT,
                    timeout=_env_float(
                        OPENAI_TRANSCRIBE_TIMEOUT_ENV,
                        DEFAULT_TRANSCRIBE_TIMEOUT_SECONDS,
                    ),
                )
                text = (response.text or "").strip()
                print(
                    f"[openai] transcribe done model={model} text_len={len(text)} ms={_elapsed_ms(model_started_at)} total_ms={_elapsed_ms(overall_started_at)}"
                )
                return text
            except Exception as exc:
                print(
                    f"[openai] transcribe fail model={model} ms={_elapsed_ms(model_started_at)} error={exc}"
                )

        print(
            f"[openai] transcribe exhausted all models total_ms={_elapsed_ms(overall_started_at)}"
        )
        return ""

    async def transcribe_audio(self, audio) -> str:
        audio_bytes = await audio.read()
        filename = getattr(audio, "filename", None) or "voice.webm"
        return await self.transcribe_audio_bytes(audio_bytes, filename=filename)

    async def synthesize_speech_bytes(self, text: str, voice: str = "alloy") -> bytes:
        started_at = perf_counter()
        model = os.getenv(OPENAI_TTS_MODEL_ENV, "").strip() or DEFAULT_TTS_MODEL
        print(f"[openai] tts start model={model} voice={voice} text_len={len(text)}")
        speech = await self.client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="wav",
            timeout=_env_float(OPENAI_TTS_TIMEOUT_ENV, DEFAULT_TTS_TIMEOUT_SECONDS),
        )

        for method_name in ("aread", "read"):
            method = getattr(speech, method_name, None)
            if method is None:
                continue
            result = method()
            if asyncio.iscoroutine(result):
                audio = await result
                print(
                    f"[openai] tts success async model={model} bytes={len(audio)} ms={_elapsed_ms(started_at)}"
                )
                return audio
            print(
                f"[openai] tts success sync model={model} bytes={len(result)} ms={_elapsed_ms(started_at)}"
            )
            return result

        content = getattr(speech, "content", None)
        if isinstance(content, bytes):
            print(
                f"[openai] tts success content model={model} bytes={len(content)} ms={_elapsed_ms(started_at)}"
            )
            return content

        print(f"[openai] tts failed to extract audio bytes ms={_elapsed_ms(started_at)}")
        raise ValueError("Could not synthesize speech audio.")

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
            timeout=_env_float(OPENAI_CHAT_TIMEOUT_ENV, DEFAULT_CHAT_TIMEOUT_SECONDS),
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
