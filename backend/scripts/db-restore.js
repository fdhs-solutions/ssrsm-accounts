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

async function restoreDatabase() {
  let targetFile = process.argv[2];

  if (!targetFile) {
    const files = fs.existsSync(BACKUP_DIR)
      ? fs.readdirSync(BACKUP_DIR).filter((f) => f.endsWith('.sql')).sort().reverse()
      : [];
    if (files.length === 0) {
      throw new Error(`No .sql backup files found in ${BACKUP_DIR}`);
    }
    targetFile = path.join(BACKUP_DIR, files[0]);
  } else if (!path.isAbsolute(targetFile)) {
    targetFile = path.resolve(process.cwd(), targetFile);
  }

  if (!fs.existsSync(targetFile)) {
    throw new Error(`Backup file not found: ${targetFile}`);
  }

  const dbName = process.env.DB_NAME || 'ssrsm_accounts';
  const args = [
    '-h', process.env.DB_HOST || 'localhost',
    '-p', String(process.env.DB_PORT || 5432),
    '-U', process.env.DB_USER || 'postgres',
    '-d', dbName,
    '-f', targetFile,
  ];

  console.log(`Restoring ${dbName} from: ${targetFile}`);
  await execFileAsync('psql', args, {
    env: { ...process.env, PGPASSWORD: process.env.DB_PASSWORD || '' },
  });

  console.log('Database restore completed successfully.');
}

restoreDatabase().catch((err) => {
  console.error('Database restore failed:', err.message);
  process.exit(1);
});
