from typing import List, Optional
from fastapi import APIRouter, File, HTTPException, UploadFile
from constants import (
    DOCUMENT_LIST_ROUTE,
    DOCUMENT_UPLOAD_ROUTE,
    HTTP_BAD_REQUEST,
    HTTP_INTERNAL_SERVER_ERROR,
    SERVICE_ERROR_PREFIX,
)
from app_services import get_document_service
from models import DocumentListResponse, DocumentUploadResponse

router = APIRouter()


@router.post(DOCUMENT_UPLOAD_ROUTE, response_model=DocumentUploadResponse)
async def upload_documents(files: Optional[List[UploadFile]] = File(default=None)):
    try:
        if not files:
            raise ValueError("Please select at least one document.")

        return await get_document_service().upload_documents(files)

    except ValueError as ve:
        raise HTTPException(status_code=HTTP_BAD_REQUEST, detail=str(ve))

    except Exception as e:
        raise HTTPException(
            status_code=HTTP_INTERNAL_SERVER_ERROR,
            detail=f"{SERVICE_ERROR_PREFIX}: {str(e)}",
        )


@router.get(DOCUMENT_LIST_ROUTE, response_model=DocumentListResponse)
async def list_documents():
    return {"documents": get_document_service().list_documents()}
