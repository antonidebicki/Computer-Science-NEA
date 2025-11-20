import asyncpg
from typing import List, Optional, Dict, Any
from api.models import MatchProcessingResult, TeamStandingUpdate
from api.services.standings_helpers import update_team_standing, update_match_status


async def process_match_result(connection: asyncpg.Connection, match_id: int) -> MatchProcessingResult:
    """
    Proccesses a finished match and updates the standings for both teams.
    calculates league points based on match outcome (Assuming 3 points for win, 0 for loss) - will be adjusted in a future feature update.
    returns a MatchProcessingResult object with updates made.
    """
    match = await connection.fetchrow(
        """
        SELECT match_id, season_id, home_team_id, away_team_id, 
               winner_team_id, home_sets_won, away_sets_won, status
        FROM "Matches"
        WHERE match_id = $1
        """,
        match_id
    )
    
    if not match:
        raise ValueError(f"Match {match_id} not found")
    if match['winner_team_id'] is None:
        raise ValueError(f"Match {match_id} has no winner recorded")
    if match['status'] != 'FINISHED':
        raise ValueError(f"Match {match_id} is not finished (status: {match['status']})")
    
    sets = await connection.fetch(
        """
        SELECT set_id, home_team_score, away_team_score
        FROM "Sets"
        WHERE match_id = $1
        ORDER BY set_number
        """,
        match_id
    )
    
    home_points = sum(s['home_team_score'] for s in sets)
    away_points = sum(s['away_team_score'] for s in sets)
    
    home_sets = match['home_sets_won']
    away_sets = match['away_sets_won']
    
    if match['winner_team_id'] == match['home_team_id']:
        home_wins, away_wins = 1, 0
        home_losses, away_losses = 0, 1
        home_league_points, away_league_points = 3, 0
    else:
        home_wins, away_wins = 0, 1
        home_losses, away_losses = 1, 0
        home_league_points, away_league_points = 0, 3
    
    await update_team_standing(
        connection,
        match['season_id'],
        match['home_team_id'],
        home_wins, home_losses, home_sets, away_sets,
        home_points, away_points, home_league_points
    )
    
    await update_team_standing(
        connection,
        match['season_id'],
        match['away_team_id'],
        away_wins, away_losses, away_sets, home_sets,
        away_points, home_points, away_league_points
    )
    
    await update_match_status(connection, match_id, 'PROCESSED')
    
    return MatchProcessingResult(
        match_id=match_id,
        season_id=match['season_id'],
        home_team_id=match['home_team_id'],
        away_team_id=match['away_team_id'],
        winner_team_id=match['winner_team_id'],
        home_updates=TeamStandingUpdate(
            wins=home_wins,
            sets=home_sets,
            points=home_points,
            league_points=home_league_points
        ),
        away_updates=TeamStandingUpdate(
            wins=away_wins,
            sets=away_sets,
            points=away_points,
            league_points=away_league_points
        )
    )


async def recalculate_season_standings(connection: asyncpg.Connection, season_id: int) -> Dict[str, Any]:
    """
    Recalculates standings for an entire season from scratch.
    Useful for fixing inconsistencies or after data corrections.
    """
    await connection.execute(
        'DELETE FROM "LeagueStandings" WHERE season_id = $1',
        season_id
    )
    
    matches = await connection.fetch(
        """
        SELECT match_id
        FROM "Matches"
        WHERE season_id = $1 AND status = 'FINISHED'
        ORDER BY match_datetime
        """,
        season_id
    )
    
    processed_count = 0
    for match in matches:
        await connection.execute(
            """
            UPDATE "Matches"
            SET status = 'FINISHED'::game_states
            WHERE match_id = $1
            """,
            match['match_id']
        )
        
        await process_match_result(connection, match['match_id'])
        processed_count += 1
    
    return {
        'season_id': season_id,
        'matches_processed': processed_count
    }


async def initialise_season_standings(connection: asyncpg.Connection, season_id: int) -> int:
    """
    Initialise empty standings entries for all teams in a season.
    Should be called when teams are added to a season.
    """
    result = await connection.execute(
        """
        INSERT INTO "LeagueStandings" 
        (season_id, team_id, matches_played, wins, losses, 
         sets_won, sets_lost, points_won, points_lost, league_points)
        SELECT 
            st.season_id,
            st.team_id,
            0, 0, 0, 0, 0, 0, 0, 0
        FROM "SeasonTeams" st
        WHERE st.season_id = $1
        ON CONFLICT (season_id, team_id) DO NOTHING
        """,
        season_id
    )
    
    #extract number of rows inserted from result string like "INSERT 0 3"
    rows_inserted = int(result.split()[-1]) if result else 0
    return rows_inserted
