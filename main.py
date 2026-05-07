from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from constants import (
    APP_HOST,
    APP_PORT,
    APP_TITLE,
    DETAIL_RESPONSE_KEY,
    ERROR_RESPONSE_KEY,
    HTTP_INTERNAL_SERVER_ERROR,
    INTERNAL_SERVER_ERROR_MESSAGE,
)
from chat_routes import router as chat_router
from chat_view import router as chat_view_router
from document_routes import router as document_router
from document_view import router as document_view_router
import uvicorn
app = FastAPI(title=APP_TITLE)

app.include_router(chat_view_router)
app.include_router(document_view_router)
app.include_router(chat_router)
app.include_router(document_router)
@app.exception_handler(Exception)
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
