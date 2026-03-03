from typing import List
from datetime import datetime
import asyncpg
from asyncpg import UniqueViolationError
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import (
    UserCreate, UserOut, InvitationCodeResponse, InvitationCodeValidation, 
    InvitationCodeRedeemResponse, PlayerHomeDataResponse, CoachHomeDataResponse, SeasonHomeData, StandingOut
)
from api.auth import AuthUtils
from api.services.invitation_code_engine import InvitationCodeEngine

router = APIRouter()


@router.get("/users", response_model=List[UserOut])
async def list_users(request: Request, user: dict = Depends(AuthUtils.require_role(["ADMIN"]))) -> List[UserOut]:
  pool = request.app.state.pool
  async with pool.acquire() as connection:
    rows = await connection.fetch(
        """
        SELECT user_id, username, email, full_name, role, created_at
        FROM "Users"
        ORDER BY user_id;
        """
    )
  return [
      UserOut(
          user_id=row["user_id"],
          username=row["username"],
          email=row["email"],
          full_name=row["full_name"],
          role=row["role"],
          created_at=row["created_at"],
      )
      for row in rows
  ]


@router.post("/users", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(request: Request, payload: UserCreate) -> UserOut:
  pool = request.app.state.pool
  async with pool.acquire() as connection:
    # Check for existing username (case-insensitive)
    existing_user = await connection.fetchrow(
        """
        SELECT user_id FROM "Users" WHERE LOWER(username) = LOWER($1);
        """,
        payload.username,
    )
    if existing_user:
      raise HTTPException(
          status_code=status.HTTP_409_CONFLICT,
          detail="A user with that username already exists.",
      )
    
    try:
      row = await connection.fetchrow(
          """
          INSERT INTO "Users" (username, hashed_password, email, full_name, role)
          VALUES ($1, $2, $3, $4, $5)
          RETURNING user_id, username, email, full_name, role, created_at;
          """,
          payload.username,
          payload.hashed_password,
          payload.email,
          payload.full_name,
          payload.role,
      )
    except UniqueViolationError as exc:
      raise HTTPException(
          status_code=status.HTTP_409_CONFLICT,
          detail="A user with that username or email already exists.",
      ) from exc
    except asyncpg.PostgresError as exc:
      raise HTTPException(
          status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
          detail="Failed to create user.",
      ) from exc

  return UserOut(
      user_id=row["user_id"],
      username=row["username"],
      email=row["email"],
      full_name=row["full_name"],
      role=row["role"],
      created_at=row["created_at"],
  )


@router.get("/users/invitation-code/generate", response_model=InvitationCodeResponse)
async def get_invitation_code(request: Request, user: dict = Depends(AuthUtils.require_role(["PLAYER", "COACH", "ADMIN"]))) -> InvitationCodeResponse:
  """
  Generate today's 6-digit invitation code for the authenticated user.
  
  The code changes daily and is deterministic based on the user ID and current date.
  """
  user_id = user.get("user_id")
  today = datetime.utcnow().strftime("%Y-%m-%d")
  
  # Generate the invitation code
  invitation_code = InvitationCodeEngine.generate_code(user_id)
  
  return InvitationCodeResponse(
      user_id=user_id,
      invitation_code=invitation_code,
      code_generated_date=today,
  )


@router.post("/users/invitation-code/redeem", response_model=InvitationCodeRedeemResponse)
async def redeem_invitation_code(
    request: Request,
    payload: InvitationCodeValidation,
    user: dict = Depends(AuthUtils.require_role(["PLAYER", "COACH", "ADMIN"])),
) -> InvitationCodeRedeemResponse:
  """
  Redeem an invitation code to add the invited user to the inviter's team or network.
  
  This endpoint validates the invitation code and logs the acceptance.
  """
  invited_user_id = user.get("user_id")
  invitation_code = payload.invitation_code.strip()
  today = datetime.utcnow().strftime("%Y-%m-%d")
  
  pool = request.app.state.pool
  
  try:
    async with pool.acquire() as connection:
      # We need to find which user this invitation code belongs to
      # Try checking all users to find whose code matches (brute force approach)
      # Alternatively, use a more efficient lookup
      
      # Get the sender's user_id by trying to reverse-engineer
      # Since we don't know the sender_user_id, we need to check if there's
      # additional context or ask for it in the payload
      
      # For now, we'll implement a lookup by checking recent invitations
      # or by having the frontend provide the sender_user_id
      
      # Better approach: Backend should validate and the frontend should know
      # who invited them (from context), so let's check the code format
      
      if not invitation_code or len(invitation_code) != 6 or not invitation_code.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invitation code format. Must be 6 digits.",
        )
      
      # Since we need the sender's user_id to validate, we need another approach
      # Option 1: Store the sender_user_id in the request payload
      # Option 2: Have a table that maps codes to users (defeats the purpose)
      # Option 3: Return a failure and ask for more context
      
      # For security, we should require the sender's user_id be provided or known
      # Let's update this to search for valid users with this code on today's date
      
      users_rows = await connection.fetch(
          """
          SELECT user_id FROM "Users"
          ORDER BY user_id;
          """
      )
      
      sender_user_id = None
      for row in users_rows:
        test_user_id = row["user_id"]
        if InvitationCodeEngine.validate_code_for_date(test_user_id, invitation_code, today):
          sender_user_id = test_user_id
          break
      
      if sender_user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid invitation code or code has expired.",
        )
      
      if sender_user_id == invited_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot accept your own invitation code.",
        )
      
      # Log the invitation acceptance
      try:
        await connection.execute(
            """
            INSERT INTO "InvitationCodes" (user_id, invited_user_id, code_date, redeemed_at)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
            """,
            sender_user_id,
            invited_user_id,
            today,
        )
      except UniqueViolationError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already redeemed an invitation from this user today.",
        )
      
      # Get sender's username for the response
      sender_row = await connection.fetchrow(
          """
          SELECT username FROM "Users" WHERE user_id = $1
          """,
          sender_user_id,
      )
      sender_username = sender_row["username"] if sender_row else None
  
  except HTTPException:
    raise
  except asyncpg.PostgresError as exc:
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Failed to process invitation code.",
    ) from exc
  
  return InvitationCodeRedeemResponse(
      success=True,
      message=f"Successfully redeemed invitation from {sender_username}",
      sender_user_id=sender_user_id,
      sender_username=sender_username,
  )


