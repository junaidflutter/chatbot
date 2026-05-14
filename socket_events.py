import base64
from binascii import Error as BinasciiError
from io import BytesIO
import os
from time import perf_counter
import wave
from app_services import get_rag_service
from constants import (
    ANONYMOUS_USER_ID,
    SOCKET_AUDIO_BASE64_KEY,
    SOCKET_AUDIO_CHUNK_INDEX_KEY,
    SOCKET_AUDIO_CODEC_KEY,
    SOCKET_AUDIO_FILENAME_KEY,
    SOCKET_AUDIO_IS_FINAL_KEY,
    SOCKET_AUDIO_NUM_CHANNELS_KEY,
    SOCKET_AUDIO_MIME_TYPE_KEY,
    SOCKET_AUDIO_SAMPLE_RATE_KEY,
    SOCKET_AUDIO_RESPONSE_EVENT,
    DEFAULT_SESSION_ID,
    AUTH_ACCESS_TOKEN_KEY,
    SOCKET_ASSISTANT_CHUNK_EVENT,
    SOCKET_ASSISTANT_DONE_EVENT,
    SOCKET_ASSISTANT_ERROR_EVENT,
    SOCKET_ASSISTANT_TYPING_EVENT,
    SOCKET_CHUNK_KEY,
    SOCKET_CONNECT_EVENT,
    SOCKET_DISCONNECT_EVENT,
    SOCKET_DONE_KEY,
    SOCKET_ERROR_KEY,
    SOCKET_JOIN_EVENT,
    SOCKET_MESSAGE_ACK_EVENT,
    SOCKET_QUESTION_KEY,
    SOCKET_SEND_MESSAGE_EVENT,
    SOCKET_SESSION_ID_KEY,
    SOCKET_START_STREAM_EVENT,
    SOCKET_AUDIO_CHUNK_EVENT,
    SOCKET_AUDIO_END_EVENT,
    SOCKET_VOICE_AUDIO_CHUNK_EVENT,
    SOCKET_VOICE_AUDIO_END_EVENT,
    SOCKET_VOICE_AUDIO_EVENT,
    SOCKET_VOICE_TRANSCRIPT_EVENT,
    SOCKET_VOICE_TRANSCRIBING_EVENT,
)
from app_services import get_openai_service
from app_services import get_auth_service
from socket_rooms import session_room
from socket_server import sio

_voice_stream_buffers = {}
_voice_stream_meta = {}
_voice_greeting_sent = set()
_voice_greeting_text = "How can I assist you today?"
VOICE_RESPONSE_MAX_CHARS_ENV = "VOICE_RESPONSE_MAX_CHARS"
DEFAULT_VOICE_RESPONSE_MAX_CHARS = 520


def _elapsed_ms(start: float) -> int:
    return int((perf_counter() - start) * 1000)


@sio.event
async def connect(sid, environ):
    print(f"[socket] {SOCKET_CONNECT_EVENT}: {sid}")


@sio.event
async def disconnect(sid):
    print(f"[socket] {SOCKET_DISCONNECT_EVENT}: {sid}")
    _clear_voice_stream(sid)
    for key in [key for key in _voice_greeting_sent if key.startswith(f"{sid}:")]:
        _voice_greeting_sent.discard(key)


@sio.on(SOCKET_JOIN_EVENT)
async def join_session(sid, data):
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    print(f"[socket] join_session sid={sid} session_id={session_id} user_id={user_id}")
    if not user_id:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {
                SOCKET_SESSION_ID_KEY: session_id,
                SOCKET_ERROR_KEY: "Authentication required.",
            },
            to=sid,
        )
        return
    await sio.enter_room(sid, session_room(session_id))
    await sio.emit(
        SOCKET_MESSAGE_ACK_EVENT,
        {SOCKET_SESSION_ID_KEY: session_id},
        to=sid,
    )


