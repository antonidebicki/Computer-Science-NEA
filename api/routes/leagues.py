from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from asyncpg.exceptions import UniqueViolationError
from api.models import (
    LeagueOut,
    LeagueCreate,
    SeasonOut,
    SeasonCreate,
    LeagueTeamOut,
    CreateLeagueInvitationRequest,
    LeagueJoinRequestOut,
    RespondToLeagueInvitationRequest,
)
from api.auth import AuthUtils
from api.services.standings_engine import initialise_season_standings
from api.services.team_invitation_code_engine import TeamInvitationCodeEngine

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


# ==================== LEAGUE INVITATION ENDPOINTS ====================

@router.post("/leagues/invitations", response_model=LeagueJoinRequestOut, status_code=status.HTTP_201_CREATED)
async def create_league_invitation(
    request: Request,
    payload: CreateLeagueInvitationRequest,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> LeagueJoinRequestOut:
    """
    Create a league invitation for a team (ADMIN action).

    Flow:
    1. League admin selects league + season + team
    2. Invitation is created with PENDING status
    3. Team admin/coach can accept or reject
    4. If accepted, team is added to SeasonTeams
    """
    pool = request.app.state.pool
    admin_user_id = user.get("user_id")

    async with pool.acquire() as connection:
        # Verify league exists and admin owns it (or user is ADMIN)
        league = await connection.fetchrow(
            'SELECT league_id, name, admin_user_id FROM "Leagues" WHERE league_id = $1;',
            payload.league_id,
        )
        if not league:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found")

        if league["admin_user_id"] != admin_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to invite teams to this league"
            )

        # Verify season exists, belongs to league, and not archived
        season = await connection.fetchrow(
            'SELECT season_id, name, league_id, is_archived FROM "Seasons" WHERE season_id = $1;',
            payload.season_id,
        )
        if not season or season["league_id"] != payload.league_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Season not found for this league")

        if season["is_archived"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot invite teams to an archived season"
            )

        # Validate invitation code to find team
        teams_rows = await connection.fetch(
            'SELECT team_id, name FROM "Teams" ORDER BY team_id;'
        )

        team = None
        for row in teams_rows:
            test_team_id = row["team_id"]
            if TeamInvitationCodeEngine.validate_code(test_team_id, payload.invitation_code):
                team = row
                break

        if team is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired team invitation code"
            )

        # Check if team already in season
        existing_team = await connection.fetchrow(
            'SELECT season_id FROM "SeasonTeams" WHERE season_id = $1 AND team_id = $2;',
            payload.season_id,
            team["team_id"],
        )
        if existing_team:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Team is already in this season"
            )

        # Check for existing pending invitation
        existing_invitation = await connection.fetchrow(
            '''SELECT join_request_id FROM "LeagueJoinRequests"
               WHERE season_id = $1 AND team_id = $2 AND status = 'PENDING';''',
            payload.season_id,
            team["team_id"],
        )
        if existing_invitation:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Team already has a pending invitation for this season"
            )

        # Create invitation
        row = await connection.fetchrow(
            '''
            INSERT INTO "LeagueJoinRequests"
            (league_id, season_id, team_id, invited_by_user_id, status)
            VALUES ($1, $2, $3, $4, 'PENDING')
            RETURNING join_request_id, league_id, season_id, team_id, invited_by_user_id,
                      status, created_at, responded_at;
            ''',
            payload.league_id,
            payload.season_id,
            team["team_id"],
            admin_user_id,
        )

        result = dict(row)
        result["league_name"] = league["name"]
        result["season_name"] = season["name"]
        result["team_name"] = team["name"]
        result["invited_by_username"] = user.get("username")

        return LeagueJoinRequestOut(**result)


@router.get("/leagues/invitations/sent", response_model=dict)
async def get_sent_league_invitations(
    request: Request,
    league_id: int = None,
    season_id: int = None,
    user: dict = Depends(AuthUtils.require_role(["ADMIN"]))
) -> dict:
    """Get invitations sent by the current league admin."""
    pool = request.app.state.pool
    admin_user_id = user.get("user_id")

    async with pool.acquire() as connection:
        query = '''
            SELECT ljr.join_request_id, ljr.league_id, ljr.season_id, ljr.team_id,
                   ljr.invited_by_user_id, ljr.status, ljr.created_at, ljr.responded_at,
                   l.name as league_name, s.name as season_name, t.name as team_name,
                   u.username as invited_by_username
            FROM "LeagueJoinRequests" ljr
            JOIN "Leagues" l ON ljr.league_id = l.league_id
            JOIN "Seasons" s ON ljr.season_id = s.season_id
            JOIN "Teams" t ON ljr.team_id = t.team_id
            JOIN "Users" u ON ljr.invited_by_user_id = u.user_id
            WHERE ljr.invited_by_user_id = $1
        '''
        params = [admin_user_id]

        if league_id is not None:
            query += " AND ljr.league_id = $2"
            params.append(league_id)
            if season_id is not None:
                query += " AND ljr.season_id = $3"
                params.append(season_id)
        elif season_id is not None:
            query += " AND ljr.season_id = $2"
            params.append(season_id)

        query += " ORDER BY ljr.created_at DESC;"

        rows = await connection.fetch(query, *params)

    invitations = [LeagueJoinRequestOut(**row) for row in rows]
    return {"invitations": invitations}


