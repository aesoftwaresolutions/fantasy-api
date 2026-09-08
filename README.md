# Fantasy Sports API

A Node.js + Express + TypeScript backend API skeleton for NFL fantasy sports management.

## Overview

This is a skeleton implementation of a fantasy sports management platform supporting both redraft and dynasty league formats. The database schema includes contract-dynasty fields that are present in the tables but not yet wired into application logic — they exist to avoid future schema migrations.

**Target Sport:** NFL only  
**Formats:** Redraft and Dynasty (Contract Dynasty fields included for future use)  
**Database:** MySQL 8.0+

## Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Language:** TypeScript (strict mode)
- **Database:** MySQL 8.0+
- **Authentication:** JWT (jsonwebtoken)
- **Password Hashing:** bcryptjs
- **Middleware:** Helmet (CSP), CORS

## Prerequisites

- Node.js 18.0 or higher
- MySQL 8.0 or higher with a running server
- npm or yarn

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and set your database and JWT credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=fantasy_app
JWT_SECRET=your-very-secret-key-change-this
JWT_EXPIRES_IN=7d
PORT=3000
```

### 3. Run Database Migration

Initialize the database schema:

```bash
npm run migrate
```

### 4. Build TypeScript

```bash
npm run build
```

### 5. Start the Server

**Development mode** (with auto-reload):
```bash
npm run dev
```

**Production mode:**
```bash
npm run start
```

The server will listen on `http://localhost:3000` by default.

## API Endpoints

### Health Check (No Auth Required)
- `GET /` — Service status
- `GET /db` — Database connectivity check

### Authentication (No Auth Required)
- `POST /api/auth/register` — Register a new user
  - Body: `{ email, password, display_name, birth_date? }`
- `POST /api/auth/login` — Login and receive JWT
  - Body: `{ email, password }`
  - Response: `{ token, user }`

### Protected Resources (Auth Required: Bearer Token)
- `GET /api/leagues` — List leagues [STUBBED]
- `GET /api/teams` — List teams [STUBBED]
- `GET /api/players` — List players [STUBBED]
- `GET /api/rosters` — List rosters [STUBBED]
- `GET /api/drafts` — List drafts [STUBBED]
- `GET /api/trades` — List trades [STUBBED]
- `GET /api/waivers` — List waiver claims [STUBBED]
- `GET /api/matchups` — List matchups [STUBBED]
- `GET /api/notifications` — List notifications [STUBBED]

All protected resource endpoints currently return HTTP 501 with:
```json
{
  "error": "not_implemented",
  "message": "<resource> endpoints not yet implemented"
}
```

## Implementation Status

### Implemented
- ✅ Project scaffold (package.json, TypeScript config)
- ✅ Database connection pool (mysql2/promise)
- ✅ Complete SQL schema (verbatim from specification)
- ✅ Database migration runner
- ✅ Health check endpoints
- ✅ User registration with password hashing (bcryptjs)
- ✅ User login with JWT token generation
- ✅ JWT authentication middleware
- ✅ Central error handling
- ✅ CORS and Helmet security middleware

### Stubbed (HTTP 501 Not Implemented)
- Leagues CRUD
- Teams CRUD
- Players CRUD
- Rosters CRUD
- Drafts CRUD
- Trades CRUD
- Waivers CRUD
- Matchups CRUD
- Notifications CRUD

## Authentication

Protected API routes require a Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

Tokens are issued by the `/api/auth/login` endpoint and expire after 7 days (configurable via `JWT_EXPIRES_IN`).

## Database Schema

The database includes the following tables:
- `users` — User accounts
- `leagues` — League containers
- `league_members` — League membership
- `teams` — Fantasy teams
- `players` — Real-world NFL player data
- `player_contracts` — Contract information (dynasty)
- `roster_slots` — Player assignments to teams
- `drafts` — Draft events
- `draft_picks` — Individual draft picks
- `trades` — Trade proposals and resolutions
- `trade_players` — Players involved in trades
- `waiver_claims` — Waiver wire claims
- `matchups` — Head-to-head weekly matchups
- `weekly_stats` — Player statistics by week
- `notifications` — Push notification log

## Commands

- `npm run build` — Compile TypeScript to JavaScript
- `npm run start` — Start the production server
- `npm run dev` — Start with ts-node-dev (auto-reload)
- `npm run migrate` — Run database migrations
- `npm run typecheck` — Check types without building

## Notes

- This is a skeleton implementation. All SQL uses parameterized queries to prevent injection.
- Password hashes are never returned in API responses.
- Contract-dynasty fields in the database are present but not yet integrated into application logic.
- All async route handlers wrap errors through a centralized error handler.