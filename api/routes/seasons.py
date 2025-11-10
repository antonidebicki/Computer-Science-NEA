from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.core.models import SeasonOut, SeasonCreate
from api.authentication.auth import AuthUtils

router = APIRouter()


@router.get("/seasons", response_model=List[SeasonOut])
async def list_seasons(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> List[SeasonOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            """
            SELECT season_id, league_id, name, start_date, end_date, is_archived
            FROM "Seasons"
            ORDER BY start_date DESC;
            """
        )
    return [SeasonOut(**row) for row in rows]


@router.get("/seasons/{season_id}", response_model=SeasonOut)
async def get_season(request: Request, season_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> SeasonOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        row = await connection.fetchrow(
            """
            SELECT season_id, league_id, name, start_date, end_date, is_archived
            FROM "Seasons"
            WHERE season_id = $1;
            """,
            season_id,
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Season not found")
    return SeasonOut(**row)


@router.post("/seasons", response_model=SeasonOut, status_code=status.HTTP_201_CREATED)
async def create_season(request: Request, payload: SeasonCreate, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> SeasonOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Seasons" (league_id, name, start_date, end_date)
                VALUES ($1, $2, $3, $4)
                RETURNING season_id, league_id, name, start_date, end_date, is_archived;
                """,
                payload.league_id,
                payload.name,
                payload.start_date,
                payload.end_date,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create season.",
            ) from exc
    return SeasonOut(**row)
