import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('a valid email address is required'),
  password: z.string().min(8, 'password must be at least 8 characters'),
  display_name: z.string().min(1, 'display_name is required').max(50),
  birth_date: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().min(1, 'email is required'),
  password: z.string().min(1, 'password is required'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
