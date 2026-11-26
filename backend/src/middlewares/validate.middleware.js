import { AppError } from '../utils/app-error.js';

export const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse({
    body: req.body,
    query: req.query,
    params: req.params,
  });

  if (!result.success) {
    const firstIssue = result.error.issues[0];
    const message = firstIssue?.message || 'Please check your input and try again.';
    return next(new AppError(message, 400, 'VALIDATION_ERROR'));
  }

  req.validated = result.data;
  return next();
};
