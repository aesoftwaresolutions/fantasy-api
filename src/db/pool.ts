import mysql, { RowDataPacket } from 'mysql2/promise';
import config from '../config/env';

const pool = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  connectionLimit: 10,
  waitForConnections: true,
  queueLimit: 0,
});

export default pool;

export async function query<T extends RowDataPacket>(
  sql: string,
  values?: any[]
): Promise<T[]> {
  const [rows] = await pool.query<T[]>(sql, values || []);
  return rows;
}
