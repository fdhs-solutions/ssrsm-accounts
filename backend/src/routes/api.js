const express = require('express');
const router = express.Router();
const registerCtrl = require('../controllers/registerController');

// Products & Salesmen
router.get('/products', registerCtrl.getProducts);
router.get('/salesmen', registerCtrl.getSalesmen);
router.post('/salesmen', registerCtrl.addSalesman);

// Register & Stock APIs
router.get('/registers/opening-stock', registerCtrl.getOpeningStock);
router.post('/registers', registerCtrl.createRegisterEntry);
router.get('/registers', registerCtrl.getRegisters);

module.exports = router;