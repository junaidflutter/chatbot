from constants import SOCKET_DEFAULT_ROOM_PREFIX


def session_room(session_id: str) -> str:
    return f"{SOCKET_DEFAULT_ROOM_PREFIX}:{session_id}"
