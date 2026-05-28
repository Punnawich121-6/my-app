import pool from './db'

export type DashboardStats = {
  totalRevenue: number
  revenueChangePercent: number
  activeOrders: number
  activeRiders: number
  pendingIssues: number
}

export type LiveOrder = {
  orderNumber: string
  restaurantName: string
  customerName: string
  status: string
  createdAt: Date
}

export type TopPerformer = {
  id: string
  name: string
  imageUrl: string | null
  orderCount: number
  revenue: number
}

export type DailyRevenue = {
  date: string
  revenue: number
  orderCount: number
}

export type StatusBreakdown = {
  status: string
  count: number
}

export async function getDashboardStats(date: string): Promise<DashboardStats> {
  const prevDate = new Date(date)
  prevDate.setDate(prevDate.getDate() - 1)
  const prev = prevDate.toISOString().split('T')[0]

  const [revenueRows] = await pool.query(`
    SELECT
      COALESCE(SUM(CASE WHEN DATE(createdAt) = ? THEN totalAmount ELSE 0 END), 0) AS today,
      COALESCE(SUM(CASE WHEN DATE(createdAt) = ? THEN totalAmount ELSE 0 END), 0) AS yesterday
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED')
      AND DATE(createdAt) IN (?, ?)
  `, [date, prev, date, prev]) as [{ today: number; yesterday: number }[], unknown]

  const { today, yesterday } = revenueRows[0]
  const revenueChangePercent = yesterday > 0
    ? Math.round(((today - yesterday) / yesterday) * 100)
    : 0

  const [activeOrdersRows] = await pool.query(`
    SELECT COUNT(*) AS count FROM \`Order\`
    WHERE DATE(createdAt) = ?
      AND status NOT IN ('CANCELLED', 'REFUNDED')
  `, [date]) as [{ count: number }[], unknown]

  const [activeRidersRows] = await pool.query(`
    SELECT COUNT(DISTINCT o.riderId) AS count
    FROM \`Order\` o
    WHERE DATE(o.createdAt) = ?
      AND o.riderId IS NOT NULL
  `, [date]) as [{ count: number }[], unknown]

  const [pendingIssuesRows] = await pool.query(`
    SELECT (
      (SELECT COUNT(*) FROM \`Order\` WHERE LOWER(status) = 'delayed' AND DATE(createdAt) = ?) +
      (SELECT COUNT(*) FROM disputes WHERE refund_type != 'none' AND DATE(created_at) = ?)
    ) AS count
  `, [date, date]) as [{ count: number }[], unknown]

  return {
    totalRevenue: Number(today),
    revenueChangePercent,
    activeOrders: Number(activeOrdersRows[0].count),
    activeRiders: Number(activeRidersRows[0].count),
    pendingIssues: Number(pendingIssuesRows[0].count),
  }
}

export async function getLiveOrders(date: string): Promise<LiveOrder[]> {
  const isToday = date === new Date().toISOString().split('T')[0]
  const statusFilter = isToday
    ? `o.status IN ('PENDING','CONFIRMED','PREPARING','OUT_FOR_DELIVERY','DELAYED','pending','accepted','preparing','delivering','delayed')`
    : `DATE(o.createdAt) = '${date}'`

  const [rows] = await pool.query(`
    SELECT
      o.orderNumber,
      r.name  AS restaurantName,
      c.name  AS customerName,
      o.status,
      o.createdAt
    FROM \`Order\` o
    JOIN Restaurant r ON o.restaurantId = r.id
    JOIN Customer   c ON o.customerId   = c.id
    WHERE ${statusFilter}
    ORDER BY o.createdAt DESC
    LIMIT 5
  `) as [LiveOrder[], unknown]

  return rows
}

export async function getTopPerformers(date: string, sortBy: 'orders' | 'revenue' = 'orders'): Promise<TopPerformer[]> {
  const orderCol = sortBy === 'revenue' ? 'revenue' : 'orderCount'
  const [rows] = await pool.query(`
    SELECT
      r.id,
      r.name,
      r.imageUrl,
      COUNT(o.id)                     AS orderCount,
      COALESCE(SUM(o.totalAmount), 0) AS revenue
    FROM Restaurant r
    LEFT JOIN \`Order\` o
      ON r.id = o.restaurantId
      AND DATE(o.createdAt) = ?
      AND o.status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
    GROUP BY r.id, r.name, r.imageUrl
    ORDER BY ${orderCol} DESC
    LIMIT 4
  `, [date]) as [TopPerformer[], unknown]

  return rows
}

export async function getDailyRevenue(date: string): Promise<DailyRevenue[]> {
  const [rows] = await pool.query(`
    SELECT
      DATE_FORMAT(DATE(createdAt), '%Y-%m-%d') AS date,
      COALESCE(SUM(totalAmount), 0)            AS revenue,
      COUNT(id)                                AS orderCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND DATE(createdAt) BETWEEN DATE_SUB(?, INTERVAL 6 DAY) AND ?
    GROUP BY DATE_FORMAT(DATE(createdAt), '%Y-%m-%d')
    ORDER BY date ASC
  `, [date, date]) as [DailyRevenue[], unknown]

  // fill missing days with 0
  const filled: DailyRevenue[] = []
  for (let i = 6; i >= 0; i--) {
    const d = new Date(date + 'T00:00:00')
    d.setDate(d.getDate() - i)
    const dateStr = d.toISOString().split('T')[0]
    const found = (rows as DailyRevenue[]).find(r => r.date === dateStr)
    filled.push(found ?? { date: dateStr, revenue: 0, orderCount: 0 })
  }
  return filled
}

export async function getOrderStatusBreakdown(date: string): Promise<StatusBreakdown[]> {
  const [rows] = await pool.query(`
    SELECT status, COUNT(*) AS count
    FROM \`Order\`
    WHERE DATE(createdAt) = ?
    GROUP BY status
    ORDER BY count DESC
  `, [date]) as [StatusBreakdown[], unknown]
  return rows
}
