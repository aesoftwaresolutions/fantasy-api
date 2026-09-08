import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket } from 'mysql2/promise';

interface Team extends RowDataPacket {
  id: string;
  league_id: string;
  owner_user_id: string;
  team_name: string;
  logo_url: string | null;
  cap_space_remaining: number | null;
  created_at: string;
}

export async function getTeam(userId: string, teamId: string): Promise<Team> {
  const [teamRows] = await pool.query<Team[]>(
    'SELECT * FROM teams WHERE id = ?',
    [teamId]
  );

  if (!teamRows.length) {
    throw new AppError(404, 'team_not_found', 'Team not found');
  }

  const team = teamRows[0];

  const [memberRows] = await pool.query<any[]>(
    'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
    [team.league_id, userId]
  );

  if (!memberRows.length) {
    throw new AppError(403, 'forbidden', 'Access denied');
  }

  return team;
}

export async function listLeagueTeams(userId: string, leagueId: string): Promise<Team[]> {
  const [leagueRows] = await pool.query<any[]>(
    'SELECT id FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  const [memberRows] = await pool.query<any[]>(
    'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
    [leagueId, userId]
  );

  if (!memberRows.length) {
    throw new AppError(403, 'forbidden', 'Access denied');
  }

  const [teams] = await pool.query<Team[]>(
    'SELECT * FROM teams WHERE league_id = ?',
    [leagueId]
  );

  return teams;
}

interface UpdateTeamInput {
  team_name?: string;
  logo_url?: string | null;
}

export async function updateTeam(userId: string, teamId: string, input: UpdateTeamInput): Promise<Team> {
  const [teamRows] = await pool.query<Team[]>(
    'SELECT * FROM teams WHERE id = ?',
    [teamId]
  );

  if (!teamRows.length) {
    throw new AppError(404, 'team_not_found', 'Team not found');
  }

  const team = teamRows[0];

  if (team.owner_user_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only team owner can update team');
  }

  const allowedFields = ['team_name', 'logo_url'];
  const updates: string[] = [];
  const values: any[] = [];

  for (const field of allowedFields) {
    if (field in input) {
      updates.push(`${field} = ?`);
      values.push((input as any)[field]);
    }
  }

  if (updates.length === 0) {
    return team;
  }

  values.push(teamId);
  const sql = `UPDATE teams SET ${updates.join(', ')} WHERE id = ?`;

  await pool.query(sql, values);

  const [updated] = await pool.query<Team[]>(
    'SELECT * FROM teams WHERE id = ?',
    [teamId]
  );

  return updated[0];
}
