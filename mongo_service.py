import json
import os
from importlib import import_module
from pathlib import Path
from constants import MONGODB_DB_DEFAULT, MONGODB_DB_ENV, MONGODB_URL_DEFAULT, MONGODB_URL_ENV


class _MemoryInsertResult:
    def __init__(self, inserted_id):
        self.inserted_id = inserted_id


class _MemoryCursor:
    def __init__(self, docs):
        self._docs = list(docs)

    def sort(self, key, direction):
        reverse = direction == -1
        self._docs.sort(key=lambda doc: (doc.get(key) is None, doc.get(key) or ""), reverse=reverse)
        return self

    def limit(self, limit):
        self._docs = self._docs[:limit]
        return self

    def __aiter__(self):
        self._iter = iter(self._docs)
        return self

    async def __anext__(self):
        try:
            return next(self._iter)
        except StopIteration:
            raise StopAsyncIteration


class _FileBackedStore:
    def __init__(self, path: str = ".local_data/memory_db.json"):
        self.path = Path(path)
        self._data = None

    def collection_docs(self, name: str):
        data = self._load()
        return data.setdefault(name, [])

    def save(self):
        if self._data is None:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self._data, indent=2), encoding="utf-8")

    def _load(self):
        if self._data is not None:
            return self._data
        if not self.path.exists():
            self._data = {}
            return self._data
        try:
            loaded = json.loads(self.path.read_text(encoding="utf-8"))
            self._data = loaded if isinstance(loaded, dict) else {}
        except Exception:
            self._data = {}
        return self._data


class _MemoryCollection:
    def __init__(self, name: str, store: _FileBackedStore):
        self.name = name
        self.store = store

    @property
    def _docs(self):
        return self.store.collection_docs(self.name)

    async def insert_one(self, doc):
        stored = dict(doc)
        self._docs.append(stored)
        self.store.save()
        return _MemoryInsertResult(stored.get("_id") or stored.get("user_id") or len(self._docs))

    async def insert_many(self, docs):
        for doc in docs:
            await self.insert_one(doc)

    async def find_one(self, query):
        for doc in self._docs:
            if all(doc.get(key) == value for key, value in query.items()):
                return dict(doc)
        return None

    def find(self, query, projection=None):
        matched = []
        for doc in self._docs:
            if all(doc.get(key) == value for key, value in query.items()):
                if projection:
                    projected = {}
                    for key, include in projection.items():
                        if key == "_id" or include:
                            if key in doc:
                                projected[key] = doc[key]
                    matched.append(projected)
                else:
                    matched.append(dict(doc))
        return _MemoryCursor(matched)


class _HybridCollection:
    def __init__(self, motor_collection, memory_collection):
        self.motor_collection = motor_collection
        self.memory_collection = memory_collection

    async def insert_one(self, doc):
        try:
            return await self.motor_collection.insert_one(doc)
        except Exception:
            return await self.memory_collection.insert_one(doc)

    async def insert_many(self, docs):
        try:
            return await self.motor_collection.insert_many(docs)
        except Exception:
            return await self.memory_collection.insert_many(docs)

    async def find_one(self, query):
        try:
            return await self.motor_collection.find_one(query)
        except Exception:
            return await self.memory_collection.find_one(query)

    def find(self, query, projection=None):
        try:
            return self.motor_collection.find(query, projection)
        except Exception:
            return self.memory_collection.find(query, projection)

    def _fallback_ready(self):
        return True


class MongoService:
    def __init__(self):
        self._client = None
        self._db = None
        self._memory_collections = {}
        self._file_store = _FileBackedStore()

    def _ensure_client(self):
        if self._client is None:
            mongo_url = os.getenv(MONGODB_URL_ENV, MONGODB_URL_DEFAULT)
            db_name = os.getenv(MONGODB_DB_ENV, MONGODB_DB_DEFAULT)
            try:
                motor_module = import_module("motor.motor_asyncio")
                async_client = getattr(motor_module, "AsyncIOMotorClient")
                self._client = async_client(mongo_url, serverSelectionTimeoutMS=1500)
                self._db = self._client[db_name]
            except Exception:
                self._client = None
                self._db = None

    @property
    def db(self):
        self._ensure_client()
        return self._db

    def collection(self, name: str):
        if name not in self._memory_collections:
            self._memory_collections[name] = _MemoryCollection(name, self._file_store)
        if self._db is None:
            return self._memory_collections[name]

        return _HybridCollection(self.db[name], self._memory_collections[name])

    async def close(self):
        if self._client is not None:
            self._client.close()
