from typing import List
from fastapi import APIRouter, HTTPException, Request, status, Depends
from asyncpg.exceptions import UniqueViolationError
from api.models import (
    TeamOut, 
    TeamCreate, 
    TeamMemberOut, 
    TeamJoinRequest,
    CreateTeamInvitationRequest,
    TeamJoinRequestOut,
    RespondToJoinRequestRequest,
)
from api.auth import AuthUtils
from api.services.invitation_code_engine import InvitationCodeEngine

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
                
                user_details = await connection.fetchrow(
                    'SELECT username, email, full_name, role as user_role FROM "Users" WHERE user_id = $1;',
                    user["user_id"],
                )
                
                result = dict(row)
                result.update(dict(user_details))
                
                return TeamMemberOut(**result)
            
        except UniqueViolationError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User is already a member of this team"
            )


@router.post("/teams/{team_id}/members", response_model=TeamMemberOut, status_code=status.HTTP_201_CREATED)
async def add_team_member(
    request: Request,
    team_id: int,
    payload: TeamJoinRequest,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
) -> TeamMemberOut:
    """ONLY and i mean ONLY use this for debugging. delete after frontend is done bc this allows admin to add anyone w/o their permission"""
    pool = request.app.state.pool
    
    user_id = request.query_params.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user_id query parameter is required"
        )
    
    try:
        user_id = int(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user_id must be an integer"
        )
    
    async with pool.acquire() as connection:
        team = await connection.fetchrow(
            'SELECT team_id FROM "Teams" WHERE team_id = $1;',
            team_id,
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
        user_to_add = await connection.fetchrow(
            'SELECT user_id FROM "Users" WHERE user_id = $1;',
            user_id,
        )
        if not user_to_add:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        try:
            async with connection.transaction():
                row = await connection.fetchrow(
                    """
                    INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number, is_captain, is_libero)
                    VALUES ($1, $2, 'Player', $3, $4, $5)
                    RETURNING team_id, user_id, role_in_team, player_number, is_captain, is_libero;
                    """,
                    team_id,
                    user_id,
                    payload.player_number,
                    payload.is_captain,
                    payload.is_libero,
                )
                
                user_details = await connection.fetchrow(
                    'SELECT username, email, full_name, role as user_role FROM "Users" WHERE user_id = $1;',
                    user_id,
                )
                
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
    
    is_admin = user.get("role") == "ADMIN"
    is_self = user.get("user_id") == user_id
    
    if not (is_admin or is_self):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only remove yourself from a team, or you must be an admin"
        )
    
    async with pool.acquire() as connection:
        team = await connection.fetchrow(
            'SELECT team_id FROM "Teams" WHERE team_id = $1;',
            team_id,
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
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
        
        await connection.execute(
            'DELETE FROM "TeamMembers" WHERE team_id = $1 AND user_id = $2;',
            team_id,
            user_id,
        )


# ==================== TEAM INVITATION ENDPOINTS ====================

@router.post("/teams/invitations", response_model=TeamJoinRequestOut, status_code=status.HTTP_201_CREATED)
async def create_team_invitation(
    request: Request,
    payload: CreateTeamInvitationRequest,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
) -> TeamJoinRequestOut:
    """
    Create a team invitation using a player's invitation code (ADMIN/COACH action).
    
    Flow:
    1. Player generates and shares their daily invitation code
    2. Admin/coach enters player's code and team ID
    3. Code is validated to find the player
    4. Invitation is created with PENDING status
    5. Player receives invitation and can accept/reject
    """
    pool = request.app.state.pool
    admin_user_id = user.get("user_id")
    
    async with pool.acquire() as connection:
        # Verify team exists and user has permission
        team = await connection.fetchrow(
            'SELECT team_id, name, created_by_user_id FROM "Teams" WHERE team_id = $1;',
            payload.team_id,
        )
        if not team:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Team not found"
            )
        
        # Check permission
        if team['created_by_user_id'] != admin_user_id and user.get('role') != 'ADMIN':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to invite players to this team"
            )
        
        # Validate invitation code - find which player owns this code
        users_rows = await connection.fetch(
            'SELECT user_id, username FROM "Users" WHERE role = \'PLAYER\' ORDER BY user_id;'
        )
        
        player_user_id = None
        player_username = None
        
        for row in users_rows:
            test_user_id = row["user_id"]
            if InvitationCodeEngine.validate_code(test_user_id, payload.invitation_code):
                player_user_id = test_user_id
                player_username = row["username"]
                break
        
        if player_user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired invitation code"
            )
        
        # Check if player is already a member
        existing_member = await connection.fetchrow(
            'SELECT team_id FROM "TeamMembers" WHERE team_id = $1 AND user_id = $2;',
            payload.team_id,
            player_user_id,
        )
        if existing_member:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Player is already a member of this team"
            )
        
        # Check for existing pending invitation
        existing_invitation = await connection.fetchrow(
            '''SELECT join_request_id FROM "TeamJoinRequests" 
               WHERE team_id = $1 AND user_id = $2 AND status = 'PENDING';''',
            payload.team_id,
            player_user_id,
        )
        if existing_invitation:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Player already has a pending invitation for this team"
            )
        
        # Create the invitation
        try:
            row = await connection.fetchrow(
                '''
                INSERT INTO "TeamJoinRequests" 
                (team_id, user_id, invited_by_user_id, invitation_code, player_number, is_libero, status)
                VALUES ($1, $2, $3, $4, $5, $6, 'PENDING')
                RETURNING join_request_id, team_id, user_id, invited_by_user_id, 
                          invitation_code, status, player_number, is_libero, created_at, responded_at;
                ''',
                payload.team_id,
                player_user_id,
                admin_user_id,
                payload.invitation_code,
                payload.player_number,
                payload.is_libero,
            )
            
            result = dict(row)
            result['team_name'] = team['name']
            result['invited_by_username'] = user.get('username')
            result['username'] = player_username
            
            return TeamJoinRequestOut(**result)
            
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create invitation"
            ) from exc


