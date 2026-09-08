import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket, ResultSetHeader } from 'mysql2/promise';
import { randomUUID } from 'crypto';

interface Player extends RowDataPacket {
  id: string;
  external_provider_id: string;
  full_name: string;
  position: string;
  nfl_team: string | null;
  status: 'active' | 'injured' | 'inactive' | 'retired';
  photo_url: string | null;
  updated_at: string;
}

interface ListPlayersFilter {
  search?: string;
  position?: string;
  limit?: number;
  offset?: number;
}

interface CreatePlayerInput {
  external_provider_id: string;
  full_name: string;
  position: string;
  nfl_team?: string | null;
  status?: 'active' | 'injured' | 'inactive' | 'retired';
  photo_url?: string | null;
}

export async function listPlayers(
  filter: ListPlayersFilter
): Promise<{ players: Player[]; total: number }> {
  const { search, position, limit: rawLimit, offset: rawOffset } = filter;

  // Clamp and validate pagination
  let limit = Math.min(Math.max(1, rawLimit ?? 50), 100);
  let offset = Math.max(0, rawOffset ?? 0);

  // Handle NaN gracefully (fall back to defaults)
  if (isNaN(limit)) limit = 50;
  if (isNaN(offset)) offset = 0;

  const whereConditions: string[] = [];
  const params: any[] = [];

  if (search) {
    whereConditions.push('full_name LIKE ?');
    params.push(`%${search}%`);
  }

  if (position) {
    whereConditions.push('position = ?');
    params.push(position);
  }

  const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

  // Get total count with same filter
  const countSql = `SELECT COUNT(*) as count FROM players ${whereClause}`;
  const [countRows] = await pool.query<any[]>(countSql, params);
  const total = countRows[0].count;

  // Get paginated results
  const playersSql = `SELECT * FROM players ${whereClause} ORDER BY full_name ASC LIMIT ? OFFSET ?`;
  const [players] = await pool.query<Player[]>(playersSql, [...params, limit, offset]);

  return { players, total };
}

export async function getPlayer(id: string): Promise<Player> {
  const [rows] = await pool.query<Player[]>('SELECT * FROM players WHERE id = ?', [id]);

  if (!rows.length) {
    throw new AppError(404, 'player_not_found', 'Player not found');
  }

  return rows[0];
}

export async function createPlayer(input: CreatePlayerInput): Promise<Player> {
  // Validate required fields
  if (!input.external_provider_id || !input.full_name || !input.position) {
    throw new AppError(400, 'validation_error', 'external_provider_id, full_name, and position are required');
  }

  const id = randomUUID();
  const { external_provider_id, full_name, position, nfl_team = null, status = 'active', photo_url = null } = input;

  try {
    const insertSql = `
      INSERT INTO players (id, external_provider_id, full_name, position, nfl_team, status, photo_url)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    await pool.query<ResultSetHeader>(insertSql, [
      id,
      external_provider_id,
      full_name,
      position,
      nfl_team,
      status,
      photo_url,
    ]);
  } catch (error: any) {
    if (error.code === 'ER_DUP_ENTRY') {
      throw new AppError(409, 'player_exists', 'A player with that provider ID already exists');
    }
    throw error;
  }

  // SELECT and return the created player
  const [rows] = await pool.query<Player[]>('SELECT * FROM players WHERE id = ?', [id]);
  return rows[0];
}
