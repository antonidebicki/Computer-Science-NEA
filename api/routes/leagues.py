from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import LeagueOut, LeagueCreate
from api.auth import AuthUtils

router = APIRouter()


@router.get("/leagues", response_model=List[LeagueOut])
async def list_leagues(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> List[LeagueOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            """
            SELECT league_id, name, admin_user_id, description, rules, created_at
            FROM "Leagues"
            ORDER BY name;
            """
        )
    return [LeagueOut(**row) for row in rows]


@router.get("/leagues/{league_id}", response_model=LeagueOut)
async def get_league(request: Request, league_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> LeagueOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        row = await connection.fetchrow(
            """
            SELECT league_id, name, admin_user_id, description, rules, created_at
            FROM "Leagues"
            WHERE league_id = $1;
            """,
            league_id,
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found")
    return LeagueOut(**row)


@router.post("/leagues", response_model=LeagueOut, status_code=status.HTTP_201_CREATED)
async def create_league(request: Request, payload: LeagueCreate, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> LeagueOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Leagues" (name, admin_user_id, description, rules)
                VALUES ($1, $2, $3, $4)
                RETURNING league_id, name, admin_user_id, description, rules, created_at;
                """,
                payload.name,
                payload.admin_user_id,
                payload.description,
                payload.rules,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create league.",
            ) from exc
    return LeagueOut(**row)