@sio.on(SOCKET_START_STREAM_EVENT)
async def start_stream(sid, data):
    started_at = perf_counter()
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    print(f"[socket] start_stream sid={sid} session_id={session_id} user_id={user_id}")
    if not user_id:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {
                SOCKET_SESSION_ID_KEY: session_id,
                SOCKET_ERROR_KEY: "Authentication required.",
            },
            to=sid,
        )
        return

    await sio.emit(
        SOCKET_MESSAGE_ACK_EVENT,
        {SOCKET_SESSION_ID_KEY: session_id},
        to=sid,
    )
    _clear_voice_stream(sid, session_id)

    greeting_key = _stream_key(sid, session_id)
    if greeting_key in _voice_greeting_sent:
        return

    _voice_greeting_sent.add(greeting_key)
    print(
        f"[socket] voice greeting queued sid={sid} session_id={session_id} ms={_elapsed_ms(started_at)}"
    )
    sio.start_background_task(_emit_voice_greeting, sid, session_id)


@sio.on(SOCKET_SEND_MESSAGE_EVENT)
async def send_message(sid, data):
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    payload = _payload_dict(data)
    question = (
        payload.get(SOCKET_QUESTION_KEY) or payload.get("question") or ""
    ).strip()
    print(
        f"[socket] send_message sid={sid} session_id={session_id} user_id={user_id} question_len={len(question)}"
    )
    if not user_id:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {
                SOCKET_SESSION_ID_KEY: session_id,
                SOCKET_ERROR_KEY: "Authentication required.",
            },
            to=sid,
        )
        return
    if not question:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_ERROR_KEY: "Question is required."},
            to=sid,
        )
        return

    room = session_room(session_id)
    await sio.enter_room(sid, room)
    await sio.emit(
        SOCKET_MESSAGE_ACK_EVENT, {SOCKET_SESSION_ID_KEY: session_id}, to=sid
    )
    await sio.emit(
        SOCKET_ASSISTANT_TYPING_EVENT, {SOCKET_SESSION_ID_KEY: session_id}, to=room
    )

    try:
        async for chunk in get_rag_service().stream_answer_question(
            question, session_id, user_id=user_id
        ):
            print(
                f"[socket] assistant_chunk sid={sid} session_id={session_id} chunk_len={len(chunk)}"
            )
            await sio.emit(
                SOCKET_ASSISTANT_CHUNK_EVENT,
                {
                    SOCKET_SESSION_ID_KEY: session_id,
                    SOCKET_CHUNK_KEY: chunk,
                },
                to=room,
            )

        await sio.emit(
            SOCKET_ASSISTANT_DONE_EVENT,
            {
                SOCKET_SESSION_ID_KEY: session_id,
                SOCKET_DONE_KEY: True,
            },
            to=room,
        )
        print(f"[socket] assistant_done sid={sid} session_id={session_id}")
    except Exception as exc:
        print(f"[socket] send_message error sid={sid} session_id={session_id} error={exc}")
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {
                SOCKET_SESSION_ID_KEY: session_id,
                SOCKET_ERROR_KEY: str(exc),
            },
            to=sid,
        )


@sio.on(SOCKET_VOICE_AUDIO_EVENT)
async def voice_audio(sid, data):
    started_at = perf_counter()
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    audio_b64, payload = _extract_audio_payload(data)
    filename = payload.get(SOCKET_AUDIO_FILENAME_KEY) or "voice.webm"
    mime_type = payload.get(SOCKET_AUDIO_MIME_TYPE_KEY) or "audio/webm"
    codec = payload.get(SOCKET_AUDIO_CODEC_KEY) or ""
    sample_rate = int(payload.get(SOCKET_AUDIO_SAMPLE_RATE_KEY) or 16000)
    num_channels = int(payload.get(SOCKET_AUDIO_NUM_CHANNELS_KEY) or 1)
    print(
        f"[socket] voice_audio sid={sid} session_id={session_id} user_id={user_id} audio_chars={len(audio_b64)} filename={filename}"
    )
    if not audio_b64:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: "Audio is required."},
            to=sid,
        )
        return

    try:
        audio_bytes = _decode_audio_payload(audio_b64)
        print(
            f"[socket] voice_audio decoded sid={sid} session_id={session_id} bytes={len(audio_bytes)} ms={_elapsed_ms(started_at)}"
        )
    except (ValueError, BinasciiError) as exc:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
            to=sid,
        )
        return

    await _process_voice_audio(
        sid=sid,
        session_id=session_id,
        user_id=user_id,
        audio_bytes=audio_bytes,
        filename=filename,
        mime_type=mime_type,
        codec=codec,
        sample_rate=sample_rate,
        num_channels=num_channels,
    )


