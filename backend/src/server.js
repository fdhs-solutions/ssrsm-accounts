const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./config/db');
const apiRoutes = require('./routes/api');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api', apiRoutes);

// Health check API
app.get('/api/health', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW()');
    res.json({
      status: 'OK',
      message: 'SSRSM Accounts Backend is running smoothly!',
      db_time: result.rows[0].now,
    });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', error: error.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(` Server is running on http://localhost:${PORT}`);
});