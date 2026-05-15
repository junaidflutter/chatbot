from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from constants import (
    CHAT_STREAM_ROUTE,
    CHAT_ROUTE,
    HEALTH_ROUTE,
    HEALTH_STATUS,
    HEALTH_STATUS_KEY,
    HTTP_BAD_REQUEST,
    HTTP_INTERNAL_SERVER_ERROR,
    SERVICE_ERROR_PREFIX,
    USER_LOG_LABEL,
    USER_ROLE,
)
from app_services import get_rag_service
from auth_dependencies import get_current_user
from models import ChatRequest, ChatResponse
from utils import format_as_json, log_json

router = APIRouter()


@router.post(CHAT_ROUTE, response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest, current_user=Depends(get_current_user)):
    try:
        user_data = format_as_json(USER_ROLE, request.question)
        log_json(USER_LOG_LABEL, user_data)

        return await get_rag_service().answer_question(
            question=request.question,
            session_id=request.session_id,
            user_id=current_user["id"],
        )

    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))

    except Exception as e:
        raise HTTPException(
            status_code=HTTP_INTERNAL_SERVER_ERROR,
            detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}",
        )


@router.post(CHAT_STREAM_ROUTE)
async def stream_chat_with_bot(
    request: ChatRequest,
    current_user=Depends(get_current_user),
):
    async def stream_answer():
        try:
            async for chunk in get_rag_service().stream_answer_question(
                question=request.question,
                session_id=request.session_id,
                user_id=current_user["id"],
            ):
                if chunk:
                    yield chunk
        except Exception as exc:
            yield f"\n{SERVICE_ERROR_PREFIX}: {str(exc)}"

    return StreamingResponse(
        stream_answer(),
        media_type="text/plain; charset=utf-8",
    )


@router.get(HEALTH_ROUTE)
async def health_check():
    return {HEALTH_STATUS_KEY: HEALTH_STATUS}
