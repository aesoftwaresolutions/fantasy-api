import { describe, it, expect, beforeEach, vi } from 'vitest';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

const { mockQuery, mockConnQuery, mockConn } = vi.hoisted(() => {
  const mockQuery = vi.fn();
  const mockConnQuery = vi.fn();
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

describe('POST /api/auth/register', () => {
  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('should return 400 validation_error when body is missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({});

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error for invalid email', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'not-an-email',
        password: 'password123',
        display_name: 'Test User',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error for password shorter than 8 chars', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'user@example.com',
        password: 'short',
        display_name: 'Test User',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error when display_name is empty', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'user@example.com',
        password: 'password123',
        display_name: '',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 201 with user when valid registration', async () => {
    mockQuery.mockResolvedValueOnce([[], []]); // SELECT existing (none)
    mockQuery.mockResolvedValueOnce([{}, []]); // INSERT user
    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'u1',
          email: 'newuser@example.com',
          display_name: 'New User',
          birth_date: null,
        },
      ],
      [],
    ]); // SELECT user

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'newuser@example.com',
        password: 'password123',
        display_name: 'New User',
      });

    expect(res.status).toBe(201);
    expect(res.body.user).toBeDefined();
    expect(res.body.user.email).toBe('newuser@example.com');
    expect(res.body.user.display_name).toBe('New User');
    expect(res.body.user.password_hash).toBeUndefined();
  });

  it('should return 201 with optional birth_date when provided', async () => {
    mockQuery.mockResolvedValueOnce([[], []]); // SELECT existing
    mockQuery.mockResolvedValueOnce([{}, []]); // INSERT user
    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'u2',
          email: 'user2@example.com',
          display_name: 'User Two',
          birth_date: '1990-01-15',
        },
      ],
      [],
    ]); // SELECT user

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'user2@example.com',
        password: 'password123',
        display_name: 'User Two',
        birth_date: '1990-01-15',
      });

    expect(res.status).toBe(201);
    expect(res.body.user.birth_date).toBe('1990-01-15');
    expect(res.body.user.password_hash).toBeUndefined();
  });
});

describe('POST /api/auth/login', () => {
  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('should return 401 invalid_credentials when user not found', async () => {
    mockQuery.mockResolvedValueOnce([[], []]); // SELECT user returns empty

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'unknown@example.com',
        password: 'password123',
      });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('invalid_credentials');
  });

  it('should return 401 invalid_credentials when password does not match', async () => {
    const correctPassword = 'password123';
    const hash = bcrypt.hashSync(correctPassword, 10);

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'u1',
          email: 'user@example.com',
          password_hash: hash,
          display_name: 'Test User',
          birth_date: null,
        },
      ],
      [],
    ]); // SELECT user

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'user@example.com',
        password: 'wrongpassword',
      });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe('invalid_credentials');
  });

  it('should return 200 with token and user when credentials are valid', async () => {
    const correctPassword = 'password123';
    const hash = bcrypt.hashSync(correctPassword, 10);

    mockQuery.mockResolvedValueOnce([
      [
        {
          id: 'u1',
          email: 'user@example.com',
          password_hash: hash,
          display_name: 'Test User',
          birth_date: '1990-01-01',
        },
      ],
      [],
    ]); // SELECT user

    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'user@example.com',
        password: correctPassword,
      });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(typeof res.body.token).toBe('string');
    expect(res.body.user).toBeDefined();
    expect(res.body.user.email).toBe('user@example.com');
    expect(res.body.user.display_name).toBe('Test User');
    expect(res.body.user.birth_date).toBe('1990-01-01');
    expect(res.body.user.password_hash).toBeUndefined();

    // Verify token is valid JWT
    const decoded = jwt.verify(res.body.token, process.env.JWT_SECRET!) as jwt.JwtPayload;
    expect(decoded.id).toBe('u1');
    expect(decoded.email).toBe('user@example.com');
  });

  it('should return 400 validation_error for missing email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        password: 'password123',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });

  it('should return 400 validation_error for missing password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'user@example.com',
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });
});
