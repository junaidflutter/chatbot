from fastapi import APIRouter, File, HTTPException, UploadFile
from constants import (
    HTTP_BAD_REQUEST,
    HTTP_INTERNAL_SERVER_ERROR,
    SERVICE_ERROR_PREFIX,
    VOICE_TRANSCRIBE_ROUTE,
)
from app_services import get_openai_service

router = APIRouter()


@router.post(VOICE_TRANSCRIBE_ROUTE)
async def transcribe_voice(audio: UploadFile = File(...)):
    try:
        transcript = await get_openai_service().transcribe_audio(audio)
        if not transcript:
            raise ValueError("Could not understand the audio. Please try again.")
        return {"text": transcript}
    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))
    except Exception as e:
        raise HTTPException(
            status_code=HTTP_INTERNAL_SERVER_ERROR,
            detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}",
        )
