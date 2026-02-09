DROP TABLE IF EXISTS "Payments" CASCADE;
DROP TABLE IF EXISTS "InvitationCodes" CASCADE;
DROP TABLE IF EXISTS "ArchivedStandings" CASCADE;
DROP TABLE IF EXISTS "LeagueStandings" CASCADE;
DROP TABLE IF EXISTS "Substitutions" CASCADE;
DROP TABLE IF EXISTS "Timeouts" CASCADE;
DROP TABLE IF EXISTS "Sets" CASCADE;
DROP TABLE IF EXISTS "MatchReferees" CASCADE;
DROP TABLE IF EXISTS "Matches" CASCADE;
DROP TABLE IF EXISTS "SeasonTeams" CASCADE;
DROP TABLE IF EXISTS "LeagueJoinRequests" CASCADE;
DROP TABLE IF EXISTS "Seasons" CASCADE;
DROP TABLE IF EXISTS "TeamMembers" CASCADE;
DROP TABLE IF EXISTS "TeamJoinRequests" CASCADE;
DROP TABLE IF EXISTS "Leagues" CASCADE;
DROP TABLE IF EXISTS "Teams" CASCADE;
DROP TABLE IF EXISTS "Users" CASCADE;

DROP TYPE IF EXISTS game_status CASCADE;
DROP TYPE IF EXISTS game_states CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS join_request_status CASCADE;

CREATE TYPE user_role AS ENUM ('ADMIN', 'COACH', 'PLAYER', 'REFEREE');
CREATE TYPE game_states AS ENUM ('UNSCHEDULED', 'SCHEDULED', 'FINISHED', 'PROCESSED');
CREATE TYPE join_request_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

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
  created_by_user_id INT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by_user_id) REFERENCES "Users"(user_id)
);

CREATE TABLE "Leagues" (
  league_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  admin_user_id INT NOT NULL,
  description TEXT,
  rules TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_user_id) REFERENCES "Users"(user_id)
);

CREATE TABLE "TeamMembers" (
  team_id INT NOT NULL,
  user_id INT NOT NULL,
  role_in_team VARCHAR(100) DEFAULT 'Player',
  player_number INT,
  is_captain BOOLEAN DEFAULT FALSE,
  is_libero BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (team_id, user_id),
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE
);

