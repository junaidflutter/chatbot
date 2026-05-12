from datetime import datetime, timezone
from constants import (
    CREATED_AT_KEY,
    MESSAGES_COLLECTION_KEY,
    MESSAGE_KEY,
    MESSAGE_ROLE_KEY,
    SESSION_ID_KEY,
    USER_ID_KEY,
)


class ChatHistoryService:
    def __init__(self, mongo_service):
        self.mongo_service = mongo_service

    async def add_message(self, user_id: str, session_id: str, role: str, message: str):
        messages = self.mongo_service.collection(MESSAGES_COLLECTION_KEY)
        await messages.insert_one(
            {
                USER_ID_KEY: user_id,
                SESSION_ID_KEY: session_id,
                MESSAGE_ROLE_KEY: role,
                MESSAGE_KEY: message,
                CREATED_AT_KEY: datetime.now(tz=timezone.utc).isoformat(),
            }
        )

    async def get_recent_messages(self, user_id: str, session_id: str, limit: int):
        messages = self.mongo_service.collection(MESSAGES_COLLECTION_KEY)
        cursor = (
            messages.find(
                {
                    USER_ID_KEY: user_id,
                    SESSION_ID_KEY: session_id,
                },
                {
                    "_id": 0,
                    MESSAGE_ROLE_KEY: 1,
                    MESSAGE_KEY: 1,
                },
            )
            .sort(CREATED_AT_KEY, 1)
            .limit(limit)
        )
        return [doc async for doc in cursor]

    async def get_session_history(self, user_id: str, session_id: str, limit: int = 100):
        messages = self.mongo_service.collection(MESSAGES_COLLECTION_KEY)
        cursor = (
            messages.find(
                {
                    USER_ID_KEY: user_id,
                    SESSION_ID_KEY: session_id,
                },
                {
                    "_id": 0,
                    CREATED_AT_KEY: 1,
                    MESSAGE_ROLE_KEY: 1,
                    MESSAGE_KEY: 1,
                },
            )
            .sort(CREATED_AT_KEY, 1)
            .limit(limit)
        )
        return [doc async for doc in cursor]