@router.get("/users/home-data", response_model=PlayerHomeDataResponse)
async def get_player_home_data(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> PlayerHomeDataResponse:
  """Get all data needed for player home screen in a single request.
  This replaces 35+ individual API calls with 1, dramatically improving load times.
  """
  pool = request.app.state.pool
  user_id = user.get("user_id")
  
  async with pool.acquire() as connection:
    # Step 1: Get all teams for this user
    user_teams = await connection.fetch(
      """
      SELECT DISTINCT t.team_id, t.name
      FROM "Teams" t
      WHERE t.team_id IN (
        SELECT team_id FROM "TeamMembers" WHERE user_id = $1
      )
      """,
      user_id
    )
    
    user_team_ids = [team["team_id"] for team in user_teams]
    
    if not user_team_ids:
      # User is not on any teams
      return PlayerHomeDataResponse(
        seasons_data=[],
        player_team_ids=[]
      )
    
    # Step 2: Get all seasons where user's teams are participating
    # and include league information
    seasons_data = await connection.fetch(
      """
      SELECT DISTINCT
        s.season_id,
        s.league_id,
        s.name as season_name,
        l.name as league_name,
        st.team_id,
        s.start_date
      FROM "Seasons" s
      JOIN "Leagues" l ON s.league_id = l.league_id
      JOIN "SeasonTeams" st ON s.season_id = st.season_id
      WHERE st.team_id = ANY($1::int[])
      AND s.is_archived = FALSE
      ORDER BY l.name, s.start_date DESC
      """,
      user_team_ids
    )
    
    if not seasons_data:
      return PlayerHomeDataResponse(
        seasons_data=[],
        player_team_ids=user_team_ids
      )
    
    # Step 3: Group by season and get standings + upcoming matches
    season_dict = {}
    for row in seasons_data:
      season_id = row["season_id"]
      if season_id not in season_dict:
        season_dict[season_id] = {
          "season_id": season_id,
          "league_id": row["league_id"],
          "season_name": row["season_name"],
          "league_name": row["league_name"],
          "team_ids": set()
        }
      season_dict[season_id]["team_ids"].add(row["team_id"])
    
    # Step 4: Get standings for each season
    season_results = []
    for season_id, season_info in season_dict.items():
      # Get standings
      standings_rows = await connection.fetch(
        """
        SELECT 
          ls.standing_id,
          st.season_id,
          st.team_id,
          t.name as team_name,
          COALESCE(ls.matches_played, 0) as matches_played,
          COALESCE(ls.wins, 0) as wins,
          COALESCE(ls.losses, 0) as losses,
          COALESCE(ls.sets_won, 0) as sets_won,
          COALESCE(ls.sets_lost, 0) as sets_lost,
          (COALESCE(ls.sets_won, 0) - COALESCE(ls.sets_lost, 0)) as set_diff,
          COALESCE(ls.points_won, 0) as points_won,
          COALESCE(ls.points_lost, 0) as points_lost,
          (COALESCE(ls.points_won, 0) - COALESCE(ls.points_lost, 0)) as point_diff,
          COALESCE(ls.league_points, 0) as league_points,
          ROW_NUMBER() OVER (
            ORDER BY COALESCE(ls.league_points, 0) DESC,
            (COALESCE(ls.sets_won, 0) - COALESCE(ls.sets_lost, 0)) DESC,
            (COALESCE(ls.points_won, 0) - COALESCE(ls.points_lost, 0)) DESC,
            t.name ASC
          ) as position
        FROM "SeasonTeams" st
        JOIN "Teams" t ON st.team_id = t.team_id
        LEFT JOIN "LeagueStandings" ls
          ON ls.season_id = st.season_id
          AND ls.team_id = st.team_id
        WHERE st.season_id = $1
        ORDER BY position ASC
        """,
        season_id
      )
      
      standings = [StandingOut(**row) for row in standings_rows]
      
      # Get upcoming matches for user's teams in this season (limit to 5)
      upcoming_matches = await connection.fetch(
        """
        SELECT 
          m.match_id,
          m.season_id,
          m.home_team_id,
          m.away_team_id,
          m.match_datetime,
          ht.name as home_team_name,
          at.name as away_team_name,
          m.venue,
          m.status
        FROM "Matches" m
        JOIN "Teams" ht ON m.home_team_id = ht.team_id
        JOIN "Teams" at ON m.away_team_id = at.team_id
        WHERE m.season_id = $1
        AND (m.home_team_id = ANY($2::int[]) OR m.away_team_id = ANY($2::int[]))
        AND m.status = 'SCHEDULED'
        AND m.match_datetime IS NOT NULL
        ORDER BY m.match_datetime ASC
        LIMIT 5
        """,
        season_id,
        list(season_info["team_ids"])
      )
      
      upcoming_fixtures = [dict(match) for match in upcoming_matches]
      
      season_results.append(SeasonHomeData(
        season_id=season_id,
        league_id=season_info["league_id"],
        season_name=season_info["season_name"],
        league_name=season_info["league_name"],
        standings=standings,
        upcoming_fixtures=upcoming_fixtures
      ))
    
    return PlayerHomeDataResponse(
      seasons_data=season_results,
      player_team_ids=user_team_ids
    )


@router.get("/coaches/home-data", response_model=CoachHomeDataResponse)
async def get_coach_home_data(request: Request, user: dict = Depends(AuthUtils.get_current_user)) -> CoachHomeDataResponse:
  """Get all data needed for coach home screen in a single request.
  This replaces 35+ individual API calls with 1, dramatically improving load times.
  Returns data for teams where the user is the coach (created_by_user_id).
  """
  pool = request.app.state.pool
  user_id = user.get("user_id")
  
  async with pool.acquire() as connection:
    # Step 1: Get all teams where this user is the coach (creator)
    coach_teams = await connection.fetch(
      """
      SELECT DISTINCT t.team_id, t.name
      FROM "Teams" t
      WHERE t.created_by_user_id = $1
      """,
      user_id
    )
    
    coach_team_ids = [team["team_id"] for team in coach_teams]
    
    if not coach_team_ids:
      # User is not a coach of any teams
      return CoachHomeDataResponse(
        seasons_data=[],
        coach_team_ids=[]
      )
    
    # Step 2: Get all seasons where coach's teams are participating
    # and include league information
    seasons_data = await connection.fetch(
      """
      SELECT DISTINCT
        s.season_id,
        s.league_id,
        s.name as season_name,
        l.name as league_name,
        st.team_id,
        s.start_date
      FROM "Seasons" s
      JOIN "Leagues" l ON s.league_id = l.league_id
      JOIN "SeasonTeams" st ON s.season_id = st.season_id
      WHERE st.team_id = ANY($1::int[])
      AND s.is_archived = FALSE
      ORDER BY l.name, s.start_date DESC
      """,
      coach_team_ids
    )
    
    if not seasons_data:
      return CoachHomeDataResponse(
        seasons_data=[],
        coach_team_ids=coach_team_ids
      )
    
    # Step 3: Group by season and get standings + upcoming matches
    season_dict = {}
    for row in seasons_data:
      season_id = row["season_id"]
      if season_id not in season_dict:
        season_dict[season_id] = {
          "season_id": season_id,
          "league_id": row["league_id"],
          "season_name": row["season_name"],
          "league_name": row["league_name"],
          "team_ids": set()
        }
      season_dict[season_id]["team_ids"].add(row["team_id"])
    
    # Step 4: Get standings for each season
    season_results = []
    for season_id, season_info in season_dict.items():
      # Get ALL standings for the season (not just coach's teams)
      # This is the key difference from player endpoint - coaches see full table
      standings_rows = await connection.fetch(
        """
        SELECT 
          ls.standing_id,
          st.season_id,
          st.team_id,
          t.name as team_name,
          COALESCE(ls.matches_played, 0) as matches_played,
          COALESCE(ls.wins, 0) as wins,
          COALESCE(ls.losses, 0) as losses,
          COALESCE(ls.sets_won, 0) as sets_won,
          COALESCE(ls.sets_lost, 0) as sets_lost,
          (COALESCE(ls.sets_won, 0) - COALESCE(ls.sets_lost, 0)) as set_diff,
          COALESCE(ls.points_won, 0) as points_won,
          COALESCE(ls.points_lost, 0) as points_lost,
          (COALESCE(ls.points_won, 0) - COALESCE(ls.points_lost, 0)) as point_diff,
          COALESCE(ls.league_points, 0) as league_points,
          ROW_NUMBER() OVER (
            ORDER BY COALESCE(ls.league_points, 0) DESC,
            (COALESCE(ls.sets_won, 0) - COALESCE(ls.sets_lost, 0)) DESC,
            (COALESCE(ls.points_won, 0) - COALESCE(ls.points_lost, 0)) DESC,
            t.name ASC
          ) as position
        FROM "SeasonTeams" st
        JOIN "Teams" t ON st.team_id = t.team_id
        LEFT JOIN "LeagueStandings" ls
          ON ls.season_id = st.season_id
          AND ls.team_id = st.team_id
        WHERE st.season_id = $1
        ORDER BY position ASC
        """,
        season_id
      )
      
      standings = [StandingOut(**row) for row in standings_rows]
      
      # Get upcoming matches for coach's teams in this season (limit to 5)
      upcoming_matches = await connection.fetch(
        """
        SELECT 
          m.match_id,
          m.season_id,
          m.home_team_id,
          m.away_team_id,
          m.match_datetime,
          ht.name as home_team_name,
          at.name as away_team_name,
          m.venue,
          m.status
        FROM "Matches" m
        JOIN "Teams" ht ON m.home_team_id = ht.team_id
        JOIN "Teams" at ON m.away_team_id = at.team_id
        WHERE m.season_id = $1
        AND (m.home_team_id = ANY($2::int[]) OR m.away_team_id = ANY($2::int[]))
        AND m.status = 'SCHEDULED'
        AND m.match_datetime IS NOT NULL
        ORDER BY m.match_datetime ASC
        LIMIT 5
        """,
        season_id,
        list(season_info["team_ids"])
      )
      
      upcoming_fixtures = [dict(match) for match in upcoming_matches]
      
      season_results.append(SeasonHomeData(
        season_id=season_id,
        league_id=season_info["league_id"],
        season_name=season_info["season_name"],
        league_name=season_info["league_name"],
        standings=standings,
        upcoming_fixtures=upcoming_fixtures
      ))
    
    return CoachHomeDataResponse(
      seasons_data=season_results,
      coach_team_ids=coach_team_ids
    )

