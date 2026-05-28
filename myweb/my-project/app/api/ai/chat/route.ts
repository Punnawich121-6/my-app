import { NextRequest } from 'next/server'
import pool from '@/app/lib/db'

const BASE_URL = process.env.AI_BASE_URL ?? 'https://gen.ai.kku.ac.th/api/v1'
const MODEL    = process.env.AI_MODEL    ?? 'claude-sonnet-4.6'

// ─── Full-site context ────────────────────────────────────────────────────────

// ── Safe query helper — never throws, returns fallback on error ──────────────
async function sq<T>(query: () => Promise<T>, fallback: T): Promise<T> {
  try { return await query() } catch { return fallback }
}

async function getFullContext() {
  const today     = new Date().toISOString().split('T')[0]
  const thisMonth = today.slice(0, 7)

  const [
    todayRow, yesterdayRow, weeklyRevenue, statusBreakdown,
    activeOrders,
    allRiders,
    allCustomers,
    allRestaurants,
    allMenuItems,
    recentOrders,
    financialStats, monthlyTrend,
    recentTransactions,
    riderReviews,
    recentMessages,
    orderStatusCounts,
  ] = await Promise.all([

    // ── วันนี้ ──
    sq(() => pool.query(`
      SELECT COALESCE(SUM(totalAmount),0) AS revenue,
             COUNT(*) AS orders,
             COALESCE(AVG(totalAmount),0) AS avgValue
      FROM \`Order\`
      WHERE DATE(createdAt)=? AND LOWER(status) NOT IN ('cancelled','refunded')
    `, [today]).then(([r]:any) => r[0]),
    { revenue: 0, orders: 0, avgValue: 0 }),

    sq(() => pool.query(`
      SELECT COALESCE(SUM(totalAmount),0) AS revenue, COUNT(*) AS orders
      FROM \`Order\`
      WHERE DATE(createdAt)=DATE_SUB(?,INTERVAL 1 DAY)
        AND LOWER(status) NOT IN ('cancelled','refunded')
    `, [today]).then(([r]:any) => r[0]),
    { revenue: 0, orders: 0 }),

    sq(() => pool.query(`
      SELECT DATE_FORMAT(DATE(createdAt),'%d/%m') AS day,
             COALESCE(SUM(totalAmount),0) AS revenue, COUNT(*) AS orders
      FROM \`Order\`
      WHERE DATE(createdAt) BETWEEN DATE_SUB(?,INTERVAL 6 DAY) AND ?
        AND LOWER(status) NOT IN ('cancelled','refunded')
      GROUP BY DATE(createdAt) ORDER BY DATE(createdAt) ASC
    `, [today, today]).then(([r]:any) => r),
    []),

    sq(() => pool.query(`
      SELECT LOWER(status) AS status, COUNT(*) AS cnt
      FROM \`Order\` WHERE DATE(createdAt)=?
      GROUP BY LOWER(status)
    `, [today]).then(([r]:any) => r),
    []),

    // ── ออเดอร์ active ──
    sq(() => pool.query(`
      SELECT COUNT(*) AS total,
        SUM(LOWER(status)='pending')   AS pending,
        SUM(LOWER(status)='preparing') AS preparing,
        SUM(LOWER(status) IN ('delivering','out_for_delivery','ready')) AS delivering,
        SUM(LOWER(status)='delayed')   AS delayed
      FROM \`Order\`
      WHERE LOWER(status) IN ('pending','accepted','preparing','ready','delivering','out_for_delivery','delayed')
    `).then(([r]:any) => r[0]),
    { total: 0, pending: 0, preparing: 0, delivering: 0, delayed: 0 }),

    // ── ไรเดอร์ทั้งหมด ──
    sq(() => pool.query(`
      SELECT name, phone, email, vehicle, vehicleType, status,
             isVerified, COALESCE(rating,0) AS rating, runsCompleted,
             DATE_FORMAT(createdAt,'%Y-%m-%d') AS joinDate
      FROM Rider ORDER BY name ASC
    `).then(([r]:any) => r),
    []),

    // ── ลูกค้าทั้งหมด ──
    sq(() => pool.query(`
      SELECT name, phone, email, address,
             DATE_FORMAT(createdAt,'%Y-%m-%d') AS joinDate
      FROM Customer ORDER BY name ASC
    `).then(([r]:any) => r),
    []),

    // ── ร้านอาหารทั้งหมด ──
    sq(() => pool.query(`
      SELECT name, phone, email, category, status,
             COALESCE(rating,0) AS rating,
             COALESCE(totalOrders,0) AS totalOrders,
             address, owner_name, open_time, close_time,
             bank_name, account_name, account_no,
             DATE_FORMAT(createdAt,'%Y-%m-%d') AS joinDate
      FROM Restaurant ORDER BY name ASC
    `).then(([r]:any) => r),
    []),

    // ── เมนูทุกร้าน ──
    sq(() => pool.query(`
      SELECT r.name AS restaurant, mi.name AS item, mi.price,
             mc.name AS category, mi.is_available
      FROM menu_items mi
      JOIN Restaurant r  ON mi.store_id = r.id
      LEFT JOIN menu_categories mc ON mi.category_id = mc.id
      ORDER BY r.name, mc.sort_order, mi.sort_order
    `).then(([r]:any) => r),
    []),

    // ── ออเดอร์ล่าสุด 100 รายการ พร้อมรายการอาหาร ──
    sq(() => pool.query(`
      SELECT o.orderNumber, o.status, o.totalAmount, o.serviceFee,
             o.notes, DATE_FORMAT(o.createdAt,'%Y-%m-%d %H:%i') AS createdAt,
             r.name AS restaurant,
             c.name AS customer, c.phone AS customerPhone,
             ri.name AS rider,
             GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name,' ฿',oi.price) SEPARATOR ', ') AS items
      FROM \`Order\` o
      JOIN Restaurant r ON o.restaurantId=r.id
      JOIN Customer   c ON o.customerId=c.id
      LEFT JOIN Rider ri ON o.riderId=ri.id
      LEFT JOIN order_items oi ON o.id=oi.order_id
      GROUP BY o.id
      ORDER BY o.createdAt DESC LIMIT 100
    `).then(([r]:any) => r),
    []),

    // ── การเงิน ──
    sq(() => pool.query(`
      SELECT
        COALESCE(SUM(CASE WHEN DATE_FORMAT(createdAt,'%Y-%m')=? THEN totalAmount END),0) AS thisMonth,
        COALESCE(SUM(CASE WHEN DATE_FORMAT(createdAt,'%Y-%m')=DATE_FORMAT(DATE_SUB(NOW(),INTERVAL 1 MONTH),'%Y-%m') THEN totalAmount END),0) AS lastMonth,
        COALESCE(SUM(totalAmount),0) AS allTime,
        COALESCE(AVG(totalAmount),0) AS avgOrder,
        COALESCE(SUM(serviceFee),0)  AS totalServiceFees,
        COUNT(*) AS completedOrders
      FROM \`Order\` WHERE LOWER(status)='completed'
    `, [thisMonth]).then(([r]:any) => r[0]),
    { thisMonth: 0, lastMonth: 0, allTime: 0, avgOrder: 0, totalServiceFees: 0, completedOrders: 0 }),

    sq(() => pool.query(`
      SELECT DATE_FORMAT(createdAt,'%Y-%m') AS month,
             COALESCE(SUM(totalAmount),0) AS revenue, COUNT(*) AS orders
      FROM \`Order\` WHERE LOWER(status)='completed'
        AND createdAt >= DATE_SUB(NOW(),INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(createdAt,'%Y-%m') ORDER BY month ASC
    `).then(([r]:any) => r),
    []),

    // ── transaction ──
    sq(() => pool.query(`
      SELECT t.id, o.orderNumber, r.name AS restaurant,
             t.amount, t.netPayout, t.status,
             DATE_FORMAT(t.createdAt,'%Y-%m-%d') AS date
      FROM transaction t
      JOIN \`Order\` o ON t.orderId=o.id
      JOIN Restaurant r ON t.restaurantId=r.id
      ORDER BY t.createdAt DESC LIMIT 50
    `).then(([r]:any) => r),
    []),

    // ── รีวิวไรเดอร์ ──
    sq(() => pool.query(`
      SELECT ri.name AS rider, rr.rating, rr.comment, rr.customer_name,
             DATE_FORMAT(rr.created_at,'%Y-%m-%d') AS date
      FROM rider_reviews rr
      JOIN Rider ri ON rr.rider_id=ri.id
      ORDER BY rr.created_at DESC LIMIT 50
    `).then(([r]:any) => r),
    []),

    // ── messages (chat ล่าสุด) ──
    sq(() => pool.query(`
      SELECT m.sender_name, m.sender_role, m.message,
             o.orderNumber,
             DATE_FORMAT(m.created_at,'%Y-%m-%d %H:%i') AS time
      FROM messages m
      JOIN \`Order\` o ON m.order_id=o.id
      ORDER BY m.created_at DESC LIMIT 50
    `).then(([r]:any) => r),
    []),

    // ── สรุปจำนวนออเดอร์ทั้งหมดตาม status ──
    sq(() => pool.query(`
      SELECT LOWER(status) AS status, COUNT(*) AS cnt
      FROM \`Order\` GROUP BY LOWER(status)
    `).then(([r]:any) => r),
    []),
  ])

  const revenueGrowth = yesterdayRow.revenue > 0
    ? (((todayRow.revenue - yesterdayRow.revenue) / yesterdayRow.revenue) * 100).toFixed(1)
    : null
  const monthGrowth = financialStats.lastMonth > 0
    ? (((financialStats.thisMonth - financialStats.lastMonth) / financialStats.lastMonth) * 100).toFixed(1)
    : null

  return {
    today,
    todayRevenue:  Math.round(todayRow.revenue),
    todayOrders:   Number(todayRow.orders),
    todayAvgOrder: Math.round(todayRow.avgValue),
    revenueGrowth,
    weeklyRevenue: (weeklyRevenue as any[]).map((d:any) =>
      `${d.day}:฿${Math.round(d.revenue).toLocaleString()}(${d.orders}ออเดอร์)`),
    todayStatusBreakdown: (statusBreakdown as any[]).map((s:any) => `${s.status}:${s.cnt}`),
    allStatusCounts: (orderStatusCounts as any[]).map((s:any) => `${s.status}:${s.cnt}`),
    activeOrders: {
      total:      Number(activeOrders.total),
      pending:    Number(activeOrders.pending),
      preparing:  Number(activeOrders.preparing),
      delivering: Number(activeOrders.delivering),
      delayed:    Number(activeOrders.delayed),
    },
    // ── ข้อมูลทุก entity ──
    allRiders: (allRiders as any[]).map((r:any) =>
      `${r.name} | เบอร์:${r.phone??'-'} | อีเมล:${r.email??'-'} | ยานพาหนะ:${r.vehicle} | สถานะ:${r.status} | verified:${r.isVerified?'ใช่':'ยัง'} | ส่งแล้ว:${r.runsCompleted}ครั้ง | ★${Number(r.rating).toFixed(1)} | สมัคร:${r.joinDate}`
    ),
    allCustomers: (allCustomers as any[]).map((c:any) =>
      `${c.name} | เบอร์:${c.phone??'-'} | อีเมล:${c.email??'-'} | ที่อยู่:${c.address??'-'} | สมัคร:${c.joinDate}`
    ),
    allRestaurants: (allRestaurants as any[]).map((r:any) =>
      `${r.name} | เบอร์:${r.phone??'-'} | อีเมล:${r.email??'-'} | ประเภท:${r.category} | สถานะ:${r.status} | ★${Number(r.rating).toFixed(1)} | ออเดอร์:${r.totalOrders} | เจ้าของ:${r.owner_name??'-'} | เปิด:${r.open_time??'-'}-${r.close_time??'-'} | ที่อยู่:${r.address??'-'} | ธนาคาร:${r.bank_name??'-'} เลขบัญชี:${r.account_no??'-'} | สมัคร:${r.joinDate}`
    ),
    allMenuItems: (allMenuItems as any[]).map((m:any) =>
      `[${m.restaurant}] ${m.item} ฿${m.price} (หมวด:${m.category??'-'}) ${m.is_available?'มีขาย':'หมด'}`
    ),
    recentOrders: (recentOrders as any[]).map((o:any) =>
      `#${o.orderNumber} | ${o.restaurant}→${o.customer}(${o.customerPhone??'-'}) | ไรเดอร์:${o.rider??'-'} | [${o.status}] ฿${o.totalAmount}+ค่าส่ง฿${o.serviceFee} | รายการ:${o.items??'-'} | ${o.createdAt}`
    ),
    financials: {
      thisMonth:       Math.round(financialStats.thisMonth),
      lastMonth:       Math.round(financialStats.lastMonth),
      monthGrowth,
      allTime:         Math.round(financialStats.allTime),
      avgOrder:        Math.round(financialStats.avgOrder),
      serviceFees:     Math.round(financialStats.totalServiceFees),
      commission:      Math.round(financialStats.thisMonth * 0.15),
      completedOrders: Number(financialStats.completedOrders),
    },
    monthlyTrend: (monthlyTrend as any[]).map((m:any) =>
      `${m.month}:฿${Math.round(m.revenue).toLocaleString()}(${m.orders}ออเดอร์)`
    ),
    recentTransactions: (recentTransactions as any[]).map((t:any) =>
      `#${t.orderNumber} | ${t.restaurant} | ฿${t.amount} → netPayout:฿${t.netPayout} | ${t.status} | ${t.date}`
    ),
    riderReviews: (riderReviews as any[]).map((rv:any) =>
      `${rv.rider} ★${rv.rating} "${rv.comment??''}" โดย${rv.customer_name} (${rv.date})`
    ),
    recentMessages: (recentMessages as any[]).map((msg:any) =>
      `ออเดอร์#${msg.orderNumber} [${msg.sender_role}]${msg.sender_name}: "${msg.message}" (${msg.time})`
    ),
  }
}

