from document_service import DocumentService
from embedding_service import EmbeddingService
from rag_service import RagService
from services import OpenAIService
from vector_store import VectorStore


_embedding_service = None
_vector_store = None
_openai_service = None
_document_service = None
_rag_service = None


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


def get_openai_service():
    global _openai_service
    if _openai_service is None:
        _openai_service = OpenAIService()
    return _openai_service


def get_document_service():
    global _document_service
    if _document_service is None:
        _document_service = DocumentService(get_embedding_service(), get_vector_store())
    return _document_service


def get_rag_service():
    global _rag_service
    if _rag_service is None:
        _rag_service = RagService(
            get_embedding_service(),
            get_vector_store(),
            get_openai_service(),
        )
    return _rag_service
