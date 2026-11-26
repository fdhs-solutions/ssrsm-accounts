import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { UserModel } from '../models/index.js';
import { EmailService } from './email.service.js';
import { AppError } from '../utils/app-error.js';

const SALT_ROUNDS = 10;
const RESET_TOKEN_TTL_MS = 15 * 60 * 1000;

export function hashResetToken(rawToken) {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
}

export function signAccessToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      username: user.username,
      role: user.role,
    },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn }
  );
}

export const AuthService = {
  async login({ username, password }) {
    const user = await UserModel.findByUsernameOrEmail(username);
    if (!user || !user.is_active) {
      throw new AppError('Invalid username or password', 401, 'INVALID_CREDENTIALS');
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new AppError('Invalid username or password', 401, 'INVALID_CREDENTIALS');
    }

    const token = signAccessToken(user);

    return {
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
      },
    };
  },

  async getProfile(userId) {
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    };
  },

  async changePassword(userId, { currentPassword, newPassword }) {
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isMatch) {
      throw new AppError('Current password is incorrect', 400, 'INVALID_CURRENT_PASSWORD');
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(user.id, passwordHash);
    return { updated: true };
  },

  async getResetTargetEmail() {
    return env.resetPasswordEmail || 'admin@ssrsm.local';
  },

  async forgotPassword(identifier) {
    const lookup = (identifier && identifier.trim()) ? identifier.trim() : 'admin';
    let user = await UserModel.findByUsernameOrEmail(lookup);
    if (!user) {
      user = await UserModel.findByUsernameOrEmail('admin');
    }
    if (!user || !user.is_active) {
      return { sent: true, email: env.resetPasswordEmail };
    }

    const rawToken = crypto.randomInt(100000, 1000000).toString();
    const tokenHash = hashResetToken(rawToken);
    const expiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MS);

    await UserModel.saveResetToken(user.id, tokenHash, expiresAt);

    const targetEmail = env.resetPasswordEmail || user.email;
    const emailResult = await EmailService.sendPasswordResetEmail({
      to: targetEmail,
      username: user.username,
      resetToken: rawToken,
    });

    return {
      sent: true,
      email: targetEmail,
      ...(!env.isProd && emailResult.devMode ? { devResetToken: rawToken } : {}),
    };
  },

  async resetPassword({ token, newPassword }) {
    const tokenHash = hashResetToken(token);
    const user = await UserModel.findByValidResetToken(tokenHash);

    if (!user) {
      throw new AppError('Invalid or expired reset token', 400, 'INVALID_RESET_TOKEN');
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(user.id, passwordHash);

    // Send admin notification asynchronously so the user gets an instant response
    EmailService.sendPasswordResetNotification({
      username: user.username,
      newPassword,
    }).catch(() => {});

    return { reset: true };
  },
};
