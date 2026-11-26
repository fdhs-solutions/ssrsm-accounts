import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

const UNIQUE_CONSTRAINT_MESSAGES = {
  uq_salesmen_name_product_active: 'This sales man already exists for the selected product.',
  uq_products_name_active: 'A product with this name already exists.',
  users_users_username_key: 'This username is already taken.',
  users_users_email_key: 'This email is already registered.',
};

export const errorHandler = (err, req, res, next) => {
  if (res.headersSent) {
    return next(err);
  }

  // PostgreSQL error mapping (never expose raw column names, SQL casts, or UUIDs)
  if (err && typeof err === 'object' && err.code) {
    if (err.code === '23505') {
      logger.warn({ constraint: err.constraint, detail: err.detail }, 'Unique constraint violation');
      const message =
        UNIQUE_CONSTRAINT_MESSAGES[err.constraint] ||
        'This record already exists.';
      return res.status(409).json({
        success: false,
        error: message,
        message,
        code: 'DUPLICATE_ENTRY',
      });
    }

    if (err.code === '23503') {
      logger.warn({ constraint: err.constraint, detail: err.detail }, 'Foreign key violation');
      const message = 'Cannot complete this action because this item is linked to existing records.';
      return res.status(400).json({
        success: false,
        error: message,
        message,
        code: 'FOREIGN_KEY_VIOLATION',
      });
    }

    if (err.code === '23502') {
      logger.warn({ column: err.column }, 'Not-null violation');
      const message = 'Please fill in all required fields.';
      return res.status(400).json({
        success: false,
        error: message,
        message,
        code: 'NOT_NULL_VIOLATION',
      });
    }

    if (err.code === '23514') {
      logger.warn({ constraint: err.constraint }, 'Check constraint violation');
      const message = 'Values cannot be negative. Please check your numbers.';
      return res.status(400).json({
        success: false,
        error: message,
        message,
        code: 'INVALID_VALUE',
      });
    }

    if (err.code === '22P02') {
      logger.warn({ err: err.message }, 'Invalid input syntax');
      const message = 'Please enter valid values and try again.';
      return res.status(400).json({
        success: false,
        error: message,
        message,
        code: 'INVALID_INPUT',
      });
    }
  }

  const statusCode = Number(err.statusCode || err.status) || 500;
  const isServerError = statusCode >= 500;

  if (isServerError) {
    logger.error({ err, method: req.method, url: req.originalUrl }, 'Unhandled server error');
  } else {
    logger.warn({ err: err.message, statusCode, method: req.method, url: req.originalUrl }, 'Operational error');
  }

  const message = isServerError
    ? 'Something went wrong. Please try again.'
    : (err.message || 'Invalid request. Please try again.');

  return res.status(statusCode).json({
    success: false,
    error: message,
    message,
    code: err.code || (isServerError ? 'INTERNAL_ERROR' : 'BAD_REQUEST'),
    ...(env.nodeEnv === 'development' && isServerError && { stack: err.stack }),
  });
};

export const notFoundHandler = (req, res) => {
  const message = 'The requested action could not be found.';
  return res.status(404).json({
    success: false,
    error: message,
    message,
    code: 'ROUTE_NOT_FOUND',
  });
};
