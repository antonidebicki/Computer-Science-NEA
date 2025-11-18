from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from asyncpg.exceptions import UniqueViolationError
from api.models import LeagueOut, LeagueCreate, SeasonOut, SeasonCreate, LeagueTeamOut
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


@router.get("/seasons/{season_id}/teams", response_model=List[LeagueTeamOut])
async def list_season_teams(
    request: Request,
    season_id: int,
    user: dict = Depends(AuthUtils.get_current_user)
) -> List[LeagueTeamOut]:
    """Get all teams in a specific season"""
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        # Verify season exists
        season = await connection.fetchrow(
            'SELECT season_id FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        # Get all teams in this season
        rows = await connection.fetch(
            """
            SELECT st.season_id, st.team_id, t.name as team_name, st.join_date
            FROM "SeasonTeams" st
            JOIN "Teams" t ON st.team_id = t.team_id
            WHERE st.season_id = $1
            ORDER BY st.join_date;
            """,
            season_id,
        )
    return [LeagueTeamOut(**row) for row in rows]


@router.post("/seasons/{season_id}/teams/{team_id}", response_model=LeagueTeamOut, status_code=status.HTTP_201_CREATED)
async def add_team_to_season(
    request: Request,
    season_id: int,
    team_id: int,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> LeagueTeamOut:
    """Add a team to a season. Only admins can do this."""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        # Verify season exists and is not archived
        season = await connection.fetchrow(
            'SELECT season_id, is_archived FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        if season['is_archived']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot add teams to an archived season"
            )
        
        # Verify team exists
        team = await connection.fetchrow(
            'SELECT team_id, name FROM "Teams" WHERE team_id = $1',
            team_id
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
        try:
            async with connection.transaction():
                # Add team to season
                row = await connection.fetchrow(
                    """
                    INSERT INTO "SeasonTeams" (season_id, team_id, join_date)
                    VALUES ($1, $2, CURRENT_DATE)
                    RETURNING season_id, team_id, join_date;
                    """,
                    season_id,
                    team_id,
                )
                
                # Combine with team name
                result = dict(row)
                result['team_name'] = team['name']
                
                return LeagueTeamOut(**result)
            
        except UniqueViolationError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Team is already in this season"
            )


@router.delete("/seasons/{season_id}/teams/{team_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_team_from_season(
    request: Request,
    season_id: int,
    team_id: int,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
):
    """Remove a team from a season. Only admins can do this."""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        # Verify season exists and is not archived
        season = await connection.fetchrow(
            'SELECT season_id, is_archived FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        if season['is_archived']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove teams from an archived season"
            )
        
        # Check if team is in season
        season_team = await connection.fetchrow(
            'SELECT season_id, team_id FROM "SeasonTeams" WHERE season_id = $1 AND team_id = $2',
            season_id,
            team_id,
        )
        if not season_team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team is not in this season"
            )
        
        # Remove team from season
        await connection.execute(
            'DELETE FROM "SeasonTeams" WHERE season_id = $1 AND team_id = $2',
            season_id,
            team_id,
        )
