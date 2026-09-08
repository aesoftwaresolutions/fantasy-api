# Contributing

Thanks for your interest in improving fantasy-api.

## Getting started

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env` and fill in the values (generate `JWT_SECRET`
   with `openssl rand -hex 64`).
3. Run the migration: `npm run migrate`
4. (Optional) Seed the player pool: `npm run seed:players`
5. Start the dev server: `npm run dev`

## Before opening a pull request

- `npm run typecheck` must pass with no errors.
- `npm run build` must succeed.
- Keep changes focused; touch only what the change requires.
- Use parameterized SQL (`?` placeholders) — never string-concatenate user input.
- Match the existing service/route structure and error-handling conventions
  (`AppError`, the shared `asyncHandler`, JSON `{ error, message }` responses).

CI runs the type check and build on every push and pull request to `main`.

## Project layout

- `src/routes` — Express routers (thin; validation + calling services)
- `src/services` — business logic and database access
- `src/middleware` — auth, error handling
- `src/db` — connection pool and migration runner
- `scripts` — one-off scripts (e.g. the nflverse player seed)
- `ios` — the SwiftUI client
