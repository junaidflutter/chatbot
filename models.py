from pydantic import BaseModel, Field
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
    document_id: str
    filename: str
    chunk_index: int
    score: float
    excerpt: str


class ChatResponse(BaseModel):
    answer: str
    from_document: bool
    sources: List[SourceChunk]
    citations: List["Citation"] = Field(default_factory=list)


class ChatHistoryResponse(BaseModel):
    session_id: str
    messages: List[ChatMessage]


class DocumentUploadResponse(BaseModel):
    uploaded_files: List[str]
    total_chunks: int


class DocumentListResponse(BaseModel):
    documents: List[str]


class RegisterRequest(BaseModel):
    email: str
    password: str
    name: Optional[str] = ""


class LoginRequest(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str] = ""


class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class Citation(BaseModel):
    document_id: str
    filename: str
    chunk_index: int
    score: float
    excerpt: str


ChatResponse.model_rebuild()
