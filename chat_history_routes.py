from fastapi import APIRouter, Depends
from constants import CHAT_HISTORY_ROUTE, DEFAULT_SESSION_ID
from app_services import get_chat_history_service
from auth_dependencies import get_current_user
from models import ChatHistoryResponse, ChatMessage

router = APIRouter()


@router.get(CHAT_HISTORY_ROUTE, response_model=ChatHistoryResponse)
async def chat_history(session_id: str = DEFAULT_SESSION_ID, current_user=Depends(get_current_user)):
    history = await get_chat_history_service().get_session_history(
        user_id=current_user["id"],
        session_id=session_id,
    )
    return {
        "session_id": session_id,
        "messages": [
            ChatMessage(
                timestamp=item["created_at"],
                role=item["role"],
                message=item["message"],
            )
            for item in history
        ],
    }
