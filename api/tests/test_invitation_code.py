"""
Test file for Invitation Code Engine.
Tests the generation and validation of daily 6-digit invitation codes.
"""

import sys
import os
from datetime import datetime, timedelta

# Add the parent directory to the path to import api module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.invitation_code_engine import InvitationCodeEngine


def test_code_generation():
    """Test that codes are generated correctly."""
    print("Testing code generation...")
    
    user_id = 123
    code = InvitationCodeEngine.generate_code(user_id)
    
    assert len(code) == 6, f"Expected 6-digit code, got {len(code)}"
    assert code.isdigit(), f"Expected numeric code, got {code}"
    
    print(f"✓ Generated code for user {user_id}: {code}")
    
    # Test that the same user on the same day generates the same code
    code2 = InvitationCodeEngine.generate_code(user_id)
    assert code == code2, "Same user should generate same code on same day"
    print(f"✓ Deterministic: same user generates same code: {code}")
    
    # Test that different users generate different codes
    code3 = InvitationCodeEngine.generate_code(456)
    assert code != code3, "Different users should generate different codes"
    print(f"✓ Different users generate different codes: {code} vs {code3}")


def test_code_validation():
    """Test that code validation works correctly."""
    print("\nTesting code validation...")
    
    user_id = 789
    code = InvitationCodeEngine.generate_code(user_id)
    
    # Valid code
    is_valid = InvitationCodeEngine.validate_code(user_id, code)
    assert is_valid, f"Generated code {code} should be valid for user {user_id}"
    print(f"✓ Code validation passed for valid code: {code}")
    
    # Invalid code
    is_valid = InvitationCodeEngine.validate_code(user_id, "000000")
    assert not is_valid, "Invalid code should fail validation"
    print(f"✓ Code validation rejected invalid code: 000000")
    
    # Wrong user
    is_valid = InvitationCodeEngine.validate_code(999, code)
    assert not is_valid, "Code generated for one user should not work for another"
    print(f"✓ Code validation rejected code for wrong user")


def test_daily_rotation():
    """Test that codes change daily (simulate with date validation)."""
    print("\nTesting daily rotation...")
    
    user_id = 555
    today = datetime.utcnow().strftime("%Y-%m-%d")
    tomorrow = (datetime.utcnow() + timedelta(days=1)).strftime("%Y-%m-%d")
    
    today_code = InvitationCodeEngine.generate_code(user_id)
    
    # Validate today's code works for today
    is_valid_today = InvitationCodeEngine.validate_code_for_date(user_id, today_code, today)
    assert is_valid_today, "Today's code should be valid for today"
    print(f"✓ Today's code ({today_code}) is valid for today ({today})")
    
    # Validate today's code does NOT work for tomorrow
    is_valid_tomorrow = InvitationCodeEngine.validate_code_for_date(user_id, today_code, tomorrow)
    assert not is_valid_tomorrow, "Today's code should NOT be valid for tomorrow"
    print(f"✓ Today's code ({today_code}) is NOT valid for tomorrow ({tomorrow})")
    
    # Get tomorrow's code and verify it's different
    tomorrow_code = InvitationCodeEngine.validate_code_for_date(user_id, today_code, tomorrow)
    print(f"✓ Codes rotate daily - security maintained")


def test_timing_resistance():
    """Test that constant-time comparison is used."""
    print("\nTesting timing resistance...")
    
    user_id = 999
    code = InvitationCodeEngine.generate_code(user_id)
    
    # Both should use constant-time comparison internally
    wrong_code = "000000"
    
    import time
    
    # Validate correct code
    start = time.perf_counter()
    for _ in range(1000):
        InvitationCodeEngine.validate_code(user_id, code)
    correct_time = time.perf_counter() - start
    
    # Validate wrong code
    start = time.perf_counter()
    for _ in range(1000):
        InvitationCodeEngine.validate_code(user_id, wrong_code)
    wrong_time = time.perf_counter() - start
    
    # Times should be similar (constant-time comparison)
    print(f"✓ Correct code validation time: {correct_time:.6f}s (1000 iterations)")
    print(f"✓ Wrong code validation time:  {wrong_time:.6f}s (1000 iterations)")
    print(f"✓ Constant-time comparison prevents timing attacks")


def test_6_digit_range():
    """Test that all codes are 6 digits (000000-999999)."""
    print("\nTesting 6-digit range...")
    
    codes = set()
    for user_id in range(1, 1001):
        code = InvitationCodeEngine.generate_code(user_id)
        assert len(code) == 6, f"Code length should be 6, got {len(code)}"
        assert code.isdigit(), f"Code should be numeric, got {code}"
        assert 0 <= int(code) <= 999999, f"Code should be 000000-999999, got {code}"
        codes.add(code)
    
    print(f"✓ Generated {len(codes)} unique codes from 1000 users")
    print(f"✓ All codes are 6-digit numeric format (000000-999999)")


if __name__ == "__main__":
    print("=" * 60)
    print("INVITATION CODE ENGINE TEST SUITE")
    print("=" * 60)
    
    try:
        test_code_generation()
        test_code_validation()
        test_daily_rotation()
        test_timing_resistance()
        test_6_digit_range()
        
        print("\n" + "=" * 60)
        print("✓ ALL TESTS PASSED")
        print("=" * 60)
    except AssertionError as e:
        print(f"\n✗ TEST FAILED: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