@sio.on(SOCKET_VOICE_AUDIO_CHUNK_EVENT)
async def voice_audio_chunk(sid, data):
    started_at = perf_counter()
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    audio_b64, payload = _extract_audio_payload(data)
    chunk_index = int(payload.get(SOCKET_AUDIO_CHUNK_INDEX_KEY) or 0)
    codec = payload.get(SOCKET_AUDIO_CODEC_KEY) or "pcm16"
    sample_rate = int(payload.get(SOCKET_AUDIO_SAMPLE_RATE_KEY) or 16000)
    num_channels = int(payload.get(SOCKET_AUDIO_NUM_CHANNELS_KEY) or 1)
    print(
        f"[socket] voice_audio_chunk sid={sid} session_id={session_id} user_id={user_id} chunk_index={chunk_index} audio_chars={len(audio_b64)}"
    )
    if not audio_b64:
        return

    try:
        chunk_bytes = _decode_audio_payload(audio_b64)
        print(
            f"[socket] voice_audio_chunk decoded sid={sid} session_id={session_id} bytes={len(chunk_bytes)} ms={_elapsed_ms(started_at)}"
        )
    except (ValueError, BinasciiError) as exc:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
            to=sid,
        )
        return

    _append_voice_stream(
        sid,
        session_id,
        chunk_bytes,
        {
            SOCKET_AUDIO_CODEC_KEY: codec,
            SOCKET_AUDIO_SAMPLE_RATE_KEY: sample_rate,
            SOCKET_AUDIO_NUM_CHANNELS_KEY: num_channels,
        },
    )


@sio.on(SOCKET_AUDIO_CHUNK_EVENT)
async def audio_chunk(sid, data):
    await voice_audio_chunk(sid, data)


