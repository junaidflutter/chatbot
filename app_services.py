from document_service import DocumentService
from embedding_service import EmbeddingService
from rag_service import RagService
from services import OpenAIService
from vector_store import VectorStore


embedding_service = EmbeddingService()
vector_store = VectorStore()
openai_service = OpenAIService()
document_service = DocumentService(embedding_service, vector_store)
rag_service = RagService(embedding_service, vector_store, openai_service)
