import { Router, Request, Response } from 'express';
import pool from '../db/pool';

const router = Router();

router.get('/', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', service: 'fantasy-api' });
});

router.get('/db', async (req: Request, res: Response, next: any) => {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    res.status(200).json({ db: 'ok' });
  } catch (error) {
    res.status(500).json({ db: 'error' });
  }
});

export default router;
