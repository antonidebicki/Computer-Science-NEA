from typing import List
import asyncpg
from asyncpg import UniqueViolationError
from fastapi import APIRouter, HTTPException, Request, status
from api.core.models import UserCreate, UserOut

router = APIRouter()


@router.get("/users", response_model=List[UserOut])
async def list_users(request: Request) -> List[UserOut]:
  pool = request.app.state.pool
  async with pool.acquire() as connection:
    rows = await connection.fetch(
        """
        SELECT user_id, username, email, full_name, role, created_at
        FROM "Users"
        ORDER BY user_id;
        """
    )
  return [
      UserOut(
          user_id=row["user_id"],
          username=row["username"],
          email=row["email"],
          full_name=row["full_name"],
          role=row["role"],
          created_at=row["created_at"],
      )
      for row in rows
  ]


@router.post("/users", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(request: Request, payload: UserCreate) -> UserOut:
  pool = request.app.state.pool
  async with pool.acquire() as connection:
    try:
      row = await connection.fetchrow(
          """
          INSERT INTO "Users" (username, hashed_password, email, full_name, role)
          VALUES ($1, $2, $3, $4, $5)
          RETURNING user_id, username, email, full_name, role, created_at;
          """,
          payload.username,
          payload.hashed_password,
          payload.email,
          payload.full_name,
          payload.role,
      )
    except UniqueViolationError as exc:
      raise HTTPException(
          status_code=status.HTTP_409_CONFLICT,
          detail="A user with that username or email already exists.",
      ) from exc
    except asyncpg.PostgresError as exc:
      raise HTTPException(
          status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
          detail="Failed to create user.",
      ) from exc

  return UserOut(
      user_id=row["user_id"],
      username=row["username"],
      email=row["email"],
      full_name=row["full_name"],
      role=row["role"],
      created_at=row["created_at"],
  )
