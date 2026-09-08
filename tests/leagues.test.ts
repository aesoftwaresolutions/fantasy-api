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

describe('GET /api/leagues', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .get('/api/leagues');

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 200 with empty leagues array when user has no leagues', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([[], []]); // SELECT leagues

    const res = await request(app)
      .get('/api/leagues')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.leagues).toEqual([]);
  });

  it('should return 200 with leagues array when user has leagues', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'l1',
          name: 'Test League',
          commissioner_id: 'u1',
          format: 'redraft',
          privacy: 'private',
          invite_code: 'ABC123',
          max_teams: 12,
          scoring_rules_json: null,
          cap_amount: null,
          season_year: 2026,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      [],
    ]); // SELECT leagues

    const res = await request(app)
      .get('/api/leagues')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.leagues).toHaveLength(1);
    expect(res.body.leagues[0].id).toBe('l1');
    expect(res.body.leagues[0].name).toBe('Test League');
  });
});

describe('POST /api/leagues', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
    mockConnQuery.mockResolvedValue([{}, []]);
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .post('/api/leagues')
      .send({ name: 'League 1', season_year: 2026 });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 400 validation_error when name is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/leagues')
      .set('Authorization', `Bearer ${token}`)
      .send({ season_year: 2026 });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error when season_year is missing', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/leagues')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'League 1' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error for invalid season_year (out of range)', async () => {
    const token = createToken('u1', 'user@example.com');

    const res = await request(app)
      .post('/api/leagues')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'League 1', season_year: 2010 });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 201 with league when valid input provided', async () => {
    const token = createToken('u1', 'user@example.com');

    // Mock the transaction chain:
    // 1. INSERT league (via conn.query)
    mockConnQuery.mockResolvedValueOnce([{}, []]);
    // 2. INSERT league_members (via conn.query)
    mockConnQuery.mockResolvedValueOnce([{}, []]);
    // 3. INSERT teams (via conn.query)
    mockConnQuery.mockResolvedValueOnce([{}, []]);
    // 4. SELECT the created league (via pool.query)
    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'l1',
          name: 'My League',
          commissioner_id: 'u1',
          format: 'redraft',
          privacy: 'private',
          invite_code: 'ABC123',
          max_teams: 12,
          scoring_rules_json: null,
          cap_amount: null,
          season_year: 2026,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      [],
    ]);

    const res = await request(app)
      .post('/api/leagues')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'My League',
        season_year: 2026,
      });

    expect(res.status).toBe(201);
    expect(res.body.league).toBeDefined();
    expect(res.body.league.id).toBe('l1');
    expect(res.body.league.name).toBe('My League');
    expect(res.body.league.season_year).toBe(2026);
    expect(res.body.league.commissioner_id).toBe('u1');
  });

  it('should return 201 with league with optional fields', async () => {
    const token = createToken('u1', 'user@example.com');

    mockConnQuery.mockResolvedValueOnce([{}, []]);
    mockConnQuery.mockResolvedValueOnce([{}, []]);
    mockConnQuery.mockResolvedValueOnce([{}, []]);
    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'l2',
          name: 'Dynasty League',
          commissioner_id: 'u1',
          format: 'dynasty',
          privacy: 'public',
          invite_code: 'XYZ789',
          max_teams: 10,
          scoring_rules_json: null,
          cap_amount: null,
          season_year: 2026,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      [],
    ]);

    const res = await request(app)
      .post('/api/leagues')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Dynasty League',
        season_year: 2026,
        format: 'dynasty',
        privacy: 'public',
        max_teams: 10,
      });

    expect(res.status).toBe(201);
    expect(res.body.league.format).toBe('dynasty');
    expect(res.body.league.privacy).toBe('public');
    expect(res.body.league.max_teams).toBe(10);
  });
});

describe('GET /api/leagues/:id', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockConnQuery.mockReset();
  });

  it('should return 401 unauthorized when no token provided', async () => {
    const res = await request(app)
      .get('/api/leagues/l1');

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('unauthorized');
  });

  it('should return 404 league_not_found when league does not exist', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([[], []]); // SELECT league returns empty

    const res = await request(app)
      .get('/api/leagues/nonexistent')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('league_not_found');
  });

  it('should return 403 forbidden when user is not a league member', async () => {
    const token = createToken('u2', 'user2@example.com');

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'l1',
          name: 'League 1',
          commissioner_id: 'u1',
          format: 'redraft',
          privacy: 'private',
          invite_code: 'ABC123',
          max_teams: 12,
          scoring_rules_json: null,
          cap_amount: null,
          season_year: 2026,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      [],
    ]); // SELECT league
    mockQuery.mockResolvedValueOnce([[], []]); // SELECT membership returns empty

    const res = await request(app)
      .get('/api/leagues/l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('forbidden');
  });

  it('should return 200 with league when user is a member', async () => {
    const token = createToken('u1', 'user@example.com');

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'l1',
          name: 'League 1',
          commissioner_id: 'u1',
          format: 'redraft',
          privacy: 'private',
          invite_code: 'ABC123',
          max_teams: 12,
          scoring_rules_json: null,
          cap_amount: null,
          season_year: 2026,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      [],
    ]); // SELECT league
    mockQuery.mockResolvedValueOnce([
      [{ id: 'member1', league_id: 'l1', user_id: 'u1', role: 'commissioner' }],
      [],
    ]); // SELECT membership

    const res = await request(app)
      .get('/api/leagues/l1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.league).toBeDefined();
    expect(res.body.league.id).toBe('l1');
    expect(res.body.league.name).toBe('League 1');
  });
});
