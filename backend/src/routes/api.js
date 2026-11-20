import express from 'express';
import { login } from '../controllers/login-controller.js';
import { getDashboardData } from '../controllers/dashboard-controller.js';
import * as salesmenCtrl from '../controllers/salesmen-Controller.js';
import * as stockCtrl from '../controllers/stockEntryController.js';

const router = express.Router();

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
router.get('/entries/opening-stock', stockCtrl.getOpeningStock);
router.get('/entries', stockCtrl.getEntries);
router.post('/entries', stockCtrl.createStockEntry);
router.put('/entries/:id', stockCtrl.updateStockEntry);
router.delete('/entries/:id', stockCtrl.deleteStockEntry);

export default router;
