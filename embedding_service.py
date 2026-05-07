from openai.types.chat import chat_completion_allowed_tool_choice_param
import os
from openai import AsyncOpenAI
from dotenv import load_dotenv
from constants import EMBEDDING_MODEL, OPENAI_API_KEY_ENV, OPENAI_API_KEY_MISSING_ERROR

load_dotenv()


class EmbeddingService:
    def __init__(self):
        api_key = os.getenv(OPENAI_API_KEY_ENV)
        if not api_key:
            raise ValueError(OPENAI_API_KEY_MISSING_ERROR)
        self.client = AsyncOpenAI(api_key=api_key)

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        response = await self.client.embeddings.create(
            model=EMBEDDING_MODEL,
            input=texts,
        )
        return [item.embedding for item in response.data]
