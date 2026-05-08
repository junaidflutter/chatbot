APP_TITLE = "AI Chatbot API"

APP_HOST = "127.0.0.1"

APP_PORT = 8000

OPENAI_API_KEY_ENV = "OPENAI_API_KEY"

DEFAULT_MODEL = "gpt-4o-mini"

EMBEDDING_MODEL = "text-embedding-3-small"

EMBEDDING_DIMENSION = 1536

DEFAULT_SESSION_ID = "default"

CHAT_HISTORY_LIMIT = 7

RAG_TOP_K = 4

RAG_MIN_SCORE = 0.25

CAR_RELATED_KEYWORDS = {
    "car",
    "cars",
    "vehicle",
    "vehicles",
    "auto",
    "automobile",
    "civic",
    "corolla",
    "honda",
    "toyota",
    "suzuki",
    "mehran",
    "alto",
    "cultus",
    "model",
    "mileage",
    "engine",
    "registration",
    "documents",
    "document",
    "sell",
    "selling",
    "buyer",
    "dealer",
    "dealership",
    "price",
    "negotiate",
    "negotiation",
    "inspection",
    "test drive",
    "ownership",
    "transfer",
    "electric car",
    "ev",
    "kia",
    "hyundai",
}

CHUNK_SIZE = 900

CHUNK_OVERLAP = 150

OPENAI_TEMPERATURE = 0.4

OPENAI_MAX_TOKENS = 180

SYSTEM_ROLE = "system"

USER_ROLE = "user"

ASSISTANT_ROLE = "assistant"

MESSAGE_CONTENT_KEY = "content"

MESSAGE_ROLE_KEY = "role"

USER_LOG_LABEL = "USER JSON"

BOT_LOG_LABEL = "BOT JSON"

HEALTH_STATUS = "healthy"

INTERNAL_SERVER_ERROR_MESSAGE = "An internal server error occurred."

OPENAI_API_KEY_MISSING_ERROR = "OPENAI_API_KEY is not set in environment variables."

SERVICE_ERROR_PREFIX = "Service Error"

TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"

JSON_INDENT = 4

HTTP_BAD_REQUEST = 400

HTTP_INTERNAL_SERVER_ERROR = 500

CHAT_ROUTE = "/chat"

SOCKET_IO_PATH = "socket.io"

SOCKET_CORS_ALLOWED_ORIGINS = "*"

SOCKET_CONNECT_EVENT = "connect"

SOCKET_DISCONNECT_EVENT = "disconnect"

SOCKET_JOIN_EVENT = "join_session"

SOCKET_SEND_MESSAGE_EVENT = "send_message"

SOCKET_VOICE_AUDIO_EVENT = "voice_audio"

SOCKET_VOICE_TRANSCRIBING_EVENT = "voice_transcribing"

SOCKET_VOICE_TRANSCRIPT_EVENT = "voice_transcript"

SOCKET_MESSAGE_ACK_EVENT = "message_ack"

SOCKET_ASSISTANT_TYPING_EVENT = "assistant_typing"

SOCKET_ASSISTANT_CHUNK_EVENT = "assistant_chunk"

SOCKET_ASSISTANT_DONE_EVENT = "assistant_done"

SOCKET_ASSISTANT_ERROR_EVENT = "assistant_error"

SOCKET_SESSION_ID_KEY = "session_id"

SOCKET_QUESTION_KEY = "question"

SOCKET_AUDIO_BASE64_KEY = "audio_base64"

SOCKET_AUDIO_MIME_TYPE_KEY = "mime_type"

SOCKET_AUDIO_FILENAME_KEY = "audio_filename"

SOCKET_CHUNK_KEY = "chunk"

SOCKET_DONE_KEY = "done"

SOCKET_ERROR_KEY = "error"

SOCKET_DEFAULT_ROOM_PREFIX = "session"

DOCUMENT_UPLOAD_ROUTE = "/documents/upload"

DOCUMENT_LIST_ROUTE = "/documents"

CHAT_VIEW_ROUTE = "/"

DOCUMENT_VIEW_ROUTE = "/documents/view"

VOICE_VIEW_ROUTE = "/voice"

VOICE_TRANSCRIBE_ROUTE = "/voice/transcribe"

HEALTH_ROUTE = "/health"

DETAIL_RESPONSE_KEY = "detail"

ERROR_RESPONSE_KEY = "error"

USER_QUERY_RESPONSE_KEY = "user_query"

BOT_RESPONSE_KEY = "bot_response"

ANSWER_RESPONSE_KEY = "answer"

FROM_DOCUMENT_RESPONSE_KEY = "from_document"

SOURCES_RESPONSE_KEY = "sources"

FILENAME_RESPONSE_KEY = "filename"

CHUNK_INDEX_RESPONSE_KEY = "chunk_index"

SCORE_RESPONSE_KEY = "score"

DOCUMENTS_RESPONSE_KEY = "documents"

UPLOADED_FILES_RESPONSE_KEY = "uploaded_files"

TOTAL_CHUNKS_RESPONSE_KEY = "total_chunks"

HEALTH_STATUS_KEY = "status"

TIMESTAMP_KEY = "timestamp"

ROLE_KEY = "role"

MESSAGE_KEY = "message"

LOG_HEADER_TEMPLATE = "\n--- {label} ---"

CAR_SELLING_SYSTEM_PROMPT = """
You are a car-selling assistant.

Your job:
- Help the user sell their car.
- Ask useful follow-up questions about the car if details are missing.
- Use the user's previous context when they already shared car details.
- Guide the user on price positioning, listing details, photos, condition, documents, negotiation, and buyer communication.

Important rules:
- If the user talks about anything unrelated to selling cars or car-sale guidance, politely refuse.
- Tell them you can only help with selling cars or car-related selling guidance.
- Keep answers practical and easy to understand.
- Keep every answer short, usually under 120 words.
- Always reply in English only, even if the user writes in another language.
- Never reply in Spanish, Urdu, Roman Urdu, or any language other than English.
"""

VOICE_TRANSCRIPTION_PROMPT = """
This is a short English voice conversation about selling cars and car-related guidance.
Preserve the user's wording as closely as possible.
Common terms may include reference, referral, registration, transfer, mileage, engine, documents, inspection, negotiate, and car model names.
"""

ENGLISH_ONLY_PROMPT = "Reply in English only. Do not use Spanish or any other language."

QDRANT_PATH = "qdrant_data"

QDRANT_COLLECTION_NAME = "project_documents"

SUPPORTED_DOCUMENT_EXTENSIONS = {".txt", ".md", ".pdf"}

RAG_SYSTEM_PROMPT = """
You decide whether the provided document context directly answers the user's question.

Rules:
- Return JSON only.
- Use can_answer_from_context=true only when the context directly contains the answer.
- Use can_answer_from_context=false when the context is only generally related or does not answer the exact question.
- If can_answer_from_context=true, answer from the document context only.
- If can_answer_from_context=false, keep answer empty.
- Always reply in English only.
- Keep the answer short and practical.

JSON format:
{"can_answer_from_context": true, "answer": "short answer from context"}
"""
