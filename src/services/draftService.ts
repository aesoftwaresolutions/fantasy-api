import { randomUUID } from 'crypto';
import pool from '../db/pool';
import { AppError } from '../lib/AppError';
import { RowDataPacket, ResultSetHeader } from 'mysql2/promise';

interface Draft extends RowDataPacket {
  id: string;
  league_id: string;
  draft_type: 'snake' | 'auction';
  status: 'scheduled' | 'in_progress' | 'completed';
  scheduled_at: string | null;
  completed_at: string | null;
}

interface DraftPick extends RowDataPacket {
  id: string;
  draft_id: string;
  team_id: string;
  player_id: string | null;
  round_number: number;
  pick_number: number;
  auction_amount: number | null;
  picked_at: string | null;
}

interface CreateDraftInput {
  draft_type?: 'snake' | 'auction';
  scheduled_at?: string;
}

interface DraftPickWithTeamAndPlayer extends DraftPick {
  team_name: string;
  full_name?: string;
  position?: string;
}

interface DraftState {
  draft: Draft;
  picks: DraftPickWithTeamAndPlayer[];
  on_the_clock: {
    pick_number: number;
    round_number: number;
    team_id: string;
    team_name: string;
  } | null;
}

export async function createDraft(
  userId: string,
  leagueId: string,
  input: CreateDraftInput
): Promise<Draft> {
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
    throw new AppError(403, 'forbidden', 'Only commissioner can create drafts');
  }

  const draft_type = input.draft_type || 'snake';

  // Only snake is supported this pass
  if (draft_type === 'auction') {
    throw new AppError(400, 'auction_not_supported', 'Auction drafts are not yet supported');
  }

  const draftId = randomUUID();
  const scheduled_at = input.scheduled_at || null;

  await pool.query(
    'INSERT INTO drafts (id, league_id, draft_type, status, scheduled_at) VALUES (?, ?, ?, ?, ?)',
    [draftId, leagueId, draft_type, 'scheduled', scheduled_at]
  );

  const [rows] = await pool.query<Draft[]>(
    'SELECT * FROM drafts WHERE id = ?',
    [draftId]
  );

  return rows[0];
}

export async function startDraft(
  userId: string,
  leagueId: string,
  draftId: string,
  rounds: number = 15
): Promise<Draft> {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Load draft
    const [draftRows] = await conn.query<Draft[]>(
      'SELECT * FROM drafts WHERE id = ? AND league_id = ?',
      [draftId, leagueId]
    );

    if (!draftRows.length) {
      throw new AppError(404, 'draft_not_found', 'Draft not found');
    }

    const draft = draftRows[0];

    // Check league exists and user is commissioner
    const [leagueRows] = await conn.query<any[]>(
      'SELECT commissioner_id FROM leagues WHERE id = ?',
      [leagueId]
    );

    if (!leagueRows.length) {
      throw new AppError(404, 'league_not_found', 'League not found');
    }

    const league = leagueRows[0];
    if (league.commissioner_id !== userId) {
      throw new AppError(403, 'forbidden', 'Only commissioner can start draft');
    }

    // Check draft status
    if (draft.status !== 'scheduled') {
      throw new AppError(409, 'draft_not_scheduled', 'Draft has already started or completed');
    }

    // Load teams in draft order
    const [teamRows] = await conn.query<any[]>(
      'SELECT id FROM teams WHERE league_id = ? ORDER BY created_at ASC, id ASC',
      [leagueId]
    );

    if (teamRows.length < 2) {
      throw new AppError(400, 'not_enough_teams', 'Need at least 2 teams to draft');
    }

    // Generate snake picks
    const teamsAsc = teamRows.map((t) => t.id);
    const pickRows: any[] = [];
    let overall = 1;

    for (let r = 1; r <= rounds; r++) {
      const order = r % 2 === 1 ? teamsAsc : [...teamsAsc].reverse();
      for (const teamId of order) {
        pickRows.push({
          id: randomUUID(),
          draft_id: draftId,
          team_id: teamId,
          round_number: r,
          pick_number: overall,
        });
        overall++;
      }
    }

    // Batch-INSERT all pick rows
    if (pickRows.length > 0) {
      const placeholders = pickRows.map(() => '(?, ?, ?, ?, ?)').join(',');
      const values = pickRows.flatMap((p) => [
        p.id,
        p.draft_id,
        p.team_id,
        p.round_number,
        p.pick_number,
      ]);

      await conn.query(
        `INSERT INTO draft_picks (id, draft_id, team_id, round_number, pick_number) VALUES ${placeholders}`,
        values
      );
    }

    // Update draft status
    await conn.query('UPDATE drafts SET status = ? WHERE id = ?', ['in_progress', draftId]);

    await conn.commit();

    const [updated] = await pool.query<Draft[]>(
      'SELECT * FROM drafts WHERE id = ?',
      [draftId]
    );

    return updated[0];
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    await conn.release();
  }
}

