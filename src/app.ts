import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
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
app.use(cors());
app.use(express.json());

// Health check routes (no auth required)
app.use('/', healthRouter);

// Auth routes (no auth required)
app.use('/api/auth', authRouter);

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
