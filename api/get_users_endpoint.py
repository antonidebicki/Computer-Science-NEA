from typing import List
from fastapi import APIRouter, Request
from .models import UserOut

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
