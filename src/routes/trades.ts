import { Router, Request, Response } from 'express';

const router = Router();

router.get('/', (req: Request, res: Response) => {
  res.status(501).json({ error: 'not_implemented', message: 'trades endpoints not yet implemented' });
});

router.get('/:id', (req: Request, res: Response) => {
  res.status(501).json({ error: 'not_implemented', message: 'trades endpoints not yet implemented' });
});

router.post('/', (req: Request, res: Response) => {
  res.status(501).json({ error: 'not_implemented', message: 'trades endpoints not yet implemented' });
});

router.put('/:id', (req: Request, res: Response) => {
  res.status(501).json({ error: 'not_implemented', message: 'trades endpoints not yet implemented' });
});

router.delete('/:id', (req: Request, res: Response) => {
  res.status(501).json({ error: 'not_implemented', message: 'trades endpoints not yet implemented' });
});

export default router;
