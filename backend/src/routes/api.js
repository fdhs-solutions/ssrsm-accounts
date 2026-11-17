import express from 'express';
import * as registerCtrl from '../controllers/registerController.js';

const router = express.Router();

// Products & Salesmen
router.get('/products', registerCtrl.getProducts);
router.get('/salesmen', registerCtrl.getSalesmen);
router.post('/salesmen', registerCtrl.addSalesman);

// Register & Stock APIs
router.get('/registers/opening-stock', registerCtrl.getOpeningStock);
router.post('/registers', registerCtrl.createRegisterEntry);
router.get('/registers', registerCtrl.getRegisters);

export default router;
