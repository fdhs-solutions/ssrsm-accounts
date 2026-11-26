import express from 'express';
import authRoutes from './auth.routes.js';
import productRoutes from './product.routes.js';
import salesmanRoutes from './salesman.routes.js';
import entryRoutes from './entry.routes.js';
import dashboardRoutes from './dashboard.routes.js';

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/products', productRoutes);
router.use('/salesmen', salesmanRoutes);
router.use('/entries', entryRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;
