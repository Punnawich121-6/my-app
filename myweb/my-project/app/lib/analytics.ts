import pool from './db'

export type QuarterlySummary = {
  year: number
  quarter: number
  revenue: number
  orderCount: number
  avgOrderValue: number
  restaurantCount: number
}

export type MonthRangeSummary = {
  year: number
  startMonth: number
  endMonth: number
  revenue: number
  orderCount: number
  avgOrderValue: number
  restaurantCount: number
}

export type MonthlyData = {
  month: number
  monthName: string
  revenue: number
  orderCount: number
}

export type CategoryData = {
  category: string
  revenue: number
  orderCount: number
  share: number
}

export type RestaurantRank = {
  id: string
  name: string
  imageUrl: string | null
  revenue: number
  orderCount: number
  avgRating: number
}

export type OrderStatusBreakdown = {
  status: string
  count: number
}

export type RiderStats = {
  totalRiders: number
  onlineRiders: number
  avgRating: number
  totalCompletedRuns: number
}

export type PlatformEarnings = {
  grossRevenue: number
  netPayout: number
  commission: number
}

export type RestaurantHealthStats = {
  total: number
  active: number
  inactive: number
  pending: number
  avgRating: number
}

export type PeakHour = {
  hour: number
  orderCount: number
}

export type CancelStats = {
  total: number
  cancelled: number
  cancelRate: number
}

const MONTH_TH = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']

export async function getQuarterlyHistory(): Promise<QuarterlySummary[]> {
  const [rows]: any = await pool.query(`
    SELECT
      YEAR(createdAt) AS year,
      QUARTER(createdAt) AS quarter,
      COALESCE(SUM(totalAmount), 0) AS revenue,
      COUNT(*) AS orderCount,
      COALESCE(AVG(totalAmount), 0) AS avgOrderValue,
      COUNT(DISTINCT restaurantId) AS restaurantCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
    GROUP BY YEAR(createdAt), QUARTER(createdAt)
    ORDER BY year DESC, quarter DESC
    LIMIT 8
  `)
  return (rows as any[]).map(r => ({
    year: Number(r.year),
    quarter: Number(r.quarter),
    revenue: Number(r.revenue),
    orderCount: Number(r.orderCount),
    avgOrderValue: Number(r.avgOrderValue),
    restaurantCount: Number(r.restaurantCount),
  }))
}

export async function getMonthRangeSummary(
  year: number, startMonth: number, endMonth: number
): Promise<MonthRangeSummary | null> {
  const [rows]: any = await pool.query(`
    SELECT
      COALESCE(SUM(totalAmount), 0) AS revenue,
      COUNT(*) AS orderCount,
      COALESCE(AVG(totalAmount), 0) AS avgOrderValue,
      COUNT(DISTINCT restaurantId) AS restaurantCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
  `, [year, startMonth, endMonth])

  if (!rows?.length) return null
  const r = rows[0]
  return {
    year, startMonth, endMonth,
    revenue: Number(r.revenue),
    orderCount: Number(r.orderCount),
    avgOrderValue: Number(r.avgOrderValue),
    restaurantCount: Number(r.restaurantCount),
  }
}

export async function getMonthlyBreakdown(
  year: number, startMonth: number, endMonth: number
): Promise<MonthlyData[]> {
  const [rows]: any = await pool.query(`
    SELECT
      MONTH(createdAt) AS month,
      COALESCE(SUM(totalAmount), 0) AS revenue,
      COUNT(*) AS orderCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
    GROUP BY MONTH(createdAt)
    ORDER BY month
  `, [year, startMonth, endMonth])

  const result: MonthlyData[] = []
  for (let m = startMonth; m <= endMonth; m++) {
    const found = (rows as any[]).find((r: any) => Number(r.month) === m)
    result.push({
      month: m,
      monthName: MONTH_TH[m],
      revenue: found ? Number(found.revenue) : 0,
      orderCount: found ? Number(found.orderCount) : 0,
    })
  }
  return result
}

export async function getCategoryBreakdown(
  year: number, startMonth: number, endMonth: number
): Promise<CategoryData[]> {
  const [rows]: any = await pool.query(`
    SELECT
      r.category,
      COALESCE(SUM(o.totalAmount), 0) AS revenue,
      COUNT(o.id) AS orderCount
    FROM \`Order\` o
    JOIN Restaurant r ON o.restaurantId = r.id
    WHERE o.status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND YEAR(o.createdAt) = ?
      AND MONTH(o.createdAt) BETWEEN ? AND ?
    GROUP BY r.category
    ORDER BY revenue DESC
    LIMIT 8
  `, [year, startMonth, endMonth])

  const total = (rows as any[]).reduce((s: number, r: any) => s + Number(r.revenue), 0)
  return (rows as any[]).map((r: any) => ({
    category: r.category || 'อื่นๆ',
    revenue: Number(r.revenue),
    orderCount: Number(r.orderCount),
    share: total > 0 ? Math.round((Number(r.revenue) / total) * 100) : 0,
  }))
}

