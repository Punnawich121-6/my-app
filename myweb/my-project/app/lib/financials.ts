import pool from './db'
import type { DailyRevenue } from './dashboard'

const PAGE_SIZE = 15

export type FinancialStats = {
    thisMonthRevenue:    number
    lastMonthRevenue:    number
    revenueChangePercent: number
    totalCommission:     number  // 15% of completed order revenue
    merchantPayouts:     number  // SUM(netPayout) from transaction
    totalServiceFees:    number  // SUM(serviceFee) from completed orders
    avgOrderValue:       number
    totalCompletedOrders: number
}

export type RevenueBreakdown = {
    merchantPayouts:     number
    platformCommission:  number
    serviceFees:         number
}

export type Transaction = {
    id:             string
    orderNumber:    string
    restaurantName: string
    customerName:   string | null
    amount:         number
    serviceFee:     number
    status:         string
    createdAt:      Date
}

export type TransactionsPage = {
    transactions: Transaction[]
    total:        number
    pageSize:     number
}

export async function getFinancialStats(): Promise<FinancialStats> {
    const [[orderRow]]: any = await pool.query(`
        SELECT
            COALESCE(SUM(CASE
                WHEN MONTH(createdAt) = MONTH(CURDATE())
                 AND YEAR(createdAt)  = YEAR(CURDATE())
                THEN totalAmount ELSE 0 END), 0)                    AS thisMonth,
            COALESCE(SUM(CASE
                WHEN MONTH(createdAt) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
                 AND YEAR(createdAt)  = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
                THEN totalAmount ELSE 0 END), 0)                    AS lastMonth,
            COALESCE(AVG(totalAmount), 0)                           AS avgOrderValue,
            COALESCE(SUM(serviceFee), 0)                            AS totalServiceFees,
            COUNT(*)                                                AS totalOrders
        FROM \`Order\`
        WHERE LOWER(status) = 'completed'
    `)

    const [[txRow]]: any = await pool.query(`
        SELECT COALESCE(SUM(netPayout), 0) AS merchantPayouts
        FROM transaction
        WHERE LOWER(status) IN ('completed', 'paid')
    `)

    const thisMonth:      number = Number(orderRow.thisMonth)
    const lastMonth:      number = Number(orderRow.lastMonth)
    const totalServiceFees: number = Number(orderRow.totalServiceFees)
    const merchantPayouts: number = Number(txRow.merchantPayouts)
    const totalCommission  = thisMonth * 0.15

    const revenueChangePercent = lastMonth > 0
        ? Math.round(((thisMonth - lastMonth) / lastMonth) * 100)
        : 0

    return {
        thisMonthRevenue:    thisMonth,
        lastMonthRevenue:    lastMonth,
        revenueChangePercent,
        totalCommission:     Math.round(totalCommission),
        merchantPayouts:     Math.round(merchantPayouts),
        totalServiceFees:    Math.round(totalServiceFees),
        avgOrderValue:       Math.round(Number(orderRow.avgOrderValue)),
        totalCompletedOrders: Number(orderRow.totalOrders),
    }
}

export async function getRevenueBreakdown(): Promise<RevenueBreakdown> {
    const [[row]]: any = await pool.query(`
        SELECT
            COALESCE(SUM(o.totalAmount), 0) AS totalRevenue,
            COALESCE(SUM(o.serviceFee),  0) AS serviceFees
        FROM \`Order\` o
        WHERE LOWER(o.status) = 'completed'
    `)
    const [[txRow]]: any = await pool.query(`
        SELECT COALESCE(SUM(netPayout), 0) AS merchantPayouts
        FROM transaction
        WHERE LOWER(status) IN ('completed', 'paid')
    `)

    const totalRevenue    = Number(row.totalRevenue)
    const serviceFees     = Number(row.serviceFees)
    const merchantPayouts = Number(txRow.merchantPayouts)
    const platformCommission = Math.max(0, totalRevenue - merchantPayouts - serviceFees)

    return { merchantPayouts, platformCommission, serviceFees }
}

export async function getFinancialDailyRevenue(): Promise<DailyRevenue[]> {
    const [rows]: any = await pool.query(`
        SELECT
            DATE_FORMAT(DATE(createdAt), '%Y-%m-%d') AS date,
            COALESCE(SUM(totalAmount), 0)            AS revenue,
            COUNT(id)                                AS orderCount
        FROM \`Order\`
        WHERE LOWER(status) = 'completed'
          AND DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
        GROUP BY DATE_FORMAT(DATE(createdAt), '%Y-%m-%d')
        ORDER BY date ASC
    `)

    const filled: DailyRevenue[] = []
    for (let i = 29; i >= 0; i--) {
        const d = new Date()
        d.setDate(d.getDate() - i)
        const dateStr = d.toISOString().split('T')[0]
        const found = (rows as DailyRevenue[]).find((r: DailyRevenue) => r.date === dateStr)
        filled.push(found ?? { date: dateStr, revenue: 0, orderCount: 0 })
    }
    return filled
}

export async function getTransactions(page = 1): Promise<TransactionsPage> {
    const offset = (page - 1) * PAGE_SIZE

    const [[countRow]]: any = await pool.query(
        `SELECT COUNT(*) AS total FROM transaction`
    )

    const [rows]: any = await pool.query(
        `SELECT
           t.id,
           o.orderNumber,
           r.name    AS restaurantName,
           c.name    AS customerName,
           t.amount,
           o.serviceFee,
           t.status,
           t.createdAt
         FROM transaction t
         JOIN \`Order\`  o ON t.orderId      = o.id
         JOIN Restaurant r ON t.restaurantId = r.id
         LEFT JOIN Customer c ON o.customerId = c.id
         ORDER BY t.createdAt DESC
         LIMIT ? OFFSET ?`,
        [PAGE_SIZE, offset]
    )

    return { transactions: rows, total: Number(countRow.total), pageSize: PAGE_SIZE }
}
