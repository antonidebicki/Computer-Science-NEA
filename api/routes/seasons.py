from typing import List, Optional
import datetime
from fastapi import APIRouter, HTTPException, Request, status, Depends, Query
from api.models import SeasonOut, SeasonCreate, GenerateFixturesRequest, GenerateFixturesResponse, StandingOut, RecalculateStandingsResponse
from api.auth import AuthUtils
from api.services.fixture_generator import generate_round_robin, assign_match_dates
from api.services.standings_engine import recalculate_season_standings, initialise_season_standings

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


@router.post("/seasons/{season_id}/generate-fixtures", response_model=GenerateFixturesResponse, status_code=status.HTTP_201_CREATED)
async def generate_fixtures(
    request: Request, 
    season_id: int, 
    payload: GenerateFixturesRequest,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> GenerateFixturesResponse:
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Season {season_id} not found"
            )
        
        team_rows = await connection.fetch(
            """
            SELECT team_id 
            FROM "SeasonTeams" 
            WHERE season_id = $1
            ORDER BY team_id
            """,
            season_id
        )
        
        team_ids = [row['team_id'] for row in team_rows]
        
        if len(team_ids) < 2:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Need at least 2 teams to generate fixtures. Found {len(team_ids)} teams."
            )
        
        matches = generate_round_robin(team_ids, double=payload.double_round_robin)
        
        if not matches:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No matches generated. Check team configuration."
            )
        
        try:
            start_date = datetime.datetime.strptime(payload.start_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid start_date format. Use YYYY-MM-DD."
            )
        
        scheduled_matches = assign_match_dates(
            matches,
            start_date,
            matches_per_week_per_team=payload.matches_per_week_per_team,
            weeks_between_matches=payload.weeks_between_matches,
            allowed_weekdays=payload.allowed_weekdays
        )
        
        async with connection.transaction():
            # Prevent duplicate fixture generation for the same season
            existing_count = await connection.fetchval(
                'SELECT COUNT(*) FROM "Matches" WHERE season_id = $1',
                season_id
            )
            
            if existing_count > 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Fixtures already exist for season {season_id}. Delete existing fixtures first."
                )
            
            for match in scheduled_matches:
                # Database expects TIMESTAMP but we have date - default to 7:00 PM
                match_datetime = datetime.datetime.combine(match['match_date'], datetime.time(19, 0))  # Default 7:00 PM
                
                await connection.execute(
                    """
                    INSERT INTO "Matches" 
                    (season_id, home_team_id, away_team_id, match_datetime, status)
                    VALUES ($1, $2, $3, $4, $5::game_states)
                    """,
                    season_id,
                    match['team_a_id'],
                    match['team_b_id'],
                    match_datetime,
                    match['status']
                )
        
        dates = [m['match_date'] for m in scheduled_matches]
        first_match = min(dates).isoformat()
        last_match = max(dates).isoformat()
        
        return GenerateFixturesResponse(
            matches_created=len(scheduled_matches),
            start_date=first_match,
            end_date=last_match,
            season_id=season_id,
            message=f"Successfully generated {len(scheduled_matches)} fixtures for {season['name']}"
        )
    

@router.post("/seasons/{season_id}/reset", status_code=status.HTTP_200_OK)
async def reset_season(request: Request, season_id: int, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> dict:
    """Archive current standings and reset season for a fresh start"""
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Season not found")
        
        async with connection.transaction():
            # Calculate differentials and position in SQL to ensure consistency with archived data
            standings = await connection.fetch(
                """
                SELECT 
                    team_id,
                    matches_played,
                    wins,
                    losses,
                    sets_won,
                    sets_lost,
                    (sets_won - sets_lost) as set_diff,
                    points_won,
                    points_lost,
                    (points_won - points_lost) as point_diff,
                    league_points,
                    ROW_NUMBER() OVER (
                        ORDER BY league_points DESC, 
                        (sets_won - sets_lost) DESC, 
                        (points_won - points_lost) DESC
                    ) as final_position
                FROM "LeagueStandings"
                WHERE season_id = $1
                ORDER BY league_points DESC, set_diff DESC, point_diff DESC
                """,
                season_id
            )
            
            if not standings:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No standings to archive. Season may already be empty."
                )
            
            archived_count = 0
            for record in standings:
                await connection.execute(
                    """
                    INSERT INTO "ArchivedStandings" 
                    (season_id, team_id, matches_played, wins, losses, 
                     sets_won, sets_lost, set_diff, points_won, points_lost, 
                     point_diff, league_points, final_position, archived_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())
                    """,
                    season_id,
                    record['team_id'],
                    record['matches_played'],
                    record['wins'],
                    record['losses'],
                    record['sets_won'],
                    record['sets_lost'],
                    record['set_diff'],
                    record['points_won'],
                    record['points_lost'],
                    record['point_diff'],
                    record['league_points'],
                    record['final_position']
                )
                archived_count += 1
            
            await connection.execute(
                'DELETE FROM "LeagueStandings" WHERE season_id = $1',
                season_id
            )
            
            await connection.execute(
                'UPDATE "Seasons" SET is_archived = TRUE WHERE season_id = $1',
                season_id
            )
        
    return {
        "message": f"Season '{season['name']}' has been reset successfully.",
        "season_id": season_id,
        "teams_archived": archived_count,
        "archived_at": datetime.datetime.now().isoformat()
    }


