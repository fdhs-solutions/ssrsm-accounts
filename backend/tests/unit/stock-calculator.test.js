import { describe, it, expect } from 'vitest';
import { calculateClosingStock } from '../../src/services/entry.service.js';

describe('calculateClosingStock', () => {
  it('computes closing stock correctly for valid inputs', () => {
    const result = calculateClosingStock({
      openingStock: 100,
      newStock: 50,
      dailySales: 30,
      stockReceived: 10,
    });
    expect(result).toBe(130);
  });

  it('rounds floating point values to 2 decimal places', () => {
    const result = calculateClosingStock({
      openingStock: 10.15,
      newStock: 5.25,
      dailySales: 2.1,
      stockReceived: 0,
    });
    expect(result).toBe(13.3);
  });

  it('throws when daily sales exceed available stock', () => {
    expect(() =>
      calculateClosingStock({
        openingStock: 20,
        newStock: 10,
        dailySales: 50,
        stockReceived: 0,
      })
    ).toThrow('Daily sales cannot exceed available stock');
  });

  it('throws when any stock value is negative or NaN', () => {
    expect(() =>
      calculateClosingStock({
        openingStock: 'not-a-number',
        newStock: 0,
        dailySales: 0,
        stockReceived: 0,
      })
    ).toThrow('Stock values must be valid non-negative numbers');

    expect(() =>
      calculateClosingStock({
        openingStock: -5,
        newStock: 0,
        dailySales: 0,
        stockReceived: 0,
      })
    ).toThrow('Stock values must be valid non-negative numbers');
  });
});
