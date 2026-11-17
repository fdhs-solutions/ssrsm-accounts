const db = require('../config/db');

// 1. Get All Products (Brands)
exports.getProducts = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM products WHERE is_active = TRUE ORDER BY name ASC');
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// 2. Get Salesmen (Optional Product Filter)
exports.getSalesmen = async (req, res) => {
  try {
    const { productId } = req.query;
    let query = 'SELECT s.*, p.name as product_name FROM salesmen s LEFT JOIN products p ON s.product_id = p.id WHERE s.is_active = TRUE';
    const params = [];

    if (productId) {
      params.push(productId);
      query += ' AND s.product_id = $1';
    }
    query += ' ORDER BY s.name ASC';

    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// 3. Add New Salesman
exports.addSalesman = async (req, res) => {
  try {
    const { name, productId } = req.body;
    if (!name || !productId) {
      return res.status(400).json({ success: false, message: 'Name and Product are required' });
    }

    const result = await db.query(
      'INSERT INTO salesmen (name, product_id) VALUES ($1, $2) RETURNING *',
      [name.trim(), productId]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// 4. Get Auto Opening Stock for a Product & Date
exports.getOpeningStock = async (req, res) => {
  try {
    const { productId, date } = req.query;
    if (!productId) {
      return res.status(400).json({ success: false, message: 'productId is required' });
    }

    const targetDate = date || new Date().toISOString().split('T')[0];

    // Find the latest previous entry before this date
    const prevEntry = await db.query(
      `SELECT closing_stock FROM daily_stock_registers 
       WHERE product_id = $1 AND entry_date < $2 AND is_extra_entry = FALSE 
       ORDER BY entry_date DESC LIMIT 1`,
      [productId, targetDate]
    );

    if (prevEntry.rows.length > 0) {
      return res.json({ success: true, openingStock: parseFloat(prevEntry.rows[0].closing_stock) });
    }

    // If no previous entry exists, fallback to product default opening stock
    const prod = await db.query('SELECT default_opening_stock FROM products WHERE id = $1', [productId]);
    const defaultStock = prod.rows.length > 0 ? parseFloat(prod.rows[0].default_opening_stock) : 0;

    res.json({ success: true, openingStock: defaultStock });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// 5. Create Daily Register Entry
exports.createRegisterEntry = async (req, res) => {
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
      isExtraEntry = false
    } = req.body;

    if (!productId || !entryDate) {
      return res.status(400).json({ success: false, message: 'productId and entryDate are required' });
    }

    // Formula: Closing = Opening + New - Sales + Return
    const closingStock = (parseFloat(openingStock) + parseFloat(newStock) - parseFloat(dailySales) + parseFloat(returnStock));

    if (closingStock < 0) {
      return res.status(400).json({ success: false, message: 'Sales cannot exceed available stock' });
    }

    // Insert into DB
    const insertQuery = `
      INSERT INTO daily_stock_registers (
        entry_date, product_id, salesman_id,
        opening_stock, new_stock, daily_sales, return_stock, closing_stock,
        cash_amount, cheque_amount, rtgs_amount, auto_amount, credit_amount,
        note, is_extra_entry
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *;
    `;

    const values = [
      entryDate, productId, salesmanId || null,
      openingStock, newStock, dailySales, returnStock, closingStock,
      cashAmount, chequeAmount, rtgsAmount, autoAmount, creditAmount,
      note, isExtraEntry
    ];

    const result = await db.query(insertQuery, values);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// 6. Get Daily Stock Register List (With Date & Product Filters)
exports.getRegisters = async (req, res) => {
  try {
    const { productId, startDate, endDate } = req.query;

    let query = `
      SELECT r.*, p.name as product_name, s.name as salesman_name
      FROM daily_stock_registers r
      JOIN products p ON r.product_id = p.id
      LEFT JOIN salesmen s ON r.salesman_id = s.id
      WHERE 1=1
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      query += ` AND r.product_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      query += ` AND r.entry_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      query += ` AND r.entry_date <= $${params.length}`;
    }

    query += ' ORDER BY r.entry_date DESC, r.created_at DESC';

    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};