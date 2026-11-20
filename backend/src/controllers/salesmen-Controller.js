import { Product, Salesman } from '../models/index.js';
import { sendSuccess, sendError, sendBadRequest } from '../utils/response.js';

// GET /api/salesmen
export const getSalesmen = async (req, res) => {
  try {
    const { productId } = req.query;
    let actualProductId = productId;

    if (productId) {
      const isUuid = /^[0-9a-fA-F-]{36}$/.test(productId);
      if (!isUuid) {
        const allProds = await Product.findActive();
        const matched = allProds.find(
          p => p.name.toLowerCase() === productId.toLowerCase()
        );
        if (matched) {
          actualProductId = matched.id;
        }
      }
    }

    const salesmen = await Salesman.find({ productId: actualProductId });
    return sendSuccess(res, salesmen);
  } catch (error) {
    return sendError(res, error);
  }
};

// POST /api/salesmen
export const addSalesman = async (req, res) => {
  try {
    const { name, productId } = req.body;
    if (!name || !productId) {
      return sendBadRequest(res, 'Name and Product are required');
    }

    let actualProductId = productId;
    // If brand name like 'Dettol', 'Dabur', 'Diaper' was sent, lookup UUID
    const isUuid = /^[0-9a-fA-F-]{36}$/.test(productId);
    if (!isUuid) {
      const allProds = await Product.findActive();
      const matched = allProds.find(
        p => p.name.toLowerCase() === productId.toLowerCase()
      );
      if (matched) {
        actualProductId = matched.id;
      }
    }

    const salesman = await Salesman.create({ name, productId: actualProductId });
    return sendSuccess(res, salesman, 201);
  } catch (error) {
    return sendError(res, error);
  }
};

// PUT /api/salesmen/:id (Update Salesman)
export const updateSalesman = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, productId } = req.body;

    if (!name && !productId) {
      return sendBadRequest(res, 'At least name or productId is required to update');
    }

    const updated = await Salesman.update(id, { name, productId });
    if (!updated) {
      return sendError(res, 'Salesman not found', 404);
    }

    return sendSuccess(res, updated, 200, 'Salesman updated successfully');
  } catch (error) {
    return sendError(res, error);
  }
};

// DELETE /api/salesmen/:id (Delete Salesman)
export const deleteSalesman = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Salesman.delete(id);

    if (!deleted) {
      return sendError(res, 'Salesman not found', 404);
    }

    return sendSuccess(res, deleted, 200, 'Salesman deleted successfully');
  } catch (error) {
    return sendError(res, error);
  }
};
