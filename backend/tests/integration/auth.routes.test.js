import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import bcrypt from 'bcryptjs';

vi.mock('../../src/config/db.js', () => ({
  default: { query: vi.fn(), pool: { end: vi.fn() } },
  query: vi.fn(),
  pool: { query: vi.fn(), end: vi.fn() },
}));

import { createApp } from '../../src/app.js';
import db from '../../src/config/db.js';

const app = createApp();

describe('Auth Routes', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('POST /api/auth/login returns JWT token and sets HttpOnly cookie', async () => {
    const hash = await bcrypt.hash('Admin@1234', 10);
    db.query.mockResolvedValueOnce({
      rows: [
        {
          id: '11111111-1111-1111-1111-111111111111',
          username: 'admin',
          email: 'admin@ssrsm.local',
          password_hash: hash,
          role: 'admin',
          is_active: true,
        },
      ],
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'Admin@1234' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeTruthy();
    expect(res.body.data.user.username).toBe('admin');
    expect(res.headers['set-cookie']?.[0]).toContain('access_token=');
  });

  it('POST /api/auth/login rejects invalid password with 401', async () => {
    const hash = await bcrypt.hash('Admin@1234', 10);
    db.query.mockResolvedValueOnce({
      rows: [
        {
          id: '11111111-1111-1111-1111-111111111111',
          username: 'admin',
          email: 'admin@ssrsm.local',
          password_hash: hash,
          role: 'admin',
          is_active: true,
        },
      ],
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'WrongPassword' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/auth/forgot-password returns 200 and devResetToken in non-prod', async () => {
    db.query
      .mockResolvedValueOnce({
        rows: [
          {
            id: '11111111-1111-1111-1111-111111111111',
            username: 'admin',
            email: 'admin@ssrsm.local',
            is_active: true,
          },
        ],
      })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ identifier: 'admin' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.devResetToken).toBeTruthy();
  });

  it('POST /api/auth/reset-password resets password for valid token', async () => {
    db.query
      .mockResolvedValueOnce({
        rows: [
          {
            id: '11111111-1111-1111-1111-111111111111',
            username: 'admin',
            email: 'admin@ssrsm.local',
          },
        ],
      })
      .mockResolvedValueOnce({
        rows: [{ id: '11111111-1111-1111-1111-111111111111', username: 'admin' }],
      });

    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: '482910', newPassword: 'NewPassword@123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('GET /api/products rejects unauthenticated requests with 401', async () => {
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(401);
    expect(res.body.code).toBe('UNAUTHORIZED');
  });
});
