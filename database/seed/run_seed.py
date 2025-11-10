#!/usr/bin/env python3
"""
Seed Data Runner for VolleyLeague Database (DEV_STAGES 1.2a)

This script runs the seed_data.sql file to populate the database with:
- 1 Admin user
- 2 Leagues (South East Division, North West Division)
- 6 Teams (3 per league)
- 6 Coaches (1 per team)
- 18 Players (3 per team)
- 2 Seasons (2025/26 for each league)
- Team assignments and memberships

Usage:
    python3 database/seed/run_seed.py
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
    print("📄 Loading environment variables from secrets/.env")
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value
else:
    print("⚠️  Warning: secrets/.env not found")


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


async def run_seed_data():
    """Execute the seed data SQL script"""
    print("\n" + "="*70)
    print("🌱 VOLLEYLEAGUE DATABASE SEED (DEV_STAGES 1.2a)")
    print("="*70 + "\n")
    
    # Read the SQL file
    sql_file = Path(__file__).parent / "seed_data.sql"
    if not sql_file.exists():
        print(f"❌ Error: SQL file not found at {sql_file}")
        return False
    
    print(f"📖 Reading SQL file: {sql_file.name}")
    with open(sql_file, 'r') as f:
        sql_content = f.read()
    
    # Connect to database
    try:
        print(f"🔌 Connecting to PostgreSQL database...")
        dsn = _pg_dsn()
        print(f"   Host: {dsn['host']}:{dsn['port']}")
        print(f"   Database: {dsn['database']}")
        print(f"   User: {dsn['user']}")
        
        pool = await asyncpg.create_pool(**dsn)
        
        async with pool.acquire() as connection:
            print(f"\n✅ Connected to database\n")
            print("🚀 Executing seed data script...")
            print("-" * 70)
            
            # Execute the SQL script
            await connection.execute(sql_content)
            
            print("-" * 70)
            print("✅ Seed data executed successfully\n")
            
            # Run verification queries
            print("🔍 Verifying data insertion...")
            print("-" * 70)
            
            # Count users by role
            print("\n📊 Users by Role:")
            role_counts = await connection.fetch(
                'SELECT role, COUNT(*) as count FROM "Users" GROUP BY role ORDER BY role'
            )
            for row in role_counts:
                print(f"   {row['role']:8} : {row['count']} users")
            
            # Count leagues
            leagues = await connection.fetch(
                'SELECT league_id, name FROM "Leagues" ORDER BY league_id'
            )
            print(f"\n📊 Leagues: {len(leagues)}")
            for league in leagues:
                print(f"   [{league['league_id']}] {league['name']}")
            
            # Count teams per league
            print(f"\n📊 Teams per League:")
            for league in leagues:
                teams = await connection.fetch(
                    'SELECT COUNT(*) as count FROM "SeasonTeams" st '
                    'JOIN "Seasons" s ON st.season_id = s.season_id '
                    'WHERE s.league_id = $1',
                    league['league_id']
                )
                print(f"   {league['name']:25} : {teams[0]['count']} teams")
            
            # Count seasons
            seasons = await connection.fetch(
                'SELECT season_id, name FROM "Seasons" ORDER BY season_id'
            )
            print(f"\n📊 Seasons: {len(seasons)}")
            for season in seasons:
                print(f"   [{season['season_id']}] {season['name']}")
            
            # Count team members
            member_counts = await connection.fetch(
                'SELECT t.name as team_name, COUNT(tm.user_id) as member_count '
                'FROM "Teams" t '
                'LEFT JOIN "TeamMembers" tm ON t.team_id = tm.team_id '
                'GROUP BY t.team_id, t.name '
                'ORDER BY t.team_id'
            )
            print(f"\n📊 Team Members:")
            for row in member_counts:
                print(f"   {row['team_name']:30} : {row['member_count']} members")
            
            print("\n" + "-" * 70)
            
        await pool.close()
        
        print("\n" + "="*70)
        print("✅ SEED DATA LOADED SUCCESSFULLY")
        print("="*70)
        print("\n📝 Summary:")
        print(f"   • 1 Admin user (league_admin)")
        print(f"   • 2 Leagues (South East, North West)")
        print(f"   • 6 Teams (3 per league)")
        print(f"   • 6 Coaches (1 per team)")
        print(f"   • 18 Players (3 per team)")
        print(f"   • 2 Seasons (2025/26 for each league)")
        print(f"   • All teams assigned to seasons")
        print(f"   • All members assigned to teams\n")
        
        print("🔐 Test Login Credentials:")
        print("   Admin:   league_admin / AdminPass123")
        print("   Coach:   sarah_johnson / AdminPass123")
        print("   Player:  emma_davies / AdminPass123")
        print("   (All users use password: AdminPass123)\n")
        
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
    success = await run_seed_data()
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
