/**
 * Standard API response helper utilities
 */

export const sendSuccess = (res, data, statusCode = 200, message = null) => {
  const response = { success: true };
  if (message) response.message = message;
  if (data !== undefined) response.data = data;
  return res.status(statusCode).json(response);
};

export const sendError = (res, error, statusCode = 500) => {
  // If PostgreSQL specific database errors occur, map to standard HTTP status codes
  if (error && typeof error === 'object') {
    // 23505: Unique violation (Duplicate key) -> 409 Conflict
    if (error.code === '23505') {
      let detail = 'Duplicate entry: A record with these details already exists.';
      if (error.detail) {
        detail = error.detail.replace(/Key \((.*?)\)=\((.*?)\) already exists\./, '$1 "$2" already exists.');
      } else if (error.message) {
        detail = error.message;
      }
      return res.status(409).json({
        success: false,
        error: detail,
        code: 'DUPLICATE_ENTRY',
      });
    }

    // 23503: Foreign key violation -> 400 Bad Request
    if (error.code === '23503') {
      return res.status(400).json({
        success: false,
        error: error.detail || 'Referenced record does not exist or is in use.',
        code: 'FOREIGN_KEY_VIOLATION',
      });
    }

    // 23502: Not null violation -> 400 Bad Request
    if (error.code === '23502') {
      return res.status(400).json({
        success: false,
        error: `Missing required field: ${error.column || 'unknown'}`,
        code: 'NOT_NULL_VIOLATION',
      });
    }

    // 22P02: Invalid text representation (e.g. invalid UUID syntax) -> 400 Bad Request
    if (error.code === '22P02') {
      return res.status(400).json({
        success: false,
        error: 'Invalid input syntax format (e.g. malformed UUID or number)',
        code: 'INVALID_INPUT',
      });
    }
  }

  const errorMessage = error instanceof Error ? error.message : error;
  return res.status(statusCode).json({
    success: false,
    error: errorMessage,
  });
};

export const sendBadRequest = (res, message = 'Bad Request') => {
  return res.status(400).json({
    success: false,
    message,
  });
};
