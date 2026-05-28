import { NextRequest, NextResponse } from 'next/server'
import pool from '@/app/lib/db'

export async function GET(req: NextRequest) {
    const q = req.nextUrl.searchParams.get('q')?.trim()
    if (!q || q.length < 2) return NextResponse.json([])

    const like = `%${q}%`
    const results: { type: string; label: string; sub: string; href: string }[] = []

    const [orders]: any = await pool.query(
        `SELECT orderNumber, status FROM \`Order\` WHERE orderNumber LIKE ? ORDER BY createdAt DESC LIMIT 5`,
        [like]
    )
    for (const o of orders) {
        results.push({ type: 'order', label: `#${o.orderNumber}`, sub: o.status, href: '/orders' })
    }

    const [restaurants]: any = await pool.query(
        `SELECT name, category FROM Restaurant WHERE name LIKE ? LIMIT 5`,
        [like]
    )
    for (const r of restaurants) {
        results.push({ type: 'restaurant', label: r.name, sub: r.category, href: '/restaurants' })
    }

    const [riders]: any = await pool.query(
        `SELECT name, status FROM Rider WHERE name LIKE ? LIMIT 5`,
        [like]
    )
    for (const r of riders) {
        results.push({ type: 'rider', label: r.name, sub: r.status, href: '/fleet' })
    }

    return NextResponse.json(results)
}
