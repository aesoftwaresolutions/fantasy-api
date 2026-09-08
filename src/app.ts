import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import config from './config/env';
import { authenticate } from './middleware/auth';
import { errorHandler, notFound } from './middleware/errorHandler';

import healthRouter from './routes/health';
import authRouter from './routes/auth';
import leaguesRouter from './routes/leagues';
import teamsRouter from './routes/teams';
import playersRouter from './routes/players';
import rostersRouter from './routes/rosters';
import draftsRouter from './routes/drafts';
import tradesRouter from './routes/trades';
import waiversRouter from './routes/waivers';
import matchupsRouter from './routes/matchups';
import notificationsRouter from './routes/notifications';

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: config.allowedOrigins,
    credentials: true,
  })
);
app.use(express.json());

// Limit brute-force attempts against the auth endpoints.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
});

// Health check routes (no auth required)
app.use('/', healthRouter);

// Auth routes (no auth required, rate limited)
app.use('/api/auth', authLimiter, authRouter);

// Protected API routes
app.use('/api/leagues', authenticate, leaguesRouter);
app.use('/api/teams', authenticate, teamsRouter);
app.use('/api/players', authenticate, playersRouter);
app.use('/api/rosters', authenticate, rostersRouter);
app.use('/api/drafts', authenticate, draftsRouter);
app.use('/api/trades', authenticate, tradesRouter);
app.use('/api/waivers', authenticate, waiversRouter);
app.use('/api/matchups', authenticate, matchupsRouter);
app.use('/api/notifications', authenticate, notificationsRouter);

// 404 handler
app.use(notFound);

// Error handler (must be last)
app.use(errorHandler);

export default app;
