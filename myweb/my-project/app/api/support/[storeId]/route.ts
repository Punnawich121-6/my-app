import { NextRequest, NextResponse } from 'next/server'
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
      image_url   VARCHAR(500),
      is_read     TINYINT(1) NOT NULL DEFAULT 0,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_store   (store_id),
      INDEX idx_created (created_at)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `)
  try { await pool.query(`ALTER TABLE support_messages ADD COLUMN image_url VARCHAR(500) AFTER message`) } catch (_) {}
  _tableReady = true
}

// GET /api/support/:storeId — messages for one thread
export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ storeId: string }> }
) {
  await ensureTable()
  const { storeId } = await params
  const [rows]: any = await pool.query(
    'SELECT * FROM support_messages WHERE store_id = ? ORDER BY created_at ASC',
    [storeId]
  )
  return NextResponse.json(rows)
}

// POST /api/support/:storeId — send message (text and/or image)
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ storeId: string }> }
) {
  await ensureTable()
  const { storeId } = await params
  const { senderRole = 'admin', senderName, storeName, message = '', imageUrl } = await req.json()
  if (!message?.trim() && !imageUrl) return NextResponse.json({ error: 'message or image required' }, { status: 400 })

  const [result]: any = await pool.query(
    'INSERT INTO support_messages (store_id, store_name, sender_role, sender_name, message, image_url) VALUES (?, ?, ?, ?, ?, ?)',
    [storeId, storeName ?? senderName ?? null, senderRole, senderName ?? null, (message ?? '').trim(), imageUrl ?? null]
  )
  const [rows]: any = await pool.query('SELECT * FROM support_messages WHERE id = ?', [result.insertId])
  return NextResponse.json(rows[0])
}

// PUT /api/support/:storeId — mark thread as read (admin)
export async function PUT(
  _req: NextRequest,
  { params }: { params: Promise<{ storeId: string }> }
) {
  await ensureTable()
  const { storeId } = await params
  await pool.query(
    `UPDATE support_messages SET is_read = 1 WHERE store_id = ? AND sender_role = 'store'`,
    [storeId]
  )
  return NextResponse.json({ ok: true })
}
