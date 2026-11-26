import express from 'express';
import { getProducts } from '../controllers/product.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';

const router = express.Router();

router.get('/', authenticate, getProducts);

export default router;
