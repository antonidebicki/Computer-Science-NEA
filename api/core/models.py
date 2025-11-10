from datetime import datetime
from typing import Optional, Annotated, Literal
from pydantic import BaseModel, EmailStr, Field, constr, field_validator

class LoginRequest(BaseModel):
    username: Annotated[str, constr(strip_whitespace=True, min_length=1)]
    password: Annotated[str, constr(min_length=1)]


class UserInfo(BaseModel):
    user_id: int
    username: str
    email: EmailStr
    full_name: Optional[str]
    role: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserInfo


class RefreshRequest(BaseModel):
    refresh_token: str


class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., max_length=128)
    full_name: str = Field(..., max_length=100)
    role: Literal["PLAYER", "COACH", "ADMIN"] = Field(...)
    
    @field_validator('username', 'full_name', 'email', mode='before')
    @classmethod
    def _strip_strings(cls, v):
        if isinstance(v, str):
            v = v.strip()
            if v == '':
                raise ValueError('must not be empty or only whitespace')
        return v

    @field_validator('password')
    @classmethod
    def _validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('password must be at least 8 characters long')
        if not any(c.islower() for c in v):
            raise ValueError('password must contain a lowercase letter')
        if not any(c.isupper() for c in v):
            raise ValueError('password must contain an uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('password must contain a digit')
        return v 


class UserOut(BaseModel):
  user_id: int
  username: str
  email: EmailStr
  full_name: Optional[str]
  role: str
  created_at: Optional[datetime]


class UserCreate(BaseModel):
  username: Annotated[str, constr(strip_whitespace=True, min_length=1)]
  hashed_password: Annotated[str, constr(min_length=1)]
  email: EmailStr
  full_name: Optional[Annotated[str, constr(strip_whitespace=True, min_length=1)]] = None
  role: Annotated[str, constr(strip_whitespace=True, min_length=1)]


class TeamOut(BaseModel):
  team_id: int
  name: str
  created_by_user_id: int
  logo_url: Optional[str]
  created_at: Optional[datetime]


class TeamCreate(BaseModel):
  name: Annotated[str, constr(strip_whitespace=True, min_length=1)]
  created_by_user_id: int
  logo_url: Optional[Annotated[str, constr(strip_whitespace=True, min_length=1)]] = None


class LeagueOut(BaseModel):
    league_id: int
    name: str
    admin_user_id: int
    description: Optional[str]
    rules: Optional[str]
    created_at: Optional[datetime]


class LeagueCreate(BaseModel):
    name: Annotated[str, constr(strip_whitespace=True, min_length=1)]
    admin_user_id: int
    description: Optional[Annotated[str, constr(strip_whitespace=True, min_length=1)]] = None
    rules: Optional[Annotated[str, constr(strip_whitespace=True, min_length=1)]] = None


class SeasonOut(BaseModel):
    season_id: int
    league_id: int
    name: str
    start_date: datetime
    end_date: datetime
    is_archived: bool


class SeasonCreate(BaseModel):
    league_id: int
    name: Annotated[str, constr(strip_whitespace=True, min_length=1)]
    start_date: datetime
    end_date: datetime


class MatchOut(BaseModel):
    match_id: int
    season_id: int
    home_team_id: int
    away_team_id: int
    match_datetime: Optional[datetime]
    venue: Optional[str]
    status: str
    winner_team_id: Optional[int]
    home_sets_won: int
    away_sets_won: int


class MatchCreate(BaseModel):
    season_id: int
    home_team_id: int
    away_team_id: int
    match_datetime: Optional[datetime] = None
    venue: Optional[Annotated[str, constr(strip_whitespace=True, min_length=1)]] = None
    status: str = "SCHEDULED"
