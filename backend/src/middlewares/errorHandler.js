/**
 * Async Handler Wrapper
 * Catches errors from async controller functions and automatically passes them to next(err)
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Global Error Handling Middleware
 * Standardizes errors across all routes & controllers in the application.
 */

export const errorHandler = (err, req, res, next) => {
  // If response has already started streaming/sent, delegate to default express handler
  if (res.headersSent) {
    return next(err);
  }

  console.error(`[API ERROR] ${req.method} ${req.originalUrl}:`, err);

  // 1. PostgreSQL Specific Errors
  if (err && typeof err === 'object') {
    // 23505: Unique constraint violation (Duplicate key) -> 409 Conflict
    if (err.code === '23505') {
      let message = 'Duplicate entry: A record with these details already exists.';
      if (err.detail) {
        // e.g. Key (name, product_id)=(w, uuid) already exists.
        message = err.detail.replace(/Key \((.*?)\)=\((.*?)\) already exists\./, '$1 "$2" already exists.');
      }
      return res.status(409).json({
        success: false,
        error: message,
        code: 'DUPLICATE_ENTRY',
      });
    }

    // 23503: Foreign key constraint violation -> 400 Bad Request
    if (err.code === '23503') {
      return res.status(400).json({
        success: false,
        error: 'Referenced record does not exist or cannot be deleted due to associated data.',
        code: 'FOREIGN_KEY_VIOLATION',
      });
    }

    // 23502: Not null constraint violation -> 400 Bad Request
    if (err.code === '23502') {
      return res.status(400).json({
        success: false,
        error: `Missing required field: ${err.column || 'unknown'}`,
        code: 'NOT_NULL_VIOLATION',
      });
    }

    // 22P02: Invalid input syntax (e.g. malformed UUID, bad numeric type) -> 400 Bad Request
    if (err.code === '22P02') {
      return res.status(400).json({
        success: false,
        error: 'Invalid input syntax format (e.g. malformed ID or numeric value).',
        code: 'INVALID_INPUT',
      });
    }
  }

  // 2. Custom App/HTTP Errors
  const statusCode = Number(err.statusCode || err.status) || 500;
  const errorMessage = err.message || 'Internal Server Error';

  return res.status(statusCode).json({
    success: false,
    error: errorMessage,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

/**
 * 404 Route Not Found Handler
 */
export const notFoundHandler = (req, res, next) => {
  return res.status(404).json({
    success: false,
    error: `API endpoint not found: ${req.method} ${req.originalUrl}`,
    code: 'ROUTE_NOT_FOUND',
  });
};
