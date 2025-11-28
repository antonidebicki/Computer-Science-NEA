# Password hashing and verification utilities

import os
import bcrypt
import cryptography
import datetime
from datetime import timedelta
from typing import Optional, List
import uuid
from jose import JWTError, jwt
from fastapi import HTTPException, Header, status


class AuthUtils:

    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    @staticmethod
    def verify_password(password: str, hashed: str) -> bool:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """
        Create a JWT access token including user_id and role in the payload.
        Args:
            data (dict): Should include 'sub', 'user_id', and 'role'.
            expires_delta (Optional[timedelta]): Expiry time delta.
        Returns:
            str: Encoded JWT token.
        """
        to_encode = data.copy()
        # mark as access token type
        to_encode.update({"type": "access"})
        if expires_delta:
            expire = datetime.datetime.now(datetime.timezone.utc) + expires_delta
        else:
            expire = datetime.datetime.now(datetime.timezone.utc) + timedelta(hours=24)
        to_encode.update({"exp": expire})
        
        # Enforce environment variables - no defaults for security
        secret_key = os.environ.get("SECRET_KEY")
        if not secret_key:
            raise ValueError("SECRET_KEY environment variable must be set")
        algorithm = os.environ.get("ALGORITHM", "HS256")
        encoded_jwt = jwt.encode(to_encode, secret_key, algorithm=algorithm)
        return encoded_jwt
    
    @staticmethod
    def decode_access_token(authorization: Optional[str]) -> dict:
        """
        Decode and verify a JWT access token from the Authorization header.
        Args:
            authorization (str): Authorization header value (e.g., "Bearer <token>").
        """
        if not authorization:
            return {"error": "Authorization header missing"}
        try:
            token = authorization.split(" ")[1]
            secret_key = os.environ.get("SECRET_KEY")
            if not secret_key:
                raise ValueError("SECRET_KEY environment variable must be set")
            algorithm = os.environ.get("ALGORITHM", "HS256")
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
            # ensure this is an access token
            if payload.get("type") != "access":
                return {"error": "Invalid token type"}
            return payload
        except (JWTError, IndexError):
            return {"error": "Invalid token"}

    # -------------------- Refresh Tokens --------------------
    @staticmethod
    def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """
        Create a JWT refresh token. Defaults to 30 days expiry.
        Includes a 'type' = 'refresh' and a unique 'jti' for rotation strategies.
        """
        to_encode = data.copy()
        # mark this token as a refresh token
        to_encode.update({"type": "refresh", "jti": str(uuid.uuid4())})
        if expires_delta:
            expire = datetime.datetime.now(datetime.timezone.utc) + expires_delta
        else:
            # default 30 days
            expire = datetime.datetime.now(datetime.timezone.utc) + timedelta(days=30)
        to_encode.update({"exp": expire})
        # Use separate refresh secret or fall back to main secret (but no default)
        secret_key = os.environ.get("REFRESH_SECRET_KEY") or os.environ.get("SECRET_KEY")
        if not secret_key:
            raise ValueError("SECRET_KEY environment variable must be set")
        algorithm = os.environ.get("ALGORITHM", "HS256")
        return jwt.encode(to_encode, secret_key, algorithm=algorithm)

    @staticmethod
    def decode_refresh_token(token: str) -> dict:
        """
        Decode and verify a refresh token passed directly (not from Authorization header).
        Ensures the token 'type' is 'refresh'.
        """
        try:
            secret_key = os.environ.get("REFRESH_SECRET_KEY") or os.environ.get("SECRET_KEY")
            if not secret_key:
                raise ValueError("SECRET_KEY environment variable must be set")
            algorithm = os.environ.get("ALGORITHM", "HS256")
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
            if payload.get("type") != "refresh":
                return {"error": "Invalid token type"}
            return payload
        except JWTError:
            return {"error": "Invalid token"}

    # -------------------- Authentication Dependencies --------------------
    @staticmethod
    def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
        """
        FastAPI dependency to extract and verify JWT token from Authorization header.
        Returns user payload (user_id, username, role) if valid.
        Raises 401 if token is missing or invalid.
        
        Usage: user: dict = Depends(AuthUtils.get_current_user)
        """
        if not authorization:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization header missing"
            )
        
        try:
            # Extract token from "Bearer <token>" format
            scheme, token = authorization.split()
            if scheme.lower() != "bearer":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication scheme"
                )
            
            # Decode and verify token
            secret_key = os.environ.get("SECRET_KEY")
            if not secret_key:
                raise ValueError("SECRET_KEY environment variable must be set")
            algorithm = os.environ.get("ALGORITHM", "HS256")
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
            
            # Ensure this is an access token
            if payload.get("type") != "access":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token type"
                )
            
            return payload
            
        except (JWTError, ValueError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
    
    @staticmethod
    def require_role(allowed_roles: List[str]):
        """
        FastAPI dependency factory that checks if user has required role.
        Returns a dependency function that validates user role.
        Raises 403 if user doesn't have required role.
        
        Usage: user: dict = Depends(AuthUtils.require_role(["ADMIN", "COACH"]))
        """
        def role_checker(authorization: Optional[str] = Header(None)) -> dict:
            # First, get the current user
            user_payload = AuthUtils.get_current_user(authorization)
            
            # Check if user role is in allowed roles
            user_role = user_payload.get("role")
            if user_role not in allowed_roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Access forbidden. Required roles: {', '.join(allowed_roles)}"
                )
            
            return user_payload
        
        return role_checker