import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { AppError } from '../utils/app-error.js';

export const authenticate = (req, res, next) => {
  try {
    let token = null;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.slice(7).trim();
    } else if (req.cookies?.access_token) {
      token = req.cookies.access_token;
    } else if (req.method === 'GET' && req.originalUrl.includes('/entries/pdf') && req.query?.token) {
      token = String(req.query.token).trim();
    }

    if (!token) {
      return next(new AppError('Authentication required', 401, 'UNAUTHORIZED'));
    }

    const decoded = jwt.verify(token, env.jwt.secret);
    req.user = {
      id: decoded.sub,
      username: decoded.username,
      role: decoded.role || 'admin',
    };
    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new AppError('Session expired. Please log in again.', 401, 'TOKEN_EXPIRED'));
    }
    return next(new AppError('Invalid authentication token', 401, 'INVALID_TOKEN'));
  }
};
