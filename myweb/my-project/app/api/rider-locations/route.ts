import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'
import { RowDataPacket } from 'mysql2'

// Ensure columns exist (silently skipped if they already do)
let migrated = false
async function ensureColumns() {
  if (migrated) return
  for (const sql of [
    'ALTER TABLE Rider ADD COLUMN latitude         DECIMAL(10,8) NULL',
    'ALTER TABLE Rider ADD COLUMN longitude        DECIMAL(11,8) NULL',
    'ALTER TABLE Rider ADD COLUMN locationUpdatedAt DATETIME     NULL',
  ]) {
    try { await pool.query(sql) } catch (_) {}
  }
  migrated = true
}

export async function GET() {
  await ensureColumns()
  try {
    const [rows] = await pool.query<RowDataPacket[]>(
      `SELECT id, name, status, vehicle, latitude, longitude, locationUpdatedAt
       FROM Rider
       WHERE latitude IS NOT NULL AND longitude IS NOT NULL
       ORDER BY locationUpdatedAt DESC`,
    )
    return NextResponse.json(rows)
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}

// Allow admin / rider app to POST location directly to Next.js server
export async function POST(req: Request) {
  await ensureColumns()
  try {
    const { riderId, latitude, longitude } = await req.json()
    if (!riderId || latitude == null || longitude == null) {
      return NextResponse.json({ error: 'riderId, latitude, longitude required' }, { status: 400 })
    }
    await pool.query(
      'UPDATE Rider SET latitude = ?, longitude = ?, locationUpdatedAt = NOW() WHERE id = ?',
      [latitude, longitude, riderId],
    )
    return NextResponse.json({ success: true })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
