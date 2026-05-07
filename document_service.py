from pathlib import Path
from fastapi import UploadFile
from pypdf import PdfReader
from constants import (
    CHUNK_INDEX_RESPONSE_KEY,
    CHUNK_OVERLAP,
    CHUNK_SIZE,
    FILENAME_RESPONSE_KEY,
    MESSAGE_KEY,
    SUPPORTED_DOCUMENT_EXTENSIONS,
    TOTAL_CHUNKS_RESPONSE_KEY,
    UPLOADED_FILES_RESPONSE_KEY,
)
from embedding_service import EmbeddingService
from vector_store import VectorStore


class DocumentService:
    def __init__(self, embedding_service: EmbeddingService, vector_store: VectorStore):
        self.embedding_service = embedding_service
        self.vector_store = vector_store

    async def upload_documents(self, files: list[UploadFile]) -> dict:
        all_chunks = []
        uploaded_files = []

        for file in files:
            text = await self._extract_text(file)
            if not text.strip():
                continue

            chunks = self._chunk_text(text)
            for index, chunk in enumerate(chunks):
                all_chunks.append(
                    {
                        FILENAME_RESPONSE_KEY: file.filename,
                        CHUNK_INDEX_RESPONSE_KEY: index,
                        MESSAGE_KEY: chunk,
                    }
                )

            uploaded_files.append(file.filename)

        if not all_chunks:
            return {UPLOADED_FILES_RESPONSE_KEY: uploaded_files, TOTAL_CHUNKS_RESPONSE_KEY: 0}

        vectors = await self.embedding_service.embed_texts(
            [chunk[MESSAGE_KEY] for chunk in all_chunks]
        )
        total_chunks = self.vector_store.add_chunks(all_chunks, vectors)

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

    def list_documents(self) -> list[str]:
        return self.vector_store.list_documents()
