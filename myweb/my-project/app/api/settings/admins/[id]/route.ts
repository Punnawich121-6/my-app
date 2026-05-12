import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const { name, email, role, isActive } = await request.json()

    await pool.query(
      'UPDATE AdminUser SET name = ?, email = ?, role = ?, isActive = ? WHERE id = ?',
      [name, email, role, isActive ? 1 : 0, id]
    )

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('PUT /api/settings/admins/[id] error:', err)
    return NextResponse.json({ error: 'Failed to update admin' }, { status: 500 })
  }
}

export async function DELETE(
  _: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Delete related sessions first to avoid FK constraint errors
    try {
      await pool.query('DELETE FROM AdminSession WHERE adminUserId = ?', [id])
    } catch { /* AdminSession may not exist */ }

    await pool.query('DELETE FROM AdminUser WHERE id = ?', [id])

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('DELETE /api/settings/admins/[id] error:', err)
    return NextResponse.json({ error: 'Failed to delete admin' }, { status: 500 })
  }
}
