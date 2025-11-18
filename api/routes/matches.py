from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import MatchOut, MatchCreate
from api.auth import AuthUtils

router = APIRouter()


@router.get("/matches", response_model=List[MatchOut])
async def list_matches(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> List[MatchOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            """
            SELECT match_id, season_id, home_team_id, away_team_id, match_datetime,
                   venue, status, winner_team_id, home_sets_won, away_sets_won
            FROM "Matches"
            ORDER BY match_datetime DESC;
            """
        )
    return [MatchOut(**row) for row in rows]


@router.get("/matches/{match_id}", response_model=MatchOut)
async def get_match(request: Request, match_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> MatchOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        row = await connection.fetchrow(
            """
            SELECT match_id, season_id, home_team_id, away_team_id, match_datetime,
                   venue, status, winner_team_id, home_sets_won, away_sets_won
            FROM "Matches"
            WHERE match_id = $1;
            """,
            match_id,
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return MatchOut(**row)


@router.post("/matches", response_model=MatchOut, status_code=status.HTTP_201_CREATED)
async def create_match(request: Request, payload: MatchCreate, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> MatchOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
                VALUES ($1, $2, $3, $4, $5, 'SCHEDULED'::game_states)
                RETURNING match_id, season_id, home_team_id, away_team_id, match_datetime,
                          venue, status, winner_team_id, home_sets_won, away_sets_won;
                """,
                payload.season_id,
                payload.home_team_id,
                payload.away_team_id,
                payload.match_datetime,
                payload.venue,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create match.",
            ) from exc
    return MatchOut(**row)
