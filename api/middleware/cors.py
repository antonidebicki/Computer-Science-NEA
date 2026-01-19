from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


def setup_cors(app: FastAPI) -> None:
    """temporary solution to fix CORS bc i cant be asked"""
    """basically allows everything"""
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:*",
            "http://127.0.0.1:*",
            "*" 
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"], 
    )
