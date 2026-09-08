import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { asyncHandler } from '../lib/asyncHandler';
import * as teamService from '../services/teamService';
import * as rosterService from '../services/rosterService';

const router = Router();

router.get(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const team = await teamService.getTeam(req.user!.id, req.params.id);
    res.status(200).json({ team });
  })
);

router.patch(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const team = await teamService.updateTeam(req.user!.id, req.params.id, req.body);
    res.status(200).json({ team });
  })
);

router.get(
  '/:id/roster',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const roster = await rosterService.listRoster(req.user!.id, req.params.id);
    res.status(200).json({ roster });
  })
);

router.post(
  '/:id/roster',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const { player_id, slot_type, roster_position } = req.body;

    if (!player_id) {
      res.status(400).json({
        error: 'validation_error',
        message: 'player_id is required',
      });
      return;
    }

    const slot = await rosterService.addPlayer(req.user!.id, req.params.id, {
      player_id,
      slot_type,
      roster_position,
    });

    res.status(201).json({ slot });
  })
);

router.delete(
  '/:id/roster/:playerId',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    await rosterService.dropPlayer(req.user!.id, req.params.id, req.params.playerId);
    res.status(204).send();
  })
);

export default router;
