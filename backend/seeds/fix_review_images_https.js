// Fixes review image URLs stored as http:// → https://
// Run once: node seeds/fix_review_images_https.js
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
    "SELECT id, images FROM reviews WHERE images LIKE '%http://%'"
  );
  console.log(`Found ${rows.length} reviews with http:// image URLs`);

  let updated = 0;
  for (const row of rows) {
    try {
      const fixed = row.images
        .replace(/http:\/\/localhost:\d+\//g, `https://${process.env.BACKEND_HOST || 'backend-gqls.onrender.com'}/`)
        .replace(/http:\/\//g, 'https://');
      await db.query('UPDATE reviews SET images = ? WHERE id = ?', [fixed, row.id]);
      updated++;
    } catch (e) {
      console.error(`Row ${row.id} failed:`, e.message);
    }
  }
  console.log(`Updated ${updated} rows.`);
  process.exit(0);
}

fix().catch(e => { console.error(e); process.exit(1); });
