import { sendSuccess, sendError } from '../utils/response.js';

export const login = async (req, res, next) => {
  try {
    const { username, password } = req.query;

    if (!username || !password) {
      return sendError(res, 'Username and password are required', 400);
    }

    const adminUser = process.env.ADMIN_USERNAME || process.env.USER_NAME;
    const adminPass = process.env.ADMIN_PASSWORD || process.env.USER_PASSWORD;

    if (username === adminUser && password === adminPass) {
      return sendSuccess(res, null, 200, 'Login successful');
    } else {
      return sendError(res, 'Invalid credentials', 401);
    }
  } catch (error) {
    return next(error);
  }
};
