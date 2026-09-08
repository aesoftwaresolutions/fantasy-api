import { Response } from 'express';
import { AuthedRequest } from '../middleware/auth';

export function asyncHandler(fn: (req: AuthedRequest, res: Response) => Promise<void>) {
  return (req: AuthedRequest, res: Response, next: any) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}
