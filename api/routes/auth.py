from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.core.models import UserOut
from api.core.auth import AuthUtils
import asyncpg

router = APIRouter()

@router.post("/login")
async def login(request: Request, username: str, password: str):
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        user = await connection.fetchrow(
            """
            SELECT user_id, username, hashed_password, role FROM "Users" WHERE username = $1;
            """,
            username,
        )
        if not user or not AuthUtils.verify_password(password, user["hashed_password"]):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
        access_token = AuthUtils.create_access_token({
            "sub": user["username"],
            "user_id": user["user_id"],
            "role": user["role"]
        })
        return {"access_token": access_token, "token_type": "bearer"}
