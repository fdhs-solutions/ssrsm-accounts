import { describe, it, expect } from 'vitest';
import jwt from 'jsonwebtoken';
import { hashResetToken, signAccessToken } from '../../src/services/auth.service.js';
import { env } from '../../src/config/env.js';

describe('AuthService helpers', () => {
  it('hashResetToken produces deterministic 64-char SHA-256 hex', () => {
    const token = 'sample-reset-token';
    const hash1 = hashResetToken(token);
    const hash2 = hashResetToken(token);

    expect(hash1).toHaveLength(64);
    expect(hash1).toBe(hash2);
    expect(hash1).not.toBe(token);
  });

  it('signAccessToken creates verifiable JWT with user claims', () => {
    const token = signAccessToken({
      id: '11111111-1111-1111-1111-111111111111',
      username: 'admin',
      role: 'admin',
    });

    const decoded = jwt.verify(token, env.jwt.secret);
    expect(decoded.sub).toBe('11111111-1111-1111-1111-111111111111');
    expect(decoded.username).toBe('admin');
    expect(decoded.role).toBe('admin');
  });
});
