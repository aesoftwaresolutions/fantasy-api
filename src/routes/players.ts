import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { asyncHandler } from '../lib/asyncHandler';
import * as playerService from '../services/playerService';

const router = Router();

router.get(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const search = typeof req.query.search === 'string' ? req.query.search : undefined;
    const position = typeof req.query.position === 'string' ? req.query.position : undefined;
    const limit = parseInt(req.query.limit as string, 10) || undefined;
    const offset = parseInt(req.query.offset as string, 10) || undefined;

    const { players, total } = await playerService.listPlayers({ search, position, limit, offset });
    res.status(200).json({ players, total, limit: limit || 50, offset: offset || 0 });
  })
);

router.get(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const player = await playerService.getPlayer(req.params.id);
    res.status(200).json({ player });
  })
);

router.post(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const { external_provider_id, full_name, position, nfl_team, status, photo_url } = req.body;

    if (!external_provider_id || !full_name || !position) {
      res.status(400).json({
        error: 'validation_error',
        message: 'external_provider_id, full_name, and position are required',
      });
      return;
    }

    const player = await playerService.createPlayer({
      external_provider_id,
      full_name,
      position,
      nfl_team,
      status,
      photo_url,
    });

    res.status(201).json({ player });
  })
);

export default router;