@sio.on(SOCKET_VOICE_AUDIO_END_EVENT)
async def voice_audio_end(sid, data):
    started_at = perf_counter()
    session_id = _get_session_id(data)
    user_id = await _get_socket_user_id(data)
    _, payload = _extract_audio_payload(data)
    chunk_count = int(payload.get(SOCKET_AUDIO_CHUNK_INDEX_KEY) or 0)
    codec = payload.get(SOCKET_AUDIO_CODEC_KEY) or "pcm16"
    sample_rate = int(payload.get(SOCKET_AUDIO_SAMPLE_RATE_KEY) or 16000)
    num_channels = int(payload.get(SOCKET_AUDIO_NUM_CHANNELS_KEY) or 1)
    filename = payload.get(SOCKET_AUDIO_FILENAME_KEY) or "voice.wav"
    is_final = True if not payload else bool(payload.get(SOCKET_AUDIO_IS_FINAL_KEY, True))
    print(
        f"[socket] voice_audio_end sid={sid} session_id={session_id} user_id={user_id} chunk_count={chunk_count} codec={codec} final={is_final}"
    )
    audio_bytes, meta = _pop_voice_stream(sid, session_id)
    if audio_bytes:
        if not is_final:
            print(
                f"[socket] voice_audio_end non-final but buffered audio present sid={sid} session_id={session_id}"
            )
        codec = meta.get(SOCKET_AUDIO_CODEC_KEY, codec)
        sample_rate = int(meta.get(SOCKET_AUDIO_SAMPLE_RATE_KEY, sample_rate) or sample_rate)
        num_channels = int(meta.get(SOCKET_AUDIO_NUM_CHANNELS_KEY, num_channels) or num_channels)
        if codec == "pcm16":
            audio_bytes = _wrap_pcm16_to_wav(
                audio_bytes,
                sample_rate=sample_rate,
                num_channels=num_channels,
            )
            filename = "voice.wav"
        print(
            f"[socket] voice_audio_end ready sid={sid} session_id={session_id} bytes={len(audio_bytes)} ms={_elapsed_ms(started_at)}"
        )
        await _process_voice_audio(
            sid=sid,
            session_id=session_id,
            user_id=user_id,
            audio_bytes=audio_bytes,
            filename=filename,
            mime_type="audio/wav" if codec == "pcm16" else "audio/webm",
            codec=codec,
            sample_rate=sample_rate,
            num_channels=num_channels,
        )
        return

    if not is_final:
        print(
            f"[socket] voice_audio_end discard sid={sid} session_id={session_id}"
        )
        return

    # Fallback if chunks were never sent but the caller still wants to finalize.
    audio_b64 = payload.get(SOCKET_AUDIO_BASE64_KEY, "").strip()
    if audio_b64:
        try:
            audio_bytes = _decode_audio_payload(audio_b64)
        except (ValueError, BinasciiError) as exc:
            await sio.emit(
                SOCKET_ASSISTANT_ERROR_EVENT,
                {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
                to=sid,
            )
            return
        await _process_voice_audio(
            sid=sid,
            session_id=session_id,
            user_id=user_id,
            audio_bytes=audio_bytes,
            filename=filename,
            mime_type="audio/wav" if codec == "pcm16" else "audio/webm",
            codec=codec,
            sample_rate=sample_rate,
            num_channels=num_channels,
        )
        return

    print(
        f"[socket] voice_audio_end ignored sid={sid} session_id={session_id} no buffered audio"
    )


@sio.on(SOCKET_AUDIO_END_EVENT)
async def audio_end(sid, data):
    await voice_audio_end(sid, data)


def _get_session_id(data) -> str:
    payload = _payload_dict(data)
    session_id = (
        payload.get(SOCKET_SESSION_ID_KEY)
        or payload.get("session_id")
        or DEFAULT_SESSION_ID
    )
    return str(session_id).strip() or DEFAULT_SESSION_ID


def _decode_audio_payload(audio_b64: str) -> bytes:
    if "," in audio_b64 and audio_b64.startswith("data:"):
        audio_b64 = audio_b64.split(",", 1)[1]

    return base64.b64decode(audio_b64)


def _wrap_pcm16_to_wav(
    audio_bytes: bytes,
    sample_rate: int = 16000,
    num_channels: int = 1,
) -> bytes:
    buffer = BytesIO()
    with wave.open(buffer, "wb") as wav_file:
        wav_file.setnchannels(num_channels)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(audio_bytes)
    return buffer.getvalue()


def _stream_key(sid, session_id) -> str:
    return f"{sid}:{session_id}"


def _clear_voice_stream(sid, session_id=None):
    if session_id is not None:
        key = _stream_key(sid, session_id)
        _voice_stream_buffers.pop(key, None)
        _voice_stream_meta.pop(key, None)
        return

    prefix = f"{sid}:"
    for key in [key for key in _voice_stream_buffers if key.startswith(prefix)]:
        _voice_stream_buffers.pop(key, None)
        _voice_stream_meta.pop(key, None)


def _append_voice_stream(sid, session_id, chunk_bytes: bytes, meta: dict):
    key = _stream_key(sid, session_id)
    buffer = _voice_stream_buffers.setdefault(key, bytearray())
    buffer.extend(chunk_bytes)
    _voice_stream_meta[key] = {
        **_voice_stream_meta.get(key, {}),
        **meta,
    }
    print(
        f"[socket] voice stream append sid={sid} session_id={session_id} chunk_bytes={len(chunk_bytes)} total_bytes={len(buffer)}"
    )


def _pop_voice_stream(sid, session_id):
    key = _stream_key(sid, session_id)
    audio_bytes = bytes(_voice_stream_buffers.pop(key, bytearray()))
    meta = _voice_stream_meta.pop(key, {})
    print(
        f"[socket] voice stream pop sid={sid} session_id={session_id} bytes={len(audio_bytes)}"
    )
    return audio_bytes, meta


async def _process_voice_audio(
    sid,
    session_id,
    user_id,
    audio_bytes: bytes,
    filename: str,
    mime_type: str,
    codec: str,
    sample_rate: int,
    num_channels: int,
):
    overall_started_at = perf_counter()
    try:
        print(
            f"[socket] voice pipeline start sid={sid} session_id={session_id} bytes={len(audio_bytes)} filename={filename} codec={codec} sample_rate={sample_rate} channels={num_channels}"
        )
        stage_started_at = perf_counter()
        print(f"[socket] transcribe start sid={sid} session_id={session_id}")
        transcript = await get_openai_service().transcribe_audio_bytes(
            audio_bytes,
            filename=filename,
        )
        print(
            f"[socket] transcribe done sid={sid} session_id={session_id} transcript_len={len(transcript)} ms={_elapsed_ms(stage_started_at)} total_ms={_elapsed_ms(overall_started_at)}"
        )
        if not transcript:
            raise ValueError("Could not understand the audio. Please try again.")

        stage_started_at = perf_counter()
        print(f"[socket] answer start sid={sid} session_id={session_id}")
        answer = await get_rag_service().answer_question(
            transcript,
            session_id=session_id,
            user_id=user_id,
        )
        answer_text = _compact_voice_answer(answer.get("answer", ""))
        if not answer_text:
            answer_text = "I could not find a clear answer. Please ask again."
        print(
            f"[socket] answer done sid={sid} session_id={session_id} answer_len={len(answer_text)} ms={_elapsed_ms(stage_started_at)} total_ms={_elapsed_ms(overall_started_at)}"
        )
        stage_started_at = perf_counter()
        print(f"[socket] tts start sid={sid} session_id={session_id}")
        audio_bytes = await get_openai_service().synthesize_speech_bytes(
            answer_text,
        )
        print(
            f"[socket] tts done sid={sid} session_id={session_id} audio_bytes={len(audio_bytes)} ms={_elapsed_ms(stage_started_at)} total_ms={_elapsed_ms(overall_started_at)}"
        )
        stage_started_at = perf_counter()
        await sio.emit(
            SOCKET_AUDIO_RESPONSE_EVENT,
            base64.b64encode(audio_bytes).decode("utf-8"),
            to=sid,
        )
        print(
            f"[socket] audio_response emitted sid={sid} session_id={session_id} emit_ms={_elapsed_ms(stage_started_at)} total_ms={_elapsed_ms(overall_started_at)}"
        )
    except Exception as exc:
        print(
            f"[socket] voice_audio error sid={sid} session_id={session_id} total_ms={_elapsed_ms(overall_started_at)} error={exc}"
        )
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
            to=sid,
        )


