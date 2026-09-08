import { Router } from 'express';
import { isEmail } from 'validator';
import { asyncHandler } from '../lib/asyncHandler';
import { registerUser, loginUser } from '../services/authService';

const router = Router();

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

    if (!isEmail(email)) {
      res.status(400).json({
        error: 'validation_error',
        message: 'A valid email address is required',
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
