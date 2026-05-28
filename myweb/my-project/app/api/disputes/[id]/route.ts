import { NextRequest, NextResponse } from 'next/server'
import pool from '@/app/lib/db'

type Params = { params: Promise<{ id: string }> }

// GET /api/disputes/[id] — full detail + action history
export async function GET(_req: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const [[dispute]]: any = await pool.query('SELECT * FROM disputes WHERE id = ?', [id])
    if (!dispute) return NextResponse.json({ error: 'Not found' }, { status: 404 })
    const [actions]: any = await pool.query(
      'SELECT * FROM dispute_actions WHERE dispute_id = ? ORDER BY created_at ASC', [id]
    )
    return NextResponse.json({ ...dispute, actions })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}

// PUT /api/disputes/[id] — admin override verdict
export async function PUT(req: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const { verdict, notes, refundType = 'none', refundAmount = 0 } = await req.json()

    await pool.query(`
      UPDATE disputes SET
        status = 'admin_resolved',
        admin_override_verdict = ?, admin_override_notes = ?,
        refund_type = ?, refund_amount = ?,
        resolved_at = NOW(), resolved_by = 'admin'
      WHERE id = ?
    `, [verdict, notes, refundType, refundAmount, id])

    await pool.query(
      'INSERT INTO dispute_actions (dispute_id, action_type, actor_role, notes) VALUES (?,?,?,?)',
      [id, 'admin_override', 'admin', `Admin ตัดสิน: ${verdict}. ${notes || ''}`]
    )
    return NextResponse.json({ success: true })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
