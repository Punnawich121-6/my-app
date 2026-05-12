import pool from './db';

export type DashboardStats = {
    totalRevenue: number  // ยอดรายได้รวมของวันนี้ 
    revenueChangePercent: number  // เปอร์เซ็นต์การเปลี่ยนแปลงรายได้
    activeOrders: number  // คำสั่งซื้อที่กำลังดำเนินการ
    activeRiders: number  // พนักงานจัดส่งที่กำลังทำงาน
    pendingIssues: number  // ปัญหาที่ยังไม่ได้รับการแก้ไข
}

export type LiveOrder = {
    orderNumber: string // หมายเลขคำสั่งซื้อ
    restaurantName: string // ซื้อร้านอาหาร
    customerName: string // ชื่อลูกค้า
    status:string  //  สเตตัสของคำสั่งซื้อ
    createAt: Date // วันทีสร้างคำสั่งซื้อ
}

export type TopPerformer = {
    id: string // รหัสพนักงานจัดส่ง
    name: string // ชื่อร้านอาหาร
    imageUrl : string | null // URL ของรูปภาพร้านอาหาร 
    orderrCount: number // จำนวนคำสั่งซื้อที่พนักงานจัดส่งได้ดำเนินการ
    revenue: number // รายได้รวมที่ร้านอาหารได้รับจากคำสั่งซื้อในวันนี้
}   
export type DailyRevenue = {
  date: string      // วันที่ในรูปแบบ 'YYYY-MM-DD'
  revenue: number   // รายได้รวมของวันนั้น
  orderCount: number // จำนวน Order ของวันนั้น
}

export type StatusBreakdown = {
  status: string  // สถานะของ Order
  count: number   // จำนวน Order ในสถานะนั้น
}

export async function getDashboardState(): Promise<DashboardStats> {
    // Query จาก  Table Order เพื่อคำนวณรายได้รวมของวันนี้และเมื่อวานนี้ 
    // [{ today: 5000, yesterday: 4000 }]

    // ดึงข้อมูลสรุปยอดขายรวมของ 'วันนี้' และ 'เมื่อวาน' (ถ้าไม่มีการขายจะส่งค่าเป็น 0) จากตาราง Order โดยนับเฉพาะออเดอร์ที่ไม่ได้ถูกยกเลิกหรือคืนเงิน
    const [revenueRows] = await pool.query(`
    SELECT
      COALESCE(SUM(CASE WHEN DATE(createdAt) = CURDATE() THEN totalAmount ELSE 0 END), 0) AS today,
      COALESCE(SUM(CASE WHEN DATE(createdAt) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN totalAmount ELSE 0 END), 0) AS yesterday
    FROM \`Order\` 
    WHERE status NOT IN ('CANCELLED', 'REFUNDED')
      AND DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) 
  `) as [{ today: number; yesterday: number }[], unknown] // กำหนดประเภทของผลลัพธ์ที่ได้จากการ query ถ้าไม่มีเป็น ค่าอื่นที่ไม่รู้จัก Return (unknown) 

    const { today, yesterday } = revenueRows[0]   // today = { 5000 } , yesterday = { 4000 }

    // คำนวณเปอร์เซ็นต์การเปลี่ยนแปลงของรายได้เมื่อเทียบกับวันก่อนหน้า โดยใช้สูตร ((วันนี้ - เมื่อวาน) / เมื่อวาน) * 100 ถ้าเมื่อวานเป็น 0 จะตั้งค่าเป็น 0 เพื่อหลีกเลี่ยงการหารด้วยศูนย์
    const revenueChangePercent = yesterday > 0
        ? Math.round(((today - yesterday) / yesterday) * 100)
        : 0

    // Query จาก Table Order  เพื่อดึงข้อมูลจำนวนคำสั่งซื้อที่กำลังดำเนินการอยู่ จำนวนไรเดอร์ที่กำลังทำงานอยู่ และจำนวนปัญหาที่ยังไม่ได้รับการแก้ไข
    const [activeOrdersRows] = await pool.query(`
    SELECT COUNT(*) AS count FROM \`Order\`
    WHERE status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY')
  `) as [{ count: number }[], unknown]

    // ดึงจำนวนคำสั่งซื้อที่มีสถานะเป็น PENDING, CONFIRMED, PREPARING หรือ OUT_FOR_DELIVERY ซึ่งแสดงถึงคำสั่งซื้อที่กำลังดำเนินการอยู่
    const [activeRidersRows] = await pool.query(`
    SELECT COUNT(*) AS count FROM Rider
    WHERE status IN ('ONLINE', 'ON_DELIVERY')
  `) as [{ count: number }[], unknown]

    // ดึงจำนวนไรเดอร์ที่มีสถานะเป็น ONLINE หรือ ON_DELIVERY ซึ่งแสดงถึงไรเดอร์ที่กำลังทำงานอยู่
    const [pendingIssuesRows] = await pool.query(`
    SELECT COUNT(*) AS count FROM \`Order\`
    WHERE status IN ('DELAYED', 'REFUNDED')
      AND DATE(createdAt) = CURDATE()
  `) as [{ count: number }[], unknown]

    return {
    totalRevenue: today, // ค่ารายได้รวมของวันนี้  = ตัวแปร today ที่ได้จากการ query
    revenueChangePercent, // เปอร์เซ็นต์การเปลี่ยนแปลงของรายได้  = ตัวแปร revenueChangePercent ที่คำนวณจาก today และ yesterday
    activeOrders: Number(activeOrdersRows[0].count), // จำนวนคำสั่งซื้อที่กำลังดำเนินการ  = ตัวแปร activeOrdersRows ที่ได้จากการ query
    activeRiders: Number(activeRidersRows[0].count), // จำนวนไรเดอร์ที่กำลังทำงาน  = ตัวแปร activeRidersRows ที่ได้จากการ query
    pendingIssues: Number(pendingIssuesRows[0].count), // จำนวนปัญหาที่ยังไม่ได้รับการแก้ไข = ตัวแปร pendingIssuesRows ที่ได้จากการ query
  }
}

