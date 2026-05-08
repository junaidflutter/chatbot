import socketio
from constants import SOCKET_CORS_ALLOWED_ORIGINS


sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=SOCKET_CORS_ALLOWED_ORIGINS,
)
