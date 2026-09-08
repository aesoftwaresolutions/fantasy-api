import { Router, Response } from 'express';
import { AuthedRequest } from '../middleware/auth';
import { registerUser, loginUser } from '../services/authService';

const router = Router();

function asyncHandler(fn: (req: AuthedRequest, res: Response) => Promise<void>) {
  return (req: AuthedRequest, res: Response, next: any) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { email, password, display_name, birth_date } = req.body;

    if (!email || !password || !display_name) {
      res.status(400).json({
        error: 'validation_error',
        message: 'email, password, and display_name are required',
      });
      return;
    }

    const user = await registerUser({ email, password, display_name, birth_date });
    res.status(201).json({ user });
  })
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({
        error: 'validation_error',
        message: 'email and password are required',
      });
      return;
    }

    const result = await loginUser({ email, password });
    res.status(200).json(result);
  })
);

export default router;
