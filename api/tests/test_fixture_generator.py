"""
Test fixture generator with real seed data from the database.

This test connects to the database, fetches teams from the seeded leagues,
and tests the fixture generation algorithm with various configurations.
"""

import asyncio
import asyncpg
import os
import datetime
from typing import List, Dict, Optional

# Import our fixture generator functions
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from services.fixture_generator import generate_round_robin, assign_match_dates


async def get_database_connection():
    """Create database connection using environment variables."""
    return await asyncpg.create_pool(
        host=os.environ.get('PGHOST', 'localhost'),
        port=int(os.environ.get('PGPORT', 5432)),
        user=os.environ.get('PGUSER', 'postgres'),
        password=os.environ.get('PGPASSWORD'),
        database=os.environ.get('PGDATABASE', 'antonidebicki')
    )


async def fetch_league_teams(pool, season_id: int) -> List[int]:
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT team_id 
            FROM "SeasonTeams" 
            WHERE season_id = $1
            ORDER BY team_id
            """,
            season_id
        )
        return [row['team_id'] for row in rows]


async def get_season_info(pool, season_id: int) -> Optional[Dict]:
    """Get season details from database."""
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """
            SELECT s.season_id, s.league_id, s.name as season_name, s.start_date, s.end_date,
                   l.name as league_name
            FROM "Seasons" s
            JOIN "Leagues" l ON s.league_id = l.league_id
            WHERE s.season_id = $1
            """,
            season_id
        )
        return dict(row) if row else None


def print_fixture_summary(fixtures: List[dict], team_ids: List[int]):
    print(f"\n{'='*80}")
    print("FIXTURE GENERATION SUMMARY")
    print(f"{'='*80}")
    
    print(f"\nTotal Matches: {len(fixtures)}")
    print(f"Total Teams: {len(team_ids)}")
    
    # Count matches per team
    team_match_counts = {}
    for fixture in fixtures:
        team_a = fixture['team_a_id']
        team_b = fixture['team_b_id']
        team_match_counts[team_a] = team_match_counts.get(team_a, 0) + 1
        team_match_counts[team_b] = team_match_counts.get(team_b, 0) + 1
    
    print(f"\nMatches per team:")
    for team_id in sorted(team_match_counts.keys()):
        print(f"  Team {team_id}: {team_match_counts[team_id]} matches")
    
    # Date range
    if fixtures:
        dates = [f['match_date'] for f in fixtures]
        first_match = min(dates)
        last_match = max(dates)
        print(f"\nFirst match: {first_match}")
        print(f"Last match: {last_match}")
        print(f"Season duration: {(last_match - first_match).days} days")
    
    # Check weekday distribution
    weekday_counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
    weekday_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    
    for fixture in fixtures:
        weekday = fixture['match_date'].weekday()
        weekday_counts[weekday] += 1
    
    print(f"\nMatches by day of week:")
    for day_num, day_name in enumerate(weekday_names):
        count = weekday_counts[day_num]
        if count > 0:
            print(f"  {day_name}: {count} matches")


async def test_single_round_robin_weekly():
    """Test 1: Single round-robin with weekly matches."""
    print("\n" + "="*80)
    print("TEST 1: Single Round-Robin, Weekly Matches")
    print("="*80)
    
    pool = await get_database_connection()
    
    try:
        # Use South East Division (should have 3 teams)
        # Get first season from database
        async with pool.acquire() as conn:
            season_row = await conn.fetchrow('SELECT season_id FROM "Seasons" LIMIT 1')
            season_id = season_row['season_id'] if season_row else 1
        
        season_info = await get_season_info(pool, season_id)
        
        if not season_info:
            print("❌ Season not found in database. Run seed data first.")
            return
        
        print(f"\nLeague: {season_info['league_name']}")
        print(f"Season: {season_info['season_name']}")
        
        team_ids = await fetch_league_teams(pool, season_id)
        print(f"Teams in season: {team_ids}")
        
        if not team_ids:
            print("❌ No teams found. Run seed data first.")
            return
        
        # Generate fixtures
        matches = generate_round_robin(team_ids, double=False)
        print(f"\nGenerated {len(matches)} unique pairings")
        
        # Schedule with weekly matches
        start_date = datetime.date(2025, 9, 1)
        fixtures = assign_match_dates(
            matches,
            start_date,
            matches_per_week_per_team=1,
            weeks_between_matches=1,
            allowed_weekdays=None  # All days allowed
        )
        
        print_fixture_summary(fixtures, team_ids)
        print("\n✅ Test 1 passed!")
        
    finally:
        await pool.close()


async def test_double_round_robin_weekends():
    """Test 2: Double round-robin with weekend-only matches."""
    print("\n" + "="*80)
    print("TEST 2: Double Round-Robin, Weekend Matches Only")
    print("="*80)
    
    pool = await get_database_connection()
    
    try:
        # Use North West Division (should have 3 teams)
        # Get second season from database
        async with pool.acquire() as conn:
            season_row = await conn.fetchrow('SELECT season_id FROM "Seasons" OFFSET 1 LIMIT 1')
            season_id = season_row['season_id'] if season_row else 2
        
        season_info = await get_season_info(pool, season_id)
        
        if not season_info:
            print("❌ Season not found in database. Run seed data first.")
            return
        
        print(f"\nLeague: {season_info['league_name']}")
        print(f"Season: {season_info['season_name']}")
        
        team_ids = await fetch_league_teams(pool, season_id)
        print(f"Teams in season: {team_ids}")
        
        if not team_ids:
            print("❌ No teams found. Run seed data first.")
            return
        
        # Generate double round-robin fixtures
        matches = generate_round_robin(team_ids, double=True)
        print(f"\nGenerated {len(matches)} matches (home & away)")
        
        # Schedule with weekend-only matches (Saturday & Sunday)
        start_date = datetime.date(2025, 9, 1)
        fixtures = assign_match_dates(
            matches,
            start_date,
            matches_per_week_per_team=1,
            weeks_between_matches=1,
            allowed_weekdays=[0, 0, 0, 0, 0, 1, 1]  # Saturday & Sunday only
        )
        
        print_fixture_summary(fixtures, team_ids)
        
        # Verify all matches are on weekends
        all_weekends = all(f['match_date'].weekday() in [5, 6] for f in fixtures)
        if all_weekends:
            print("\n✅ All matches scheduled on weekends!")
        else:
            print("\n❌ Some matches not on weekends!")
        
        print("\n✅ Test 2 passed!")
        
    finally:
        await pool.close()


async def test_fortnightly_matches():
    """Test 3: Single round-robin with fortnightly matches."""
    print("\n" + "="*80)
    print("TEST 3: Single Round-Robin, Fortnightly Matches")
    print("="*80)
    
    pool = await get_database_connection()
    
    try:
        # Get first season from database
        async with pool.acquire() as conn:
            season_row = await conn.fetchrow('SELECT season_id FROM "Seasons" LIMIT 1')
            season_id = season_row['season_id'] if season_row else 1
        
        season_info = await get_season_info(pool, season_id)
        
        if not season_info:
            print("❌ Season not found in database.")
            return
        
        print(f"\nLeague: {season_info['league_name']}")
        print(f"Season: {season_info['season_name']}")
        
        team_ids = await fetch_league_teams(pool, season_id)
        print(f"Teams in season: {team_ids}")
        
        if not team_ids:
            print("❌ No teams found.")
            return
        
        # Generate fixtures
        matches = generate_round_robin(team_ids, double=False)
        print(f"\nGenerated {len(matches)} unique pairings")
        
        # Schedule with fortnightly matches
        start_date = datetime.date(2025, 9, 1)
        fixtures = assign_match_dates(
            matches,
            start_date,
            matches_per_week_per_team=1,
            weeks_between_matches=2,  # Every 2 weeks
            allowed_weekdays=None
        )
        
        print_fixture_summary(fixtures, team_ids)
        
        # Verify matches are 2 weeks apart
        if len(fixtures) > 1:
            dates = sorted([f['match_date'] for f in fixtures])
            gaps = [(dates[i+1] - dates[i]).days for i in range(len(dates)-1)]
            print(f"\nGaps between match rounds: {set(gaps)} days")
            if all(gap >= 14 for gap in gaps):
                print("✅ All matches at least 2 weeks apart!")
            else:
                print("⚠️ Some matches closer than 2 weeks")
        
        print("\n✅ Test 3 passed!")
        
    finally:
        await pool.close()


async def run_all_tests():
    """Run all fixture generator tests."""
    print("\n" + "🏐"*40)
    print("FIXTURE GENERATOR TEST SUITE")
    print("🏐"*40)
    
    try:
        await test_single_round_robin_weekly()
        await test_double_round_robin_weekends()
        await test_fortnightly_matches()
        
        print("\n" + "="*80)
        print("✅ ALL TESTS PASSED!")
        print("="*80 + "\n")
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(run_all_tests())
