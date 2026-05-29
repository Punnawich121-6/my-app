// Nulls out support message image_url values that point to ephemeral disk files
// (files saved with old disk-storage multer; they disappear on Render restart)
// Run once: node seeds/fix_support_images.js
require('dotenv').config();
const mysql = require('mysql2/promise');

const db = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: { minVersion: 'TLSv1.2', rejectUnauthorized: false },
});

async function fix() {
  const [rows] = await db.query(
    "SELECT id FROM support_messages WHERE image_url LIKE '%/uploads/support/%'"
  );
  console.log(`Found ${rows.length} support messages with broken file-path image URLs`);

  if (rows.length === 0) { console.log('Nothing to fix.'); process.exit(0); }

  const ids = rows.map(r => r.id);
  const [result] = await db.query(
    'UPDATE support_messages SET image_url = NULL WHERE id IN (?)',
    [ids]
  );
  console.log(`Cleared image_url on ${result.affectedRows} rows.`);
  process.exit(0);
}

fix().catch(e => { console.error(e); process.exit(1); });