export async function getTopRestaurants(
  year: number, startMonth: number, endMonth: number
): Promise<RestaurantRank[]> {
  const [rows]: any = await pool.query(`
    SELECT
      r.id,
      r.name,
      r.imageUrl,
      COALESCE(SUM(o.totalAmount), 0) AS revenue,
      COUNT(o.id) AS orderCount,
      COALESCE(AVG(rv.rating), 0) AS avgRating
    FROM Restaurant r
    LEFT JOIN \`Order\` o ON r.id = o.restaurantId
      AND o.status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND YEAR(o.createdAt) = ?
      AND MONTH(o.createdAt) BETWEEN ? AND ?
    LEFT JOIN reviews rv ON r.id = rv.store_id
    GROUP BY r.id, r.name, r.imageUrl
    ORDER BY revenue DESC
    LIMIT 5
  `, [year, startMonth, endMonth])

  return (rows as any[]).map((r: any) => ({
    id: r.id,
    name: r.name,
    imageUrl: r.imageUrl ?? null,
    revenue: Number(r.revenue),
    orderCount: Number(r.orderCount),
    avgRating: parseFloat(Number(r.avgRating).toFixed(1)),
  }))
}

export async function getOrderStatusBreakdown(
  year: number, startMonth: number, endMonth: number
): Promise<OrderStatusBreakdown[]> {
  const [rows]: any = await pool.query(`
    SELECT status, COUNT(*) AS count
    FROM \`Order\`
    WHERE YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
    GROUP BY status
    ORDER BY count DESC
  `, [year, startMonth, endMonth])

  return (rows as any[]).map((r: any) => ({
    status: r.status,
    count: Number(r.count),
  }))
}

export async function getCancelStats(
  year: number, startMonth: number, endMonth: number
): Promise<CancelStats> {
  const [rows]: any = await pool.query(`
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN UPPER(status) IN ('CANCELLED','REFUNDED') THEN 1 ELSE 0 END) AS cancelled
    FROM \`Order\`
    WHERE YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
  `, [year, startMonth, endMonth])

  const r = rows[0]
  const total     = Number(r.total)
  const cancelled = Number(r.cancelled)
  return {
    total,
    cancelled,
    cancelRate: total > 0 ? parseFloat(((cancelled / total) * 100).toFixed(1)) : 0,
  }
}

export async function getRiderStats(): Promise<RiderStats> {
  const [rows]: any = await pool.query(`
    SELECT
      COUNT(*) AS totalRiders,
      SUM(CASE WHEN UPPER(status) = 'ONLINE' THEN 1 ELSE 0 END) AS onlineRiders,
      COALESCE(AVG(rating), 0) AS avgRating,
      COALESCE(SUM(runsCompleted), 0) AS totalCompletedRuns
    FROM Rider
  `)

  const r = rows[0]
  return {
    totalRiders:       Number(r.totalRiders),
    onlineRiders:      Number(r.onlineRiders),
    avgRating:         parseFloat(Number(r.avgRating).toFixed(1)),
    totalCompletedRuns: Number(r.totalCompletedRuns),
  }
}

export async function getPlatformEarnings(
  year: number, startMonth: number, endMonth: number
): Promise<PlatformEarnings> {
  const [rows]: any = await pool.query(`
    SELECT
      COALESCE(SUM(amount), 0)                AS grossRevenue,
      COALESCE(SUM(netPayout), 0)             AS netPayout,
      COALESCE(SUM(amount - netPayout), 0)    AS commission
    FROM \`transaction\`
    WHERE YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
      AND status IN ('completed', 'paid')
  `, [year, startMonth, endMonth])

  const r = rows[0]
  return {
    grossRevenue: Number(r.grossRevenue),
    netPayout:    Number(r.netPayout),
    commission:   Number(r.commission),
  }
}

export async function getRestaurantHealthStats(): Promise<RestaurantHealthStats> {
  const [rows]: any = await pool.query(`
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN LOWER(status) = 'active'   THEN 1 ELSE 0 END) AS active,
      SUM(CASE WHEN LOWER(status) = 'inactive' THEN 1 ELSE 0 END) AS inactive,
      SUM(CASE WHEN LOWER(status) = 'pending'  THEN 1 ELSE 0 END) AS pending,
      COALESCE(AVG(rating), 0) AS avgRating
    FROM Restaurant
  `)

  const r = rows[0]
  return {
    total:     Number(r.total),
    active:    Number(r.active),
    inactive:  Number(r.inactive),
    pending:   Number(r.pending),
    avgRating: parseFloat(Number(r.avgRating).toFixed(1)),
  }
}

export async function getPeakHours(
  year: number, startMonth: number, endMonth: number
): Promise<PeakHour[]> {
  const [rows]: any = await pool.query(`
    SELECT
      HOUR(createdAt) AS hour,
      COUNT(*) AS orderCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED', 'cancelled')
      AND YEAR(createdAt) = ?
      AND MONTH(createdAt) BETWEEN ? AND ?
    GROUP BY HOUR(createdAt)
    ORDER BY orderCount DESC
    LIMIT 5
  `, [year, startMonth, endMonth])

  return (rows as any[]).map((r: any) => ({
    hour:       Number(r.hour),
    orderCount: Number(r.orderCount),
  }))
}
