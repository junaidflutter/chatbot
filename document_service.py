from pathlib import Path
from fastapi import UploadFile
from pypdf import PdfReader
from datetime import datetime, timezone
import secrets
from constants import (
    CHUNK_INDEX_RESPONSE_KEY,
    CHUNK_OVERLAP,
    CHUNK_SIZE,
    CREATED_AT_KEY,
    DOCUMENTS_COLLECTION_KEY,
    DOCUMENT_ID_KEY,
    FILENAME_RESPONSE_KEY,
    MESSAGE_KEY,
    SUPPORTED_DOCUMENT_EXTENSIONS,
    TOTAL_CHUNKS_RESPONSE_KEY,
    UPLOADED_FILES_RESPONSE_KEY,
    USER_ID_KEY,
)
from embedding_service import EmbeddingService
from vector_store import VectorStore


class DocumentService:
    def __init__(self, embedding_service: EmbeddingService, vector_store: VectorStore, mongo_service=None):
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.mongo_service = mongo_service

    async def upload_documents(self, files: list[UploadFile], user_id: str) -> dict:
        all_chunks = []
        uploaded_files = []
        documents = []

        for file in files:
            document_id = secrets.token_hex(12)
            text = await self._extract_text(file)
            if not text.strip():
                continue

            chunks = self._chunk_text(text)
            for index, chunk in enumerate(chunks):
                all_chunks.append(
                    {
                        DOCUMENT_ID_KEY: document_id,
                        USER_ID_KEY: user_id,
                        FILENAME_RESPONSE_KEY: file.filename,
                        CHUNK_INDEX_RESPONSE_KEY: index,
                        MESSAGE_KEY: chunk,
                    }
                )

            uploaded_files.append(file.filename)
            documents.append(
                {
                    DOCUMENT_ID_KEY: document_id,
                    USER_ID_KEY: user_id,
                    FILENAME_RESPONSE_KEY: file.filename,
                    "chunk_count": len(chunks),
                    CREATED_AT_KEY: datetime.now(tz=timezone.utc).isoformat(),
                }
            )

        if not all_chunks:
            return {
                UPLOADED_FILES_RESPONSE_KEY: uploaded_files,
                TOTAL_CHUNKS_RESPONSE_KEY: 0,
            }

        vectors = await self.embedding_service.embed_texts(
            [chunk[MESSAGE_KEY] for chunk in all_chunks]
        )
        total_chunks = self.vector_store.add_chunks(all_chunks, vectors)
        if self.mongo_service is not None and documents:
            await self.mongo_service.collection(DOCUMENTS_COLLECTION_KEY).insert_many(documents)

        return {
            UPLOADED_FILES_RESPONSE_KEY: uploaded_files,
            TOTAL_CHUNKS_RESPONSE_KEY: total_chunks,
        }

    async def _extract_text(self, file: UploadFile) -> str:
        extension = Path(file.filename or "").suffix.lower()
        if extension not in SUPPORTED_DOCUMENT_EXTENSIONS:
            raise ValueError(f"Unsupported file type: {extension}")

        content = await file.read()
        if extension == ".pdf":
            return self._extract_pdf_text(content)

        return content.decode("utf-8", errors="ignore")

    def _extract_pdf_text(self, content: bytes) -> str:
        from io import BytesIO

        reader = PdfReader(BytesIO(content))
        return "\n".join(page.extract_text() or "" for page in reader.pages)

    def _chunk_text(self, text: str) -> list[str]:
        clean_text = " ".join(text.split())
        chunks = []
        start = 0

        while start < len(clean_text):
            end = start + CHUNK_SIZE
            chunks.append(clean_text[start:end])
            start = end - CHUNK_OVERLAP

        return chunks

    async def list_documents(self, user_id: str) -> list[str]:
        if self.mongo_service is None:
            return self.vector_store.list_documents(user_id=user_id)

        cursor = (
            self.mongo_service.collection(DOCUMENTS_COLLECTION_KEY)
            .find({USER_ID_KEY: user_id}, {FILENAME_RESPONSE_KEY: 1, "_id": 0})
            .sort(CREATED_AT_KEY, -1)
        )
        docs = [doc async for doc in cursor]
        filenames = [doc[FILENAME_RESPONSE_KEY] for doc in docs if FILENAME_RESPONSE_KEY in doc]
        return filenames