@router.get("/leagues/invitations/received", response_model=dict)
async def get_received_league_invitations(
    request: Request,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
) -> dict:
    """Get invitations received by teams owned by the current user."""
    pool = request.app.state.pool
    current_user_id = user.get("user_id")

    async with pool.acquire() as connection:
        rows = await connection.fetch(
            '''
            SELECT ljr.join_request_id, ljr.league_id, ljr.season_id, ljr.team_id,
                   ljr.invited_by_user_id, ljr.status, ljr.created_at, ljr.responded_at,
                   l.name as league_name, s.name as season_name, t.name as team_name,
                   u.username as invited_by_username
            FROM "LeagueJoinRequests" ljr
            JOIN "Leagues" l ON ljr.league_id = l.league_id
            JOIN "Seasons" s ON ljr.season_id = s.season_id
            JOIN "Teams" t ON ljr.team_id = t.team_id
            JOIN "Users" u ON ljr.invited_by_user_id = u.user_id
            WHERE t.created_by_user_id = $1
            ORDER BY ljr.created_at DESC;
            ''',
            current_user_id,
        )

    invitations = [LeagueJoinRequestOut(**row) for row in rows]
    return {"invitations": invitations}


@router.post("/leagues/invitations/{join_request_id}/respond", response_model=LeagueJoinRequestOut)
async def respond_to_league_invitation(
    request: Request,
    join_request_id: int,
    payload: RespondToLeagueInvitationRequest,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
) -> LeagueJoinRequestOut:
    """Accept or reject a league invitation (team admin/coach action)."""
    pool = request.app.state.pool
    current_user_id = user.get("user_id")

    async with pool.acquire() as connection:
        invitation = await connection.fetchrow(
            '''
            SELECT ljr.*, l.name as league_name, s.name as season_name, t.name as team_name,
                   t.created_by_user_id, s.is_archived, u.username as invited_by_username
            FROM "LeagueJoinRequests" ljr
            JOIN "Leagues" l ON ljr.league_id = l.league_id
            JOIN "Seasons" s ON ljr.season_id = s.season_id
            JOIN "Teams" t ON ljr.team_id = t.team_id
            JOIN "Users" u ON ljr.invited_by_user_id = u.user_id
            WHERE ljr.join_request_id = $1;
            ''',
            join_request_id,
        )
        if not invitation:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")

        if invitation["created_by_user_id"] != current_user_id and user.get("role") != "ADMIN":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to respond to this invitation"
            )

        if invitation["status"] != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invitation has already been responded to"
            )

        if invitation["is_archived"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot join an archived season"
            )

        if payload.accept:
            # Add team to season
            try:
                await connection.execute(
                    '''
                    INSERT INTO "SeasonTeams" (season_id, team_id, join_date)
                    VALUES ($1, $2, CURRENT_DATE);
                    ''',
                    invitation["season_id"],
                    invitation["team_id"],
                )
                await initialise_season_standings(connection, invitation["season_id"])
            except UniqueViolationError:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Team is already in this season"
                )

        # Update invitation status
        updated = await connection.fetchrow(
            '''
            UPDATE "LeagueJoinRequests"
            SET status = $1, responded_at = CURRENT_TIMESTAMP
            WHERE join_request_id = $2
            RETURNING join_request_id, league_id, season_id, team_id, invited_by_user_id,
                      status, created_at, responded_at;
            ''',
            "ACCEPTED" if payload.accept else "REJECTED",
            join_request_id,
        )

        result = dict(updated)
        result["league_name"] = invitation["league_name"]
        result["season_name"] = invitation["season_name"]
        result["team_name"] = invitation["team_name"]
        result["invited_by_username"] = invitation["invited_by_username"]

        return LeagueJoinRequestOut(**result)


@router.delete("/leagues/invitations/{join_request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_league_invitation(
    request: Request,
    join_request_id: int,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
):
    """Cancel or delete a league invitation (admin or team owner)."""
    pool = request.app.state.pool
    current_user_id = user.get("user_id")

    async with pool.acquire() as connection:
        invitation = await connection.fetchrow(
            '''
            SELECT ljr.join_request_id, ljr.invited_by_user_id, t.created_by_user_id
            FROM "LeagueJoinRequests" ljr
            JOIN "Teams" t ON ljr.team_id = t.team_id
            WHERE ljr.join_request_id = $1;
            ''',
            join_request_id,
        )
        if not invitation:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")

        if (invitation["invited_by_user_id"] != current_user_id and
                invitation["created_by_user_id"] != current_user_id and
                user.get("role") != "ADMIN"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this invitation"
            )

        await connection.execute(
            'DELETE FROM "LeagueJoinRequests" WHERE join_request_id = $1;',
            join_request_id,
        )
