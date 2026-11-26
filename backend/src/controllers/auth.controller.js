import { AuthService } from '../services/auth.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { sendSuccess } from '../utils/response.js';
import { env } from '../config/env.js';

const COOKIE_OPTIONS = {
  httpOnly: true,
  sameSite: 'lax',
  secure: env.isProd,
  maxAge: 7 * 24 * 60 * 60 * 1000,
  path: '/',
};

export const login = asyncHandler(async (req, res) => {
  const { username, password } = req.validated.body;
  const result = await AuthService.login({ username, password });

  // Set HttpOnly cookie for Web clients AND return token in JSON for Mobile/Desktop native clients
  res.cookie('access_token', result.token, COOKIE_OPTIONS);
  return sendSuccess(res, result, 200, 'Login successful');
});

export const logout = asyncHandler(async (req, res) => {
  res.clearCookie('access_token', { path: '/' });
  return sendSuccess(res, null, 200, 'Logged out successfully');
});

export const getMe = asyncHandler(async (req, res) => {
  const profile = await AuthService.getProfile(req.user.id);
  return sendSuccess(res, profile);
});

export const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.validated.body;
  await AuthService.changePassword(req.user.id, { currentPassword, newPassword });
  return sendSuccess(res, null, 200, 'Password updated successfully');
});

export const getResetTarget = asyncHandler(async (req, res) => {
  const email = await AuthService.getResetTargetEmail();
  return sendSuccess(res, { email });
});

export const forgotPassword = asyncHandler(async (req, res) => {
  const { identifier, email } = req.validated.body || {};
  const result = await AuthService.forgotPassword(identifier || email);
  return sendSuccess(
    res,
    {
      email: result.email,
      ...(result.devResetToken ? { devResetToken: result.devResetToken } : {}),
    },
    200,
    `A 6-digit reset code has been sent to ${result.email}.`
  );
});

export const resetPassword = asyncHandler(async (req, res) => {
  const { token, newPassword } = req.validated.body;
  await AuthService.resetPassword({ token, newPassword });
  return sendSuccess(res, null, 200, 'Password reset successful. Please log in with your new password.');
});
