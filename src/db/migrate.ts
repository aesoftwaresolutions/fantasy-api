import mysql from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import config from '../config/env';

async function runMigrations() {
  let connection;
  try {
    // Create connection without selecting a database
    connection = await mysql.createConnection({
      host: config.db.host,
      port: config.db.port,
      user: config.db.user,
      password: config.db.password,
      multipleStatements: true,
    });

    const migrationPath = path.join(__dirname, '../../db/migrations/001_init.sql');
    const sql = fs.readFileSync(migrationPath, 'utf-8');

    console.log('Running migration: 001_init.sql');
    await connection.query(sql);
    console.log('Migration completed successfully');

    await connection.end();
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    if (connection) {
      await connection.end();
    }
    process.exit(1);
  }
}

runMigrations();