// ─── Build system prompt from context ─────────────────────────────────────────

function buildSystemPrompt(ctx: Awaited<ReturnType<typeof getFullContext>>) {
  return `คุณคือ AI ผู้ช่วยของแอดมิน "Zest & Savory" แพลตฟอร์มสั่งอาหารดีลิเวอรี่

กฎสำคัญ:
1. ข้อมูลด้านล่างคือข้อมูลจริงจากฐานข้อมูล ณ ${ctx.today} — ใช้ตอบคำถามได้ทันที
2. ห้ามบอกว่า "ไม่มีการเชื่อมต่อฐานข้อมูล" หรือ "ไม่สามารถดึงข้อมูลได้" เด็ดขาด
3. ถ้าข้อมูลเป็น 0 หรือว่างเปล่า ให้แจ้งตรงๆ ว่ายังไม่มีข้อมูลในส่วนนั้น
4. ตอบภาษาไทย กระชับ มืออาชีพ อ้างอิงข้อมูลจากด้านล่างเสมอ
5. เมื่อถามหาเบอร์โทร/ชื่อ/อีเมล ให้ค้นหาจากรายชื่อด้านล่างแล้วตอบตรงๆ

━━━ DASHBOARD วันนี้ (${ctx.today}) ━━━
รายได้: ฿${ctx.todayRevenue.toLocaleString()} | ออเดอร์: ${ctx.todayOrders} | เฉลี่ย: ฿${ctx.todayAvgOrder}
เทียบเมื่อวาน: ${ctx.revenueGrowth != null ? ctx.revenueGrowth + '%' : 'ไม่มีข้อมูลเมื่อวาน'}
7 วันย้อนหลัง: ${ctx.weeklyRevenue.join(' | ') || 'ยังไม่มีข้อมูล'}
สถานะออเดอร์วันนี้: ${ctx.todayStatusBreakdown.join(', ') || 'ยังไม่มีออเดอร์'}
สถานะออเดอร์ทั้งหมด: ${ctx.allStatusCounts.join(', ') || '-'}

🚨 ออเดอร์ active ตอนนี้: รวม ${ctx.activeOrders.total} | รอ:${ctx.activeOrders.pending} | ทำ:${ctx.activeOrders.preparing} | ส่ง:${ctx.activeOrders.delivering} | ล่าช้า:${ctx.activeOrders.delayed}

━━━ ไรเดอร์ทั้งหมด (${ctx.allRiders.length} คน) ━━━
${ctx.allRiders.map(r => '- ' + r).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ ลูกค้าทั้งหมด (${ctx.allCustomers.length} คน) ━━━
${ctx.allCustomers.map(c => '- ' + c).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ ร้านอาหารทั้งหมด (${ctx.allRestaurants.length} ร้าน) ━━━
${ctx.allRestaurants.map(r => '- ' + r).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ เมนูอาหาร ━━━
${ctx.allMenuItems.map(m => '- ' + m).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ ออเดอร์ล่าสุด 100 รายการ ━━━
${ctx.recentOrders.map(o => '- ' + o).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ การเงิน ━━━
เดือนนี้: ฿${ctx.financials.thisMonth.toLocaleString()} ${ctx.financials.monthGrowth != null ? '(' + ctx.financials.monthGrowth + '% vs เดือนที่แล้ว)' : ''}
เดือนที่แล้ว: ฿${ctx.financials.lastMonth.toLocaleString()}
รายได้รวมตลอดกาล: ฿${ctx.financials.allTime.toLocaleString()} | ออเดอร์สำเร็จ: ${ctx.financials.completedOrders.toLocaleString()} รายการ
Commission 15%: ฿${ctx.financials.commission.toLocaleString()} | Service Fees: ฿${ctx.financials.serviceFees.toLocaleString()} | เฉลี่ย/ออเดอร์: ฿${ctx.financials.avgOrder}
Trend 12 เดือน: ${ctx.monthlyTrend.join(' → ') || 'ยังไม่มีข้อมูล'}

━━━ Transaction ล่าสุด 50 รายการ ━━━
${ctx.recentTransactions.map(t => '- ' + t).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ รีวิวไรเดอร์ล่าสุด ━━━
${ctx.riderReviews.map(r => '- ' + r).join('\n') || 'ยังไม่มีข้อมูล'}

━━━ แชทล่าสุดในระบบ ━━━
${ctx.recentMessages.map(m => '- ' + m).join('\n') || 'ยังไม่มีข้อมูล'}`
}

