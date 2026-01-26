from typing import List
from datetime import datetime
import asyncpg
from asyncpg import UniqueViolationError
from fastapi import APIRouter, HTTPException, Request, status, Depends
from api.models import UserCreate, UserOut, InvitationCodeResponse, InvitationCodeValidation, InvitationCodeRedeemResponse
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

