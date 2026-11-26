import { ProductModel } from '../models/index.js';
import { AppError } from '../utils/app-error.js';
import { isUuid } from '../utils/formatters.js';

export const ProductService = {
  async listActive() {
    const products = await ProductModel.findActive();
    return products.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category,
      defaultOpeningStock: parseFloat(p.default_opening_stock || 0),
    }));
  },

  /**
   * Resolves either a UUID or a brand name (e.g. "Dettol") to an active product record.
   * Returns null if allowAll is true and input is empty or "all".
   */
  async resolveProduct(productIdOrName, { allowAll = false } = {}) {
    if (!productIdOrName || (allowAll && productIdOrName.toLowerCase() === 'all')) {
      return null;
    }

    const product = isUuid(productIdOrName)
      ? await ProductModel.findById(productIdOrName)
      : await ProductModel.findByName(productIdOrName);

    if (!product) {
      throw new AppError(`Product not found: ${productIdOrName}`, 404, 'PRODUCT_NOT_FOUND');
    }

    return product;
  },
};
