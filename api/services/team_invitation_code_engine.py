import hmac
import hashlib
from datetime import datetime, timezone
import os


class TeamInvitationCodeEngine:
    """Generate and validate daily 6-digit invitation codes based on team ID."""

    SECRET_KEY = os.getenv(
        "TEAM_INVITATION_SECRET_KEY",
        "default-team-invitation-secret-key-change-in-production",
    )

    @staticmethod
    def generate_code(team_id: int) -> str:
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        message = f"{team_id}:{today}"

        signature = hmac.new(
            TeamInvitationCodeEngine.SECRET_KEY.encode(),
            message.encode(),
            hashlib.sha256,
        ).digest()

        code_int = int.from_bytes(signature[:4], byteorder='big') % 1000000
        return f"{code_int:06d}"

    @staticmethod
    def validate_code(team_id: int, code: str) -> bool:
        try:
            expected_code = TeamInvitationCodeEngine.generate_code(team_id)
            return hmac.compare_digest(code, expected_code)
        except Exception as e:
            print("Exeption:" + str(e))
            return False