async def _get_socket_user_id(data) -> str | None:
    payload = _payload_dict(data)
    token = payload.get(AUTH_ACCESS_TOKEN_KEY, "").strip()
    if not token:
        return ANONYMOUS_USER_ID

    payload = get_auth_service().verify_token(token)
    if not payload:
        return ANONYMOUS_USER_ID

    return payload["user_id"]


async def _get_voice_greeting_audio() -> bytes:
    return await get_openai_service().synthesize_speech_bytes(_voice_greeting_text)


async def _emit_voice_greeting(sid, session_id):
    started_at = perf_counter()
    try:
        print(f"[socket] voice greeting start sid={sid} session_id={session_id}")
        greeting_audio = await _get_voice_greeting_audio()
        await sio.emit(
            SOCKET_AUDIO_RESPONSE_EVENT,
            base64.b64encode(greeting_audio).decode("utf-8"),
            to=sid,
        )
        print(
            f"[socket] voice greeting emitted sid={sid} session_id={session_id} bytes={len(greeting_audio)} ms={_elapsed_ms(started_at)}"
        )
    except Exception as exc:
        print(
            f"[socket] voice greeting error sid={sid} session_id={session_id} ms={_elapsed_ms(started_at)} error={exc}"
        )


def _extract_audio_payload(data):
    if isinstance(data, str):
        return data.strip(), {}
    if isinstance(data, dict):
        payload = dict(data)
        audio_b64 = (payload.get(SOCKET_AUDIO_BASE64_KEY) or "").strip()
        if not audio_b64:
            raw_value = payload.get("audio") or payload.get("data") or payload.get("chunk")
            if isinstance(raw_value, str):
                audio_b64 = raw_value.strip()
        return audio_b64, payload
    return "", {}


def _payload_dict(data) -> dict:
    return data if isinstance(data, dict) else {}


def _compact_voice_answer(text: str) -> str:
    text = " ".join((text or "").split())
    max_chars = _voice_response_max_chars()
    if max_chars <= 0 or len(text) <= max_chars:
        return text

    candidate = text[:max_chars].rstrip()
    sentence_end = max(candidate.rfind("."), candidate.rfind("?"), candidate.rfind("!"))
    if sentence_end >= max_chars * 0.55:
        return candidate[: sentence_end + 1]
    return candidate.rstrip(" ,;:") + "."


def _voice_response_max_chars() -> int:
    try:
        return int(
            os.getenv(
                VOICE_RESPONSE_MAX_CHARS_ENV,
                str(DEFAULT_VOICE_RESPONSE_MAX_CHARS),
            )
        )
    except ValueError:
        return DEFAULT_VOICE_RESPONSE_MAX_CHARS