export async function getDraftState(
  userId: string,
  leagueId: string,
  draftId: string
): Promise<DraftState> {
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

  // Load draft
  const [draftRows] = await pool.query<Draft[]>(
    'SELECT * FROM drafts WHERE id = ? AND league_id = ?',
    [draftId, leagueId]
  );

  if (!draftRows.length) {
    throw new AppError(404, 'draft_not_found', 'Draft not found');
  }

  const draft = draftRows[0];

  // Load picks joined to team_name and player
  const [pickRows] = await pool.query<DraftPickWithTeamAndPlayer[]>(
    `SELECT dp.*, t.team_name, p.full_name, p.position
     FROM draft_picks dp
     JOIN teams t ON dp.team_id = t.id
     LEFT JOIN players p ON dp.player_id = p.id
     WHERE dp.draft_id = ?
     ORDER BY dp.pick_number ASC`,
    [draftId]
  );

  // Find on_the_clock: first pick with player_id IS NULL
  let on_the_clock: DraftState['on_the_clock'] = null;
  const firstUnpicked = pickRows.find((p) => p.player_id === null);
  if (firstUnpicked) {
    on_the_clock = {
      pick_number: firstUnpicked.pick_number,
      round_number: firstUnpicked.round_number,
      team_id: firstUnpicked.team_id,
      team_name: firstUnpicked.team_name,
    };
  }

  return {
    draft,
    picks: pickRows,
    on_the_clock,
  };
}

export async function makePick(
  userId: string,
  leagueId: string,
  draftId: string,
  playerId: string
): Promise<DraftPick> {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Load draft
    const [draftRows] = await conn.query<Draft[]>(
      'SELECT * FROM drafts WHERE id = ? AND league_id = ?',
      [draftId, leagueId]
    );

    if (!draftRows.length) {
      throw new AppError(404, 'draft_not_found', 'Draft not found');
    }

    const draft = draftRows[0];

    if (draft.status !== 'in_progress') {
      throw new AppError(409, 'draft_not_active', 'Draft is not in progress');
    }

    // Find current pick
    const [currentPickRows] = await conn.query<DraftPick[]>(
      'SELECT * FROM draft_picks WHERE draft_id = ? AND player_id IS NULL ORDER BY pick_number ASC LIMIT 1',
      [draftId]
    );

    if (!currentPickRows.length) {
      throw new AppError(409, 'draft_complete', 'All picks have been made');
    }

    const currentPick = currentPickRows[0];

    // Get team info
    const [teamRows] = await conn.query<any[]>(
      'SELECT owner_user_id FROM teams WHERE id = ?',
      [currentPick.team_id]
    );

    const team = teamRows[0];

    // Get league commissioner for authorization check
    const [leagueRows] = await conn.query<any[]>(
      'SELECT commissioner_id FROM leagues WHERE id = ?',
      [leagueId]
    );

    const league = leagueRows[0];

    // Authorization: team owner or commissioner
    const isTeamOwner = team.owner_user_id === userId;
    const isCommissioner = league.commissioner_id === userId;

    if (!isTeamOwner && !isCommissioner) {
      throw new AppError(403, 'not_on_the_clock', 'It is not your turn to pick');
    }

    // Validate player exists
    const [playerRows] = await conn.query<any[]>(
      'SELECT id FROM players WHERE id = ?',
      [playerId]
    );

    if (!playerRows.length) {
      throw new AppError(404, 'player_not_found', 'Player not found');
    }

    // Validate player not already drafted in THIS draft
    const [draftedRows] = await conn.query<any[]>(
      'SELECT id FROM draft_picks WHERE draft_id = ? AND player_id = ?',
      [draftId, playerId]
    );

    if (draftedRows.length > 0) {
      throw new AppError(409, 'player_already_drafted', 'That player is already drafted');
    }

    // Update the draft pick
    await conn.query('UPDATE draft_picks SET player_id = ?, picked_at = NOW() WHERE id = ?', [
      playerId,
      currentPick.id,
    ]);

    // Insert player onto roster
    try {
      await conn.query(
        'INSERT INTO roster_slots (id, team_id, player_id, slot_type, roster_position) VALUES (?, ?, ?, ?, ?)',
        [randomUUID(), currentPick.team_id, playerId, 'bench', null]
      );
    } catch (err: any) {
      if (err.code === 'ER_DUP_ENTRY') {
        // Ignore duplicate: draft pick is source of truth
      } else {
        throw err;
      }
    }

    // Check if all picks are done
    const [remainingRows] = await conn.query<any[]>(
      'SELECT COUNT(*) as cnt FROM draft_picks WHERE draft_id = ? AND player_id IS NULL',
      [draftId]
    );

    if (remainingRows[0].cnt === 0) {
      await conn.query('UPDATE drafts SET status = ?, completed_at = NOW() WHERE id = ?', [
        'completed',
        draftId,
      ]);
    }

    await conn.commit();

    // Return the updated pick
    const [updated] = await pool.query<DraftPick[]>(
      'SELECT * FROM draft_picks WHERE id = ?',
      [currentPick.id]
    );

    return updated[0];
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    await conn.release();
  }
}
