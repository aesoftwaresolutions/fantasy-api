import { randomUUID } from 'crypto';
import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket, ResultSetHeader } from 'mysql2/promise';

interface Matchup extends RowDataPacket {
  id: string;
  league_id: string;
  week_number: number;
  team_a_id: string;
  team_b_id: string;
  team_a_score: number;
  team_b_score: number;
  status: 'scheduled' | 'in_progress' | 'final';
}

interface Standing extends RowDataPacket {
  team_id: string;
  team_name: string;
  wins: number;
  losses: number;
  ties: number;
  points_for: number;
  points_against: number;
}

interface CreateMatchupInput {
  week_number: number;
  team_a_id: string;
  team_b_id: string;
}

interface UpdateMatchupInput {
  team_a_score?: number;
  team_b_score?: number;
  status?: 'scheduled' | 'in_progress' | 'final';
}

export async function listMatchups(userId: string, leagueId: string, week?: number): Promise<Matchup[]> {
  // Check league exists
  const [leagueRows] = await pool.query<any[]>(
    'SELECT id FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  // Check user is member
  const [memberRows] = await pool.query<any[]>(
    'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
    [leagueId, userId]
  );

  if (!memberRows.length) {
    throw new AppError(403, 'forbidden', 'Access denied');
  }

  // Fetch matchups
  let sql = 'SELECT * FROM matchups WHERE league_id = ?';
  const params: any[] = [leagueId];

  if (week !== undefined) {
    sql += ' AND week_number = ?';
    params.push(week);
  }

  sql += ' ORDER BY week_number ASC';

  const [rows] = await pool.query<Matchup[]>(sql, params);

  // Coerce scores to numbers
  return rows.map((row) => ({
    ...row,
    team_a_score: Number(row.team_a_score),
    team_b_score: Number(row.team_b_score),
  }));
}

export async function createMatchup(userId: string, leagueId: string, input: CreateMatchupInput): Promise<Matchup> {
  const { week_number, team_a_id, team_b_id } = input;

  // Check league exists
  const [leagueRows] = await pool.query<any[]>(
    'SELECT commissioner_id FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  // Check user is commissioner
  const league = leagueRows[0];
  if (league.commissioner_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only commissioner can create matchups');
  }

  // Validate teams are different
  if (team_a_id === team_b_id) {
    throw new AppError(400, 'validation_error', 'a team cannot play itself');
  }

  // Verify both teams exist and belong to this league
  const [teamARows] = await pool.query<any[]>(
    'SELECT id FROM teams WHERE id = ? AND league_id = ?',
    [team_a_id, leagueId]
  );

  if (!teamARows.length) {
    throw new AppError(400, 'team_not_in_league', 'Team A not found in this league');
  }

  const [teamBRows] = await pool.query<any[]>(
    'SELECT id FROM teams WHERE id = ? AND league_id = ?',
    [team_b_id, leagueId]
  );

  if (!teamBRows.length) {
    throw new AppError(400, 'team_not_in_league', 'Team B not found in this league');
  }

  const matchupId = randomUUID();

  await pool.query(
    'INSERT INTO matchups (id, league_id, week_number, team_a_id, team_b_id) VALUES (?, ?, ?, ?, ?)',
    [matchupId, leagueId, week_number, team_a_id, team_b_id]
  );

  const [rows] = await pool.query<Matchup[]>(
    'SELECT * FROM matchups WHERE id = ?',
    [matchupId]
  );

  const matchup = rows[0];
  return {
    ...matchup,
    team_a_score: Number(matchup.team_a_score),
    team_b_score: Number(matchup.team_b_score),
  };
}

export async function updateMatchupScore(
  userId: string,
  leagueId: string,
  matchupId: string,
  input: UpdateMatchupInput
): Promise<Matchup> {
  // Check league exists
  const [leagueRows] = await pool.query<any[]>(
    'SELECT commissioner_id FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  // Check user is commissioner
  const league = leagueRows[0];
  if (league.commissioner_id !== userId) {
    throw new AppError(403, 'forbidden', 'Only commissioner can update matchups');
  }

  // Load matchup
  const [matchupRows] = await pool.query<Matchup[]>(
    'SELECT * FROM matchups WHERE id = ? AND league_id = ?',
    [matchupId, leagueId]
  );

  if (!matchupRows.length) {
    throw new AppError(404, 'matchup_not_found', 'Matchup not found');
  }

  // Build dynamic UPDATE from whitelist
  const allowedFields = ['team_a_score', 'team_b_score', 'status'];
  const updates: string[] = [];
  const values: any[] = [];

  for (const field of allowedFields) {
    if (field in input) {
      updates.push(`${field} = ?`);
      values.push((input as any)[field]);
    }
  }

  if (updates.length === 0) {
    throw new AppError(400, 'validation_error', 'no updatable fields provided');
  }

  values.push(matchupId);
  const sql = `UPDATE matchups SET ${updates.join(', ')} WHERE id = ?`;

  await pool.query(sql, values);

  const [updated] = await pool.query<Matchup[]>(
    'SELECT * FROM matchups WHERE id = ?',
    [matchupId]
  );

  const matchup = updated[0];
  return {
    ...matchup,
    team_a_score: Number(matchup.team_a_score),
    team_b_score: Number(matchup.team_b_score),
  };
}

export async function getStandings(userId: string, leagueId: string): Promise<Standing[]> {
  // Check league exists
  const [leagueRows] = await pool.query<any[]>(
    'SELECT id FROM leagues WHERE id = ?',
    [leagueId]
  );

  if (!leagueRows.length) {
    throw new AppError(404, 'league_not_found', 'League not found');
  }

  // Check user is member
  const [memberRows] = await pool.query<any[]>(
    'SELECT id FROM league_members WHERE league_id = ? AND user_id = ?',
    [leagueId, userId]
  );

  if (!memberRows.length) {
    throw new AppError(403, 'forbidden', 'Access denied');
  }

  // Get all teams in the league
  const [teamRows] = await pool.query<any[]>(
    'SELECT id, team_name FROM teams WHERE league_id = ?',
    [leagueId]
  );

  // Get all final matchups
  const [matchupRows] = await pool.query<Matchup[]>(
    'SELECT * FROM matchups WHERE league_id = ? AND status = ?',
    [leagueId, 'final']
  );

  // Coerce scores to numbers
  const finalMatchups = matchupRows.map((m) => ({
    ...m,
    team_a_score: Number(m.team_a_score),
    team_b_score: Number(m.team_b_score),
  }));

  // Build standings in JS
  const standingsMap = new Map<string, any>();

  for (const team of teamRows) {
    standingsMap.set(team.id, {
      team_id: team.id,
      team_name: team.team_name,
      wins: 0,
      losses: 0,
      ties: 0,
      points_for: 0,
      points_against: 0,
    });
  }

  for (const matchup of finalMatchups) {
    const teamA = standingsMap.get(matchup.team_a_id);
    const teamB = standingsMap.get(matchup.team_b_id);

    if (teamA && teamB) {
      teamA.points_for += matchup.team_a_score;
      teamA.points_against += matchup.team_b_score;
      teamB.points_for += matchup.team_b_score;
      teamB.points_against += matchup.team_a_score;

      if (matchup.team_a_score === matchup.team_b_score) {
        teamA.ties += 1;
        teamB.ties += 1;
      } else if (matchup.team_a_score > matchup.team_b_score) {
        teamA.wins += 1;
        teamB.losses += 1;
      } else {
        teamA.losses += 1;
        teamB.wins += 1;
      }
    }
  }

  // Sort by wins DESC, then points_for DESC
  const standings = Array.from(standingsMap.values()).sort((a, b) => {
    if (b.wins !== a.wins) {
      return b.wins - a.wins;
    }
    return b.points_for - a.points_for;
  });

  return standings;
}
