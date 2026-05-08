from app_services import get_rag_service
from constants import (
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
)
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


def _get_session_id(data) -> str:
    session_id = (data or {}).get(SOCKET_SESSION_ID_KEY) or DEFAULT_SESSION_ID
    return str(session_id).strip() or DEFAULT_SESSION_ID
