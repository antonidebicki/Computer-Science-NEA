#!/usr/bin/env python3
"""
Cleanup Script for VolleyLeague Seed Data

This script removes all seed data inserted by run_seed.py, leaving the database
in a clean state for re-seeding or testing.

⚠️  WARNING: This will delete all seed data including:
- All users created by seed script
- All leagues, teams, seasons
- All team memberships
- All related data

Usage:
    python3 database/seed/cleanup_seed.py
    python3 database/seed/cleanup_seed.py --confirm  (skip confirmation prompt)
"""

import os
import sys
import asyncio
import asyncpg
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Load environment variables from secrets/.env
env_path = Path(__file__).parent.parent.parent / "secrets" / ".env"
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value


def _pg_dsn() -> dict:
    """Read connection details from standard PG* environment variables."""
    return {
        "host": os.environ.get("PGHOST", "localhost"),
        "port": int(os.environ.get("PGPORT", 5432)),
        "user": os.environ.get("PGUSER", "postgres"),
        "password": os.environ.get("PGPASSWORD"),
        "database": os.environ.get("PGDATABASE", "antonidebicki"),
        "ssl": os.environ.get("PGSSLMODE") == "require",
    }


async def cleanup_seed_data(skip_confirm: bool = False):
    """Remove all seed data from the database"""
    print("\n" + "="*70)
    print("🧹 VOLLEYLEAGUE DATABASE CLEANUP")
    print("="*70 + "\n")
    
    if not skip_confirm:
        print("⚠️  WARNING: This will delete all seed data from the database!")
        print("\nThis includes:")
        print("  • All seed users (admin, coaches, players)")
        print("  • All leagues (South East, North West)")
        print("  • All teams and their members")
        print("  • All seasons and season assignments")
        print("  • Any matches or standings data")
        print()
        
        response = input("Are you sure you want to continue? (yes/no): ").strip().lower()
        if response != 'yes':
            print("\n❌ Cleanup cancelled")
            return False
    
    try:
        print(f"\n🔌 Connecting to PostgreSQL database...")
        pool = await asyncpg.create_pool(**_pg_dsn())
        
        async with pool.acquire() as connection:
            print(f"✅ Connected to database\n")
            print("🗑️  Deleting seed data...")
            print("-" * 70)
            
            # Count existing data before deletion
            user_count = await connection.fetchval('SELECT COUNT(*) FROM "Users"')
            league_count = await connection.fetchval('SELECT COUNT(*) FROM "Leagues"')
            team_count = await connection.fetchval('SELECT COUNT(*) FROM "Teams"')
            season_count = await connection.fetchval('SELECT COUNT(*) FROM "Seasons"')
            
            print(f"📊 Current database state:")
            print(f"   Users: {user_count}")
            print(f"   Leagues: {league_count}")
            print(f"   Teams: {team_count}")
            print(f"   Seasons: {season_count}\n")
            
            # Delete data in reverse order of dependencies
            async with connection.transaction():
                # Delete team members first (references teams and users)
                deleted = await connection.execute('DELETE FROM "TeamMembers"')
                print(f"✓ Deleted team members")
                
                # Delete season teams (references seasons and teams)
                deleted = await connection.execute('DELETE FROM "SeasonTeams"')
                print(f"✓ Deleted season team assignments")
                
                # Delete matches (if any exist)
                deleted = await connection.execute('DELETE FROM "Matches"')
                print(f"✓ Deleted matches")
                
                # Delete league standings (if any exist)
                deleted = await connection.execute('DELETE FROM "LeagueStandings"')
                print(f"✓ Deleted league standings")
                
                # Delete seasons
                deleted = await connection.execute('DELETE FROM "Seasons"')
                print(f"✓ Deleted seasons")
                
                # Delete teams
                deleted = await connection.execute('DELETE FROM "Teams"')
                print(f"✓ Deleted teams")
                
                # Delete leagues
                deleted = await connection.execute('DELETE FROM "Leagues"')
                print(f"✓ Deleted leagues")
                
                # Delete seed users (keep test users from other tests)
                seed_usernames = [
                    'league_admin',
                    # South East coaches and players
                    'sarah_johnson', 'emma_davies', 'olivia_smith', 'sophie_brown',
                    'mike_thompson', 'james_wilson', 'liam_taylor', 'noah_jones',
                    'lisa_anderson', 'ava_martin', 'mia_white', 'isabella_harris',
                    # North West coaches and players
                    'david_roberts', 'ethan_clark', 'lucas_lewis', 'mason_walker',
                    'rachel_green', 'charlotte_hall', 'amelia_allen', 'harper_young',
                    'tom_baker', 'william_king', 'benjamin_scott', 'alexander_hill'
                ]
                
                deleted_users = 0
                for username in seed_usernames:
                    result = await connection.execute(
                        'DELETE FROM "Users" WHERE username = $1',
                        username
                    )
                    if result != 'DELETE 0':
                        deleted_users += 1
                
                print(f"✓ Deleted {deleted_users} seed users")
            
            print("-" * 70)
            
            # Verify cleanup
            user_count_after = await connection.fetchval('SELECT COUNT(*) FROM "Users"')
            league_count_after = await connection.fetchval('SELECT COUNT(*) FROM "Leagues"')
            team_count_after = await connection.fetchval('SELECT COUNT(*) FROM "Teams"')
            season_count_after = await connection.fetchval('SELECT COUNT(*) FROM "Seasons"')
            
            print(f"\n📊 Database state after cleanup:")
            print(f"   Users: {user_count_after}")
            print(f"   Leagues: {league_count_after}")
            print(f"   Teams: {team_count_after}")
            print(f"   Seasons: {season_count_after}\n")
            
        await pool.close()
        
        print("="*70)
        print("✅ CLEANUP COMPLETED SUCCESSFULLY")
        print("="*70)
        print(f"\n📝 Summary:")
        print(f"   • Removed {deleted_users} seed users")
        print(f"   • Removed {league_count} leagues")
        print(f"   • Removed {team_count} teams")
        print(f"   • Removed {season_count} seasons")
        print(f"   • Removed all related data (members, assignments, etc.)\n")
        print(f"💡 Tip: Run 'python3 database/seed/run_seed.py' to re-seed the database\n")
        
        return True
        
    except asyncpg.PostgresError as e:
        print(f"\n❌ Database Error: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Main entry point"""
    skip_confirm = '--confirm' in sys.argv or '-y' in sys.argv
    success = await cleanup_seed_data(skip_confirm)
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