@router.get("/teams/invitations/sent", response_model=dict)
async def get_sent_invitations(
    request: Request,
    team_id: int = None,
    user: dict = Depends(AuthUtils.require_role(["COACH", "ADMIN"]))
) -> dict:
    """
    Get all invitations sent by the current user (admin/coach checking sent invitations).
    Optionally filter by team_id.
    """
    pool = request.app.state.pool
    user_id = user.get("user_id")
    
    async with pool.acquire() as connection:
        if team_id:
            # Verify user has permission for this team
            team = await connection.fetchrow(
                'SELECT created_by_user_id FROM "Teams" WHERE team_id = $1;',
                team_id,
            )
            if not team:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Team not found"
                )
            
            # Only team creator or admin can view invitations
            if team['created_by_user_id'] != user_id and user.get('role') != 'ADMIN':
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to view invitations for this team"
                )
            
            rows = await connection.fetch(
                '''
                SELECT 
                    jr.join_request_id, jr.team_id, jr.user_id, jr.invited_by_user_id,
                    jr.invitation_code, jr.status, jr.player_number, jr.is_libero,
                    jr.created_at, jr.responded_at,
                    t.name as team_name,
                    u.username,
                    inv.username as invited_by_username
                FROM "TeamJoinRequests" jr
                JOIN "Teams" t ON jr.team_id = t.team_id
                JOIN "Users" u ON jr.user_id = u.user_id
                JOIN "Users" inv ON jr.invited_by_user_id = inv.user_id
                WHERE jr.team_id = $1 AND jr.invited_by_user_id = $2
                ORDER BY jr.created_at DESC;
                ''',
                team_id,
                user_id,
            )
        else:
            # Get invitations for all teams created by this user
            rows = await connection.fetch(
                '''
                SELECT 
                    jr.join_request_id, jr.team_id, jr.user_id, jr.invited_by_user_id,
                    jr.invitation_code, jr.status, jr.player_number, jr.is_libero,
                    jr.created_at, jr.responded_at,
                    t.name as team_name,
                    u.username,
                    inv.username as invited_by_username
                FROM "TeamJoinRequests" jr
                JOIN "Teams" t ON jr.team_id = t.team_id
                JOIN "Users" u ON jr.user_id = u.user_id
                JOIN "Users" inv ON jr.invited_by_user_id = inv.user_id
                WHERE jr.invited_by_user_id = $1
                ORDER BY jr.created_at DESC;
                ''',
                user_id,
            )
        
        invitations = [TeamJoinRequestOut(**dict(row)) for row in rows]
        return {"invitations": [inv.model_dump() for inv in invitations]}


