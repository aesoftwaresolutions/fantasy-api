import { z } from 'zod';

export const createMatchupSchema = z.object({
  week_number: z.number().int().gte(1).lte(30),
  team_a_id: z.string().min(1),
  team_b_id: z.string().min(1),
});

export const updateMatchupSchema = z
  .object({
    team_a_score: z.number().gte(0).optional(),
    team_b_score: z.number().gte(0).optional(),
    status: z.enum(['scheduled', 'in_progress', 'final']).optional(),
  })
  .refine((obj) => Object.keys(obj).length > 0, {
    message: 'no updatable fields provided',
  });

export type CreateMatchupBody = z.infer<typeof createMatchupSchema>;
export type UpdateMatchupBody = z.infer<typeof updateMatchupSchema>;
