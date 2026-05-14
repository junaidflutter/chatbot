from fastapi import APIRouter, Depends, HTTPException
from constants import AUTH_ACCESS_TOKEN_KEY, AUTH_TOKEN_TYPE, AUTH_USER_KEY, HTTP_BAD_REQUEST, HTTP_INTERNAL_SERVER_ERROR, SERVICE_ERROR_PREFIX
from auth_dependencies import get_current_user
from app_services import get_auth_service
from models import AuthResponse, LoginRequest, RegisterRequest, UserResponse

router = APIRouter()


def _user_payload(user: dict) -> dict:
    return {
        "id": user.get("user_id") or str(user.get("_id", "")),
        "email": user["email"],
        "name": user.get("name", ""),
    }


@router.post("/auth/register", response_model=AuthResponse)
async def register(request: RegisterRequest):
    try:
        user = await get_auth_service().register_user(request.email, request.password, request.name or "")
        token = get_auth_service().create_token(user)
        return {
            AUTH_ACCESS_TOKEN_KEY: token,
            "token_type": AUTH_TOKEN_TYPE,
            AUTH_USER_KEY: _user_payload(user),
        }
    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=HTTP_INTERNAL_SERVER_ERROR, detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}")


@router.post("/auth/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    try:
        user = await get_auth_service().login_user(request.email, request.password)
        token = get_auth_service().create_token(user)
        return {
            AUTH_ACCESS_TOKEN_KEY: token,
            "token_type": AUTH_TOKEN_TYPE,
            AUTH_USER_KEY: _user_payload(user),
        }
    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=HTTP_INTERNAL_SERVER_ERROR, detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}")


@router.get("/auth/me", response_model=UserResponse)
async def me(user=Depends(get_current_user)):
    return {
        "id": user["id"],
        "email": user["email"],
        "name": user.get("name", ""),
    }
