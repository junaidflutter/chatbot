from fastapi import Header, HTTPException, status
from constants import AUTH_BEARER_PREFIX, AUTH_HEADER_NAME


async def get_current_user(authorization: str = Header(default=None, alias=AUTH_HEADER_NAME)):
    if not authorization or not authorization.startswith(AUTH_BEARER_PREFIX):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing access token.")

    token = authorization[len(AUTH_BEARER_PREFIX) :].strip()
    from app_services import get_auth_service

    payload = get_auth_service().verify_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token.")

    user = await get_auth_service().get_user_by_id(payload["user_id"])
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found.")
    user["id"] = user["user_id"]
    return user
