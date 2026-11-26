export const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export function isUuid(value) {
  return typeof value === 'string' && UUID_REGEX.test(value);
}

export function fmtNum(val) {
  if (val === null || val === undefined || val === '') return '';
  const num = parseFloat(val);
  if (Number.isNaN(num) || num === 0) return '';
  return num % 1 === 0
    ? num.toLocaleString('en-IN')
    : num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function fmtNumZero(val) {
  if (val === null || val === undefined || val === '') return '0';
  const num = parseFloat(val);
  if (Number.isNaN(num)) return '0';
  return num % 1 === 0
    ? num.toLocaleString('en-IN')
    : num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function fmtDate(iso) {
  if (!iso) return '';
  const clean = iso.toString().split('T')[0];
  const parts = clean.split('-');
  if (parts.length === 3) {
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
  return clean;
}
