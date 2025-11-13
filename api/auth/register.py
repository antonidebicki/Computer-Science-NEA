from api.auth import AuthUtils
from api.models import UserCreate, UserOut, RegisterRequest
from api.routes.users import create_user
from fastapi import APIRouter, Request, status

router = APIRouter()



@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(request: Request, payload: RegisterRequest) -> UserOut:
    
    user_create = UserCreate(
        username=payload.username,
        hashed_password=AuthUtils.hash_password(payload.password),
        email=payload.email,
        full_name=payload.full_name,
        role=payload.role,
    )
    
    return await create_user(request, user_create)
