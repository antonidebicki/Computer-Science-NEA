# Password hashing and verification utilities

import os
import bcrypt
import cryptography
import datetime
from datetime import timedelta
from typing import Optional
from jose import JWTError, jwt


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
        if expires_delta:
            expire = datetime.datetime.now(datetime.timezone.utc) + expires_delta
        else:
            expire = datetime.datetime.now(datetime.timezone.utc) + timedelta(hours=24)
        to_encode.update({"exp": expire})
        secret_key = os.environ.get("SECRET_KEY", "your-default-secret-key")
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
            secret_key = os.environ.get("SECRET_KEY", "your-default-secret-key")
            algorithm = os.environ.get("ALGORITHM", "HS256")
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
            return payload
        except (JWTError, IndexError):
            return {"error": "Invalid token"}

    @staticmethod
    def require_role(allowed_roles: list, token_payload: dict) -> bool:
        """
        Check if the user's role from the token payload is in the allowed roles.
        Args:
            allowed_roles (list): List of roles that are permitted.
            token_payload (dict): Decoded JWT payload containing 'role'.
        """
        user_role = token_payload.get("role")
        return user_role in allowed_roles