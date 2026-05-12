import atexit
from uuid import uuid4
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, FieldCondition, Filter, MatchValue, PointStruct, VectorParams
from constants import EMBEDDING_DIMENSION, FILENAME_RESPONSE_KEY, QDRANT_COLLECTION_NAME, QDRANT_PATH, USER_ID_KEY


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

    def search(self, vector: list[float], limit: int, user_id: str | None = None):
        response = self.client.query_points(
            collection_name=self.collection_name,
            query=vector,
            query_filter=self._build_filter(user_id),
            limit=limit,
            with_payload=True,
        )
        return response.points

    def list_documents(self, user_id: str | None = None) -> list[str]:
        points, _ = self.client.scroll(
            collection_name=self.collection_name,
            limit=1000,
            scroll_filter=self._build_filter(user_id),
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

    def _build_filter(self, user_id: str | None):
        if not user_id:
            return None

        return Filter(
            must=[
                FieldCondition(
                    key=USER_ID_KEY,
                    match=MatchValue(value=user_id),
                )
            ]
        )
