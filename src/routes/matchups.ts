import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { asyncHandler } from '../lib/asyncHandler';
import { validate } from '../lib/validate';
import { createMatchupSchema, updateMatchupSchema } from '../schemas/matchupSchemas';
import * as matchupService from '../services/matchupService';

const router = Router();

router.get(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.query.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id query parameter is required' });
      return;
    }

    const weekParam = req.query.week as string | undefined;
    let week: number | undefined;
    if (weekParam !== undefined) {
      week = parseInt(weekParam, 10);
      if (isNaN(week)) {
        week = undefined;
      }
    }

    const matchups = await matchupService.listMatchups(req.user!.id, leagueId, week);
    res.status(200).json({ matchups });
  })
);

router.post(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.body.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id is required' });
      return;
    }

    const { week_number, team_a_id, team_b_id } = validate(createMatchupSchema, {
      week_number: req.body.week_number,
      team_a_id: req.body.team_a_id,
      team_b_id: req.body.team_b_id,
    });

    const matchup = await matchupService.createMatchup(req.user!.id, leagueId, {
      week_number,
      team_a_id,
      team_b_id,
    });

    res.status(201).json({ matchup });
  })
);

router.patch(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagueId = req.body.league_id as string;
    if (!leagueId) {
      res.status(400).json({ error: 'validation_error', message: 'league_id is required' });
      return;
    }

    // Validate the body directly: Zod strips league_id and other unknown keys,
    // and absent score fields stay absent so the "no fields" refine can fire.
    const input = validate(updateMatchupSchema, req.body);

    const matchup = await matchupService.updateMatchupScore(req.user!.id, leagueId, req.params.id, input);
    res.status(200).json({ matchup });
  })
);

export default router;
