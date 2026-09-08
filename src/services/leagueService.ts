import { randomUUID, randomBytes } from 'crypto';
import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket, ResultSetHeader } from 'mysql2/promise';

interface League extends RowDataPacket {
  id: string;
  name: string;
  commissioner_id: string;
  format: 'redraft' | 'dynasty' | 'contract_dynasty';
  privacy: 'private' | 'public';
  invite_code: string | null;
  max_teams: number;
  scoring_rules_json: string | null;
  cap_amount: number | null;
  season_year: number;
  created_at: string;
}

function generateInviteCode(): string {
  // Cryptographically random: invite codes act as access credentials.
  return randomBytes(4).toString('hex').toUpperCase(); // 8 hex chars
}

interface CreateLeagueInput {
  name: string;
  season_year: number;
  format?: 'redraft' | 'dynasty' | 'contract_dynasty';
  privacy?: 'private' | 'public';
  max_teams?: number;
  team_name?: string;
}

export async function createLeague(userId: string, input: CreateLeagueInput): Promise<League> {
  const { name, season_year, format = 'redraft', privacy = 'private', max_teams = 12, team_name } = input;

  if (!name || !season_year) {
    throw new AppError(400, 'validation_error', 'name and season_year are required');
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const leagueId = randomUUID();
    let inviteCode: string | null = null;
    let attempts = 0;

    // Retry generating unique invite code up to 5 times
    while (!inviteCode && attempts < 5) {
      const candidate = generateInviteCode();
      try {
        const [result] = await conn.query<ResultSetHeader>(
          'INSERT INTO leagues (id, name, commissioner_id, format, privacy, invite_code, max_teams, season_year) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [leagueId, name, userId, format, privacy, candidate, max_teams, season_year]
        );
        inviteCode = candidate;
      } catch (err: any) {
        if (err.code === 'ER_DUP_ENTRY') {
          attempts++;
        } else {
          throw err;
        }
      }
    }

    if (!inviteCode) {
      throw new AppError(500, 'internal_error', 'Failed to generate unique invite code');
    }

    // Add commissioner as league member
    const memberId = randomUUID();
    await conn.query(
      'INSERT INTO league_members (id, league_id, user_id, role) VALUES (?, ?, ?, ?)',
      [memberId, leagueId, userId, 'commissioner']
    );

    // Create commissioner's team
    const teamId = randomUUID();
    const finalTeamName = team_name || 'My Team';
    await conn.query(
      'INSERT INTO teams (id, league_id, owner_user_id, team_name) VALUES (?, ?, ?, ?)',
      [teamId, leagueId, userId, finalTeamName]
    );

    await conn.commit();

    const [rows] = await pool.query<League[]>(
      'SELECT * FROM leagues WHERE id = ?',
      [leagueId]
    );

    if (!rows.length) {
      throw new AppError(500, 'internal_error', 'Failed to retrieve created league');
    }

    return rows[0];
  } catch (err: any) {
    await conn.rollback();
    throw err;
  } finally {
    await conn.release();
  }
}

interface JoinLeagueInput {
  invite_code: string;
  team_name?: string;
}

export async function joinLeague(userId: string, input: JoinLeagueInput): Promise<League> {
  const { invite_code, team_name } = input;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [leagueRows] = await conn.query<League[]>(
      'SELECT * FROM leagues WHERE invite_code = ?',
      [invite_code]
    );

    if (!leagueRows.length) {
      throw new AppError(404, 'league_not_found', 'League not found');
    }

    const league = leagueRows[0];

    // Check membership count vs max_teams
    const [countRows] = await conn.query<any[]>(
      // Lock the league's membership rows so the capacity check and insert
      // are atomic against a concurrent join (avoids over-filling a league).
      'SELECT COUNT(*) as cnt FROM league_members WHERE league_id = ? FOR UPDATE',
      [league.id]
    );
    const memberCount = countRows[0].cnt;

    if (memberCount >= league.max_teams) {
      throw new AppError(409, 'league_full', 'League is at maximum capacity');
    }

    // Check not already a member
    const [existingMember] = await conn.query<any[]>(
      'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
      [league.id, userId]
    );

    if (existingMember.length > 0) {
      throw new AppError(409, 'already_member', 'User is already a member of this league');
    }

    // Add user as league member
    const memberId = randomUUID();
    try {
      await conn.query(
        'INSERT INTO league_members (id, league_id, user_id, role) VALUES (?, ?, ?, ?)',
        [memberId, league.id, userId, 'member']
      );
    } catch (err: any) {
      if (err.code === 'ER_DUP_ENTRY') {
        throw new AppError(409, 'already_member', 'User is already a member of this league');
      }
      throw err;
    }

    // Create user's team
    const teamId = randomUUID();
    const finalTeamName = team_name || 'My Team';
    await conn.query(
      'INSERT INTO teams (id, league_id, owner_user_id, team_name) VALUES (?, ?, ?, ?)',
      [teamId, league.id, userId, finalTeamName]
    );

    await conn.commit();
    return league;
  } catch (err: any) {
    await conn.rollback();
    throw err;
  } finally {
    await conn.release();
  }
}

export async function getLeagueForMember(userId: string, leagueId: string): Promise<League> {
  const [leagueRows] = await pool.query<League[]>(
    'SELECT * FROM leagues WHERE id = ?',
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

  return leagueRows[0];
}

export async function listUserLeagues(userId: string): Promise<League[]> {
  const [rows] = await pool.query<League[]>(
    `SELECT l.* FROM leagues l
     INNER JOIN league_members lm ON l.id = lm.league_id
     WHERE lm.user_id = ?`,
    [userId]
  );

  return rows;
}

interface UpdateLeagueInput {
  name?: string;
  max_teams?: number;
  privacy?: 'private' | 'public';
  scoring_rules_json?: string | null;
}

export async function updateLeague(userId: string, leagueId: string, input: UpdateLeagueInput): Promise<League> {
  const [leagueRows] = await pool.query<League[]>(
    'SELECT * FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  const league = leagueRows[0];

  if (league.commissioner_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only commissioner can update league');
  }

  const allowedFields = ['name', 'max_teams', 'privacy', 'scoring_rules_json'];
  const updates: string[] = [];
  const values: any[] = [];

  for (const field of allowedFields) {
    if (field in input) {
      updates.push(`${field} = ?`);
      values.push((input as any)[field]);
    }
  }

  if (updates.length === 0) {
    return league;
  }

  values.push(leagueId);
  const sql = `UPDATE leagues SET ${updates.join(', ')} WHERE id = ?`;

  await pool.query(sql, values);

  const [updated] = await pool.query<League[]>(
    'SELECT * FROM leagues WHERE id = ?',
    [leagueId]
  );

  return updated[0];
}

export async function deleteLeague(userId: string, leagueId: string): Promise<void> {
  const [leagueRows] = await pool.query<League[]>(
    'SELECT * FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  const league = leagueRows[0];

  if (league.commissioner_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only commissioner can delete league');
  }

  await pool.query(
    'DELETE FROM leagues WHERE id = ?',
    [leagueId]
  );
}
