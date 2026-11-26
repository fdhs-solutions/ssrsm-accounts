import { execFile } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { promisify } from 'util';
import dotenv from 'dotenv';

dotenv.config();

const execFileAsync = promisify(execFile);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKUP_DIR = path.resolve(__dirname, '../../database/backups');
const MAX_BACKUPS_TO_KEEP = 14;

async function backupDatabase() {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });

  const now = new Date();
  const stamp = now.toISOString().replace(/[:.]/g, '-');
  const dbName = process.env.DB_NAME || 'ssrsm_accounts';
  const filePath = path.join(BACKUP_DIR, `${dbName}_${stamp}.sql`);

  const args = [
    '-h', process.env.DB_HOST || 'localhost',
    '-p', String(process.env.DB_PORT || 5432),
    '-U', process.env.DB_USER || 'postgres',
    '-F', 'p',
    '--clean',
    '--if-exists',
    '-f', filePath,
    dbName,
  ];

  console.log(`Creating PostgreSQL backup: ${filePath}`);
  await execFileAsync('pg_dump', args, {
    env: { ...process.env, PGPASSWORD: process.env.DB_PASSWORD || '' },
  });

  // Prune older backups beyond retention limit
  const files = fs.readdirSync(BACKUP_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort()
    .reverse();

  for (const oldFile of files.slice(MAX_BACKUPS_TO_KEEP)) {
    fs.unlinkSync(path.join(BACKUP_DIR, oldFile));
  }

  console.log(`Backup completed: ${filePath}`);
}

backupDatabase().catch((err) => {
  console.error('Database backup failed:', err.message);
  process.exit(1);
});
