-- =========================================================
-- Fantasy Sports App — Core Database Schema (MVP)
-- Sport: NFL only | Formats: Redraft + Dynasty
-- Contract Dynasty fields are included but NOT wired into
-- app logic yet — that's a separate build track per the
-- roadmap doc. They exist here so we don't have to alter
-- tables later.
-- Target: MySQL 8.0+ (matches Hostinger VPS defaults)
-- =========================================================

CREATE DATABASE IF NOT EXISTS fantasy_app
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fantasy_app;

-- ---------------------------------------------------------
-- USERS — one account per real person
-- ---------------------------------------------------------
CREATE TABLE users (
    id              CHAR(36)      PRIMARY KEY DEFAULT (UUID()),
    email           VARCHAR(255)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    display_name    VARCHAR(50)   NOT NULL,
    birth_date      DATE          NULL,        -- needed for COPPA / age-gate logic
    apple_user_id   VARCHAR(255)  NULL UNIQUE,  -- if using Sign in with Apple
    created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------
-- LEAGUES — a container for one group's season
-- ---------------------------------------------------------
CREATE TABLE leagues (
    id                  CHAR(36)      PRIMARY KEY DEFAULT (UUID()),
    name                VARCHAR(100)  NOT NULL,
    commissioner_id     CHAR(36)      NOT NULL,
    format              ENUM('redraft', 'dynasty', 'contract_dynasty') NOT NULL DEFAULT 'redraft',
    privacy             ENUM('private', 'public') NOT NULL DEFAULT 'private',
    invite_code         VARCHAR(10)   UNIQUE,
    max_teams           TINYINT       NOT NULL DEFAULT 12,
    scoring_rules_json  JSON          NULL,     -- custom scoring per league
    cap_amount          INT           NULL,     -- salary cap, contract_dynasty only
    season_year         SMALLINT      NOT NULL,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commissioner_id) REFERENCES users(id)
);

-- ---------------------------------------------------------
-- LEAGUE_MEMBERS — join table: which users are in which league
-- ---------------------------------------------------------
CREATE TABLE league_members (
    id          CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    league_id   CHAR(36)  NOT NULL,
    user_id     CHAR(36)  NOT NULL,
    role        ENUM('commissioner', 'member') NOT NULL DEFAULT 'member',
    joined_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_membership (league_id, user_id),
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------
-- TEAMS — one fantasy team per league member
-- ---------------------------------------------------------
CREATE TABLE teams (
    id                  CHAR(36)      PRIMARY KEY DEFAULT (UUID()),
    league_id           CHAR(36)      NOT NULL,
    owner_user_id       CHAR(36)      NOT NULL,
    team_name           VARCHAR(50)   NOT NULL,
    logo_url            VARCHAR(255)  NULL,
    cap_space_remaining INT           NULL,     -- contract_dynasty only
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_user_id) REFERENCES users(id)
);

