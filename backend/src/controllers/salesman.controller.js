import { SalesmanService } from '../services/salesman.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { sendSuccess } from '../utils/response.js';

export const getSalesmen = asyncHandler(async (req, res) => {
  const { productId } = req.validated.query;
  const salesmen = await SalesmanService.list({ productId });
  return sendSuccess(res, salesmen);
});

export const addSalesman = asyncHandler(async (req, res) => {
  const { name, productId, phone } = req.validated.body;
  const salesman = await SalesmanService.create({ name, productId, phone });
  return sendSuccess(res, salesman, 201, 'Salesman created successfully');
});

export const updateSalesman = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const updated = await SalesmanService.update(id, req.validated.body);
  return sendSuccess(res, updated, 200, 'Salesman updated successfully');
});

export const deleteSalesman = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const deleted = await SalesmanService.remove(id);
  return sendSuccess(res, deleted, 200, 'Salesman deleted successfully');
});
