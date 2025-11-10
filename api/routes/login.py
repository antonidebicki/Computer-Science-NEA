from fastapi import APIRouter, HTTPException, Request, status
from api.authentication.auth import AuthUtils
from api.core.models import LoginRequest, LoginResponse, UserInfo
import asyncpg

router = APIRouter()

@router.post("/login", response_model=LoginResponse)
async def login(request: Request, payload: LoginRequest) -> LoginResponse:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        user = await connection.fetchrow(
            """
            SELECT user_id, username, hashed_password, email, full_name, role 
            FROM "Users" 
            WHERE username = $1;
            """,
            payload.username,
        )
        if not user or not AuthUtils.verify_password(payload.password, user["hashed_password"]):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
        
        claims = {
            "sub": user["username"],
            "user_id": user["user_id"],
            "role": user["role"]
        }
        access_token = AuthUtils.create_access_token(claims)
        refresh_token = AuthUtils.create_refresh_token(claims)
        
        return LoginResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserInfo(
                user_id=user["user_id"],
                username=user["username"],
                email=user["email"],
                full_name=user["full_name"],
                role=user["role"]
            )
        )