from document_service import DocumentService
from embedding_service import EmbeddingService
from chat_history_service import ChatHistoryService
from mongo_service import MongoService
from auth_service import AuthService
from rag_service import RagService
from services import OpenAIService
from vector_store import VectorStore


_mongo_service = None
_embedding_service = None
_vector_store = None
_chat_history_service = None
_openai_service = None
_auth_service = None
_document_service = None
_rag_service = None


def get_mongo_service():
    global _mongo_service
    if _mongo_service is None:
        _mongo_service = MongoService()
    return _mongo_service


def get_embedding_service():
    global _embedding_service
    if _embedding_service is None:
        _embedding_service = EmbeddingService()
    return _embedding_service


def get_vector_store():
    global _vector_store
    if _vector_store is None:
        _vector_store = VectorStore()
    return _vector_store


def get_chat_history_service():
    global _chat_history_service
    if _chat_history_service is None:
        _chat_history_service = ChatHistoryService(get_mongo_service())
    return _chat_history_service


def get_openai_service():
    global _openai_service
    if _openai_service is None:
        _openai_service = OpenAIService(get_chat_history_service())
    return _openai_service


def get_auth_service():
    global _auth_service
    if _auth_service is None:
        _auth_service = AuthService(get_mongo_service())
    return _auth_service


def get_document_service():
    global _document_service
    if _document_service is None:
        _document_service = DocumentService(
            get_embedding_service(),
            get_vector_store(),
            get_mongo_service(),
        )
    return _document_service


def get_rag_service():
    global _rag_service
    if _rag_service is None:
        _rag_service = RagService(
            get_embedding_service(),
            get_vector_store(),
            get_openai_service(),
            get_chat_history_service(),
        )
    return _rag_service
