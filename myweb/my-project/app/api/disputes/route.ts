import { NextRequest, NextResponse } from 'next/server'
import pool from '@/app/lib/db'

async function ensureTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS disputes (
      id                    INT AUTO_INCREMENT PRIMARY KEY,
      order_id              VARCHAR(255),
      order_number          VARCHAR(255),
      customer_id           VARCHAR(255),
      customer_name         VARCHAR(255),
      restaurant_name       VARCHAR(255),
      rider_name            VARCHAR(255),
      reason_type           VARCHAR(50)  DEFAULT 'other',
      description           TEXT,
      evidence_urls         TEXT,
      status                ENUM('analyzing','auto_resolved','pending_review','escalated','admin_resolved','closed') DEFAULT 'analyzing',
      confidence_score      DECIMAL(5,2),
      ai_verdict            VARCHAR(50),
      ai_fault_party        VARCHAR(50),
      ai_reasoning          TEXT,
      refund_type           ENUM('full','partial','none') DEFAULT 'none',
      refund_amount         DECIMAL(10,2) DEFAULT 0,
      admin_override_verdict VARCHAR(100),
      admin_override_notes  TEXT,
      created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      resolved_at           TIMESTAMP NULL,
      resolved_by           VARCHAR(100),
      INDEX idx_status  (status),
      INDEX idx_created (created_at)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS dispute_actions (
      id          INT AUTO_INCREMENT PRIMARY KEY,
      dispute_id  INT NOT NULL,
      action_type VARCHAR(100),
      actor_role  VARCHAR(50),
      notes       TEXT,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_dispute (dispute_id)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `)
}

export async function GET(req: NextRequest) {
  try {
    await ensureTables()
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status') || 'all'
    const page   = Math.max(1, Number(searchParams.get('page')  || 1))
    const limit  = Math.max(1, Number(searchParams.get('limit') || 20))
    const offset = (page - 1) * limit

    const params: (string | number)[] = []
    let where = ''
    if (status !== 'all') { where = 'WHERE status = ?'; params.push(status) }

    const [[countRow]]: any = await pool.query(
      `SELECT COUNT(*) AS total FROM disputes ${where}`, params
    )
    const [rows]: any = await pool.query(
      `SELECT id, order_id, order_number, customer_name, restaurant_name, rider_name,
              reason_type, status, confidence_score, ai_verdict, ai_fault_party,
              refund_type, refund_amount, created_at, resolved_at
       FROM disputes ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    )

    // Stats in same call
    const [[stats]]: any = await pool.query(`
      SELECT
        COUNT(*)                                                           AS total,
        SUM(status = 'auto_resolved')                                      AS auto_resolved,
        SUM(status = 'pending_review')                                     AS pending_review,
        SUM(status = 'escalated')                                          AS escalated,
        SUM(status = 'admin_resolved')                                     AS admin_resolved,
        SUM(status = 'analyzing')                                          AS analyzing,
        SUM(CASE WHEN refund_type != 'none' THEN refund_amount ELSE 0 END) AS total_refunded,
        ROUND(AVG(confidence_score), 1)                                    AS avg_confidence
      FROM disputes
    `)

    return NextResponse.json({ disputes: rows, total: countRow.total, page, limit, stats })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
