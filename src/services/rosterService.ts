import { randomUUID } from 'crypto';
import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket, ResultSetHeader } from 'mysql2/promise';

interface RosterSlot extends RowDataPacket {
  id: string;
  team_id: string;
  player_id: string;
  slot_type: 'starter' | 'bench' | 'ir';
  roster_position: string | null;
  acquired_at: string;
}

interface RosterSlotWithPlayer extends RosterSlot {
  full_name: string;
  position: string;
  nfl_team: string | null;
  status: 'active' | 'injured' | 'inactive' | 'retired';
}

interface AddPlayerInput {
  player_id: string;
  slot_type?: 'starter' | 'bench' | 'ir';
  roster_position?: string;
}

export async function listRoster(userId: string, teamId: string): Promise<RosterSlotWithPlayer[]> {
  const [teamRows] = await pool.query<any[]>(
    'SELECT league_id FROM teams WHERE id = ?',
    [teamId]
  );

  if (!teamRows.length) {
    throw new AppError(404, 'team_not_found', 'Team not found');
  }

  const leagueId = teamRows[0].league_id;

  const [memberRows] = await pool.query<any[]>(
    'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
    [leagueId, userId]
  );

  if (!memberRows.length) {
    throw new AppError(403, 'forbidden', 'Access denied');
  }

  const [rows] = await pool.query<RosterSlotWithPlayer[]>(
    `SELECT rs.*, p.full_name, p.position, p.nfl_team, p.status
     FROM roster_slots rs
     JOIN players p ON rs.player_id = p.id
     WHERE rs.team_id = ?`,
    [teamId]
  );

  return rows;
}

export async function addPlayer(userId: string, teamId: string, input: AddPlayerInput): Promise<RosterSlot> {
  const { player_id, slot_type = 'bench', roster_position } = input;

  const [teamRows] = await pool.query<any[]>(
    'SELECT league_id, owner_user_id FROM teams WHERE id = ?',
    [teamId]
  );

  if (!teamRows.length) {
    throw new AppError(404, 'team_not_found', 'Team not found');
  }

  const team = teamRows[0];

  if (team.owner_user_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only team owner can add players');
  }

  const [playerRows] = await pool.query<any[]>(
    'SELECT id FROM players WHERE id = ?',
    [player_id]
  );

  if (!playerRows.length) {
    throw new AppError(404, 'player_not_found', 'Player not found');
  }

  const slotId = randomUUID();

  try {
    await pool.query(
      'INSERT INTO roster_slots (id, team_id, player_id, slot_type, roster_position) VALUES (?, ?, ?, ?, ?)',
      [slotId, teamId, player_id, slot_type, roster_position || null]
    );
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') {
      throw new AppError(409, 'player_already_on_team', 'Player is already on this team');
    }
    throw err;
  }

  const [rows] = await pool.query<RosterSlot[]>(
    'SELECT * FROM roster_slots WHERE id = ?',
    [slotId]
  );

  return rows[0];
}

export async function dropPlayer(userId: string, teamId: string, playerId: string): Promise<void> {
  const [teamRows] = await pool.query<any[]>(
    'SELECT owner_user_id FROM teams WHERE id = ?',
    [teamId]
  );

  if (!teamRows.length) {
    throw new AppError(404, 'team_not_found', 'Team not found');
  }

  const team = teamRows[0];

  if (team.owner_user_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only team owner can drop players');
  }

  const [result] = await pool.query<ResultSetHeader>(
    'DELETE FROM roster_slots WHERE team_id = ? AND player_id = ?',
    [teamId, playerId]
  );

  if (result.affectedRows === 0) {
    throw new AppError(404, 'roster_slot_not_found', 'Roster slot not found');
  }
}
