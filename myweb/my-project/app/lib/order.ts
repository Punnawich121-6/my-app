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
    id: string
    orderNumber: string
    restaurantName: string
    restaurantAddress: string
    customerName: string
    riderName: string | null
    status: string
    totalAmount: number
    createdAt: Date
}

export type OrderDetail = {
    id: string
    orderNumber: string
    status: string
    totalAmount: number
    serviceFee: number
    notes: string
    createdAt: Date
    restaurantName: string
    restaurantAddress: string
    customerName: string
    customerPhone: string
    customerAddress: string
    riderName: string | null
    items: { name: string; price: number; quantity: number }[]
}

export type OrdersPage = {
    orders: AllOrder[]
    total: number
    pageSize: number
}

export async function getOrder(): Promise<Order> {
    const [[row]]: any = await pool.query(`
        SELECT
            COUNT(CASE WHEN LOWER(status) IN (${ACTIVE_STATUSES}) THEN 1 END) AS totalActive,
            COUNT(CASE WHEN LOWER(status) = 'preparing' THEN 1 END) AS preparing,
            COUNT(CASE WHEN LOWER(status) IN ('out_for_delivery', 'ready', 'delivering') THEN 1 END) AS outForDelivery,
            COUNT(CASE WHEN LOWER(status) IN ('pending','accepted','preparing','delivering') AND createdAt <= NOW() - INTERVAL 45 MINUTE THEN 1 END) AS \`delayed\`,
            COUNT(CASE WHEN DATE(createdAt) = SUBDATE(CURDATE(), 1) THEN 1 END) AS totalYesterday
        FROM \`Order\`
    `)

    const totalActive: number = row.totalActive
    const totalYesterday: number = row.totalYesterday

    const changePercent = totalYesterday > 0
        ? Math.round(((totalActive - totalYesterday) / totalYesterday) * 100)
        : 0

    return {
        totalActive,
        preparing: row.preparing,
        outForDelivery: row.outForDelivery,
        delayed: row.delayed,
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
           o.id,
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

export async function getOrderDetail(id: string): Promise<OrderDetail | null> {
    const [[order]]: any = await pool.query(
        `SELECT o.id, o.orderNumber, o.status, o.totalAmount, o.serviceFee, o.notes, o.createdAt,
                r.name AS restaurantName, r.address AS restaurantAddress,
                c.name AS customerName, c.phone AS customerPhone, c.address AS customerAddress,
                ri.name AS riderName
         FROM \`Order\` o
         JOIN Restaurant r ON o.restaurantId = r.id
         JOIN Customer   c ON o.customerId   = c.id
         LEFT JOIN Rider ri ON o.riderId = ri.id
         WHERE o.id = ?`,
        [id]
    )
    if (!order) return null
    const [items]: any = await pool.query(
        'SELECT name, price, quantity FROM order_items WHERE order_id = ?',
        [id]
    )
    return { ...order, items }
}
