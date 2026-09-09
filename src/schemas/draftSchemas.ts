import { z } from 'zod';

export const createDraftSchema = z.object({
  draft_type: z.enum(['snake', 'auction']).optional(),
  scheduled_at: z.string().optional(),
});

export const startDraftSchema = z.object({
  rounds: z.number().int().gte(1).lte(30).optional(),
});

export const makePickSchema = z.object({
  player_id: z.string().min(1),
});

export type CreateDraftBody = z.infer<typeof createDraftSchema>;
export type StartDraftBody = z.infer<typeof startDraftSchema>;
export type MakePickBody = z.infer<typeof makePickSchema>;
