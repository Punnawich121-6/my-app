// fix_broken_images.js — แก้ Unsplash photo IDs ที่ถูกลบแล้ว
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

const FIXES = [
  {
    old: 'https://images.unsplash.com/photo-1617196034183-421b4040d20d?auto=format&fit=crop&w=400&q=80',
    new: 'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=400&q=80',
    label: 'แคลิฟอร์เนียโรล',
  },
  {
    old: 'https://images.unsplash.com/photo-1617196034096-7bed30d47b9d?auto=format&fit=crop&w=400&q=80',
    new: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?auto=format&fit=crop&w=400&q=80',
    label: 'เทมปุระโรล',
  },
];

async function fix() {
  for (const { old: oldUrl, new: newUrl, label } of FIXES) {
    const [result] = await db.query(
      'UPDATE menu_items SET image_url = ? WHERE image_url = ?',
      [newUrl, oldUrl]
    );
    console.log(`${label}: updated ${result.affectedRows} row(s)`);
  }
  console.log('Done.');
  process.exit(0);
}

fix().catch(e => { console.error(e); process.exit(1); });
