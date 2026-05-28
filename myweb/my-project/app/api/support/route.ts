import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'

let _tableReady = false
async function ensureTable() {
  if (_tableReady) return
  await pool.query(`
    CREATE TABLE IF NOT EXISTS support_messages (
      id          INT AUTO_INCREMENT PRIMARY KEY,
      store_id    VARCHAR(255) NOT NULL,
      store_name  VARCHAR(255),
      sender_role ENUM('store','admin') NOT NULL DEFAULT 'store',
      sender_name VARCHAR(255),
      message     TEXT NOT NULL,
      is_read     TINYINT(1) NOT NULL DEFAULT 0,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_store   (store_id),
      INDEX idx_created (created_at)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `)
  _tableReady = true
}

// GET /api/support?type=threads|unread
export async function GET(req: Request) {
  await ensureTable()
  const { searchParams } = new URL(req.url)
  const type = searchParams.get('type')

  if (type === 'unread') {
    const [rows]: any = await pool.query(
      `SELECT COUNT(*) AS total FROM support_messages WHERE sender_role = 'store' AND is_read = 0`
    )
    return NextResponse.json({ count: Number(rows[0].total) })
  }

  // threads list
  const [rows]: any = await pool.query(`
    SELECT
      sm.store_id,
      MAX(sm.store_name) AS store_name,
      (SELECT message     FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_message,
      (SELECT sender_role FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_role,
      (SELECT created_at  FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_at,
      SUM(CASE WHEN sm.sender_role = 'store' AND sm.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
    FROM support_messages sm
    GROUP BY sm.store_id
    ORDER BY last_at DESC
  `)
  return NextResponse.json(rows)
}