CREATE TABLE "TeamJoinRequests" (
  join_request_id SERIAL PRIMARY KEY,
  team_id INT NOT NULL,
  user_id INT NOT NULL,
  invited_by_user_id INT NOT NULL,
  invitation_code VARCHAR(6) NOT NULL,
  status join_request_status DEFAULT 'PENDING',
  player_number INT,
  is_libero BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  responded_at TIMESTAMP,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE,
  FOREIGN KEY (invited_by_user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE,
  UNIQUE (team_id, user_id, status)
);

CREATE TABLE "Seasons" (
  season_id SERIAL PRIMARY KEY,
  league_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
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

CREATE TABLE "LeagueJoinRequests" (
  join_request_id SERIAL PRIMARY KEY,
  league_id INT NOT NULL,
  season_id INT NOT NULL,
  team_id INT NOT NULL,
  invited_by_user_id INT NOT NULL,
  status join_request_status DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  responded_at TIMESTAMP,
  FOREIGN KEY (league_id) REFERENCES "Leagues"(league_id) ON DELETE CASCADE,
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  FOREIGN KEY (invited_by_user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE,
  UNIQUE (season_id, team_id, status)
);

CREATE TABLE "Matches" (
  match_id SERIAL PRIMARY KEY,
  season_id INT NOT NULL,
  home_team_id INT NOT NULL,
  away_team_id INT NOT NULL,
  match_datetime TIMESTAMP,
  venue VARCHAR(255),
  status game_states DEFAULT 'SCHEDULED',
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
  user_id INT NOT NULL,
  referee_role VARCHAR(100) NOT NULL,
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
  UNIQUE (match_id, set_number),
  CHECK (set_number BETWEEN 1 AND 5),
  CHECK (home_team_score >= 0),
  CHECK (away_team_score >= 0),
  CHECK (home_team_score <> away_team_score)
);

CREATE TABLE "Timeouts" (
  timeout_id SERIAL PRIMARY KEY,
  set_id INT NOT NULL,
  team_id INT NOT NULL,
  score_at_timeout VARCHAR(20),
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
  score_at_substitution VARCHAR(20),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (set_id) REFERENCES "Sets"(set_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (player_in_user_id) REFERENCES "Users"(user_id),
  FOREIGN KEY (player_out_user_id) REFERENCES "Users"(user_id)
);

CREATE TABLE "LeagueStandings" (
  standing_id SERIAL PRIMARY KEY,
  season_id INT NOT NULL,
  team_id INT NOT NULL,
  matches_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  sets_won INT DEFAULT 0,
  sets_lost INT DEFAULT 0,
  points_won INT DEFAULT 0,
  points_lost INT DEFAULT 0,
  league_points INT DEFAULT 0,
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE,
  UNIQUE (season_id, team_id)
);

CREATE TABLE "ArchivedStandings" (
  archive_id SERIAL PRIMARY KEY,
  season_id INT NOT NULL,
  team_id INT NOT NULL,
  matches_played INT NOT NULL,
  wins INT NOT NULL,
  losses INT NOT NULL,
  sets_won INT NOT NULL,
  sets_lost INT NOT NULL,
  set_diff INT NOT NULL,
  points_won INT NOT NULL,
  points_lost INT NOT NULL,
  point_diff INT NOT NULL,
  league_points INT NOT NULL,
  final_position INT,
  archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (season_id) REFERENCES "Seasons"(season_id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES "Teams"(team_id) ON DELETE CASCADE
);

CREATE TABLE "InvitationCodes" (
  invitation_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  invited_user_id INT NOT NULL,
  code_date DATE NOT NULL,
  redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE,
  FOREIGN KEY (invited_user_id) REFERENCES "Users"(user_id) ON DELETE CASCADE,
  UNIQUE (invited_user_id, user_id, code_date)
);

CREATE TABLE "Payments" (
  payment_id SERIAL PRIMARY KEY,
  requester_league_id INT,
  requester_team_id INT,
  payer_team_id INT,
  payer_user_id INT,
  amount DECIMAL(10, 2) NOT NULL,
  description VARCHAR(255) NOT NULL,
  due_date DATE,
  status VARCHAR(50) DEFAULT 'UNPAID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (requester_league_id) REFERENCES "Leagues"(league_id),
  FOREIGN KEY (requester_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (payer_team_id) REFERENCES "Teams"(team_id),
  FOREIGN KEY (payer_user_id) REFERENCES "Users"(user_id),
  CONSTRAINT chk_payment_parties CHECK (
    (requester_league_id IS NOT NULL OR requester_team_id IS NOT NULL) AND
    (payer_team_id IS NOT NULL OR payer_user_id IS NOT NULL)
  )
);

CREATE OR REPLACE FUNCTION enforce_set_rules()
RETURNS TRIGGER AS $$
DECLARE
  match_status game_states;
  existing_sets INT;
  home_wins INT;
  away_wins INT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    SELECT status INTO match_status
    FROM "Matches"
    WHERE match_id = OLD.match_id;

    IF match_status = 'FINISHED' THEN
      RAISE EXCEPTION 'Cannot modify sets for a finished match';
    END IF;

    RETURN OLD;
  END IF;

  SELECT status INTO match_status
  FROM "Matches"
  WHERE match_id = NEW.match_id;

  IF match_status = 'FINISHED' THEN
    RAISE EXCEPTION 'Cannot modify sets for a finished match';
  END IF;

  SELECT COUNT(*) INTO existing_sets
  FROM "Sets"
  WHERE match_id = NEW.match_id
    AND (TG_OP <> 'UPDATE' OR set_id <> OLD.set_id);

  IF existing_sets >= 5 THEN
    RAISE EXCEPTION 'A match cannot have more than 5 sets';
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE home_team_score > away_team_score),
    COUNT(*) FILTER (WHERE away_team_score > home_team_score)
  INTO home_wins, away_wins
  FROM "Sets"
  WHERE match_id = NEW.match_id
    AND (TG_OP <> 'UPDATE' OR set_id <> OLD.set_id);

  IF TG_OP = 'INSERT' AND (home_wins >= 3 OR away_wins >= 3) THEN
    RAISE EXCEPTION 'Cannot insert additional sets after a team has won 3 sets';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sets_before_change
BEFORE INSERT OR UPDATE OR DELETE ON "Sets"
FOR EACH ROW
EXECUTE FUNCTION enforce_set_rules();

CREATE OR REPLACE FUNCTION finalize_match_on_finish()
RETURNS TRIGGER AS $$
DECLARE
  total_sets INT;
  home_wins INT;
  away_wins INT;
BEGIN
  IF NEW.status = 'FINISHED' AND (OLD.status IS DISTINCT FROM 'FINISHED') THEN
    SELECT
      COUNT(*),
      COUNT(*) FILTER (WHERE home_team_score > away_team_score),
      COUNT(*) FILTER (WHERE away_team_score > home_team_score)
    INTO total_sets, home_wins, away_wins
    FROM "Sets"
    WHERE match_id = NEW.match_id;

    IF total_sets < 3 OR total_sets > 5 THEN
      RAISE EXCEPTION 'Finished match must have between 3 and 5 sets';
    END IF;

    IF NOT (
      (home_wins = 3 AND away_wins BETWEEN 0 AND 2) OR
      (away_wins = 3 AND home_wins BETWEEN 0 AND 2)
    ) THEN
      RAISE EXCEPTION 'Finished match must have exactly one team with 3 set wins';
    END IF;

    NEW.home_sets_won = home_wins;
    NEW.away_sets_won = away_wins;
    IF home_wins = 3 THEN
      NEW.winner_team_id = NEW.home_team_id;
    ELSE
      NEW.winner_team_id = NEW.away_team_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_matches_finalize_on_finish
BEFORE UPDATE ON "Matches"
FOR EACH ROW
EXECUTE FUNCTION finalize_match_on_finish();