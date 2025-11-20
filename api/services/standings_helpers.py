import asyncpg


async def update_team_standing(
    connection: asyncpg.Connection,
    season_id: int,
    team_id: int,
    wins: int,
    losses: int,
    sets_won: int,
    sets_lost: int,
    points_won: int,
    points_lost: int,
    league_points: int
) -> None:
    """Update/ insert a standing for a single team."""
    await connection.execute(
        """
        INSERT INTO "LeagueStandings" 
        (season_id, team_id, matches_played, wins, losses, 
         sets_won, sets_lost, points_won, points_lost, league_points)
        VALUES ($1, $2, 1, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (season_id, team_id) 
        DO UPDATE SET
            matches_played = "LeagueStandings".matches_played + 1,
            wins = "LeagueStandings".wins + $3,
            losses = "LeagueStandings".losses + $4,
            sets_won = "LeagueStandings".sets_won + $5,
            sets_lost = "LeagueStandings".sets_lost + $6,
            points_won = "LeagueStandings".points_won + $7,
            points_lost = "LeagueStandings".points_lost + $8,
            league_points = "LeagueStandings".league_points + $9
        """,
        season_id, team_id,
        wins, losses, sets_won, sets_lost,
        points_won, points_lost, league_points
    )


async def update_match_status(connection: asyncpg.Connection, match_id: int, status: str) -> None:
    """Update match status."""
    await connection.execute(
        """
        UPDATE "Matches"
        SET status = $1::game_states
        WHERE match_id = $2
        """,
        status, match_id
    )
