import { createApp } from './app.js';
import { env } from './config/env.js';
import { pool } from './config/db.js';
import { logger } from './config/logger.js';

const app = createApp();
let server;
let isShuttingDown = false;

async function startServer() {
  try {
    await pool.query('SELECT 1');
    logger.info({ database: env.db.database }, 'Connected to PostgreSQL');

    server = app.listen(env.port, () => {
      logger.info({ port: env.port, env: env.nodeEnv }, `Server running on http://localhost:${env.port}`);
    });
  } catch (err) {
    logger.fatal({ err }, 'Failed to start server');
    process.exit(1);
  }
}

async function gracefulShutdown(signal, exitCode = 0) {
  if (isShuttingDown) return;
  isShuttingDown = true;

  logger.info({ signal }, 'Graceful shutdown initiated');

  const forceExitTimer = setTimeout(() => {
    logger.error('Graceful shutdown timed out; forcing exit');
    process.exit(1);
  }, 10000);
  forceExitTimer.unref();

  try {
    if (server) {
      await new Promise((resolve) => server.close(resolve));
      logger.info('HTTP server closed');
    }
    await pool.end();
    logger.info('PostgreSQL pool closed');
    process.exit(exitCode);
  } catch (err) {
    logger.error({ err }, 'Error during graceful shutdown');
    process.exit(1);
  }
}

process.on('SIGINT', () => gracefulShutdown('SIGINT', 0));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM', 0));

process.on('unhandledRejection', (reason) => {
  logger.error({ err: reason }, 'Unhandled Promise Rejection');
  gracefulShutdown('unhandledRejection', 1);
});

process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Uncaught Exception');
  gracefulShutdown('uncaughtException', 1);
});

startServer();
