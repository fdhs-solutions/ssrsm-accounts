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
