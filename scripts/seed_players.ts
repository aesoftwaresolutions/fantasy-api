import { parse } from 'csv-parse/sync';
import pool from '../src/db/pool';
import { ResultSetHeader } from 'mysql2/promise';
import { randomUUID } from 'crypto';

interface NflversePlayer {
  gsis_id?: string;
  display_name?: string;
  position?: string;
  latest_team?: string;
  status?: string;
  headshot?: string;
}

interface PlayerRow {
  id: string;
  external_provider_id: string;
  full_name: string;
  position: string;
  nfl_team: string | null;
  status: 'active' | 'injured' | 'inactive' | 'retired';
  photo_url: string | null;
}

function mapStatus(nflverseStatus?: string): 'active' | 'injured' | 'inactive' | 'retired' {
  switch (nflverseStatus?.toUpperCase()) {
    case 'ACT':
      return 'active';
    case 'RET':
      return 'retired';
    case 'PUP':
    case 'RES':
      return 'injured';
    default:
      return 'inactive';
  }
}

async function seedPlayers() {
  try {
    console.log('Fetching nflverse players dataset...');
    const response = await fetch(
      'https://github.com/nflverse/nflverse-data/releases/download/players/players.csv'
    );

    if (!response.ok) {
      throw new Error(`Failed to fetch CSV: ${response.statusText}`);
    }

    const csvText = await response.text();
    console.log('Parsing CSV...');
    const rows = parse(csvText, { columns: true, skip_empty_lines: true }) as NflversePlayer[];

    console.log(`Loaded ${rows.length} rows from CSV`);

    const playersToInsert: PlayerRow[] = [];
    let skipped = 0;

    for (const row of rows) {
      const { gsis_id, display_name, position, latest_team, status, headshot } = row;

      // Skip rows with missing required fields
      if (!gsis_id || !display_name || !position) {
        skipped++;
        continue;
      }

      // Truncate nfl_team to 5 chars max
      let nfl_team = latest_team || null;
      if (nfl_team && nfl_team.length > 5) {
        nfl_team = nfl_team.substring(0, 5);
      }

      // Set photo_url to null if over 255 chars
      let photo_url = headshot || null;
      if (photo_url && photo_url.length > 255) {
        photo_url = null;
      }

      playersToInsert.push({
        id: randomUUID(),
        external_provider_id: gsis_id,
        full_name: display_name,
        position,
        nfl_team,
        status: mapStatus(status),
        photo_url,
      });
    }

    console.log(`Prepared ${playersToInsert.length} players for insert (${skipped} skipped)`);

    // Insert in batches of 500
    const BATCH_SIZE = 500;
    let insertedCount = 0;

    for (let i = 0; i < playersToInsert.length; i += BATCH_SIZE) {
      const batch = playersToInsert.slice(i, i + BATCH_SIZE);
      const placeholders = batch.map(() => '(?, ?, ?, ?, ?, ?, ?)').join(', ');
      const flatParams = batch.flatMap((p) => [
        p.id,
        p.external_provider_id,
        p.full_name,
        p.position,
        p.nfl_team,
        p.status,
        p.photo_url,
      ]);

      const sql = `
        INSERT INTO players (id, external_provider_id, full_name, position, nfl_team, status, photo_url)
        VALUES ${placeholders}
        ON DUPLICATE KEY UPDATE
          full_name = VALUES(full_name),
          position = VALUES(position),
          nfl_team = VALUES(nfl_team),
          status = VALUES(status),
          photo_url = VALUES(photo_url)
      `;

      await pool.query<ResultSetHeader>(sql, flatParams);
      insertedCount += batch.length;
      console.log(`Progress: ${insertedCount}/${playersToInsert.length} rows processed`);
    }

    console.log(`Seeding complete! Inserted/updated ${insertedCount} players (${skipped} skipped).`);
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('Error seeding players:', error);
    await pool.end();
    process.exit(1);
  }
}

seedPlayers();
