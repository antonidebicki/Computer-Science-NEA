from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import LeagueOut, LeagueCreate, SeasonOut, SeasonCreate
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


@router.get("/leagues/{league_id}/seasons", response_model=List[SeasonOut])
async def list_league_seasons(request: Request, league_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> List[SeasonOut]:
    """Get all seasons for a specific league"""
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        # First verify league exists
        league = await connection.fetchrow(
            'SELECT league_id FROM "Leagues" WHERE league_id = $1',
            league_id
        )
        if not league:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found")
        
        # Get all seasons for this league
        rows = await connection.fetch(
            """
            SELECT season_id, league_id, name, start_date, end_date, is_archived
            FROM "Seasons"
            WHERE league_id = $1
            ORDER BY start_date DESC;
            """,
            league_id,
        )
    return [SeasonOut(**row) for row in rows]


@router.post("/leagues/{league_id}/seasons", response_model=SeasonOut, status_code=status.HTTP_201_CREATED)
async def create_league_season(request: Request, league_id: int, payload: SeasonCreate, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> SeasonOut:
    """Create a new season for a specific league"""
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        # First verify league exists
        league = await connection.fetchrow(
            'SELECT league_id FROM "Leagues" WHERE league_id = $1',
            league_id
        )
        if not league:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found")
        
        # Verify the payload league_id matches the URL parameter
        if payload.league_id != league_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"League ID in payload ({payload.league_id}) does not match URL parameter ({league_id})"
            )
        
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Seasons" (league_id, name, start_date, end_date)
                VALUES ($1, $2, $3, $4)
                RETURNING season_id, league_id, name, start_date, end_date, is_archived;
                """,
                league_id,
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
