import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'

function timeAgo(date: Date | string): string {
    const diff = Math.floor((Date.now() - new Date(date).getTime()) / 1000)
    if (diff < 60) return 'just now'
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
    return `${Math.floor(diff / 86400)}d ago`
}

export async function GET() {
    const [delayed]: any = await pool.query(
        `SELECT id, orderNumber, createdAt FROM \`Order\` WHERE LOWER(status) = 'delayed' ORDER BY createdAt DESC LIMIT 3`
    )
    const [pending]: any = await pool.query(
        `SELECT id, orderNumber, createdAt FROM \`Order\` WHERE LOWER(status) = 'pending' ORDER BY createdAt DESC LIMIT 5`
    )
    const [restaurants]: any = await pool.query(
        `SELECT id, name, createdAt FROM Restaurant WHERE LOWER(status) = 'pending' ORDER BY createdAt DESC LIMIT 3`
    )

    // Unread support messages from stores (one per store, latest)
    let supportMsgs: any[] = []
    try {
        const [rows]: any = await pool.query(`
            SELECT
                store_id,
                MAX(store_name) AS store_name,
                MAX(message)   AS last_message,
                MAX(created_at) AS last_at,
                COUNT(*)        AS unread_count
            FROM support_messages
            WHERE sender_role = 'store' AND is_read = 0
            GROUP BY store_id
            ORDER BY last_at DESC
            LIMIT 5
        `)
        supportMsgs = rows
    } catch (_) {}

    const notifications = [
        ...delayed.map((o: any) => ({
            id: `delayed-${o.id}`,
            type: 'alert',
            title: 'Order Delayed',
            body: `Order #${o.orderNumber} requires attention`,
            href: '/orders?status=delayed',
            time: timeAgo(o.createdAt),
        })),
        ...restaurants.map((r: any) => ({
            id: `restaurant-${r.id}`,
            type: 'restaurant',
            title: 'Pending Approval',
            body: `${r.name} is waiting for approval`,
            href: '/restaurants',
            time: timeAgo(r.createdAt),
        })),
        ...pending.map((o: any) => ({
            id: `order-${o.id}`,
            type: 'order',
            title: 'New Order',
            body: `Order #${o.orderNumber} is pending`,
            href: '/orders?status=pending',
            time: timeAgo(o.createdAt),
        })),
        ...supportMsgs.map((s: any) => ({
            id: `support-${s.store_id}`,
            type: 'support',
            title: `ข้อความจาก ${s.store_name ?? 'ร้านค้า'}`,
            body: s.last_message || '📷 ส่งรูปภาพมา',
            href: `/support?store=${s.store_id}`,
            time: timeAgo(s.last_at),
            unreadCount: Number(s.unread_count),
        })),
    ]

    return NextResponse.json(notifications)
}
