from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from asyncpg.exceptions import UniqueViolationError
from api.models import TeamOut, TeamCreate, TeamMemberOut, TeamJoinRequest
from api.auth import AuthUtils

router = APIRouter()


@router.get("/teams", response_model=List[TeamOut])
async def list_teams(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> List[TeamOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            """
            SELECT team_id, name, created_by_user_id, logo_url, created_at
            FROM "Teams"
            ORDER BY name;
            """
        )
    return [TeamOut(**row) for row in rows]


@router.get("/teams/{team_id}", response_model=TeamOut)
async def get_team(request: Request, team_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> TeamOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        row = await connection.fetchrow(
            """
            SELECT team_id, name, created_by_user_id, logo_url, created_at
            FROM "Teams"
            WHERE team_id = $1;
            """,
            team_id,
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    return TeamOut(**row)


@router.post("/teams", response_model=TeamOut, status_code=status.HTTP_201_CREATED)
async def create_team(request: Request, payload: TeamCreate, user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))) -> TeamOut:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        try:
            row = await connection.fetchrow(
                """
                INSERT INTO "Teams" (name, created_by_user_id, logo_url)
                VALUES ($1, $2, $3)
                RETURNING team_id, name, created_by_user_id, logo_url, created_at;
                """,
                payload.name,
                payload.created_by_user_id,
                payload.logo_url,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create team.",
            ) from exc
    return TeamOut(**row)


@router.get("/teams/{team_id}/members", response_model=List[TeamMemberOut])
async def get_team_members(request: Request, team_id: int, user: dict = Depends(AuthUtils.get_current_user)) -> List[TeamMemberOut]:
    pool = request.app.state.pool
    async with pool.acquire() as connection:
        team = await connection.fetchrow(
            """
            SELECT team_id FROM "Teams" WHERE team_id = $1;
            """,
            team_id,
        )
        if not team:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
        
        # Get all team members with user details
        rows = await connection.fetch(
            """
            SELECT 
                tm.team_id,
                tm.user_id,
                tm.role_in_team,
                tm.player_number,
                tm.is_captain,
                tm.is_libero,
                u.username,
                u.email,
                u.full_name,
                u.role as user_role
            FROM "TeamMembers" tm
            JOIN "Users" u ON tm.user_id = u.user_id
            WHERE tm.team_id = $1
            ORDER BY tm.is_captain DESC, tm.player_number ASC;
            """,
            team_id,
        )
    
    return [TeamMemberOut(**row) for row in rows]


@router.post("/teams/{team_id}/join", response_model=TeamMemberOut, status_code=status.HTTP_201_CREATED)
async def join_team(
    request: Request,
    team_id: int,
    payload: TeamJoinRequest,
    user: dict = Depends(AuthUtils.get_current_user)
) -> TeamMemberOut:
    """Allows a player to join a team."""
    pool = request.app.state.pool
    
    # Only players can join teams
    if user.get("role") != "PLAYER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only users with PLAYER role can join teams"
        )
    
    async with pool.acquire() as connection:
        # Verify team exists
        team = await connection.fetchrow(
            'SELECT team_id FROM "Teams" WHERE team_id = $1;',
            team_id,
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
        try:
            async with connection.transaction():
                # Insert player into TeamMembers
                row = await connection.fetchrow(
                    """
                    INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number, is_captain, is_libero)
                    VALUES ($1, $2, 'Player', $3, $4, $5)
                    RETURNING team_id, user_id, role_in_team, player_number, is_captain, is_libero;
                    """,
                    team_id,
                    user["user_id"],
                    payload.player_number,
                    payload.is_captain,
                    payload.is_libero,
                )
                
                # Fetch user details to return complete TeamMemberOut
                user_details = await connection.fetchrow(
                    'SELECT username, email, full_name, role as user_role FROM "Users" WHERE user_id = $1;',
                    user["user_id"],
                )
                
                # Combine the data
                result = dict(row)
                result.update(dict(user_details))
                
                return TeamMemberOut(**result)
            
        except UniqueViolationError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User is already a member of this team"
            )


@router.delete("/teams/{team_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_team_member(
    request: Request,
    team_id: int,
    user_id: int,
    user: dict = Depends(AuthUtils.get_current_user)
):
    """Remove a player from a team. Can be done by the player themselves or an admin."""
    pool = request.app.state.pool
    
    # Check if user is admin or the player being removed
    is_admin = user.get("role") == "ADMIN"
    is_self = user.get("user_id") == user_id
    
    if not (is_admin or is_self):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only remove yourself from a team, or you must be an admin"
        )
    
    async with pool.acquire() as connection:
        # Verify team exists
        team = await connection.fetchrow(
            'SELECT team_id FROM "Teams" WHERE team_id = $1;',
            team_id,
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
        # Check if membership exists
        member = await connection.fetchrow(
            'SELECT team_id, user_id FROM "TeamMembers" WHERE team_id = $1 AND user_id = $2;',
            team_id,
            user_id,
        )
        if not member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User is not a member of this team"
            )
        
        # Remove the member
        await connection.execute(
            'DELETE FROM "TeamMembers" WHERE team_id = $1 AND user_id = $2;',
            team_id,
            user_id,
        )

