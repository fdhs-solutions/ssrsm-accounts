import { ProductService } from '../services/product.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { sendSuccess } from '../utils/response.js';

export const getProducts = asyncHandler(async (req, res) => {
  const products = await ProductService.listActive();
  return sendSuccess(res, products);
});
