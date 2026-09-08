import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import pool from '../db/pool';
import config from '../config/env';
import { RowDataPacket } from 'mysql2/promise';

interface User extends RowDataPacket {
  id: string;
  email: string;
  password_hash: string;
  display_name: string;
  birth_date: string | null;
}

interface RegisterInput {
  email: string;
  password: string;
  display_name: string;
  birth_date?: string;
}

interface LoginInput {
  email: string;
  password: string;
}

class AuthError extends Error {
  constructor(
    public status: number,
    public error: string,
    message: string
  ) {
    super(message);
  }
}

export async function registerUser(input: RegisterInput) {
  const { email, password, display_name, birth_date } = input;

  // Check if user already exists
  const [existingRows] = await pool.query<User[]>(
    'SELECT id FROM users WHERE email = ?',
    [email]
  );

  if (existingRows.length > 0) {
    throw new AuthError(400, 'user_exists', 'Email already registered');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const userId = randomUUID();

  const [result] = await pool.query(
    'INSERT INTO users (id, email, password_hash, display_name, birth_date) VALUES (?, ?, ?, ?, ?)',
    [userId, email, passwordHash, display_name, birth_date || null]
  );

  const [userRows] = await pool.query<User[]>(
    'SELECT id, email, display_name, birth_date FROM users WHERE id = ?',
    [userId]
  );

  return userRows[0];
}

export async function loginUser(input: LoginInput) {
  const { email, password } = input;

  const [userRows] = await pool.query<User[]>(
    'SELECT id, email, password_hash, display_name, birth_date FROM users WHERE email = ?',
    [email]
  );

  if (userRows.length === 0) {
    throw new AuthError(401, 'invalid_credentials', 'Email or password is incorrect');
  }

  const user = userRows[0];
  const passwordMatch = await bcrypt.compare(password, user.password_hash);

  if (!passwordMatch) {
    throw new AuthError(401, 'invalid_credentials', 'Email or password is incorrect');
  }

  const signOptions: jwt.SignOptions = {
    expiresIn: config.jwt.expiresIn as jwt.SignOptions['expiresIn'],
  };

  const token = jwt.sign(
    { id: user.id, email: user.email },
    config.jwt.secret,
    signOptions
  );

  return {
    token,
    user: {
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      birth_date: user.birth_date,
    },
  };
}