@router.get("/seasons/{season_id}/standings", response_model=List[StandingOut])
async def get_season_standings(
    request: Request,
    season_id: int,
    archived: bool = Query(False, description="Return archived standings instead of current"),
    user: dict = Depends(AuthUtils.get_current_user)
) -> List[StandingOut]:
    """Get league standings for a season. Set archived=true to get historical data."""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        if archived:
            rows = await connection.fetch(
                """
                SELECT 
                    NULL as standing_id,
                    a.season_id,
                    a.team_id,
                    t.name as team_name,
                    a.matches_played,
                    a.wins,
                    a.losses,
                    a.sets_won,
                    a.sets_lost,
                    a.set_diff,
                    a.points_won,
                    a.points_lost,
                    a.point_diff,
                    a.league_points,
                    a.final_position as position
                FROM "ArchivedStandings" a
                JOIN "Teams" t ON a.team_id = t.team_id
                WHERE a.season_id = $1
                ORDER BY a.final_position ASC;
                """,
                season_id
            )
        else:
            # Calculate position dynamically since current standings can change
            rows = await connection.fetch(
                """
                SELECT 
                    ls.standing_id,
                    ls.season_id,
                    ls.team_id,
                    t.name as team_name,
                    ls.matches_played,
                    ls.wins,
                    ls.losses,
                    ls.sets_won,
                    ls.sets_lost,
                    (ls.sets_won - ls.sets_lost) as set_diff,
                    ls.points_won,
                    ls.points_lost,
                    (ls.points_won - ls.points_lost) as point_diff,
                    ls.league_points,
                    ROW_NUMBER() OVER (
                        ORDER BY ls.league_points DESC,
                        (ls.sets_won - ls.sets_lost) DESC,
                        (ls.points_won - ls.points_lost) DESC
                    ) as position
                FROM "LeagueStandings" ls
                JOIN "Teams" t ON ls.team_id = t.team_id
                WHERE ls.season_id = $1
                ORDER BY position ASC;
                """,
                season_id
            )
        
        return [StandingOut(**row) for row in rows]


@router.post("/seasons/{season_id}/recalculate-standings", response_model=RecalculateStandingsResponse)
async def recalculate_standings(
    request: Request,
    season_id: int,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> RecalculateStandingsResponse:
    """Recalculate standings for a season from scratch based on all finished matches"""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        async with connection.transaction():
            try:
                result = await recalculate_season_standings(connection, season_id)
                
                return RecalculateStandingsResponse(
                    season_id=season_id,
                    matches_processed=result['matches_processed'],
                    message=f"Standings recalculated for {season['name']}. Processed {result['matches_processed']} matches."
                )
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to recalculate standings: {str(e)}"
                )


@router.post("/seasons/{season_id}/initialize-standings")
async def initialize_standings(
    request: Request,
    season_id: int,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> dict:
    """Initialize empty standings entries for all teams in a season"""
    pool = request.app.state.pool
    
    async with pool.acquire() as connection:
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Season not found"
            )
        
        async with connection.transaction():
            try:
                rows_inserted = await initialise_season_standings(connection, season_id)
                
                return {
                    "season_id": season_id,
                    "teams_initialized": rows_inserted,
                    "message": f"Initialized standings for {rows_inserted} teams in {season['name']}"
                }
            except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to initialize standings: {str(e)}"
            )