export async function getLiveOrders(): Promise<LiveOrder[]> {
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
    WHERE o.status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELAYED')
    ORDER BY o.createdAt DESC
    LIMIT 5
  `) as [LiveOrder[], unknown]

  return rows
}


export async function getTopPerformers(): Promise<TopPerformer[]> {
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
      AND DATE(o.createdAt) = CURDATE()
      AND o.status NOT IN ('CANCELLED', 'REFUNDED')
    GROUP BY r.id, r.name, r.imageUrl
    ORDER BY orderCount DESC
    LIMIT 4
  `) as [TopPerformer[], unknown]

  return rows // คืนค่า  rows ที่ได้จากการ query ซึ่งเป็นอาเรย์ของร้านอาหารที่มีประสิทธิภาพสูงสุด 4 ร้าน
}

export async function getDailyRevenue(): Promise<DailyRevenue[]> {
  const [rows] = await pool.query(`
    SELECT
      DATE_FORMAT(DATE(createdAt), '%Y-%m-%d') AS date,
      COALESCE(SUM(totalAmount), 0)            AS revenue,
      COUNT(id)                                AS orderCount
    FROM \`Order\`
    WHERE status NOT IN ('CANCELLED', 'REFUNDED')
      AND DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
    GROUP BY DATE_FORMAT(DATE(createdAt), '%Y-%m-%d')
    ORDER BY date ASC
  `) as [DailyRevenue[], unknown]

  // เติมวันที่ขาดหายไปด้วย 0 เพื่อให้กราฟแสดงครบ 7 วันเสมอ
  const filled: DailyRevenue[] = []
  for (let i = 6; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    const dateStr = d.toISOString().split('T')[0]
    const found = (rows as DailyRevenue[]).find(r => r.date === dateStr)
    filled.push(found ?? { date: dateStr, revenue: 0, orderCount: 0 })
  }
  return filled
}


// ดึงจำนวน Order วันนี้ แยกตาม status เพื่อแสดง breakdown
export async function getOrderStatusBreakdown(): Promise<StatusBreakdown[]> {
  const [rows] = await pool.query(`
    SELECT status, COUNT(*) AS count
    FROM \`Order\`
    WHERE DATE(createdAt) = CURDATE()
    GROUP BY status
    ORDER BY count DESC
  `) as [StatusBreakdown[], unknown]
  return rows
}