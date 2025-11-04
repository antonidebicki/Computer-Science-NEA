-- PostgreSQL schema for the VolleyLeague Application
-- This schema combines league management features with detailed, volleyball-specific match tracking.

-- Drop tables in reverse order of dependency to avoid foreign key constraint errors.
DROP TABLE IF EXISTS "Payments" CASCADE;
DROP TABLE IF EXISTS "LeagueStandings" CASCADE;
DROP TABLE IF EXISTS "Substitutions" CASCADE;
DROP TABLE IF EXISTS "Timeouts" CASCADE;
DROP TABLE IF EXISTS "Sets" CASCADE;
DROP TABLE IF EXISTS "MatchReferees" CASCADE;
DROP TABLE IF EXISTS "Matches" CASCADE;
DROP TABLE IF EXISTS "SeasonTeams" CASCADE;
DROP TABLE IF EXISTS "Seasons" CASCADE;
DROP TABLE IF EXISTS "TeamMembers" CASCADE;
DROP TABLE IF EXISTS "Leagues" CASCADE;
DROP TABLE IF EXISTS "Teams" CASCADE;
DROP TABLE IF EXISTS "Users" CASCADE;

-- Drop enum types if they exist to allow recreation with updated values/names
DROP TYPE IF EXISTS game_status CASCADE;
DROP TYPE IF EXISTS game_states CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- ENUM type for user roles and game states to ensure data integrity.
CREATE TYPE user_role AS ENUM ('ADMIN', 'COACH', 'PLAYER', 'REFEREE');
CREATE TYPE game_states AS ENUM ('UNSCHEDULED', 'SCHEDULED', 'FINISHED', 'PROCESSED');

-- Core Tables for Users, Teams, and Leagues

CREATE TABLE "Users" (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  role user_role NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Teams" (
  team_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  -- A team is created by a user, typically a coach or admin.
  created_by_user_id INT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by_user_id) REFERENCES "Users"(user_id)
);

CREATE TABLE "Leagues" (
  league_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  -- A league is managed by an administrator.
  admin_user_id INT NOT NULL,
  description TEXT,
  rules TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_user_id) REFERENCES "Users"(user_id)
);

-- Relationship & Hierarchy Tables

CREATE TABLE "TeamMembers" (
  team_id INT NOT NULL,
  user_id INT NOT NULL,
  -- e.g., Player number, coach title.
  role_in_team VARCHAR(100) DEFAULT 'Player',
  player_number INT,
  is_captain BOOLEAN DEFAULT FALSE,
  is_libero BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (team_id, user_id),
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE
);

CREATE TABLE "Seasons" (
  season_id SERIAL PRIMARY KEY,
  league_id INT NOT NULL,
  name VARCHAR(255) NOT NULL, -- e.g., "2024-2025 Season"
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_archived BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (league_id) REFERENCES "Leagues"(league_id) ON DELETE CASCADE
);

CREATE TABLE "SeasonTeams" (
  season_id INT NOT NULL,
  team_id INT NOT NULL,
  join_date DATE DEFAULT CURRENT_DATE,
  PRIMARY KEY (season_id, team_id),
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE
);

-- Match, Scoring, and Standings Tables

CREATE TABLE "Matches" (
  match_id SERIAL PRIMARY KEY,
  season_id INT NOT NULL,
  home_team_id INT NOT NULL,
  away_team_id INT NOT NULL,
  match_datetime TIMESTAMP,
  venue VARCHAR(255),
  status game_states DEFAULT 'SCHEDULED', -- e.g., UNSCHEDULED, SCHEDULED, FINISHED, PROCESSED
  winner_team_id INT,
  home_sets_won INT DEFAULT 0,
  away_sets_won INT DEFAULT 0,
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id),
  FOREIGN KEY (home_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (away_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (winner_team_id) REFERENCES "Teams"(team_id)
);

CREATE TABLE "MatchReferees" (
  match_id INT NOT NULL,
  user_id INT NOT NULL, -- User with 'REFEREE' role
  referee_role VARCHAR(100) NOT NULL, -- e.g., '1st Referee', 'Scorer'
  PRIMARY KEY (match_id, user_id),
  FOREIGN KEY (match_id) REFERENCES "Matches"(match_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES "Users"(user_id)
);

CREATE TABLE "Sets" (
  set_id SERIAL PRIMARY KEY,
  match_id INT NOT NULL,
  set_number INT NOT NULL,
  home_team_score INT DEFAULT 0,
  away_team_score INT DEFAULT 0,
  winner_team_id INT,
  FOREIGN KEY (match_id) REFERENCES "Matches"(match_id) ON DELETE CASCADE,
  FOREIGN KEY (winner_team_id) REFERENCES "Teams"(team_id),
  UNIQUE (match_id, set_number)
);

-- Detailed Match Event Tracking (inspired by the original schema)

CREATE TABLE "Timeouts" (
  timeout_id SERIAL PRIMARY KEY,
  set_id INT NOT NULL,
  team_id INT NOT NULL,
  score_at_timeout VARCHAR(20), -- e.g., "15-12"
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (set_id) REFERENCES "Sets"(set_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id)
);

CREATE TABLE "Substitutions" (
  substitution_id SERIAL PRIMARY KEY,
  set_id INT NOT NULL,
  team_id INT NOT NULL,
  player_in_user_id INT NOT NULL,
  player_out_user_id INT NOT NULL,
  score_at_substitution VARCHAR(20), -- e.g., "10-8"
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (set_id) REFERENCES "Sets"(set_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (player_in_user_id) REFERENCES "Users"(user_id),
  FOREIGN KEY (player_out_user_id) REFERENCES "Users"(user_id)
);

-- Summary table for efficient querying of league standings

CREATE TABLE "LeagueStandings" (
  standing_id SERIAL PRIMARY KEY,
  season_id INT NOT NULL,
  team_id INT NOT NULL,
  matches_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  sets_won INT DEFAULT 0,
  sets_lost INT DEFAULT 0,
  points_won INT DEFAULT 0, -- Total points scored across all matches
  points_lost INT DEFAULT 0, -- Total points conceded across all matches
  league_points INT DEFAULT 0, -- Points awarded for wins/losses (e.g., 3 for a win)
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  UNIQUE (season_id, team_id)
);

-- Table for the desirable "Payments" feature

CREATE TABLE "Payments" (
  payment_id SERIAL PRIMARY KEY,
  -- The entity requesting payment (e.g., a league or team)
  requester_league_id INT,
  requester_team_id INT,
  -- The entity being asked to pay (e.g., a team or player)
  payer_team_id INT,
  payer_user_id INT,
  amount DECIMAL(10, 2) NOT NULL,
  description VARCHAR(255) NOT NULL,
  due_date DATE,
  status VARCHAR(50) DEFAULT 'UNPAID', -- e.g., UNPAID, PAID, OVERDUE
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (requester_league_id) REFERENCES "Leagues"(league_id),
  FOREIGN KEY (requester_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (payer_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (payer_user_id) REFERENCES "Users"(user_id),
  -- Ensures that a payment has a valid requester and payer
  CONSTRAINT chk_payment_parties CHECK (
    (requester_league_id IS NOT NULL OR requester_team_id IS NOT NULL) AND
    (payer_team_id IS NOT NULL OR payer_user_id IS NOT NULL)
  )
);
