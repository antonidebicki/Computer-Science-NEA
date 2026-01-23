-- ============================================================================
-- SEED DATA for VolleyLeague (DEV_STAGES 1.2b - Expanded)
-- ============================================================================
-- This script populates the database with realistic test data:
-- - 1 Admin user (owns leagues)
-- - 2 Leagues (South East Division, North West Division)
-- - 12 Teams (6 per league)
-- - 12 Coaches (1 per team)
-- - 60 Players (5 per team)
-- - 2 Current seasons (2025/26 Season for each league)
-- - Full round-robin fixture schedule for each league
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
DELETE FROM "Users" WHERE username LIKE '%_coach_%' OR username LIKE '%_player_%' OR username IN (
    'league_admin',
    'sarah_johnson', 'emma_davies', 'olivia_smith', 'sophie_brown', 'grace_cooper', 'natalie_phillips',
    'mike_thompson', 'james_wilson', 'liam_taylor', 'noah_jones', 'jackson_mitchell', 'logan_perez',
    'lisa_anderson', 'ava_martin', 'mia_white', 'isabella_harris', 'evelyn_rodriguez', 'abigail_carter',
    'david_roberts', 'ethan_clark', 'lucas_lewis', 'mason_walker', 'aiden_turner', 'oliver_phillips',
    'rachel_green', 'charlotte_hall', 'amelia_allen', 'harper_young', 'ella_adams', 'chloe_nelson',
    'tom_baker', 'william_king', 'benjamin_scott', 'alexander_hill', 'henry_jackson', 'samuel_jenkins'
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
-- SOUTH EAST DIVISION - Teams and Members (6 Teams)
-- ============================================================================

-- Team 1: South Bucks Volleyball Club
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('sarah_johnson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'sarah.j@southbucks.vc', 'Sarah Johnson', 'COACH', NOW()),
    -- Players
    ('emma_davies', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'emma.d@southbucks.vc', 'Emma Davies', 'PLAYER', NOW()),
    ('olivia_smith', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'olivia.s@southbucks.vc', 'Olivia Smith', 'PLAYER', NOW()),
    ('sophie_brown', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'sophie.b@southbucks.vc', 'Sophie Brown', 'PLAYER', NOW()),
    ('grace_cooper', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'grace.c@southbucks.vc', 'Grace Cooper', 'PLAYER', NOW()),
    ('natalie_phillips', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'natalie.p@southbucks.vc', 'Natalie Phillips', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 2: Wycombe Eagles VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('mike_thompson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mike.t@wycombeagles.vc', 'Mike Thompson', 'COACH', NOW()),
    -- Players
    ('james_wilson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'james.w@wycombeagles.vc', 'James Wilson', 'PLAYER', NOW()),
    ('liam_taylor', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'liam.t@wycombeagles.vc', 'Liam Taylor', 'PLAYER', NOW()),
    ('noah_jones', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'noah.j@wycombeagles.vc', 'Noah Jones', 'PLAYER', NOW()),
    ('jackson_mitchell', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'jackson.m@wycombeagles.vc', 'Jackson Mitchell', 'PLAYER', NOW()),
    ('logan_perez', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'logan.p@wycombeagles.vc', 'Logan Perez', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 3: Thames Titans VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('lisa_anderson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'lisa.a@thamestitans.vc', 'Lisa Anderson', 'COACH', NOW()),
    -- Players
    ('ava_martin', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'ava.m@thamestitans.vc', 'Ava Martin', 'PLAYER', NOW()),
    ('mia_white', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mia.w@thamestitans.vc', 'Mia White', 'PLAYER', NOW()),
    ('isabella_harris', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'isabella.h@thamestitans.vc', 'Isabella Harris', 'PLAYER', NOW()),
    ('evelyn_rodriguez', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'evelyn.r@thamestitans.vc', 'Evelyn Rodriguez', 'PLAYER', NOW()),
    ('abigail_carter', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'abigail.c@thamestitans.vc', 'Abigail Carter', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 4: Oxford Octopi VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_oxford', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@oxfordoctopi.vc', 'James Davies', 'COACH', NOW()),
    -- Players
    ('player_oxford_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@oxfordoctopi.vc', 'Sophie Wilson', 'PLAYER', NOW()),
    ('player_oxford_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@oxfordoctopi.vc', 'Victoria Brown', 'PLAYER', NOW()),
    ('player_oxford_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@oxfordoctopi.vc', 'Emma Stone', 'PLAYER', NOW()),
    ('player_oxford_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@oxfordoctopi.vc', 'Lily Turner', 'PLAYER', NOW()),
    ('player_oxford_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@oxfordoctopi.vc', 'Amy Foster', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 5: Reading Rockets VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_reading', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@readingrockets.vc', 'Mark Jensen', 'COACH', NOW()),
    -- Players
    ('player_reading_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@readingrockets.vc', 'Jessica Lane', 'PLAYER', NOW()),
    ('player_reading_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@readingrockets.vc', 'Katie Price', 'PLAYER', NOW()),
    ('player_reading_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@readingrockets.vc', 'Hannah Morgan', 'PLAYER', NOW()),
    ('player_reading_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@readingrockets.vc', 'Lauren Blake', 'PLAYER', NOW()),
    ('player_reading_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@readingrockets.vc', 'Natasha Hart', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 6: Brighton Bolts VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_brighton', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@brightonbolts.vc', 'Steven Grey', 'COACH', NOW()),
    -- Players
    ('player_brighton_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@brightonbolts.vc', 'Rachel Webb', 'PLAYER', NOW()),
    ('player_brighton_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@brightonbolts.vc', 'Samantha Rose', 'PLAYER', NOW()),
    ('player_brighton_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@brightonbolts.vc', 'Maria Stone', 'PLAYER', NOW()),
    ('player_brighton_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@brightonbolts.vc', 'Sophia Davis', 'PLAYER', NOW()),
    ('player_brighton_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@brightonbolts.vc', 'Maya Evans', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- NORTH WEST DIVISION - Teams and Members (6 Teams)
-- ============================================================================

-- Team 4: Manchester Meteors VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('david_roberts', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'david.r@manchestermeteors.vc', 'David Roberts', 'COACH', NOW()),
    -- Players
    ('ethan_clark', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'ethan.c@manchestermeteors.vc', 'Ethan Clark', 'PLAYER', NOW()),
    ('lucas_lewis', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'lucas.l@manchestermeteors.vc', 'Lucas Lewis', 'PLAYER', NOW()),
    ('mason_walker', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'mason.w@manchestermeteors.vc', 'Mason Walker', 'PLAYER', NOW()),
    ('aiden_turner', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'aiden.t@manchestermeteors.vc', 'Aiden Turner', 'PLAYER', NOW()),
    ('oliver_phillips', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'oliver.p@manchestermeteors.vc', 'Oliver Phillips', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 5: Liverpool Lightning VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('rachel_green', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'rachel.g@liverpoollightning.vc', 'Rachel Green', 'COACH', NOW()),
    -- Players
    ('charlotte_hall', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'charlotte.h@liverpoollightning.vc', 'Charlotte Hall', 'PLAYER', NOW()),
    ('amelia_allen', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'amelia.a@liverpoollightning.vc', 'Amelia Allen', 'PLAYER', NOW()),
    ('harper_young', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'harper.y@liverpoollightning.vc', 'Harper Young', 'PLAYER', NOW()),
    ('ella_adams', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'ella.a@liverpoollightning.vc', 'Ella Adams', 'PLAYER', NOW()),
    ('chloe_nelson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'chloe.n@liverpoollightning.vc', 'Chloe Nelson', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 6: Preston Panthers VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('tom_baker', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'tom.b@prestonpanthers.vc', 'Tom Baker', 'COACH', NOW()),
    -- Players
    ('william_king', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'william.k@prestonpanthers.vc', 'William King', 'PLAYER', NOW()),
    ('benjamin_scott', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'benjamin.s@prestonpanthers.vc', 'Benjamin Scott', 'PLAYER', NOW()),
    ('alexander_hill', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'alexander.h@prestonpanthers.vc', 'Alexander Hill', 'PLAYER', NOW()),
    ('henry_jackson', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'henry.j@prestonpanthers.vc', 'Henry Jackson', 'PLAYER', NOW()),
    ('samuel_jenkins', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'samuel.j@prestonpanthers.vc', 'Samuel Jenkins', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 7: Leeds Legends VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_leeds', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@leedslegends.vc', 'Paul Turner', 'COACH', NOW()),
    -- Players
    ('player_leeds_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@leedslegends.vc', 'George Wright', 'PLAYER', NOW()),
    ('player_leeds_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@leedslegends.vc', 'Thomas Hughes', 'PLAYER', NOW()),
    ('player_leeds_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@leedslegends.vc', 'Daniel Morris', 'PLAYER', NOW()),
    ('player_leeds_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@leedslegends.vc', 'Charles Rice', 'PLAYER', NOW()),
    ('player_leeds_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@leedslegends.vc', 'Joseph Sanders', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 8: Sheffield Stars VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_sheffield', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@sheffieldstars.vc', 'Robert Hall', 'COACH', NOW()),
    -- Players
    ('player_sheffield_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@sheffieldstars.vc', 'Michael Bennett', 'PLAYER', NOW()),
    ('player_sheffield_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@sheffieldstars.vc', 'Kevin Powell', 'PLAYER', NOW()),
    ('player_sheffield_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@sheffieldstars.vc', 'Brian Long', 'PLAYER', NOW()),
    ('player_sheffield_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@sheffieldstars.vc', 'Edward Patterson', 'PLAYER', NOW()),
    ('player_sheffield_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@sheffieldstars.vc', 'Anthony Hughes', 'PLAYER', NOW())
ON CONFLICT (username) DO NOTHING;

-- Team 9: Salford Strikers VC
INSERT INTO "Users" (username, hashed_password, email, full_name, role, created_at)
VALUES 
    -- Coach
    ('coach_salford', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'coach@salfordstrikers.vc', 'Andrew Murphy', 'COACH', NOW()),
    -- Players
    ('player_salford_1', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p1@salfordstrikers.vc', 'Christopher Hill', 'PLAYER', NOW()),
    ('player_salford_2', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p2@salfordstrikers.vc', 'Steven Chapman', 'PLAYER', NOW()),
    ('player_salford_3', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p3@salfordstrikers.vc', 'Richard Richards', 'PLAYER', NOW()),
    ('player_salford_4', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p4@salfordstrikers.vc', 'Jeffrey Greene', 'PLAYER', NOW()),
    ('player_salford_5', '$2b$12$bU7lE0y/kMRBQjEOez4LF.q2tKu0QPnjqKKgVf7VzPu1AfILRqNMa', 'p5@salfordstrikers.vc', 'Paul Henderson', 'PLAYER', NOW())
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
-- 3. TEAMS (12 teams total - 6 per league)
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
    ),
    (
        'Oxford Octopi VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_oxford'),
        'https://example.com/logos/oxfordoctopi.png',
        NOW()
    ),
    (
        'Reading Rockets VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_reading'),
        'https://example.com/logos/readingrockets.png',
        NOW()
    ),
    (
        'Brighton Bolts VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_brighton'),
        'https://example.com/logos/brightonbolts.png',
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
    ),
    (
        'Leeds Legends VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_leeds'),
        'https://example.com/logos/leedslegends.png',
        NOW()
    ),
    (
        'Sheffield Stars VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_sheffield'),
        'https://example.com/logos/sheffieldstars.png',
        NOW()
    ),
    (
        'Salford Strikers VC',
        (SELECT user_id FROM "Users" WHERE username = 'coach_salford'),
        'https://example.com/logos/salfordstrikers.png',
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
-- 5. SEASON TEAMS (Assign all 6 teams to their respective seasons)
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
  AND t.name IN ('South Bucks Volleyball Club', 'Wycombe Eagles VC', 'Thames Titans VC', 'Oxford Octopi VC', 'Reading Rockets VC', 'Brighton Bolts VC')
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
  AND t.name IN ('Manchester Meteors VC', 'Liverpool Lightning VC', 'Preston Panthers VC', 'Leeds Legends VC', 'Sheffield Stars VC', 'Salford Strikers VC')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. TEAM MEMBERS (Assign coaches and players to all 12 teams)
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
        WHEN u.username = 'grace_cooper' THEN 18
        WHEN u.username = 'natalie_phillips' THEN 21
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'South Bucks Volleyball Club'
  AND u.username IN ('sarah_johnson', 'emma_davies', 'olivia_smith', 'sophie_brown', 'grace_cooper', 'natalie_phillips')
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
        WHEN u.username = 'jackson_mitchell' THEN 17
        WHEN u.username = 'logan_perez' THEN 22
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Wycombe Eagles VC'
  AND u.username IN ('mike_thompson', 'james_wilson', 'liam_taylor', 'noah_jones', 'jackson_mitchell', 'logan_perez')
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
        WHEN u.username = 'evelyn_rodriguez' THEN 16
        WHEN u.username = 'abigail_carter' THEN 19
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Thames Titans VC'
  AND u.username IN ('lisa_anderson', 'ava_martin', 'mia_white', 'isabella_harris', 'evelyn_rodriguez', 'abigail_carter')
ON CONFLICT DO NOTHING;

-- Oxford Octopi VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_oxford_1' THEN 1
        WHEN u.username = 'player_oxford_2' THEN 2
        WHEN u.username = 'player_oxford_3' THEN 3
        WHEN u.username = 'player_oxford_4' THEN 4
        WHEN u.username = 'player_oxford_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Oxford Octopi VC'
  AND u.username IN ('coach_oxford', 'player_oxford_1', 'player_oxford_2', 'player_oxford_3', 'player_oxford_4', 'player_oxford_5')
ON CONFLICT DO NOTHING;

-- Reading Rockets VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_reading_1' THEN 1
        WHEN u.username = 'player_reading_2' THEN 2
        WHEN u.username = 'player_reading_3' THEN 3
        WHEN u.username = 'player_reading_4' THEN 4
        WHEN u.username = 'player_reading_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Reading Rockets VC'
  AND u.username IN ('coach_reading', 'player_reading_1', 'player_reading_2', 'player_reading_3', 'player_reading_4', 'player_reading_5')
ON CONFLICT DO NOTHING;

-- Brighton Bolts VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_brighton_1' THEN 1
        WHEN u.username = 'player_brighton_2' THEN 2
        WHEN u.username = 'player_brighton_3' THEN 3
        WHEN u.username = 'player_brighton_4' THEN 4
        WHEN u.username = 'player_brighton_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Brighton Bolts VC'
  AND u.username IN ('coach_brighton', 'player_brighton_1', 'player_brighton_2', 'player_brighton_3', 'player_brighton_4', 'player_brighton_5')
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
        WHEN u.username = 'aiden_turner' THEN 20
        WHEN u.username = 'oliver_phillips' THEN 23
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Manchester Meteors VC'
  AND u.username IN ('david_roberts', 'ethan_clark', 'lucas_lewis', 'mason_walker', 'aiden_turner', 'oliver_phillips')
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
        WHEN u.username = 'ella_adams' THEN 24
        WHEN u.username = 'chloe_nelson' THEN 25
        WHEN u.username = 'emma_davies' THEN 28
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Liverpool Lightning VC'
  AND u.username IN ('rachel_green', 'charlotte_hall', 'amelia_allen', 'harper_young', 'ella_adams', 'chloe_nelson', 'emma_davies')
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
        WHEN u.username = 'henry_jackson' THEN 26
        WHEN u.username = 'samuel_jenkins' THEN 27
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Preston Panthers VC'
  AND u.username IN ('tom_baker', 'william_king', 'benjamin_scott', 'alexander_hill', 'henry_jackson', 'samuel_jenkins')
ON CONFLICT DO NOTHING;

-- Leeds Legends VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_leeds_1' THEN 1
        WHEN u.username = 'player_leeds_2' THEN 2
        WHEN u.username = 'player_leeds_3' THEN 3
        WHEN u.username = 'player_leeds_4' THEN 4
        WHEN u.username = 'player_leeds_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Leeds Legends VC'
  AND u.username IN ('coach_leeds', 'player_leeds_1', 'player_leeds_2', 'player_leeds_3', 'player_leeds_4', 'player_leeds_5')
ON CONFLICT DO NOTHING;

-- Sheffield Stars VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_sheffield_1' THEN 1
        WHEN u.username = 'player_sheffield_2' THEN 2
        WHEN u.username = 'player_sheffield_3' THEN 3
        WHEN u.username = 'player_sheffield_4' THEN 4
        WHEN u.username = 'player_sheffield_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Sheffield Stars VC'
  AND u.username IN ('coach_sheffield', 'player_sheffield_1', 'player_sheffield_2', 'player_sheffield_3', 'player_sheffield_4', 'player_sheffield_5')
ON CONFLICT DO NOTHING;

-- Salford Strikers VC
INSERT INTO "TeamMembers" (team_id, user_id, role_in_team, player_number)
SELECT 
    t.team_id,
    u.user_id,
    CASE 
        WHEN u.role = 'COACH' THEN 'Coach'
        ELSE 'Player'
    END,
    CASE 
        WHEN u.username = 'player_salford_1' THEN 1
        WHEN u.username = 'player_salford_2' THEN 2
        WHEN u.username = 'player_salford_3' THEN 3
        WHEN u.username = 'player_salford_4' THEN 4
        WHEN u.username = 'player_salford_5' THEN 5
        ELSE NULL
    END
FROM "Teams" t
CROSS JOIN "Users" u
WHERE t.name = 'Salford Strikers VC'
  AND u.username IN ('coach_salford', 'player_salford_1', 'player_salford_2', 'player_salford_3', 'player_salford_4', 'player_salford_5')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. SCHEDULED MATCHES (Full round-robin fixtures for 6 teams per league)
-- Each league has 15 matches (6 teams × 5 opponents ÷ 2)
-- ============================================================================

-- South East Division Matches (15 matches total)
-- South Bucks vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club'),
 (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC'),
 '2026-02-10 19:00:00'::timestamp, 'South Bucks Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club'),
 (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC'),
 '2026-02-12 19:00:00'::timestamp, 'South Bucks Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club'),
 (SELECT team_id FROM "Teams" WHERE name = 'Oxford Octopi VC'),
 '2026-02-14 19:00:00'::timestamp, 'South Bucks Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club'),
 (SELECT team_id FROM "Teams" WHERE name = 'Reading Rockets VC'),
 '2026-02-16 19:00:00'::timestamp, 'South Bucks Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'South Bucks Volleyball Club'),
 (SELECT team_id FROM "Teams" WHERE name = 'Brighton Bolts VC'),
 '2026-02-18 19:00:00'::timestamp, 'South Bucks Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Wycombe Eagles vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC'),
 '2026-02-11 19:00:00'::timestamp, 'Wycombe Sports Hall', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Oxford Octopi VC'),
 '2026-02-13 19:00:00'::timestamp, 'Wycombe Sports Hall', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Reading Rockets VC'),
 '2026-02-15 19:00:00'::timestamp, 'Wycombe Sports Hall', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Wycombe Eagles VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Brighton Bolts VC'),
 '2026-02-17 19:00:00'::timestamp, 'Wycombe Sports Hall', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Thames Titans vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Oxford Octopi VC'),
 '2026-02-10 20:00:00'::timestamp, 'Thames Valley Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Reading Rockets VC'),
 '2026-02-12 20:00:00'::timestamp, 'Thames Valley Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Thames Titans VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Brighton Bolts VC'),
 '2026-02-14 20:00:00'::timestamp, 'Thames Valley Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Oxford Octopi vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Oxford Octopi VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Reading Rockets VC'),
 '2026-02-11 20:00:00'::timestamp, 'Oxford University Sports Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Oxford Octopi VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Brighton Bolts VC'),
 '2026-02-13 20:00:00'::timestamp, 'Oxford University Sports Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Reading Rockets vs Brighton Bolts
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Reading Rockets VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Brighton Bolts VC'),
 '2026-02-10 20:30:00'::timestamp, 'Reading Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- North West Division Matches (15 matches total)
-- Manchester Meteors vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC'),
 '2026-02-10 19:00:00'::timestamp, 'Manchester Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC'),
 '2026-02-12 19:00:00'::timestamp, 'Manchester Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Leeds Legends VC'),
 '2026-02-14 19:00:00'::timestamp, 'Manchester Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Sheffield Stars VC'),
 '2026-02-16 19:00:00'::timestamp, 'Manchester Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Manchester Meteors VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Salford Strikers VC'),
 '2026-02-18 19:00:00'::timestamp, 'Manchester Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Liverpool Lightning vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC'),
 '2026-02-11 19:00:00'::timestamp, 'Liverpool Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Leeds Legends VC'),
 '2026-02-13 19:00:00'::timestamp, 'Liverpool Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Sheffield Stars VC'),
 '2026-02-15 19:00:00'::timestamp, 'Liverpool Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Liverpool Lightning VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Salford Strikers VC'),
 '2026-02-17 19:00:00'::timestamp, 'Liverpool Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Preston Panthers vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Leeds Legends VC'),
 '2026-02-10 20:00:00'::timestamp, 'Preston Leisure Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Sheffield Stars VC'),
 '2026-02-12 20:00:00'::timestamp, 'Preston Leisure Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Preston Panthers VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Salford Strikers VC'),
 '2026-02-14 20:00:00'::timestamp, 'Preston Leisure Center', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Leeds Legends vs others
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Leeds Legends VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Sheffield Stars VC'),
 '2026-02-11 20:00:00'::timestamp, 'Leeds Sports Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Leeds Legends VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Salford Strikers VC'),
 '2026-02-13 20:00:00'::timestamp, 'Leeds Sports Arena', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- Sheffield Stars vs Salford Strikers
