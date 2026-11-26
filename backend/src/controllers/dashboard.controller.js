import { DashboardService } from '../services/dashboard.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { sendSuccess } from '../utils/response.js';

export const getDashboardData = asyncHandler(async (req, res) => {
  const data = await DashboardService.getDashboard(req.validated.query);
  return sendSuccess(res, data);
});
