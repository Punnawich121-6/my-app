import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'
import bcrypt from 'bcryptjs'
import crypto from 'crypto'

async function ensureColumns() {
  // Add optional columns if they don't exist yet
  const alter = [
    "ALTER TABLE AdminUser ADD COLUMN IF NOT EXISTS name VARCHAR(100) NULL",
    "ALTER TABLE AdminUser ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'Editor'",
    "ALTER TABLE AdminUser ADD COLUMN IF NOT EXISTS isActive TINYINT(1) DEFAULT 1",
    "ALTER TABLE AdminUser ADD COLUMN IF NOT EXISTS createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
  ]
  for (const sql of alter) {
    try { await pool.query(sql) } catch { /* column already exists */ }
  }
}

export async function GET() {
  try {
    await ensureColumns()
    const [rows] = await pool.query(
      `SELECT id,
        COALESCE(name, SUBSTRING_INDEX(email,'@',1)) AS name,
        email,
        COALESCE(role, 'Editor') AS role,
        COALESCE(isActive, 1)   AS isActive,
        lastLogin
       FROM AdminUser
       ORDER BY createdAt ASC`
    ) as [{ id: string; name: string; email: string; role: string; isActive: number; lastLogin: Date | null }[], unknown]

    return NextResponse.json(rows)
  } catch (err) {
    console.error('GET /api/settings/admins error:', err)
    return NextResponse.json([], { status: 200 })
  }
}

export async function POST(request: Request) {
  try {
    await ensureColumns()
    const { name, email, password, role } = await request.json()

    if (!email || !password) {
      return NextResponse.json({ error: 'Email and password are required' }, { status: 400 })
    }

    const [existing] = await pool.query('SELECT id FROM AdminUser WHERE email = ? LIMIT 1', [email]) as [{ id: string }[], unknown]
    if ((existing as unknown[]).length > 0) {
      return NextResponse.json({ error: 'Email already exists' }, { status: 409 })
    }

    const passwordHash = await bcrypt.hash(password, 12)
    const id = crypto.randomUUID()

    await pool.query(
      'INSERT INTO AdminUser (id, name, email, passwordHash, role, isActive) VALUES (?, ?, ?, ?, ?, 1)',
      [id, name || email.split('@')[0], email, passwordHash, role || 'Editor']
    )

    return NextResponse.json({ success: true, id })
  } catch (err) {
    console.error('POST /api/settings/admins error:', err)
    return NextResponse.json({ error: 'Failed to create admin' }, { status: 500 })
  }
}
