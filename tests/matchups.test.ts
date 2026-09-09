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

describe('GET /api/matchups', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .get('/api/matchups');

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id query param is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .get('/api/matchups')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 200 with matchups when user is league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u2' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([
        [{ id: 'm1' }],
        [],
      ]) // SELECT league_members
      .mockResolvedValueOnce([
        [
          {
            id: 'mt1',
            league_id: 'l1',
            week_number: 1,
            team_a_id: 't1',
            team_b_id: 't2',
            team_a_score: '100',
            team_b_score: '90',
            status: 'final',
          },
        ],
        [],
      ]); // SELECT matchups

    const res = await request(app)
      .get('/api/matchups?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.matchups).toHaveLength(1);
    expect(res.body.matchups[0].id).toBe('mt1');
    expect(res.body.matchups[0].team_a_score).toBe(100);
    expect(res.body.matchups[0].team_b_score).toBe(90);
  });

  it('should return 404 league_not_found when league does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([[], []]); // SELECT leagues returns empty

    const res = await request(app)
      .get('/api/matchups?league_id=nonexistent')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('league_not_found');
  });

  it('should return 403 forbidden when user is not a league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u2' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([[], []]); // SELECT league_members returns empty

    const res = await request(app)
      .get('/api/matchups?league_id=l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });
});

describe('POST /api/matchups', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .post('/api/matchups')
      .send({
        league_id: 'l1',
        week_number: 1,
        team_a_id: 't1',
        team_b_id: 't2',
      });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/matchups')
      .set('Authorization', `Bearer ${token}`)
      .send({
        week_number: 1,
        team_a_id: 't1',
        team_b_id: 't2',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 201 with matchup when commissioner creates a valid matchup', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([
        [{ id: 't1' }],
        [],
      ]) // SELECT teams WHERE id = t1
      .mockResolvedValueOnce([
        [{ id: 't2' }],
        [],
      ]) // SELECT teams WHERE id = t2
      .mockResolvedValueOnce([{}, []]) // INSERT matchup
      .mockResolvedValueOnce([
        [
          {
            id: 'mt1',
            league_id: 'l1',
            week_number: 1,
            team_a_id: 't1',
            team_b_id: 't2',
            team_a_score: '0',
            team_b_score: '0',
            status: 'scheduled',
          },
        ],
        [],
      ]); // SELECT matchup back

    const res = await request(app)
      .post('/api/matchups')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        week_number: 1,
        team_a_id: 't1',
        team_b_id: 't2',
      });

    expect(res.status).toBe(201);
    expect(res.body.matchup).toBeDefined();
    expect(res.body.matchup.league_id).toBe('l1');
    expect(res.body.matchup.week_number).toBe(1);
    expect(res.body.matchup.team_a_id).toBe('t1');
    expect(res.body.matchup.team_b_id).toBe('t2');
  });

  it('should return 403 forbidden when non-commissioner tries to create a matchup', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [{ id: 'l1', commissioner_id: 'u2' }],
      [],
    ]); // SELECT leagues

    const res = await request(app)
      .post('/api/matchups')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        week_number: 1,
        team_a_id: 't1',
        team_b_id: 't2',
      });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });

  it('should return 400 validation_error when a team plays itself', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [{ id: 'l1', commissioner_id: 'u1' }],
      [],
    ]); // SELECT leagues

    const res = await request(app)
      .post('/api/matchups')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        week_number: 1,
        team_a_id: 't1',
        team_b_id: 't1',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });
});

