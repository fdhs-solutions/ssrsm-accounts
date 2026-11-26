import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { env } from './config/env.js';
import { httpLogger } from './config/logger.js';
import db from './config/db.js';
import apiRoutes from './routes/index.js';
import { apiRateLimiter } from './middlewares/rate-limit.middleware.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';

export function createApp() {
  const app = express();

  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin: (origin, callback) => {
        // Allow native mobile/desktop apps (no Origin header) or configured/localhost origins in dev
        if (!origin) return callback(null, true);
        if (!env.isProd && origin.startsWith('http://localhost')) {
          return callback(null, true);
        }
        if (env.corsOrigins.includes(origin)) {
          return callback(null, true);
        }
        return callback(new Error('Not allowed by CORS'));
      },
      credentials: true,
    })
  );

  app.use(cookieParser());
  app.use(express.json({ limit: '100kb' }));
  app.use(httpLogger);
  app.use('/api', apiRateLimiter);

  app.get('/api/health', async (req, res) => {
    try {
      const result = await db.query('SELECT NOW() AS db_time');
      return res.json({
        status: 'OK',
        message: 'SSRSM Accounts Backend is running smoothly!',
        db_time: result.rows[0].db_time,
      });
    } catch (error) {
      return res.status(503).json({
        status: 'ERROR',
        message: env.isProd ? 'Database unavailable' : error.message,
      });
    }
  });

  app.use('/api', apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
