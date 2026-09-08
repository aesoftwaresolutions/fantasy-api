import { Request, Response, NextFunction } from 'express';

export function notFound(req: Request, res: Response): void {
  res.status(404).json({
    error: 'not_found',
    message: `Route ${req.originalUrl} not found`,
  });
}

export function errorHandler(err: any, req: Request, res: Response, next: NextFunction): void {
  console.error(err);

  const status = err.status || 500;
  const message = err.message || 'Internal server error';

  res.status(status).json({
    error: err.error || 'internal_error',
    message,
  });
}
