import express from 'express';
import { getDashboardData } from '../controllers/dashboard.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';
import { validate } from '../middlewares/validate.middleware.js';
import { dashboardQuerySchema } from '../validators/dashboard.validator.js';

const router = express.Router();

router.get('/', authenticate, validate(dashboardQuerySchema), getDashboardData);

export default router;
