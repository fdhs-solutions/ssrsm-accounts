import express from 'express';
import * as salesmanCtrl from '../controllers/salesman.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';
import { validate } from '../middlewares/validate.middleware.js';
import {
  getSalesmenSchema,
  createSalesmanSchema,
  updateSalesmanSchema,
  salesmanIdParamSchema,
} from '../validators/salesman.validator.js';

const router = express.Router();

router.use(authenticate);

router.get('/', validate(getSalesmenSchema), salesmanCtrl.getSalesmen);
router.post('/', validate(createSalesmanSchema), salesmanCtrl.addSalesman);
router.put('/:id', validate(updateSalesmanSchema), salesmanCtrl.updateSalesman);
router.delete('/:id', validate(salesmanIdParamSchema), salesmanCtrl.deleteSalesman);

export default router;
