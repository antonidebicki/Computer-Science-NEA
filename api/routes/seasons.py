from typing import List
import datetime
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import SeasonOut, SeasonCreate, GenerateFixturesRequest, GenerateFixturesResponse
from api.auth import AuthUtils
from api.services.fixture_generator import generate_round_robin, assign_match_dates

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
        # 1. Verify season exists
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        
        if not season:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Season {season_id} not found"
            )
        
        # 2. Get all teams in the season
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
        
        # 3. Generate round-robin pairings
        matches = generate_round_robin(team_ids, double=payload.double_round_robin)
        
        if not matches:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No matches generated. Check team configuration."
            )
        
        # 4. Parse start date
        try:
            start_date = datetime.datetime.strptime(payload.start_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid start_date format. Use YYYY-MM-DD."
            )
        
        # 5. Assign match dates
        scheduled_matches = assign_match_dates(
            matches,
            start_date,
            matches_per_week_per_team=payload.matches_per_week_per_team,
            weeks_between_matches=payload.weeks_between_matches,
            allowed_weekdays=payload.allowed_weekdays
        )
        
        # 6. Insert all matches in transaction
        async with connection.transaction():
            # Check if fixtures already exist for this season
            existing_count = await connection.fetchval(
                'SELECT COUNT(*) FROM "Matches" WHERE season_id = $1',
                season_id
            )
            
            if existing_count > 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Fixtures already exist for season {season_id}. Delete existing fixtures first."
                )
            
            # Insert all matches
            for match in scheduled_matches:
                # Convert date to datetime for the TIMESTAMP column
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
        
        # 7. Calculate summary
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
        # Verify season exists
        season = await connection.fetchrow(
            'SELECT season_id, name FROM "Seasons" WHERE season_id = $1',
            season_id
        )
        if not season:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Season not found")
        
        async with connection.transaction():
            # Get current standings with calculated fields and ranking
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
            
            # Archive standings with all calculated fields
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
            
            # Clear current standings
            await connection.execute(
                'DELETE FROM "LeagueStandings" WHERE season_id = $1',
                season_id
            )
            
            # Mark season as archived
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