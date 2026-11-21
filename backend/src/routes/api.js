import express from 'express';
import { login } from '../controllers/login-controller.js';
import { getDashboardData } from '../controllers/dashboard-controller.js';
import * as salesmenCtrl from '../controllers/salesmen-Controller.js';
import * as stockCtrl from '../controllers/stockEntryController.js';
import { generateRegisterPdf } from '../controllers/pdf-controller.js';
import { Product } from '../models/index.js';
import { sendSuccess, sendError } from '../utils/response.js';

const router = express.Router();

// ==========================================
// 0. Products (GET)
// ==========================================
router.get('/products', async (req, res) => {
  try {
    const products = await Product.findActive();
    // Return clean fields
    const mapped = products.map(p => ({
      id: p.id,
      name: p.name,
      category: p.category,
      defaultOpeningStock: parseFloat(p.default_opening_stock || 0),
    }));
    return sendSuccess(res, mapped);
  } catch (error) {
    return sendError(res, error);
  }
});

// ==========================================
// 1. Login (GET)
// ==========================================
router.get('/login', login);

// ==========================================
// 2. Dashboard / Home Page Analytics (GET)
// ==========================================
router.get('/dashboard', getDashboardData);

// ==========================================
// 3. Salesmen CRUD (GET, POST, PUT, DELETE)
// ==========================================
router.get('/salesmen', salesmenCtrl.getSalesmen);
router.post('/salesmen', salesmenCtrl.addSalesman);
router.put('/salesmen/:id', salesmenCtrl.updateSalesman);
router.delete('/salesmen/:id', salesmenCtrl.deleteSalesman);

// ==========================================
// 4. Entries CRUD (GET, POST, PUT, DELETE)
// ==========================================
router.get('/entries/pdf', generateRegisterPdf);
router.get('/entries/opening-stock', stockCtrl.getOpeningStock);
router.get('/entries', stockCtrl.getEntries);
router.post('/entries', stockCtrl.createStockEntry);
router.put('/entries/:id', stockCtrl.updateStockEntry);
router.delete('/entries/:id', stockCtrl.deleteStockEntry);

export default router;
