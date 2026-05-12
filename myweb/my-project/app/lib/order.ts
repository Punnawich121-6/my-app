import pool from './db'

const PAGE_SIZE = 10

// Active statuses as stored in DB (loercase, backend naming)
const ACTIVE_STATUSES = `'pending','accepted','preparing','ready','delivering','delayed'`

type Order = {
    totalActive: number
    preparing: number
    outForDelivery: number
    delayed: number
    changePercent: number
}

export type AllOrder = {
    orderNumber: string
    restaurantName: string
    restaurantAddress: string
    customerName: string
    riderName: string | null
    status: string
    totalAmount: number
    createdAt: Date
}

export type OrdersPage = {
    orders: AllOrder[]
    total: number
    pageSize: number
}

export async function getOrder(): Promise<Order> {
    const [[activeRow]]: any = await pool.query(`
        SELECT COUNT(id) AS totalActive
        FROM \`Order\`
        WHERE LOWER(status) IN (${ACTIVE_STATUSES})
    `)

    const [[yesterdayRow]]: any = await pool.query(`
        SELECT COUNT(id) AS totalYesterday
        FROM \`Order\`
        WHERE DATE(createdAt) = SUBDATE(CURDATE(), 1)
    `)

    const [[preparingRow]]: any = await pool.query(`
        SELECT COUNT(id) AS preparing
        FROM \`Order\`
        WHERE LOWER(status) = 'preparing'
    `)

    const [[outForDeliveryRow]]: any = await pool.query(`
        SELECT COUNT(id) AS outForDelivery
        FROM \`Order\`
        WHERE LOWER(status) IN ('out_for_delivery', 'ready', 'delivering')
    `)

    const [[delayedRow]]: any = await pool.query(`
        SELECT COUNT(id) AS \`delayed\`
        FROM \`Order\`
        WHERE LOWER(status) = 'delayed'
    `)

    const totalActive: number = activeRow.totalActive
    const totalYesterday: number = yesterdayRow.totalYesterday

    const changePercent = totalYesterday > 0
        ? Math.round(((totalActive - totalYesterday) / totalYesterday) * 100)
        : 0

    return {
        totalActive,
        preparing: preparingRow.preparing,
        outForDelivery: outForDeliveryRow.outForDelivery,
        delayed: delayedRow.delayed,
        changePercent,
    }
}

const VALID_STATUSES = new Set([
    'pending', 'accepted', 'preparing', 'ready',
    'delivering', 'completed', 'cancelled', 'delayed',
])

function buildStatusClause(status: string, values: (string | number)[]): string {
    if (!status || status === 'ALL') return '1=1'
    const lower = status.toLowerCase()
    if (!VALID_STATUSES.has(lower)) return '1=1'
    values.push(lower)
    return 'LOWER(o.status) = ?'
}

export async function getAllOrders(params: {
    status?: string
    zone?: string
    page?: number
} = {}): Promise<OrdersPage> {
    const { status, zone, page = 1 } = params
    const offset = (page - 1) * PAGE_SIZE

    const values: (string | number)[] = []
    const conditions: string[] = [buildStatusClause(status ?? 'ALL', values)]

    if (zone && zone !== 'ALL') {
        conditions.push('r.address LIKE ?')
        values.push(`%${zone}%`)
    }

    const where = `WHERE ${conditions.join(' AND ')}`

    const [[countRow]]: any = await pool.query(
        `SELECT COUNT(*) AS total
         FROM \`Order\` o
         JOIN Restaurant r ON o.restaurantId = r.id
         JOIN Customer   c ON o.customerId   = c.id
         ${where}`,
        values
    )

    const [rows]: any = await pool.query(
        `SELECT
           o.orderNumber,
           r.name    AS restaurantName,
           r.address AS restaurantAddress,
           c.name    AS customerName,
           ri.name   AS riderName,
           o.status,
           o.totalAmount,
           o.createdAt
         FROM \`Order\` o
         JOIN Restaurant r ON o.restaurantId = r.id
         JOIN Customer   c ON o.customerId   = c.id
         LEFT JOIN Rider ri ON o.riderId = ri.id
         ${where}
         ORDER BY o.createdAt DESC
         LIMIT ? OFFSET ?`,
        [...values, PAGE_SIZE, offset]
    )

    return { orders: rows, total: countRow.total, pageSize: PAGE_SIZE }
}