-- ---------------------------------------------------------
-- PLAYERS — real-world NFL players (synced from data provider)
-- ---------------------------------------------------------
CREATE TABLE players (
    id                  CHAR(36)      PRIMARY KEY DEFAULT (UUID()),
    external_provider_id VARCHAR(50) NOT NULL UNIQUE, -- ID from SportsDataIO/Sportradar
    full_name           VARCHAR(100)  NOT NULL,
    position            VARCHAR(10)   NOT NULL,        -- QB, RB, WR, TE, K, DEF
    nfl_team            VARCHAR(5)    NULL,
    status              ENUM('active', 'injured', 'inactive', 'retired') DEFAULT 'active',
    photo_url           VARCHAR(255)  NULL,
    updated_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------
-- PLAYER_CONTRACTS — contract dynasty only (built now, used later)
-- ---------------------------------------------------------
CREATE TABLE player_contracts (
    id                  CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    player_id           CHAR(36)  NOT NULL,
    team_id             CHAR(36)  NOT NULL,
    years_remaining     TINYINT   NOT NULL DEFAULT 1,
    annual_cap_hit      INT       NOT NULL,
    is_franchise_tag    BOOLEAN   DEFAULT FALSE,
    dead_cap_if_cut     INT       DEFAULT 0,
    signed_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id),
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- ROSTER_SLOTS — which players are on which team, right now
-- ---------------------------------------------------------
CREATE TABLE roster_slots (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    team_id         CHAR(36)  NOT NULL,
    player_id       CHAR(36)  NOT NULL,
    slot_type       ENUM('starter', 'bench', 'ir') NOT NULL DEFAULT 'bench',
    roster_position VARCHAR(10) NULL,  -- e.g. 'FLEX', 'QB1'
    acquired_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_player_per_team (team_id, player_id),
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- ---------------------------------------------------------
-- DRAFTS — one draft event per league per season
-- ---------------------------------------------------------
CREATE TABLE drafts (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    league_id       CHAR(36)  NOT NULL,
    draft_type      ENUM('snake', 'auction') NOT NULL DEFAULT 'snake',
    status          ENUM('scheduled', 'in_progress', 'completed') DEFAULT 'scheduled',
    scheduled_at    TIMESTAMP NULL,
    completed_at    TIMESTAMP NULL,
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- DRAFT_PICKS — each individual pick made during a draft
-- ---------------------------------------------------------
CREATE TABLE draft_picks (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    draft_id        CHAR(36)  NOT NULL,
    team_id         CHAR(36)  NOT NULL,
    player_id       CHAR(36)  NULL,      -- null until pick is made
    round_number    SMALLINT  NOT NULL,
    pick_number     SMALLINT  NOT NULL,  -- overall pick order
    auction_amount  INT       NULL,      -- auction drafts only
    picked_at       TIMESTAMP NULL,
    FOREIGN KEY (draft_id) REFERENCES drafts(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES teams(id),
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- ---------------------------------------------------------
-- TRADES — proposed and resolved trades between teams
-- ---------------------------------------------------------
CREATE TABLE trades (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    league_id       CHAR(36)  NOT NULL,
    proposing_team_id CHAR(36) NOT NULL,
    receiving_team_id CHAR(36) NOT NULL,
    status          ENUM('pending', 'accepted', 'rejected', 'vetoed', 'expired') DEFAULT 'pending',
    resolution_method ENUM('commissioner', 'league_vote', 'instant') NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at     TIMESTAMP NULL,
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE,
    FOREIGN KEY (proposing_team_id) REFERENCES teams(id),
    FOREIGN KEY (receiving_team_id) REFERENCES teams(id)
);

-- ---------------------------------------------------------
-- TRADE_PLAYERS — which players moved in a given trade
-- ---------------------------------------------------------
CREATE TABLE trade_players (
    id          CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    trade_id    CHAR(36)  NOT NULL,
    player_id   CHAR(36)  NOT NULL,
    from_team_id CHAR(36) NOT NULL,
    to_team_id   CHAR(36) NOT NULL,
    FOREIGN KEY (trade_id) REFERENCES trades(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- ---------------------------------------------------------
-- WAIVERS — waiver wire claims
-- ---------------------------------------------------------
CREATE TABLE waiver_claims (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    league_id       CHAR(36)  NOT NULL,
    team_id         CHAR(36)  NOT NULL,
    player_id       CHAR(36)  NOT NULL,
    drop_player_id  CHAR(36)  NULL,       -- player being dropped to make room
    priority_at_claim TINYINT NOT NULL,
    status          ENUM('pending', 'successful', 'unsuccessful') DEFAULT 'pending',
    processed_at    TIMESTAMP NULL,
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES teams(id),
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- ---------------------------------------------------------
-- MATCHUPS — head-to-head weekly matchups
-- ---------------------------------------------------------
CREATE TABLE matchups (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    league_id       CHAR(36)  NOT NULL,
    week_number     TINYINT   NOT NULL,
    team_a_id       CHAR(36)  NOT NULL,
    team_b_id       CHAR(36)  NOT NULL,
    team_a_score    DECIMAL(6,2) DEFAULT 0,
    team_b_score    DECIMAL(6,2) DEFAULT 0,
    status          ENUM('scheduled', 'in_progress', 'final') DEFAULT 'scheduled',
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE,
    FOREIGN KEY (team_a_id) REFERENCES teams(id),
    FOREIGN KEY (team_b_id) REFERENCES teams(id)
);

-- ---------------------------------------------------------
-- WEEKLY_STATS — raw stat lines synced from the data provider
-- ---------------------------------------------------------
CREATE TABLE weekly_stats (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    player_id       CHAR(36)  NOT NULL,
    season_year     SMALLINT  NOT NULL,
    week_number     TINYINT   NOT NULL,
    stat_line_json  JSON      NOT NULL,   -- raw stats: yards, TDs, etc.
    fantasy_points  DECIMAL(6,2) NOT NULL DEFAULT 0,
    synced_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_player_week (player_id, season_year, week_number),
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- ---------------------------------------------------------
-- NOTIFICATIONS — push notification log/queue
-- ---------------------------------------------------------
CREATE TABLE notifications (
    id              CHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    user_id         CHAR(36)  NOT NULL,
    league_id       CHAR(36)  NULL,
    type            ENUM('trade_offer', 'draft_reminder', 'score_update', 'waiver_result', 'general') NOT NULL,
    message         VARCHAR(255) NOT NULL,
    is_read         BOOLEAN   DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE SET NULL
);

-- ---------------------------------------------------------
-- Indexes for common query patterns
-- ---------------------------------------------------------
CREATE INDEX idx_roster_team ON roster_slots(team_id);
CREATE INDEX idx_matchup_league_week ON matchups(league_id, week_number);
CREATE INDEX idx_stats_player_season ON weekly_stats(player_id, season_year);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);
