from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.core.models import TeamOut, TeamCreate
from api.authentication.auth import AuthUtils

router = APIRouter()


@router.get("/teams", response_model=List[TeamOut])
async def list_teams(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> List[TeamOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            """
            SELECT team_id, name, created_by_user_id, logo_url, created_at
            FROM "Teams"
            ORDER BY name;
            """
        )
    return [TeamOut(**row) for row in rows]


@router.get("/teams/{team_id}", response_model=TeamOut)
async def get_team(request: Request, team_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> TeamOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        row = await connection.fetchrow(
            """
            SELECT team_id, name, created_by_user_id, logo_url, created_at
            FROM "Teams"
            WHERE team_id = $1;
            """,
            team_id,
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    return TeamOut(**row)


@router.post("/teams", response_model=TeamOut, status_code=status.HTTP_201_CREATED)
async def create_team(request: Request, payload: TeamCreate, user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))) -> TeamOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Teams" (name, created_by_user_id, logo_url)
                VALUES ($1, $2, $3)
                RETURNING team_id, name, created_by_user_id, logo_url, created_at;
                """,
                payload.name,
                payload.created_by_user_id,
                payload.logo_url,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create team.",
            ) from exc
    return TeamOut(**row)
