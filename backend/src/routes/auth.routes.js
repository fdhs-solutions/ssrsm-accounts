import express from 'express';
import * as authCtrl from '../controllers/auth.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';
import { authRateLimiter } from '../middlewares/rate-limit.middleware.js';
import { validate } from '../middlewares/validate.middleware.js';
import {
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
} from '../validators/auth.validator.js';

const router = express.Router();

router.post('/login', authRateLimiter, validate(loginSchema), authCtrl.login);
router.post('/logout', authCtrl.logout);
router.get('/reset-target', authCtrl.getResetTarget);
router.post('/forgot-password', authRateLimiter, validate(forgotPasswordSchema), authCtrl.forgotPassword);
router.post('/reset-password', authRateLimiter, validate(resetPasswordSchema), authCtrl.resetPassword);

router.get('/me', authenticate, authCtrl.getMe);
router.post('/change-password', authenticate, validate(changePasswordSchema), authCtrl.changePassword);

export default router;
