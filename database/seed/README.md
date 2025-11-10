# Database Seed Data (DEV_STAGES 1.2a)

This directory contains seed data scripts for populating the VolleyLeague database with realistic test data.

## 📁 Files

- **`seed_data.sql`** - Raw SQL script with all seed data
- **`run_seed.py`** - Python script to execute seeding with verification
- **`cleanup_seed.py`** - Python script to remove all seed data

## 🌱 Seed Data Contents

### Users (25 total)
- **1 Admin**: League administrator (owns both leagues)
- **6 Coaches**: One per team
- **18 Players**: Three per team (54 players for a full roster would be realistic, but using 3 for testing)

### Leagues (2)
- **South East Division**: Covering Buckinghamshire, Oxfordshire, Thames Valley
- **North West Division**: Covering Greater Manchester, Merseyside, Lancashire

### Teams (6 total, 3 per league)

**South East Division:**
1. South Bucks Volleyball Club
   - Coach: Sarah Johnson
   - Players: Emma Davies (#7), Olivia Smith (#12), Sophie Brown (#15)

2. Wycombe Eagles VC
   - Coach: Mike Thompson
   - Players: James Wilson (#8), Liam Taylor (#11), Noah Jones (#14)

3. Thames Titans VC
   - Coach: Lisa Anderson
   - Players: Ava Martin (#9), Mia White (#10), Isabella Harris (#13)

**North West Division:**
4. Manchester Meteors VC
   - Coach: David Roberts
   - Players: Ethan Clark (#5), Lucas Lewis (#16), Mason Walker (#18)

5. Liverpool Lightning VC
   - Coach: Rachel Green
   - Players: Charlotte Hall (#6), Amelia Allen (#17), Harper Young (#19)

6. Preston Panthers VC
   - Coach: Tom Baker
   - Players: William King (#3), Benjamin Scott (#4), Alexander Hill (#20)

### Seasons (2)
- **2025/26 Season** for South East Division (Sep 1, 2025 - May 31, 2026)
- **2025/26 Season** for North West Division (Sep 1, 2025 - May 31, 2026)

### Assignments
- All 6 teams are assigned to their respective league seasons
- All coaches and players are assigned to their teams with jersey numbers

## 🚀 Usage

### Running the Seed Script

```bash
# From project root
python3 database/seed/run_seed.py
```

**Expected Output:**
```
======================================================================
🌱 VOLLEYLEAGUE DATABASE SEED (DEV_STAGES 1.2a)
======================================================================

📖 Reading SQL file: seed_data.sql
🔌 Connecting to PostgreSQL database...
   Host: localhost:5432
   Database: antonidebicki
   User: postgres

✅ Connected to database

🚀 Executing seed data script...
----------------------------------------------------------------------
----------------------------------------------------------------------
✅ Seed data executed successfully

🔍 Verifying data insertion...
----------------------------------------------------------------------

📊 Users by Role:
   ADMIN    : 1 users
   COACH    : 6 users
   PLAYER   : 18 users

📊 Leagues: 2
   [1] South East Division
   [2] North West Division

📊 Teams per League:
   South East Division       : 3 teams
   North West Division       : 3 teams

📊 Seasons: 2
   [1] 2025/26 Season
   [2] 2025/26 Season

📊 Team Members:
   South Bucks Volleyball Club    : 4 members
   Wycombe Eagles VC              : 4 members
   Thames Titans VC               : 4 members
   Manchester Meteors VC          : 4 members
   Liverpool Lightning VC         : 4 members
   Preston Panthers VC            : 4 members

----------------------------------------------------------------------

======================================================================
✅ SEED DATA LOADED SUCCESSFULLY
======================================================================

📝 Summary:
   • 1 Admin user (league_admin)
   • 2 Leagues (South East, North West)
   • 6 Teams (3 per league)
   • 6 Coaches (1 per team)
   • 18 Players (3 per team)
   • 2 Seasons (2025/26 for each league)
   • All teams assigned to seasons
   • All members assigned to teams

🔐 Test Login Credentials:
   Admin:   league_admin / AdminPass123
   Coach:   sarah_johnson / AdminPass123
   Player:  emma_davies / AdminPass123
   (All users use password: AdminPass123)
```

### Cleaning Up Seed Data

```bash
# From project root (will prompt for confirmation)
python3 database/seed/cleanup_seed.py

# Skip confirmation prompt
python3 database/seed/cleanup_seed.py --confirm
```

**What it removes:**
- All seed users (25 users: 1 admin, 6 coaches, 18 players)
- All leagues (2)
- All teams (6)
- All seasons (2)
- All team memberships
- All season team assignments
- Any related data (matches, standings, etc.)

### Manual SQL Execution (Alternative)

If you prefer to use psql directly:

```bash
# Run seed
psql -U postgres -d antonidebicki -f database/seed/seed_data.sql

# Verify data
psql -U postgres -d antonidebicki -c "SELECT role, COUNT(*) FROM \"Users\" GROUP BY role;"
```

## 🔐 Test Credentials

All seed users use the same password for easy testing: **AdminPass123**

**Example Logins:**

| Role | Username | Email | Full Name |
|------|----------|-------|-----------|
| ADMIN | league_admin | admin@volleyleague.com | League Administrator |
| COACH | sarah_johnson | sarah.j@southbucks.vc | Sarah Johnson |
| COACH | mike_thompson | mike.t@wycombeagles.vc | Mike Thompson |
| PLAYER | emma_davies | emma.d@southbucks.vc | Emma Davies |
| PLAYER | james_wilson | james.w@wycombeagles.vc | James Wilson |

## 🧪 Testing with Seed Data

### Test Login as Different Roles

```bash
# Login as admin
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "league_admin", "password": "AdminPass123"}'

# Login as coach
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "sarah_johnson", "password": "AdminPass123"}'

# Login as player
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "emma_davies", "password": "AdminPass123"}'
```

### Test Protected Endpoints

```bash
# Get leagues (any authenticated user)
curl -X GET http://localhost:8000/api/leagues \
  -H "Authorization: Bearer <your_token>"

# Create league (ADMIN only)
curl -X POST http://localhost:8000/api/leagues \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test League",
    "admin_user_id": 1,
    "description": "Test description"
  }'

# Create team (COACH or ADMIN)
curl -X POST http://localhost:8000/api/teams \
  -H "Authorization: Bearer <coach_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Team",
    "created_by_user_id": 2
  }'
```

## 📊 Database Verification Queries

After seeding, you can run these queries to verify data:

```sql
-- Count users by role
SELECT role, COUNT(*) as count 
FROM "Users" 
GROUP BY role 
ORDER BY role;

-- List leagues with admin
SELECT l.name as league_name, u.full_name as admin_name
FROM "Leagues" l
JOIN "Users" u ON l.admin_user_id = u.user_id;

-- List teams with coach
SELECT t.name as team_name, u.full_name as coach_name
FROM "Teams" t
JOIN "Users" u ON t.created_by_user_id = u.user_id;

-- Count teams per season
SELECT s.name as season_name, l.name as league_name, COUNT(st.team_id) as team_count
FROM "Seasons" s
JOIN "Leagues" l ON s.league_id = l.league_id
LEFT JOIN "SeasonTeams" st ON s.season_id = st.season_id
GROUP BY s.season_id, s.name, l.name;

-- List all team members with jersey numbers
SELECT 
    t.name as team_name,
    u.full_name as member_name,
    tm.role as team_role,
    tm.jersey_number
FROM "TeamMembers" tm
JOIN "Teams" t ON tm.team_id = t.team_id
JOIN "Users" u ON tm.user_id = u.user_id
ORDER BY t.team_id, tm.role, u.full_name;
```

## 🔄 Re-seeding

If you need to re-seed the database:

```bash
# 1. Clean up existing seed data
python3 database/seed/cleanup_seed.py --confirm

# 2. Run seed script again
python3 database/seed/run_seed.py
```

## ⚠️ Important Notes

1. **Idempotent**: The seed script uses `ON CONFLICT DO NOTHING` clauses, so it won't error if data already exists
2. **Password Security**: All users use the same password for testing (`AdminPass123`). **Never use in production!**
3. **Foreign Keys**: The cleanup script deletes data in the correct order to respect foreign key constraints
4. **Test Data**: This is realistic test data for development. You'll need real data for production

## 🎯 Next Steps (DEV_STAGES)

After seeding:
- ✅ **1.2a Complete**: Database populated with test data
- ⏭️ **1.2b**: Create fixture generator for matches
- ⏭️ **1.2c-f**: Implement round-robin algorithm and match scheduling

## 📝 Data Structure Summary

```
Admin (1)
  └── Leagues (2)
        ├── South East Division
        │     ├── Season: 2025/26
        │     └── Teams (3)
        │           ├── South Bucks VC (Coach: Sarah + 3 players)
        │           ├── Wycombe Eagles VC (Coach: Mike + 3 players)
        │           └── Thames Titans VC (Coach: Lisa + 3 players)
        │
        └── North West Division
              ├── Season: 2025/26
              └── Teams (3)
                    ├── Manchester Meteors VC (Coach: David + 3 players)
                    ├── Liverpool Lightning VC (Coach: Rachel + 3 players)
                    └── Preston Panthers VC (Coach: Tom + 3 players)
```
