import express from 'express';
import * as entryCtrl from '../controllers/entry.controller.js';
import { generateRegisterPdf } from '../controllers/pdf.controller.js';
import { authenticate } from '../middlewares/auth.middleware.js';
import { validate } from '../middlewares/validate.middleware.js';
import {
  openingStockSchema,
  getEntriesSchema,
  createEntrySchema,
  updateEntrySchema,
  entryIdParamSchema,
  bulkDeleteEntriesSchema,
} from '../validators/entry.validator.js';

const router = express.Router();

router.use(authenticate);

router.get('/pdf', generateRegisterPdf);
router.get('/opening-stock', validate(openingStockSchema), entryCtrl.getOpeningStock);
router.get('/', validate(getEntriesSchema), entryCtrl.getEntries);
router.post('/', validate(createEntrySchema), entryCtrl.createStockEntry);
router.post('/bulk-delete', validate(bulkDeleteEntriesSchema), entryCtrl.deleteMultipleStockEntries);
router.put('/:id', validate(updateEntrySchema), entryCtrl.updateStockEntry);
router.delete('/:id', validate(entryIdParamSchema), entryCtrl.deleteStockEntry);

export default router;
