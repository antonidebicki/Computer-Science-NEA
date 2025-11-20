from typing import List, Optional
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import MatchOut, MatchCreate, ProcessMatchRequest, ProcessMatchResponse
from api.auth import AuthUtils
from api.services.standings_engine import process_match_result

router = APIRouter()


@router.get("/matches", response_model=List[MatchOut])
async def list_matches(
    request: Request,
    season_id: Optional[int] = None,
    team_id: Optional[int] = None,
    user: dict = Depends(AuthUtils.get_current_user)
) -> List[MatchOut]:
    """List matches with optional filtering by season_id or team_id"""
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        query = """
            SELECT match_id, season_id, home_team_id, away_team_id, match_datetime,
                   venue, status, winner_team_id, home_sets_won, away_sets_won
            FROM "Matches"
            WHERE 1=1
        """
        params = []
        
        if season_id is not None:
            params.append(season_id)
            query += f" AND season_id = ${len(params)}"
        
        if team_id is not None:
            params.append(team_id)
            query += f" AND (home_team_id = ${len(params)} OR away_team_id = ${len(params)})"
        
        query += " ORDER BY match_datetime DESC;"
        rows = await connection.fetch(query, *params)
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


@router.post("/matches/process", response_model=ProcessMatchResponse)
async def process_match(
    request: Request,
    payload: ProcessMatchRequest,
    user: dict = Depends(AuthUtils.require_role(["ADMIN", "REFEREE"]))
) -> ProcessMatchResponse:
    """Process a finished match and update league standings"""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        async with connection.transaction():
            try:
                result = await process_match_result(connection, payload.match_id)
                
                return ProcessMatchResponse(
                    match_id=result.match_id,
                    season_id=result.season_id,
                    home_team_id=result.home_team_id,
                    away_team_id=result.away_team_id,
                    winner_team_id=result.winner_team_id,
                    status='PROCESSED',
                    message=f"Match {payload.match_id} processed successfully. Standings updated."
                )
            except ValueError as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=str(e)
                )
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to process match: {str(e)}"
                )

