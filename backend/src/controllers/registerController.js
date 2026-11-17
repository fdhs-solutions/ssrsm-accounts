import { Product, Salesman, DailyStockRegister } from '../models/index.js';
import { sendSuccess, sendError, sendBadRequest } from '../utils/response.js';

// 1. Get All Products (Brands)
  export const getProducts = async (req, res) => {
    try {
      const products = await Product.findActive();
      return sendSuccess(res, products);
    } catch (error) {
      return sendError(res, error);
    }
  };

  // 2. Get Salesmen (Optional Product Filter)
    export const getSalesmen = async (req, res) => {
      try {
        const { productId } = req.query;
        const salesmen = await Salesman.find({ productId });
        return sendSuccess(res, salesmen);
      } catch (error) {
        return sendError(res, error);
      }
    };

    // 3. Add New Salesman
      export const addSalesman = async (req, res) => {
        try {
          const { name, productId } = req.body;
          if (!name || !productId) {
            return sendBadRequest(res, 'Name and Product are required');
          }

          const salesman = await Salesman.create({ name, productId });
          return sendSuccess(res, salesman, 201);
        } catch (error) {
          return sendError(res, error);
        }
      };

      // 4. Get Auto Opening Stock for a Product & Date
        export const getOpeningStock = async (req, res) => {
          try {
            const { productId, date } = req.query;
            if (!productId) {
              return sendBadRequest(res, 'productId is required');
            }

            const targetDate = date || new Date().toISOString().split('T')[0];

            // Find the latest previous entry before this date
            const prevClosingStock = await DailyStockRegister.findLatestClosingStockBefore(productId, targetDate);

              if (prevClosingStock !== null) {
                return res.json({ success: true, openingStock: prevClosingStock });
              }

              // If no previous entry exists, fallback to product default opening stock
              const defaultStock = await Product.getDefaultOpeningStock(productId);
              return res.json({ success: true, openingStock: defaultStock });
            } catch (error) {
              return sendError(res, error);
            }
          };

          // 5. Create Daily Register Entry
            export const createRegisterEntry = async (req, res) => {
              try {
                const {
                  entryDate,
                  productId,
                  salesmanId,
                  openingStock = 0,
                  newStock = 0,
                  dailySales = 0,
                  returnStock = 0,
                  cashAmount = 0,
                  chequeAmount = 0,
                  rtgsAmount = 0,
                  autoAmount = 0,
                  creditAmount = 0,
                  note = '',
      isExtraEntry = false,
                } = req.body;

                if (!productId || !entryDate) {
                  return sendBadRequest(res, 'productId and entryDate are required');
                }

                // Formula: Closing = Opening + New - Sales + Return
                const closingStock = (
                  parseFloat(openingStock) +
                  parseFloat(newStock) -
                  parseFloat(dailySales) +
                  parseFloat(returnStock)
                );

                if (closingStock < 0) {
                  return sendBadRequest(res, 'Sales cannot exceed available stock');
                }

                const newRegister = await DailyStockRegister.create({
                  entryDate,
                  productId,
                  salesmanId,
                  openingStock,
                  newStock,
                  dailySales,
                  returnStock,
                  closingStock,
                  cashAmount,
                  chequeAmount,
                  rtgsAmount,
                  autoAmount,
                  creditAmount,
                  note,
                  isExtraEntry,
                });

                return sendSuccess(res, newRegister, 201);
              } catch (error) {
                return sendError(res, error);
              }
            };

            // 6. Get Daily Stock Register List (With Date & Product Filters)
              export const getRegisters = async (req, res) => {
                try {
                  const { productId, startDate, endDate } = req.query;
                  const registers = await DailyStockRegister.findAll({ productId, startDate, endDate });
                  return sendSuccess(res, registers);
                } catch (error) {
                  return sendError(res, error);
                }
              };
