import base64
from binascii import Error as BinasciiError
from app_services import get_rag_service
from constants import (
    SOCKET_AUDIO_BASE64_KEY,
    SOCKET_AUDIO_FILENAME_KEY,
    SOCKET_AUDIO_MIME_TYPE_KEY,
    DEFAULT_SESSION_ID,
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
    SOCKET_VOICE_AUDIO_EVENT,
    SOCKET_VOICE_TRANSCRIPT_EVENT,
    SOCKET_VOICE_TRANSCRIBING_EVENT,
)
from app_services import get_openai_service
from socket_rooms import session_room
from socket_server import sio


@sio.event
async def connect(sid, environ):
    print(f"{SOCKET_CONNECT_EVENT}: {sid}")


@sio.event
async def disconnect(sid):
    print(f"{SOCKET_DISCONNECT_EVENT}: {sid}")


@sio.on(SOCKET_JOIN_EVENT)
async def join_session(sid, data):
    session_id = _get_session_id(data)
    await sio.enter_room(sid, session_room(session_id))
    await sio.emit(
        SOCKET_MESSAGE_ACK_EVENT,
        {SOCKET_SESSION_ID_KEY: session_id},
        to=sid,
    )


@sio.on(SOCKET_SEND_MESSAGE_EVENT)
async def send_message(sid, data):
    session_id = _get_session_id(data)
    question = (data or {}).get(SOCKET_QUESTION_KEY, "").strip()

    if not question:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_ERROR_KEY: "Question is required."},
            to=sid,
        )
        return

    room = session_room(session_id)
    await sio.enter_room(sid, room)
    await sio.emit(SOCKET_MESSAGE_ACK_EVENT, {SOCKET_SESSION_ID_KEY: session_id}, to=sid)
    await sio.emit(SOCKET_ASSISTANT_TYPING_EVENT, {SOCKET_SESSION_ID_KEY: session_id}, to=room)

    try:
        async for chunk in get_rag_service().stream_answer_question(question, session_id):
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
    except Exception as exc:
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
    session_id = _get_session_id(data)
    audio_b64 = (data or {}).get(SOCKET_AUDIO_BASE64_KEY, "").strip()
    filename = (data or {}).get(SOCKET_AUDIO_FILENAME_KEY) or "voice.webm"

    if not audio_b64:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: "Audio is required."},
            to=sid,
        )
        return

    try:
        audio_bytes = _decode_audio_payload(audio_b64)
    except (ValueError, BinasciiError) as exc:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
            to=sid,
        )
        return

    await sio.emit(
        SOCKET_VOICE_TRANSCRIBING_EVENT,
        {SOCKET_SESSION_ID_KEY: session_id},
        to=sid,
    )

    try:
        transcript = await get_openai_service().transcribe_audio_bytes(
            audio_bytes,
            filename=filename,
        )
        if not transcript:
            raise ValueError("Could not understand the audio. Please try again.")

        await sio.emit(
            SOCKET_VOICE_TRANSCRIPT_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_QUESTION_KEY: transcript},
            to=sid,
        )
    except Exception as exc:
        await sio.emit(
            SOCKET_ASSISTANT_ERROR_EVENT,
            {SOCKET_SESSION_ID_KEY: session_id, SOCKET_ERROR_KEY: str(exc)},
            to=sid,
        )


def _get_session_id(data) -> str:
    session_id = (data or {}).get(SOCKET_SESSION_ID_KEY) or DEFAULT_SESSION_ID
    return str(session_id).strip() or DEFAULT_SESSION_ID


def _decode_audio_payload(audio_b64: str) -> bytes:
    if "," in audio_b64 and audio_b64.startswith("data:"):
        audio_b64 = audio_b64.split(",", 1)[1]

    return base64.b64decode(audio_b64)
