import { PdfService } from '../services/pdf.service.js';
import { asyncHandler } from '../utils/async-handler.js';

export const generateRegisterPdf = asyncHandler(async (req, res) => {
  const { productId, productName, startDate, endDate, download } = req.query;
  await PdfService.streamRegisterPdf(res, {
    productId,
    productName,
    startDate,
    endDate,
    download,
  });
});
