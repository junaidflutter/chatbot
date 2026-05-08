from fastapi import APIRouter, HTTPException
from constants import (
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
from models import ChatRequest, ChatResponse
from utils import format_as_json, log_json

router = APIRouter()


@router.post(CHAT_ROUTE, response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest):
    try:
        user_data = format_as_json(USER_ROLE, request.question)
        log_json(USER_LOG_LABEL, user_data)

        return await get_rag_service().answer_question(
            question=request.question,
            session_id=request.session_id,
        )

    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))

    except Exception as e:
        raise HTTPException(
            status_code=HTTP_INTERNAL_SERVER_ERROR,
            detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}",
        )


@router.get(HEALTH_ROUTE)
async def health_check():
    return {HEALTH_STATUS_KEY: HEALTH_STATUS}