describe('PATCH /api/matchups/:id', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .patch('/api/matchups/mt1')
      .send({
        league_id: 'l1',
        team_a_score: 100,
        team_b_score: 90,
        status: 'final',
      });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when league_id is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .patch('/api/matchups/mt1')
      .set('Authorization', `Bearer ${token}`)
      .send({
        team_a_score: 100,
        team_b_score: 90,
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 200 with updated matchup when commissioner updates scores', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([
        [
          {
            id: 'mt1',
            league_id: 'l1',
            week_number: 1,
            team_a_id: 't1',
            team_b_id: 't2',
            team_a_score: '0',
            team_b_score: '0',
            status: 'scheduled',
          },
        ],
        [],
      ]) // SELECT matchup
      .mockResolvedValueOnce([{}, []]) // UPDATE matchup
      .mockResolvedValueOnce([
        [
          {
            id: 'mt1',
            league_id: 'l1',
            week_number: 1,
            team_a_id: 't1',
            team_b_id: 't2',
            team_a_score: '100',
            team_b_score: '90',
            status: 'final',
          },
        ],
        [],
      ]); // SELECT matchup back

    const res = await request(app)
      .patch('/api/matchups/mt1')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        team_a_score: 100,
        team_b_score: 90,
        status: 'final',
      });

    expect(res.status).toBe(200);
    expect(res.body.matchup.team_a_score).toBe(100);
    expect(res.body.matchup.team_b_score).toBe(90);
    expect(res.body.matchup.status).toBe('final');
  });

  it('should return 400 validation_error when no updatable fields are provided', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .patch('/api/matchups/mt1')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 404 matchup_not_found when matchup does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u1' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([[], []]); // SELECT matchup returns empty

    const res = await request(app)
      .patch('/api/matchups/nonexistent')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        team_a_score: 100,
      });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('matchup_not_found');
  });

  it('should return 403 forbidden when non-commissioner tries to update', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [{ id: 'l1', commissioner_id: 'u2' }],
      [],
    ]); // SELECT leagues

    const res = await request(app)
      .patch('/api/matchups/mt1')
      .set('Authorization', `Bearer ${token}`)
      .send({
        league_id: 'l1',
        team_a_score: 100,
      });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });
});

describe('GET /api/leagues/:id/standings', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .get('/api/leagues/l1/standings');

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 200 with standings when user is league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u2' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([
        [{ id: 'm1' }],
        [],
      ]) // SELECT league_members
      .mockResolvedValueOnce([
        [
          { id: 't1', team_name: 'Team A' },
          { id: 't2', team_name: 'Team B' },
        ],
        [],
      ]) // SELECT teams
      .mockResolvedValueOnce([
        [
          {
            id: 'mt1',
            league_id: 'l1',
            week_number: 1,
            team_a_id: 't1',
            team_b_id: 't2',
            team_a_score: '100',
            team_b_score: '90',
            status: 'final',
          },
        ],
        [],
      ]); // SELECT matchups (final only)

    const res = await request(app)
      .get('/api/leagues/l1/standings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.standings).toHaveLength(2);
    // Team A should be first (1 win)
    expect(res.body.standings[0].team_id).toBe('t1');
    expect(res.body.standings[0].team_name).toBe('Team A');
    expect(res.body.standings[0].wins).toBe(1);
    expect(res.body.standings[0].losses).toBe(0);
    expect(res.body.standings[0].ties).toBe(0);
    expect(res.body.standings[0].points_for).toBe(100);
    expect(res.body.standings[0].points_against).toBe(90);
    // Team B should be second (0 wins)
    expect(res.body.standings[1].team_id).toBe('t2');
    expect(res.body.standings[1].wins).toBe(0);
    expect(res.body.standings[1].losses).toBe(1);
    expect(res.body.standings[1].points_for).toBe(90);
    expect(res.body.standings[1].points_against).toBe(100);
  });

  it('should return 404 league_not_found when league does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([[], []]); // SELECT leagues returns empty

    const res = await request(app)
      .get('/api/leagues/nonexistent/standings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('league_not_found');
  });

  it('should return 403 forbidden when user is not a league member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery
      .mockResolvedValueOnce([
        [{ id: 'l1', commissioner_id: 'u2' }],
        [],
      ]) // SELECT leagues
      .mockResolvedValueOnce([[], []]); // SELECT league_members returns empty

    const res = await request(app)
      .get('/api/leagues/l1/standings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });
});