@router.get("/teams/invitations/received", response_model=dict)
async def get_received_invitations(
    request: Request,
    user: dict = Depends(AuthUtils.require_role(["PLAYER"]))
) -> dict:
    """Get all invitations received by the current user (player checking their invitations)."""
    pool = request.app.state.pool
    user_id = user.get("user_id")
    
    async with pool.acquire() as connection:
        rows = await connection.fetch(
            '''
            SELECT 
                jr.join_request_id, jr.team_id, jr.user_id, jr.invited_by_user_id,
                jr.invitation_code, jr.status, jr.player_number, jr.is_libero,
                jr.created_at, jr.responded_at,
                t.name as team_name,
                u.username,
                inv.username as invited_by_username
            FROM "TeamJoinRequests" jr
            JOIN "Teams" t ON jr.team_id = t.team_id
            JOIN "Users" u ON jr.user_id = u.user_id
            JOIN "Users" inv ON jr.invited_by_user_id = inv.user_id
            WHERE jr.user_id = $1
            ORDER BY jr.created_at DESC;
            ''',
            user_id,
        )
        
        invitations = [TeamJoinRequestOut(**dict(row)) for row in rows]
        return {"invitations": [inv.model_dump() for inv in invitations]}


@router.post("/teams/invitations/{join_request_id}/respond", response_model=TeamJoinRequestOut)
async def respond_to_invitation(
    request: Request,
    join_request_id: int,
    payload: RespondToJoinRequestRequest,
    user: dict = Depends(AuthUtils.require_role(["PLAYER"]))
) -> TeamJoinRequestOut:
    """
    Accept or reject a team invitation (PLAYER action).
    If accepted, the player is added to the team.
    """
    pool = request.app.state.pool
    user_id = user.get("user_id")
    
    async with pool.acquire() as connection:
        # Get the invitation
        invitation = await connection.fetchrow(
            '''
            SELECT jr.*, t.created_by_user_id, t.name as team_name,
                   u.username, inv.username as invited_by_username
            FROM "TeamJoinRequests" jr
            JOIN "Teams" t ON jr.team_id = t.team_id
            JOIN "Users" u ON jr.user_id = u.user_id
            JOIN "Users" inv ON jr.invited_by_user_id = inv.user_id
            WHERE jr.join_request_id = $1;
            ''',
            join_request_id,
        )
        
        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found"
            )
        
        # Check permission - only the invited player can respond
        if invitation['user_id'] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only respond to your own invitations"
            )
        
        # Check if already responded
        if invitation['status'] != 'PENDING':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invitation has already been {invitation['status'].lower()}"
            )
        
        async with connection.transaction():
            # Update the invitation
            new_status = 'ACCEPTED' if payload.accept else 'REJECTED'
            updated_invitation = await connection.fetchrow(
                '''
                UPDATE "TeamJoinRequests"
                SET status = $1, responded_at = CURRENT_TIMESTAMP
                WHERE join_request_id = $2
                RETURNING join_request_id, team_id, user_id, invited_by_user_id,
                          invitation_code, status, player_number, is_libero, 
                          created_at, responded_at;
                ''',
                new_status,
                join_request_id,
            )
            
            # If accepted, add the player to the team
            if payload.accept:
                try:
                    await connection.execute(
                        '''
                        INSERT INTO "TeamMembers" 
                        (team_id, user_id, role_in_team, player_number, is_captain, is_libero)
                        VALUES ($1, $2, 'Player', $3, FALSE, $4);
                        ''',
                        invitation['team_id'],
                        user_id,
                        payload.player_number or invitation['player_number'],
                        payload.is_libero or invitation['is_libero'],
                    )
                except UniqueViolationError:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="You are already a member of this team"
                    )
            
            result = dict(updated_invitation)
            result['team_name'] = invitation['team_name']
            result['username'] = invitation['username']
            result['invited_by_username'] = invitation['invited_by_username']
            
            return TeamJoinRequestOut(**result)


@router.delete("/teams/invitations/{join_request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_invitation(
    request: Request,
    join_request_id: int,
    user: dict = Depends(AuthUtils.get_current_user)
):
    """
    Delete/cancel an invitation.
    Admin can cancel sent invitations, player can decline pending invitations.
    """
    pool = request.app.state.pool
    user_id = user.get("user_id")
    
    async with pool.acquire() as connection:
        invitation = await connection.fetchrow(
            'SELECT user_id, invited_by_user_id, status FROM "TeamJoinRequests" WHERE join_request_id = $1;',
            join_request_id,
        )
        
        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found"
            )
        
        # Admin who sent it or player who received it can delete
        is_sender = invitation['invited_by_user_id'] == user_id
        is_recipient = invitation['user_id'] == user_id
        
        if not (is_sender or is_recipient):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete invitations you sent or received"
            )
        
        # Can only delete pending invitations
        if invitation['status'] != 'PENDING':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only delete pending invitations"
            )
        
        await connection.execute(
            'DELETE FROM "TeamJoinRequests" WHERE join_request_id = $1;',
            join_request_id,
        )
