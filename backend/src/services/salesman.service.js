import { SalesmanModel } from '../models/index.js';
import { ProductService } from './product.service.js';
import { AppError } from '../utils/app-error.js';

export const SalesmanService = {
  async list({ productId }) {
    const product = await ProductService.resolveProduct(productId, { allowAll: true });
    return SalesmanModel.find({ productId: product?.id });
  },

  async create({ name, productId, phone }) {
    const product = await ProductService.resolveProduct(productId);
    return SalesmanModel.create({ name, productId: product.id, phone });
  },

  async update(id, { name, productId, phone }) {
    let resolvedProductId;
    if (productId !== undefined) {
      const product = await ProductService.resolveProduct(productId);
      resolvedProductId = product.id;
    }

    const updated = await SalesmanModel.update(id, {
      name,
      productId: resolvedProductId,
      phone,
    });

    if (!updated) {
      throw new AppError('Salesman not found', 404, 'SALESMAN_NOT_FOUND');
    }
    return updated;
  },

  async remove(id) {
    const deleted = await SalesmanModel.delete(id);
    if (!deleted) {
      throw new AppError('Salesman not found', 404, 'SALESMAN_NOT_FOUND');
    }
    return deleted;
  },
};
