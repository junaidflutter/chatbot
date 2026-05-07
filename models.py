from pydantic import BaseModel
from typing import List, Optional
from constants import DEFAULT_SESSION_ID


class ChatRequest(BaseModel):
    question: str
    session_id: Optional[str] = DEFAULT_SESSION_ID


class ChatMessage(BaseModel):
    timestamp: str
    role: str
    message: str


class SourceChunk(BaseModel):
    filename: str
    chunk_index: int
    score: float


class ChatResponse(BaseModel):
    answer: str
    from_document: bool
    sources: List[SourceChunk]


class DocumentUploadResponse(BaseModel):
    uploaded_files: List[str]
    total_chunks: int


class DocumentListResponse(BaseModel):
    documents: List[str]
