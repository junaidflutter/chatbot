import atexit
from uuid import uuid4
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams
from constants import EMBEDDING_DIMENSION, FILENAME_RESPONSE_KEY, QDRANT_COLLECTION_NAME, QDRANT_PATH


class VectorStore:
    def __init__(self):
        self.client = QdrantClient(path=QDRANT_PATH)
        self.collection_name = QDRANT_COLLECTION_NAME
        self._ensure_collection()
        atexit.register(self.close)

    def _ensure_collection(self):
        if self.client.collection_exists(self.collection_name):
            return

        self.client.create_collection(
            collection_name=self.collection_name,
            vectors_config=VectorParams(
                size=EMBEDDING_DIMENSION,
                distance=Distance.COSINE,
            ),
        )

    def add_chunks(self, chunks: list[dict], vectors: list[list[float]]) -> int:
        points = [
            PointStruct(
                id=str(uuid4()),
                vector=vector,
                payload=chunk,
            )
            for chunk, vector in zip(chunks, vectors)
        ]

        if not points:
            return 0

        self.client.upsert(
            collection_name=self.collection_name,
            points=points,
        )
        return len(points)

    def search(self, vector: list[float], limit: int):
        response = self.client.query_points(
            collection_name=self.collection_name,
            query=vector,
            limit=limit,
            with_payload=True,
        )
        return response.points

    def list_documents(self) -> list[str]:
        points, _ = self.client.scroll(
            collection_name=self.collection_name,
            limit=1000,
            with_payload=True,
            with_vectors=False,
        )
        filenames = {
            point.payload[FILENAME_RESPONSE_KEY]
            for point in points
            if point.payload and FILENAME_RESPONSE_KEY in point.payload
        }
        return sorted(filenames)

    def close(self):
        self.client.close()
