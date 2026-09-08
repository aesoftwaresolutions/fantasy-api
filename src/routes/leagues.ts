import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { asyncHandler } from '../lib/asyncHandler';
import * as leagueService from '../services/leagueService';
import { listLeagueTeams } from '../services/teamService';

const router = Router();

router.post(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const { name, season_year, format, privacy, max_teams, team_name } = req.body;

    if (!name || !season_year) {
      res.status(400).json({
        error: 'validation_error',
        message: 'name and season_year are required',
      });
      return;
    }

    const league = await leagueService.createLeague(req.user!.id, {
      name,
      season_year,
      format,
      privacy,
      max_teams,
      team_name,
    });

    res.status(201).json({ league });
  })
);

router.post(
  '/join',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const { invite_code, team_name } = req.body;

    if (!invite_code) {
      res.status(400).json({
        error: 'validation_error',
        message: 'invite_code is required',
      });
      return;
    }

    const league = await leagueService.joinLeague(req.user!.id, { invite_code, team_name });

    res.status(200).json({ league });
  })
);

router.get(
  '/',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const leagues = await leagueService.listUserLeagues(req.user!.id);
    res.status(200).json({ leagues });
  })
);

router.get(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const league = await leagueService.getLeagueForMember(req.user!.id, req.params.id);
    res.status(200).json({ league });
  })
);

router.get(
  '/:id/teams',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const teams = await listLeagueTeams(req.user!.id, req.params.id);
    res.status(200).json({ teams });
  })
);

router.patch(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    const league = await leagueService.updateLeague(req.user!.id, req.params.id, req.body);
    res.status(200).json({ league });
  })
);

router.delete(
  '/:id',
  asyncHandler(async (req: AuthedRequest, res: Response) => {
    await leagueService.deleteLeague(req.user!.id, req.params.id);
    res.status(204).send();
  })
);

export default router;