// ─── Route handler ─────────────────────────────────────────────────────────────

export async function POST(req: NextRequest) {
  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey || apiKey === 'your-anthropic-api-key-here') {
    return new Response(JSON.stringify({ error: 'API key not set' }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    })
  }

  const { messages } = await req.json()
  const ctx = await getFullContext()
  const systemPrompt = buildSystemPrompt(ctx)

  const encoder = new TextEncoder()
  const stream = new ReadableStream({
    async start(controller) {
      const res = await fetch(`${BASE_URL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: MODEL,
          messages: [
            { role: 'system', content: systemPrompt },
            ...messages,
          ],
          stream: true,
        }),
      })

      if (!res.ok || !res.body) {
        const errText = await res.text()
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: errText })}\n\n`))
        controller.close()
        return
      }

      const reader = res.body.getReader()
      const dec = new TextDecoder()
      let buf = ''
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        buf += dec.decode(value, { stream: true })
        const lines = buf.split('\n')
        buf = lines.pop() ?? ''
        for (const line of lines) {
          if (!line.startsWith('data:')) continue
          const raw = line.slice(5).trim()
          if (raw === '[DONE]') continue
          try {
            const evt = JSON.parse(raw)
            const text = evt.choices?.[0]?.delta?.content
            if (text) controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text })}\n\n`))
          } catch { /* skip malformed */ }
        }
      }
      controller.enqueue(encoder.encode('data: [DONE]\n\n'))
      controller.close()
    },
  })

  return new Response(stream, {
    headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
      connection: 'keep-alive',
    },
  })
}
