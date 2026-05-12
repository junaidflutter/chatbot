import base64
import hashlib
import hmac
import json
import os
import secrets
from datetime import datetime, timezone
from typing import Optional
from constants import (
    AUTH_SECRET_DEFAULT,
    AUTH_SECRET_ENV,
    AUTH_TOKEN_TTL_SECONDS,
    CREATED_AT_KEY,
    EMAIL_KEY,
    NAME_KEY,
    PASSWORD_HASH_KEY,
    USERS_COLLECTION_KEY,
    USER_ID_KEY,
)


class AuthService:
    def __init__(self, mongo_service):
        self.mongo_service = mongo_service
        self.secret = os.getenv(AUTH_SECRET_ENV, AUTH_SECRET_DEFAULT).encode("utf-8")

    @staticmethod
    def _b64encode(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")

    @staticmethod
    def _b64decode(data: str) -> bytes:
        padding = "=" * (-len(data) % 4)
        return base64.urlsafe_b64decode((data + padding).encode("utf-8"))

    def hash_password(self, password: str) -> str:
        salt = secrets.token_bytes(16)
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 120000)
        return f"{self._b64encode(salt)}:{self._b64encode(digest)}"

    def verify_password(self, password: str, stored: str) -> bool:
        try:
            salt_part, hash_part = stored.split(":", 1)
            salt = self._b64decode(salt_part)
            expected = self._b64decode(hash_part)
            actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 120000)
            return hmac.compare_digest(expected, actual)
        except Exception:
            return False

    def create_token(self, user: dict) -> str:
        now = int(datetime.now(tz=timezone.utc).timestamp())
        payload = {
            USER_ID_KEY: str(user.get(USER_ID_KEY) or user.get("_id")),
            EMAIL_KEY: user.get(EMAIL_KEY),
            NAME_KEY: user.get(NAME_KEY, ""),
            "iat": now,
            "exp": now + AUTH_TOKEN_TTL_SECONDS,
        }
        payload_bytes = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        body = self._b64encode(payload_bytes)
        signature = hmac.new(self.secret, body.encode("utf-8"), hashlib.sha256).digest()
        return f"{body}.{self._b64encode(signature)}"

    def verify_token(self, token: str) -> Optional[dict]:
        try:
            body, signature = token.split(".", 1)
            expected = hmac.new(self.secret, body.encode("utf-8"), hashlib.sha256).digest()
            if not hmac.compare_digest(expected, self._b64decode(signature)):
                return None
            payload = json.loads(self._b64decode(body).decode("utf-8"))
            now = int(datetime.now(tz=timezone.utc).timestamp())
            if int(payload.get("exp", 0)) < now:
                return None
            return payload
        except Exception:
            return None

    async def register_user(self, email: str, password: str, name: str = "") -> dict:
        users = self.mongo_service.collection(USERS_COLLECTION_KEY)
        normalized_email = email.strip().lower()
        existing = await users.find_one({EMAIL_KEY: normalized_email})
        if existing:
            raise ValueError("Email already exists.")

        now = datetime.now(tz=timezone.utc).isoformat()
        user_id = secrets.token_hex(12)
        user_doc = {
            USER_ID_KEY: user_id,
            EMAIL_KEY: normalized_email,
            NAME_KEY: name.strip(),
            PASSWORD_HASH_KEY: self.hash_password(password),
            CREATED_AT_KEY: now,
        }
        result = await users.insert_one(user_doc)
        user_doc["_id"] = result.inserted_id
        return user_doc

    async def login_user(self, email: str, password: str) -> dict:
        users = self.mongo_service.collection(USERS_COLLECTION_KEY)
        normalized_email = email.strip().lower()
        user = await users.find_one({EMAIL_KEY: normalized_email})
        if not user or not self.verify_password(password, user.get(PASSWORD_HASH_KEY, "")):
            raise ValueError("Invalid email or password.")
        return user

    async def get_user_by_id(self, user_id: str) -> Optional[dict]:
        users = self.mongo_service.collection(USERS_COLLECTION_KEY)
        return await users.find_one({USER_ID_KEY: user_id})