INSERT INTO "Matches" (season_id, home_team_id, away_team_id, match_datetime, venue, status) VALUES
((SELECT season_id FROM "Seasons" WHERE name = '2025/26 Season' AND league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')),
 (SELECT team_id FROM "Teams" WHERE name = 'Sheffield Stars VC'),
 (SELECT team_id FROM "Teams" WHERE name = 'Salford Strikers VC'),
 '2026-02-10 20:30:00'::timestamp, 'Sheffield Sports Complex', 'SCHEDULED') ON CONFLICT DO NOTHING;

-- ============================================================================
-- 9. INITIALIZE LEAGUE STANDINGS FOR ALL SEASONS
-- ============================================================================

-- Initialize standings for South East Division 2025/26 Season
INSERT INTO "LeagueStandings" (season_id, team_id, matches_played, wins, losses, sets_won, sets_lost, points_won, points_lost, league_points)
SELECT 
    s.season_id,
    st.team_id,
    0, 0, 0, 0, 0, 0, 0, 0
FROM "Seasons" s
JOIN "SeasonTeams" st ON s.season_id = st.season_id
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'South East Division')
ON CONFLICT (season_id, team_id) DO NOTHING;

-- Initialize standings for North West Division 2025/26 Season
INSERT INTO "LeagueStandings" (season_id, team_id, matches_played, wins, losses, sets_won, sets_lost, points_won, points_lost, league_points)
SELECT 
    s.season_id,
    st.team_id,
    0, 0, 0, 0, 0, 0, 0, 0
FROM "Seasons" s
JOIN "SeasonTeams" st ON s.season_id = st.season_id
WHERE s.name = '2025/26 Season'
  AND s.league_id = (SELECT league_id FROM "Leagues" WHERE name = 'North West Division')
ON CONFLICT (season_id, team_id) DO NOTHING;

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
