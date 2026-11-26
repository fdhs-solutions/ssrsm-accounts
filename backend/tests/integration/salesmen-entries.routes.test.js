import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';

vi.mock('../../src/config/db.js', () => ({
  default: { query: vi.fn(), pool: { end: vi.fn() } },
  query: vi.fn(),
  pool: { query: vi.fn(), end: vi.fn() },
}));

import { createApp } from '../../src/app.js';
import db from '../../src/config/db.js';
import { signAccessToken } from '../../src/services/auth.service.js';

const app = createApp();
const authToken = signAccessToken({
  id: '11111111-1111-1111-1111-111111111111',
  username: 'admin',
  role: 'admin',
});

describe('Salesmen & Entries Routes', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('POST /api/salesmen resolves brand name to UUID and creates salesman', async () => {
    const productUuid = '22222222-2222-2222-2222-222222222222';
    db.query
      .mockResolvedValueOnce({ rows: [{ id: productUuid, name: 'Dettol', default_opening_stock: 145 }] })
      .mockResolvedValueOnce({
        rows: [{ id: '33333333-3333-3333-3333-333333333333', name: 'Amit', product_id: productUuid, is_active: true }],
      });

    const res = await request(app)
      .post('/api/salesmen')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Amit', productId: 'Dettol' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Amit');
  });

  it('POST /api/entries rejects negative closing stock', async () => {
    const productUuid = '22222222-2222-2222-2222-222222222222';
    db.query.mockResolvedValueOnce({ rows: [{ id: productUuid, name: 'Dettol' }] });

    const res = await request(app)
      .post('/api/entries')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        entryDate: '2026-11-26',
        productId: productUuid,
        openingStock: 10,
        newStock: 0,
        dailySales: 50,
        stockReceived: 0,
      });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe('NEGATIVE_CLOSING_STOCK');
  });

  it('GET /api/dashboard returns summary, mode breakdown, salesmen, and trend', async () => {
    db.query
      .mockResolvedValueOnce({
        rows: [
          {
            total_opening_stock: '100',
            total_closing_stock: '80',
            total_sales: '20',
            total_new_stock: '0',
            total_stock_received: '0',
            total_cash: '500',
            total_cheque: '0',
            total_rtgs: '0',
            total_auto: '0',
            total_credit: '0',
            total_collection: '500',
          },
        ],
      })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({
        rows: [
          { entry_date: '2026-11-26', daily_sales: '20', total_collection: '500', cash_amount: '500' },
        ],
      });

    const res = await request(app)
      .get('/api/dashboard?productId=all')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalSales).toBe(20);
    expect(res.body.data.dailyTrend).toHaveLength(1);
  });
});
