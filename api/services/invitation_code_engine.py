import hmac
import hashlib
from datetime import datetime, timezone
import os


class InvitationCodeEngine:
    """Generate and validate daily 6-digit invitation codes based on user ID."""
    
    # change this for production its a default key rn so defintely change for NEA too
    # tho i rlly cba to change it rn 
    SECRET_KEY = os.getenv("INVITATION_SECRET_KEY", "default-secret-key-change-in-production")
    
    @staticmethod
    def generate_code(user_id: int) -> str:
        """
        nnly need the user id to generate everything else is found by the device
        """
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        
        message = f"{user_id}:{today}"
        
        signature = hmac.new(
            InvitationCodeEngine.SECRET_KEY.encode(),
            message.encode(),
            hashlib.sha256
        ).digest()
        
        code_int = int.from_bytes(signature[:4], byteorder='big') % 1000000
        
        return f"{code_int:06d}"
    
    @staticmethod
    def validate_code(user_id: int, code: str) -> bool:
        """
        validate if code is correct
        """
        try:
            expected_code = InvitationCodeEngine.generate_code(user_id)
            # keep this constant time to keep it secure from timing attacks
            return hmac.compare_digest(code, expected_code)
        except Exception as e:
            print("Exeption:" + str(e))
            return False
    
    @staticmethod
    def validate_code_for_date(user_id: int, code: str, date_str: str) -> bool:
        """
        just made this to check past dates for testing
        """
        try:
            message = f"{user_id}:{date_str}"
            signature = hmac.new(
                InvitationCodeEngine.SECRET_KEY.encode(),
                message.encode(),
                hashlib.sha256
            ).digest()
            
            code_int = int.from_bytes(signature[:4], byteorder='big') % 1000000
            expected_code = f"{code_int:06d}"
            
            return hmac.compare_digest(code, expected_code)
        except Exception as e:
            print("Exeption:" + str(e))
            return False
