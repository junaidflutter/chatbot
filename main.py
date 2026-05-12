from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse
from fastapi.responses import JSONResponse
from constants import (
    APP_HOST,
    APP_PORT,
    APP_TITLE,
    AUTH_VIEW_ROUTE,
    DETAIL_RESPONSE_KEY,
    ERROR_RESPONSE_KEY,
    HTTP_INTERNAL_SERVER_ERROR,
    INTERNAL_SERVER_ERROR_MESSAGE,
    ROOT_ROUTE,
    SOCKET_IO_PATH,
)
from chat_routes import router as chat_router
from chat_history_routes import router as chat_history_router
from auth_routes import router as auth_router
from chat_view import router as chat_view_router
from auth_view import router as auth_view_router
from document_routes import router as document_router
from document_view import router as document_view_router
from voice_view import router as voice_view_router
from socket_server import sio
import socket_events
import socketio
import uvicorn
api_app = FastAPI(title=APP_TITLE)

api_app.include_router(chat_view_router)
api_app.include_router(auth_view_router)
api_app.include_router(document_view_router)
api_app.include_router(voice_view_router)
api_app.include_router(auth_router)
api_app.include_router(chat_router)
api_app.include_router(chat_history_router)
api_app.include_router(document_router)
app = socketio.ASGIApp(sio, other_asgi_app=api_app, socketio_path=SOCKET_IO_PATH)


@api_app.get(ROOT_ROUTE)
async def root():
    return RedirectResponse(url=AUTH_VIEW_ROUTE)


@api_app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=HTTP_INTERNAL_SERVER_ERROR,
        content={
            DETAIL_RESPONSE_KEY: INTERNAL_SERVER_ERROR_MESSAGE,
            ERROR_RESPONSE_KEY: str(exc),
        },
    )

if __name__ == "__main__":
    uvicorn.run(app, host=APP_HOST, port=APP_PORT)
