import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'
import * as XLSX from 'xlsx'

// ─── Report definitions ───────────────────────────────────────────────────────

type Row = Record<string, unknown>

const REPORTS = {
  orders: {
    label: 'Orders Report',
    needsDate: true,
    async fetch(from: string, to: string): Promise<Row[]> {
      const [rows] = await pool.query(
        `SELECT
           o.orderNumber               AS \`Order #\`,
           r.name                      AS \`Restaurant\`,
           c.name                      AS \`Customer\`,
           COALESCE(ri.name, '-')      AS \`Rider\`,
           o.status                    AS \`Status\`,
           o.totalAmount               AS \`Total (฿)\`,
           COALESCE(o.serviceFee, 0)   AS \`Service Fee (฿)\`,
           DATE_FORMAT(o.createdAt, '%Y-%m-%d %H:%i') AS \`Date\`
         FROM \`Order\` o
         JOIN Restaurant r  ON o.restaurantId = r.id
         JOIN Customer   c  ON o.customerId   = c.id
         LEFT JOIN Rider ri ON o.riderId       = ri.id
         WHERE o.createdAt BETWEEN ? AND ?
         ORDER BY o.createdAt DESC`,
        [from, to],
      ) as [Row[], unknown]
      return rows
    },
  },

  financials: {
    label: 'Financial Report',
    needsDate: true,
    async fetch(from: string, to: string): Promise<Row[]> {
      const [rows] = await pool.query(
        `SELECT
           o.orderNumber                        AS \`Order #\`,
           r.name                               AS \`Restaurant\`,
           o.totalAmount                        AS \`Revenue (฿)\`,
           COALESCE(o.serviceFee, 0)            AS \`Service Fee (฿)\`,
           ROUND(o.totalAmount * 0.15, 2)       AS \`Commission (฿)\`,
           ROUND(o.totalAmount * 0.85 - COALESCE(o.serviceFee,0), 2) AS \`Net Payout (฿)\`,
           o.status                             AS \`Status\`,
           DATE_FORMAT(o.createdAt, '%Y-%m-%d') AS \`Date\`
         FROM \`Order\` o
         JOIN Restaurant r ON o.restaurantId = r.id
         WHERE LOWER(o.status) = 'completed'
           AND o.createdAt BETWEEN ? AND ?
         ORDER BY o.createdAt DESC`,
        [from, to],
      ) as [Row[], unknown]
      return rows
    },
  },

  restaurants: {
    label: 'Restaurants Report',
    needsDate: false,
    async fetch(): Promise<Row[]> {
      const [rows] = await pool.query(
        `SELECT
           r.name          AS \`Name\`,
           r.category      AS \`Category\`,
           COALESCE(r.rating, 0)       AS \`Rating\`,
           COALESCE(r.totalOrders, 0)  AS \`Total Orders\`,
           r.status        AS \`Status\`,
           r.address       AS \`Address\`,
           COALESCE(r.phone,'')  AS \`Phone\`,
           COALESCE(r.email,'')  AS \`Email\`,
           r.open_time     AS \`Open\`,
           r.close_time    AS \`Close\`
         FROM Restaurant r
         ORDER BY r.totalOrders DESC`,
      ) as [Row[], unknown]
      return rows
    },
  },

  fleet: {
    label: 'Fleet Report',
    needsDate: false,
    async fetch(): Promise<Row[]> {
      const [rows] = await pool.query(
        `SELECT
           ri.name         AS \`Name\`,
           COALESCE(ri.phone,'')  AS \`Phone\`,
           COALESCE(ri.email,'')  AS \`Email\`,
           ri.vehicle      AS \`Vehicle\`,
           ri.vehicleType  AS \`Type\`,
           ri.status       AS \`Status\`,
           COALESCE(ri.rating,0) AS \`Rating\`,
           ri.runsCompleted      AS \`Runs Completed\`,
           CASE WHEN ri.isVerified THEN 'Yes' ELSE 'No' END AS \`Verified\`
         FROM Rider ri
         ORDER BY ri.runsCompleted DESC`,
      ) as [Row[], unknown]
      return rows
    },
  },
} as const

type ReportKey = keyof typeof REPORTS

// ─── CSV helper ───────────────────────────────────────────────────────────────

function toCSV(rows: Row[]): string {
  if (rows.length === 0) return ''
  const headers = Object.keys(rows[0])
  const escape = (v: unknown) => {
    const s = v === null || v === undefined ? '' : String(v)
    return s.includes(',') || s.includes('"') || s.includes('\n')
      ? `"${s.replace(/"/g, '""')}"`
      : s
  }
  return [
    headers.map(escape).join(','),
    ...rows.map(r => headers.map(h => escape(r[h])).join(',')),
  ].join('\r\n')
}

// ─── Route handler ────────────────────────────────────────────────────────────

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const report = (searchParams.get('report') ?? 'orders') as ReportKey
  const format = searchParams.get('format') ?? 'csv'

  // Date range — default to last 30 days
  const now = new Date()
  const defaultFrom = new Date(now)
  defaultFrom.setDate(now.getDate() - 30)

  const from = searchParams.get('from') ?? defaultFrom.toISOString().split('T')[0] + ' 00:00:00'
  const to   = searchParams.get('to')   ?? now.toISOString().split('T')[0] + ' 23:59:59'

  const config = REPORTS[report]
  if (!config) {
    return NextResponse.json({ error: 'Invalid report type' }, { status: 400 })
  }

  try {
    const rows: Row[] = config.needsDate
      ? await (config as typeof REPORTS.orders).fetch(from, to)
      : await (config as typeof REPORTS.restaurants).fetch()

    const dateStamp = now.toISOString().split('T')[0]
    const filename  = `${config.label.replace(/\s+/g, '_')}_${dateStamp}`

    // ── CSV ──────────────────────────────────────────────────────────────────
    if (format === 'csv') {
      const csv = toCSV(rows)
      return new NextResponse('﻿' + csv, { // BOM for Excel UTF-8
        headers: {
          'Content-Type': 'text/csv; charset=utf-8',
          'Content-Disposition': `attachment; filename="${filename}.csv"`,
        },
      })
    }

    // ── XLSX ─────────────────────────────────────────────────────────────────
    if (format === 'xlsx') {
      const ws = XLSX.utils.json_to_sheet(rows)

      // Auto column widths
      const colWidths = Object.keys(rows[0] ?? {}).map(key => ({
        wch: Math.max(key.length, ...rows.map(r => String(r[key] ?? '').length)) + 2,
      }))
      ws['!cols'] = colWidths

      const wb = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(wb, ws, config.label.slice(0, 31))
      const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' }) as Buffer

      return new NextResponse(new Uint8Array(buf), {
        headers: {
          'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'Content-Disposition': `attachment; filename="${filename}.xlsx"`,
        },
      })
    }

    // ── PDF (return raw data — client renders printable HTML) ────────────────
    if (format === 'pdf') {
      return NextResponse.json({
        rows,
        label: config.label,
        filename,
        dateRange: config.needsDate ? { from, to } : null,
        generatedAt: now.toISOString(),
      })
    }

    return NextResponse.json({ error: 'Invalid format' }, { status: 400 })
  } catch (err) {
    console.error('[/api/export] error:', err)
    return NextResponse.json({ error: 'Export failed. Check server logs.' }, { status: 500 })
  }
}
