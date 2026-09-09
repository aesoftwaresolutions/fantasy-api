import { describe, it, expect, beforeEach, vi } from 'vitest';
import request from 'supertest';
import jwt from 'jsonwebtoken';

const { mockQuery, mockConnQuery, mockConn } = vi.hoisted(() => {
  const mockQuery = vi.fn();
  const mockConnQuery = vi.fn().mockResolvedValue([{}, []]);
  const mockConn = {
    query: mockConnQuery,
    beginTransaction: vi.fn().mockResolvedValue(undefined),
    commit: vi.fn().mockResolvedValue(undefined),
    rollback: vi.fn().mockResolvedValue(undefined),
    release: vi.fn().mockResolvedValue(undefined),
  };
  return { mockQuery, mockConnQuery, mockConn };
});

vi.mock('../src/db/pool', () => ({
  default: {
    query: (...args: any[]) => mockQuery(...args),
    getConnection: vi.fn(async () => mockConn),
  },
  query: (...args: any[]) => mockQuery(...args),
}));

import app from '../src/app';

function createToken(userId: string, email: string): string {
  return jwt.sign({ id: userId, email }, process.env.JWT_SECRET!);
}

describe('POST /api/drafts', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .post('/api/drafts')
      .send({ league_id: 'l1' });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/drafts')
      .set('Authorization', `Bearer ${token}`)
      .send({ draft_type: 'snake' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 auction_not_supported when draft_type is auction', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]); // SELECT leagues

    const res = await request(app)
      .post('/api/drafts')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', draft_type: 'auction' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('auction_not_supported');
  });

  it('should return 201 with draft when commissioner creates a snake draft', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([{}, []]) // INSERT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'scheduled',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]); // SELECT draft back

    const res = await request(app)
      .post('/api/drafts')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', draft_type: 'snake' });

    expect(res.status).toBe(201);
    expect(res.body.draft).toBeDefined();
    expect(res.body.draft.id).toBe('d1');
    expect(res.body.draft.league_id).toBe('l1');
    expect(res.body.draft.draft_type).toBe('snake');
    expect(res.body.draft.status).toBe('scheduled');
  });

  it('should return 403 forbidden when non-commissioner tries to create a draft', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [{ id: 'l1', commissioner_id: 'u2' }],
      [],
    ]); // SELECT leagues

    const res = await request(app)
      .post('/api/drafts')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', draft_type: 'snake' });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });

  it('should return 404 league_not_found when league does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([[], []]); // SELECT leagues returns empty

    const res = await request(app)
      .post('/api/drafts')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'nonexistent', draft_type: 'snake' });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('league_not_found');
  });
});

describe('POST /api/drafts/:id/start', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .post('/api/drafts/d1/start')
      .send({ league_id: 'l1' });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/drafts/d1/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ rounds: 15 });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 200 with draft when commissioner starts a draft', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'scheduled',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 't1' }, { id: 't2' }],
        [],
      ]) // SELECT teams
      .mockResolvedValueOnce([{}, []]) // INSERT picks
      .mockResolvedValueOnce([{}, []]) // UPDATE draft status
      .mockResolvedValueOnce(undefined); // commit

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'd1',
          league_id: 'l1',
          draft_type: 'snake',
          status: 'in_progress',
          scheduled_at: null,
          completed_at: null,
        },
      ],
      [],
    ]); // SELECT draft back

    const res = await request(app)
      .post('/api/drafts/d1/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', rounds: 2 });

    expect(res.status).toBe(200);
    expect(res.body.draft).toBeDefined();
    expect(res.body.draft.status).toBe('in_progress');
  });

  it('should return 404 draft_not_found when draft does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery.mockResolvedValueOnce([[], []]); // SELECT draft returns empty

    const res = await request(app)
      .post('/api/drafts/nonexistent/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', rounds: 15 });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('draft_not_found');
  });

  it('should return 409 draft_not_scheduled when draft is not in scheduled status', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]); // SELECT league

    const res = await request(app)
      .post('/api/drafts/d1/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', rounds: 15 });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('draft_not_scheduled');
  });

  it('should return 400 not_enough_teams when draft has fewer than 2 teams', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'scheduled',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 't1' }],
        [],
      ]); // SELECT teams returns only 1

    const res = await request(app)
      .post('/api/drafts/d1/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', rounds: 15 });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('not_enough_teams');
  });
});

describe('GET /api/drafts/:id', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .get('/api/drafts/d1');

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id query param is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .get('/api/drafts/d1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 200 with draft state when user is league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 'm1' }],
        [],
      ]) // SELECT league_members
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'p1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: null,
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: null,
            team_name: 'Team A',
            full_name: undefined,
            position: undefined,
          },
        ],
        [],
      ]); // SELECT picks

    const res = await request(app)
      .get('/api/drafts/d1?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.draft).toBeDefined();
    expect(res.body.draft.id).toBe('d1');
    expect(res.body.picks).toHaveLength(1);
    expect(res.body.on_the_clock).toBeDefined();
    expect(res.body.on_the_clock.team_id).toBe('t1');
    expect(res.body.on_the_clock.pick_number).toBe(1);
  });

  it('should return 404 draft_not_found when draft does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 'm1' }],
        [],
      ]) // SELECT league_members
      .mockResolvedValueOnce([[], []]); // SELECT draft returns empty

    const res = await request(app)
      .get('/api/drafts/nonexistent?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('draft_not_found');
  });

  it('should return 403 forbidden when user is not a league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([[], []]); // SELECT league_members returns empty

    const res = await request(app)
      .get('/api/drafts/d1?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });

  it('should return null on_the_clock when draft is complete', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 'm1' }],
        [],
      ]) // SELECT league_members
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'completed',
            scheduled_at: null,
            completed_at: '2026-09-09T00:00:00Z',
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'p1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: 'player1',
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: '2026-09-09T00:00:00Z',
            team_name: 'Team A',
            full_name: 'John Doe',
            position: 'QB',
          },
        ],
        [],
      ]); // SELECT picks

    const res = await request(app)
      .get('/api/drafts/d1?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.on_the_clock).toBeNull();
  });
});

