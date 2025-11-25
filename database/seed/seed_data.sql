-- ============================================================================
-- SEED DATA for VolleyLeague (DEV_STAGES 1.2a)
-- ============================================================================
-- This script populates the database with realistic test data:
-- - 1 Admin user (owns leagues)
-- - 2 Leagues (South East Division, North West Division)
-- - 6 Teams (3 per league)
-- - 6 Coaches (1 per team)
-- - 18 Players (3 per team)
-- - 2 Current seasons (2025/26 Season for each league)
-- - Team assignments to seasons
-- ============================================================================

BEGIN;

-- ============================================================================
-- CLEANUP: Remove existing seed data to prevent duplicates
-- ============================================================================

-- Delete in correct order to respect foreign key constraints
DELETE FROM "Sets" WHERE match_id IN (SELECT match_id FROM "Matches");
DELETE FROM "Matches";
DELETE FROM "LeagueStandings";
DELETE FROM "ArchivedStandings";
DELETE FROM "SeasonTeams";
DELETE FROM "TeamMembers";
DELETE FROM "Seasons";
DELETE FROM "Teams";
DELETE FROM "Leagues";
DELETE FROM "Users" WHERE username IN (
    'league_admin',
    'sarah_johnson', 'emma_davies', 'olivia_smith', 'sophie_brown',
    'mike_thompson', 'james_wilson', 'liam_taylor', 'noah_jones',
    'lisa_anderson', 'ava_martin', 'mia_white', 'isabella_harris',
    'david_roberts', 'ethan_clark', 'lucas_lewis', 'mason_walker',
    'rachel_green', 'charlotte_hall', 'amelia_allen', 'harper_young',
    'tom_baker', 'william_king', 'benjamin_scott', 'alexander_green'
);

-- ============================================================================
-- 1. USERS (Admin, Coaches, Players)
-- ============================================================================

-- Admin User (owns both leagues)
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES (
    'league_admin',
    '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', -- password: AdminPass123
    'admin@volleyleague.com',
    'League Administrator',
    'ADMIN',
    NOW()
) ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- SOUTH EAST DIVISION - Teams and Members
-- ============================================================================

