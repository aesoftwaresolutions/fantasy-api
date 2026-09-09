import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { asyncHandler } from '../lib/asyncHandler';
import { validate } from '../lib/validate';
import {
  createDraftSchema,
  startDraftSchema,
  makePickSchema,
} from '../schemas/draftSchemas';
import * as draftService from '../services/draftService';

const router = Router();

router.post(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.body.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id is required' });
      return;
    }

    const input = validate(createDraftSchema, req.body);

    const draft = await draftService.createDraft(req.user!.id, leagueId, input);
    res.status(201).json({ draft });
  })
);

router.post(
  '/:id/start',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.body.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id is required' });
      return;
    }

    const input = validate(startDraftSchema, req.body);

    const draft = await draftService.startDraft(
      req.user!.id,
      leagueId,
      req.params.id,
      input.rounds ?? 15
    );
    res.status(200).json({ draft });
  })
);

router.get(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.query.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id query parameter is required' });
      return;
    }

    const state = await draftService.getDraftState(req.user!.id, leagueId, req.params.id);
    res.status(200).json(state);
  })
);

router.post(
  '/:id/pick',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.body.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id is required' });
      return;
    }

    const { player_id } = validate(makePickSchema, req.body);

    const pick = await draftService.makePick(req.user!.id, leagueId, req.params.id, player_id);
    res.status(201).json({ pick });
  })
);

export default router;
