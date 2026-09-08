import { Router } from 'express';
import { asyncHandler } from '../lib/asyncHandler';
import { validate } from '../lib/validate';
import { registerSchema, loginSchema } from '../schemas/authSchemas';
import { registerUser, loginUser } from '../services/authService';

const router = Router();

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const input = validate(registerSchema, req.body);
    const user = await registerUser(input);
    res.status(201).json({ user });
  })
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const input = validate(loginSchema, req.body);
    const result = await loginUser(input);
    res.status(200).json(result);
  })
);

export default router;
