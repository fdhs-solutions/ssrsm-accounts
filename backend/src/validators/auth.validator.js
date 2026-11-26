import { z } from 'zod';

export const loginSchema = z.object({
  body: z.object({
    username: z.string().trim().min(1, 'Username is required'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    identifier: z.string().trim().optional(),
    email: z.string().trim().optional(),
  }).optional().default({}),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    token: z.string().trim().min(6, 'Valid 6-digit reset code is required'),
    newPassword: z.string().min(6, 'New password must be at least 6 characters'),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: z.string().min(6, 'New password must be at least 6 characters'),
  }),
});
