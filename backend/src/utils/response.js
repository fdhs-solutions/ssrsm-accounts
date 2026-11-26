export const sendSuccess = (res, data = undefined, statusCode = 200, message = null) => {
  const response = { success: true };
  if (message) response.message = message;
  if (data !== undefined) response.data = data;
  return res.status(statusCode).json(response);
};

export const sendError = (res, message, statusCode = 500, code = 'ERROR') => {
  return res.status(statusCode).json({
    success: false,
    error: message,
    message,
    code,
  });
};
