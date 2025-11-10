from fastapi import APIRouter, HTTPException, Request, status
from api.authentication.auth import AuthUtils
from api.core.models import RefreshRequest, LoginResponse, UserInfo
import asyncpg

router = APIRouter()


@router.post("/refresh", response_model=LoginResponse)
async def refresh_token(request: Request, body: RefreshRequest) -> LoginResponse:
    payload = AuthUtils.decode_refresh_token(body.refresh_token)
    if "error" in payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    # Fetch fresh user data from database
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        user = await connection.fetchrow(
            """
            SELECT user_id, username, email, full_name, role 
            FROM "Users" 
            WHERE user_id = $1;
            """,
            payload.get("user_id"),
        )
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    # Issue new tokens with fresh claims
    claims = {
        "sub": user["username"],
        "user_id": user["user_id"],
        "role": user["role"],
    }
    new_access = AuthUtils.create_access_token(claims)
    new_refresh = AuthUtils.create_refresh_token(claims)
    
    return LoginResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        user=UserInfo(
            user_id=user["user_id"],
            username=user["username"],
            email=user["email"],
            full_name=user["full_name"],
            role=user["role"]
        )
    )
