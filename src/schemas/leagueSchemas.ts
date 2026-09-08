import { z } from 'zod';

const format = z.enum(['redraft', 'dynasty', 'contract_dynasty']);
const privacy = z.enum(['private', 'public']);

export const createLeagueSchema = z.object({
  name: z.string().min(1, 'name is required').max(100),
  season_year: z.number().int().gte(2020).lte(2100),
  format: format.optional(),
  privacy: privacy.optional(),
  max_teams: z.number().int().gte(2).lte(20).optional(),
  team_name: z.string().max(50).optional(),
});

export const joinLeagueSchema = z.object({
  invite_code: z.string().min(1, 'invite_code is required'),
  team_name: z.string().max(50).optional(),
});

// All fields optional (partial update); unknown keys are stripped by Zod.
export const updateLeagueSchema = z
  .object({
    name: z.string().min(1).max(100).optional(),
    max_teams: z.number().int().gte(2).lte(20).optional(),
    privacy: privacy.optional(),
    scoring_rules_json: z.string().nullable().optional(),
  })
  .refine((obj) => Object.keys(obj).length > 0, {
    message: 'no updatable fields provided',
  });

export type CreateLeagueBody = z.infer<typeof createLeagueSchema>;
export type JoinLeagueBody = z.infer<typeof joinLeagueSchema>;
export type UpdateLeagueBody = z.infer<typeof updateLeagueSchema>;
