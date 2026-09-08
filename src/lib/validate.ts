import { ZodSchema } from 'zod';
import { AppError } from './AppError';

// Parse `data` against a Zod schema, returning the typed, unknown-key-stripped
// value. On failure, throw an AppError that the central error handler renders
// as a 400 { error: 'validation_error', message }.
export function validate<T>(schema: ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    const first = result.error.issues[0];
    const path = first.path.join('.');
    const message = path ? `${path}: ${first.message}` : first.message;
    throw new AppError(400, 'validation_error', message);
  }
  return result.data;
}