-- Team 1: South Bucks Volleyball Club
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('sarah_johnson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'sarah.j@southbucks.vc', 'Sarah Johnson', 'COACH', NOW()),
    -- Players
    ('emma_davies', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'emma.d@southbucks.vc', 'Emma Davies', 'PLAYER', NOW()),
    ('olivia_smith', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'olivia.s@southbucks.vc', 'Olivia Smith', 'PLAYER', NOW()),
    ('sophie_brown', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'sophie.b@southbucks.vc', 'Sophie Brown', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 2: Wycombe Eagles VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('mike_thompson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mike.t@wycombeagles.vc', 'Mike Thompson', 'COACH', NOW()),
    -- Players
    ('james_wilson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'james.w@wycombeagles.vc', 'James Wilson', 'PLAYER', NOW()),
    ('liam_taylor', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'liam.t@wycombeagles.vc', 'Liam Taylor', 'PLAYER', NOW()),
    ('noah_jones', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'noah.j@wycombeagles.vc', 'Noah Jones', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 3: Thames Titans VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('lisa_anderson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'lisa.a@thamestitans.vc', 'Lisa Anderson', 'COACH', NOW()),
    -- Players
    ('ava_martin', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'ava.m@thamestitans.vc', 'Ava Martin', 'PLAYER', NOW()),
    ('mia_white', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mia.w@thamestitans.vc', 'Mia White', 'PLAYER', NOW()),
    ('isabella_harris', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'isabella.h@thamestitans.vc', 'Isabella Harris', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- NORTH WEST DIVISION - Teams and Members
-- ============================================================================

-- Team 4: Manchester Meteors VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('david_roberts', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'david.r@manchestermeteors.vc', 'David Roberts', 'COACH', NOW()),
    -- Players
    ('ethan_clark', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'ethan.c@manchestermeteors.vc', 'Ethan Clark', 'PLAYER', NOW()),
    ('lucas_lewis', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'lucas.l@manchestermeteors.vc', 'Lucas Lewis', 'PLAYER', NOW()),
    ('mason_walker', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mason.w@manchestermeteors.vc', 'Mason Walker', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 5: Liverpool Lightning VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('rachel_green', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'rachel.g@liverpoollightning.vc', 'Rachel Green', 'COACH', NOW()),
    -- Players
    ('charlotte_hall', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'charlotte.h@liverpoollightning.vc', 'Charlotte Hall', 'PLAYER', NOW()),
    ('amelia_allen', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'amelia.a@liverpoollightning.vc', 'Amelia Allen', 'PLAYER', NOW()),
    ('harper_young', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'harper.y@liverpoollightning.vc', 'Harper Young', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 6: Preston Panthers VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('tom_baker', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'tom.b@prestonpanthers.vc', 'Tom Baker', 'COACH', NOW()),
    -- Players
    ('william_king', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'william.k@prestonpanthers.vc', 'William King', 'PLAYER', NOW()),
    ('benjamin_scott', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'benjamin.s@prestonpanthers.vc', 'Benjamin Scott', 'PLAYER', NOW()),
    ('alexander_hill', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'alexander.h@prestonpanthers.vc', 'Alexander Hill', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- 2. LEAGUES
-- ============================================================================

INSERT INTO "Leagues" (name, admin_user_id, description, rules, created_at)
VALUES 
    (
        'South East Division',
        (SELECT user_id FROM "Users" WHERE username = 'league_admin'),
        'Premier volleyball league covering South East England, featuring top clubs from Buckinghamshire, Oxfordshire, and Thames Valley regions.',
        'Standard FIVB rules apply. Best of 5 sets format. 2 timeouts per team per set. 6 substitutions per set.',
        NOW()
    ),
    (
        'North West Division',
        (SELECT user_id FROM "Users" WHERE username = 'league_admin'),
        'Premier volleyball league covering North West England, featuring elite clubs from Greater Manchester, Merseyside, and Lancashire.',
        'Standard FIVB rules apply. Best of 5 sets format. 2 timeouts per team per set. 6 substitutions per set.',
        NOW()
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. TEAMS
-- ============================================================================

-- South East Division Teams
INSERT INTO "Teams" (name, created_by_user_id, logo_url, created_at)
VALUES 
    (
        'South Bucks Volleyball Club',
        (SELECT user_id FROM "Users" WHERE username = 'sarah_johnson'),
        'https://example.com/logos/southbucks.png',
        NOW()
    ),
    (
        'Wycombe Eagles VC',
        (SELECT user_id FROM "Users" WHERE username = 'mike_thompson'),
        'https://example.com/logos/wycombeagles.png',
        NOW()
    ),
    (
        'Thames Titans VC',
        (SELECT user_id FROM "Users" WHERE username = 'lisa_anderson'),
        'https://example.com/logos/thamestitans.png',
        NOW()
    )
ON CONFLICT DO NOTHING;

-- North West Division Teams
INSERT INTO "Teams" (name, created_by_user_id, logo_url, created_at)
VALUES 
    (
        'Manchester Meteors VC',
        (SELECT user_id FROM "Users" WHERE username = 'david_roberts'),
        'https://example.com/logos/manchestermeteors.png',
        NOW()
    ),
    (
        'Liverpool Lightning VC',
        (SELECT user_id FROM "Users" WHERE username = 'rachel_green'),
        'https://example.com/logos/liverpoollightning.png',
        NOW()
    ),
    (
        'Preston Panthers VC',
        (SELECT user_id FROM "Users" WHERE username = 'tom_baker'),
        'https://example.com/logos/prestonpanthers.png',
        NOW()
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. SEASONS (2025/26 Season for each league)
-- ============================================================================

INSERT INTO "Seasons" (league_id, name, start_date, end_date, is_archived)
VALUES 
    (
        (SELECT league_id FROM "Leagues" WHERE name = 'South East Division'),
        '2025/26 Season',
        '2025-09-01',
        '2026-05-31',
        FALSE
    ),
    (
        (SELECT league_id FROM "Leagues" WHERE name = 'North West Division'),
        '2025/26 Season',
        '2025-09-01',
        '2026-05-31',
        FALSE
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. SEASON TEAMS (Assign teams to their respective seasons)
-- ============================================================================

-- South East Division Season Teams
INSERT INTO "SeasonTeams" (season_id, team_id, join_date)
SELECT 
    s.season_id,
    t.team_id,
    CURRENT_DATE
FROM "Seasons" s
CROSS JOIN "Teams" t
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')
  AND t.name IN ('South Bucks Volleyball Club', 'Wycombe Eagles VC', 'Thames Titans VC')
ON CONFLICT DO NOTHING;

-- North West Division Season Teams
INSERT INTO "SeasonTeams" (season_id, team_id, join_date)
SELECT 
    s.season_id,
    t.team_id,
    CURRENT_DATE
FROM "Seasons" s
CROSS JOIN "Teams" t
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')
  AND t.name IN ('Manchester Meteors VC', 'Liverpool Lightning VC', 'Preston Panthers VC')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. TEAM MEMBERS (Assign coaches and players to teams)
-- ============================================================================

-- South Bucks Volleyball Club
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'emma_davies' THEN 7
        WHEN u.username = 'olivia_smith' THEN 12
        WHEN u.username = 'sophie_brown' THEN 15
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'South Bucks Volleyball Club'
  AND u.username IN ('sarah_johnson', 'emma_davies', 'olivia_smith', 'sophie_brown')
ON CONFLICT DO NOTHING;

-- Wycombe Eagles VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'james_wilson' THEN 8
        WHEN u.username = 'liam_taylor' THEN 11
        WHEN u.username = 'noah_jones' THEN 14
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Wycombe Eagles VC'
  AND u.username IN ('mike_thompson', 'james_wilson', 'liam_taylor', 'noah_jones')
ON CONFLICT DO NOTHING;

-- Thames Titans VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'ava_martin' THEN 9
        WHEN u.username = 'mia_white' THEN 10
        WHEN u.username = 'isabella_harris' THEN 13
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Thames Titans VC'
  AND u.username IN ('lisa_anderson', 'ava_martin', 'mia_white', 'isabella_harris')
ON CONFLICT DO NOTHING;

-- Manchester Meteors VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'ethan_clark' THEN 5
        WHEN u.username = 'lucas_lewis' THEN 16
        WHEN u.username = 'mason_walker' THEN 18
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Manchester Meteors VC'
  AND u.username IN ('david_roberts', 'ethan_clark', 'lucas_lewis', 'mason_walker')
ON CONFLICT DO NOTHING;

-- Liverpool Lightning VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'charlotte_hall' THEN 6
        WHEN u.username = 'amelia_allen' THEN 17
        WHEN u.username = 'harper_young' THEN 19
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Liverpool Lightning VC'
  AND u.username IN ('rachel_green', 'charlotte_hall', 'amelia_allen', 'harper_young')
ON CONFLICT DO NOTHING;

-- Preston Panthers VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'william_king' THEN 3
        WHEN u.username = 'benjamin_scott' THEN 4
        WHEN u.username = 'alexander_hill' THEN 20
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Preston Panthers VC'
  AND u.username IN ('tom_baker', 'william_king', 'benjamin_scott', 'alexander_hill')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. SCHEDULED MATCHES (Sample matches for testing)
-- ============================================================================

-- South East Division Matches
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-10 19:00:00'::timestamp,
    'Main Arena',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')
ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-11 19:00:00'::timestamp,
    'Sports Hall',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')
ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-12 19:00:00'::timestamp,
    'Community Center',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')
ON CONFLICT DO NOTHING;

-- North West Division Matches
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-10 19:00:00'::timestamp,
    'Manchester Arena',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')
ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-11 19:00:00'::timestamp,
    'Liverpool Sports Complex',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')
ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status)
SELECT 
    s.season_id,
    t1.team_id,
    t2.team_id,
    '2025-12-12 19:00:00'::timestamp,
    'Preston Leisure Center',
    'SCHEDULED'
FROM "Seasons" s
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC') t1
CROSS JOIN (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC') t2
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run these to verify data was inserted correctly)
-- ============================================================================

-- Count users by role
SELECT role, COUNT(*) as count 
FROM "Users" 
GROUP BY role 
ORDER BY role;

-- List all leagues with admin info
SELECT l.league_id, l.name as league_name, u.full_name as admin_name
FROM "Leagues" l
JOIN "Users" u ON l.admin_user_id = u.user_id;

-- List all teams with coach info
SELECT t.team_id, t.name as team_name, u.full_name as coach_name
FROM "Teams" t
JOIN "Users" u ON t.created_by_user_id = u.user_id
ORDER BY t.team_id;

-- List all seasons
SELECT s.season_id, l.name as league_name, s.name as season_name, s.start_date, s.end_date
FROM "Seasons" s
JOIN "Leagues" l ON s.league_id = l.league_id;

-- Count teams per season
SELECT s.name as season_name, l.name as league_name, COUNT(st.team_id) as team_count
FROM "Seasons" s
JOIN "Leagues" l ON s.league_id = l.league_id
LEFT JOIN "SeasonTeams" st ON s.season_id = st.season_id
GROUP BY s.season_id, s.name, l.name;

-- List all team members with roles
SELECT 
    t.name as team_name,
    u.full_name as member_name,
    u.role as user_role,
    tm.role_in_team as team_role,
    tm.player_number
FROM "TeamMembers" tm
JOIN "Teams" t ON tm.team_id = t.team_id
JOIN "Users" u ON tm.user_id = u.user_id
ORDER BY t.team_id, tm.role_in_team, u.full_name;