describe('POST /api/drafts/:id/pick', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ player_id: 'p1' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error when player_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 201 with pick when team owner makes a valid pick', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'pick1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: null,
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: null,
          },
        ],
        [],
      ]) // SELECT current pick
      .mockResolvedValueOnce([
        [{ owner_user_id: 'u1' }],
        [],
      ]) // SELECT team
      .mockResolvedValueOnce([
        [{ commissioner_id: 'u1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 'p1' }],
        [],
      ]) // SELECT player
      .mockResolvedValueOnce([[], []]) // SELECT drafted check returns empty
      .mockResolvedValueOnce([{}, []]) // UPDATE pick
      .mockResolvedValueOnce([{}, []]) // INSERT roster
      .mockResolvedValueOnce([
        [{ cnt: 0 }],
        [],
      ]) // SELECT remaining picks
      .mockResolvedValueOnce(undefined); // commit

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'pick1',
          draft_id: 'd1',
          team_id: 't1',
          player_id: 'p1',
          round_number: 1,
          pick_number: 1,
          auction_amount: null,
          picked_at: '2026-09-09T00:00:00Z',
        },
      ],
      [],
    ]); // SELECT pick back

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(201);
    expect(res.body.pick).toBeDefined();
    expect(res.body.pick.player_id).toBe('p1');
    expect(res.body.pick.picked_at).toBe('2026-09-09T00:00:00Z');
  });

  it('should return 404 draft_not_found when draft does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery.mockResolvedValueOnce([[], []]); // SELECT draft returns empty

    const res = await request(app)
      .post('/api/drafts/nonexistent/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('draft_not_found');
  });

  it('should return 409 draft_not_active when draft is not in_progress', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery.mockResolvedValueOnce([
      [
        {
          id: 'd1',
          league_id: 'l1',
          draft_type: 'snake',
          status: 'scheduled',
          scheduled_at: null,
          completed_at: null,
        },
      ],
      [],
    ]); // SELECT draft

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('draft_not_active');
  });

  it('should return 409 draft_complete when all picks are done', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([[], []]); // SELECT current pick returns empty

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('draft_complete');
  });

  it('should return 403 not_on_the_clock when it is not the user\'s turn', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'pick1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: null,
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: null,
          },
        ],
        [],
      ]) // SELECT current pick
      .mockResolvedValueOnce([
        [{ owner_user_id: 'u2' }],
        [],
      ]) // SELECT team (different owner)
      .mockResolvedValueOnce([
        [{ commissioner_id: 'u3' }],
        [],
      ]); // SELECT league (different commissioner)

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('not_on_the_clock');
  });

  it('should return 404 player_not_found when player does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'pick1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: null,
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: null,
          },
        ],
        [],
      ]) // SELECT current pick
      .mockResolvedValueOnce([
        [{ owner_user_id: 'u1' }],
        [],
      ]) // SELECT team
      .mockResolvedValueOnce([
        [{ commissioner_id: 'u1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([[], []]); // SELECT player returns empty

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'nonexistent' });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('player_not_found');
  });

  it('should return 409 player_already_drafted when player was already drafted', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery
      .mockResolvedValueOnce([
        [
          {
            id: 'd1',
            league_id: 'l1',
            draft_type: 'snake',
            status: 'in_progress',
            scheduled_at: null,
            completed_at: null,
          },
        ],
        [],
      ]) // SELECT draft
      .mockResolvedValueOnce([
        [
          {
            id: 'pick1',
            draft_id: 'd1',
            team_id: 't1',
            player_id: null,
            round_number: 1,
            pick_number: 1,
            auction_amount: null,
            picked_at: null,
          },
        ],
        [],
      ]) // SELECT current pick
      .mockResolvedValueOnce([
        [{ owner_user_id: 'u1' }],
        [],
      ]) // SELECT team
      .mockResolvedValueOnce([
        [{ commissioner_id: 'u1' }],
        [],
      ]) // SELECT league
      .mockResolvedValueOnce([
        [{ id: 'p1' }],
        [],
      ]) // SELECT player
      .mockResolvedValueOnce([
        [{ id: 'pick2' }],
        [],
      ]); // SELECT drafted check returns a pick

    const res = await request(app)
      .post('/api/drafts/d1/pick')
      .set('Authorization', `Bearer ${token}`)
      .send({ league_id: 'l1', player_id: 'p1' });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('player_already_drafted');
  });
});
