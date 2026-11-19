import express from 'express';
import * as stockCtrl from '../controllers/stockEntryController.js';

const router = express.Router();

// ==========================================
// Products Routes
// ==========================================
router.get('/products', stockCtrl.getProducts);

// ==========================================
// Salesmen Routes (Full CRUD)
// ==========================================
router.get('/salesmen', stockCtrl.getSalesmen);
router.post('/salesmen', stockCtrl.addSalesman);
router.put('/salesmen/:id', stockCtrl.updateSalesman);
router.delete('/salesmen/:id', stockCtrl.deleteSalesman);

// ==========================================
// Daily Stock Entries Routes (Full CRUD)
// ==========================================
router.get('/stock-entries/opening-stock', stockCtrl.getOpeningStock);
router.get('/stock-entries', stockCtrl.getStockEntries);
router.post('/stock-entries', stockCtrl.createStockEntry);
router.put('/stock-entries/:id', stockCtrl.updateStockEntry);
router.delete('/stock-entries/:id', stockCtrl.deleteStockEntry);

// Backward-compatibility aliases for /registers
router.get('/registers/opening-stock', stockCtrl.getOpeningStock);
router.get('/registers', stockCtrl.getStockEntries);
router.post('/registers', stockCtrl.createStockEntry);
router.put('/registers/:id', stockCtrl.updateStockEntry);
router.delete('/registers/:id', stockCtrl.deleteStockEntry);

export default router;
