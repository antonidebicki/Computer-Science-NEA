from ..core.auth import AuthUtils
import datetime
from typing import Optional, Literal
import asyncpg
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, EmailStr, Field, field_validator

router = APIRouter()

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

class RegisterResponse(BaseModel):
    message: str
    user_id: int
    username: str
    role: Literal["PLAYER", "COACH", "ADMIN"]