import { NextRequest, NextResponse } from 'next/server'
import {
  getQuarterlyHistory,
  getMonthlyBreakdown,
  getCategoryBreakdown,
  getMonthRangeSummary,
  getTopRestaurants,
  getOrderStatusBreakdown,
  getCancelStats,
  getRiderStats,
  getPlatformEarnings,
  getRestaurantHealthStats,
  getPeakHours,
} from '@/app/lib/analytics'

const BASE_URL = process.env.AI_BASE_URL        ?? 'https://gen.ai.kku.ac.th/api/v1'
const MODEL    = process.env.AI_ANALYTICS_MODEL ?? process.env.AI_MODEL ?? 'o4-mini'

const MONTH_TH_FULL = ['', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม']
const MONTH_ABBR = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']

export async function POST(req: NextRequest) {
  const { year, startMonth, endMonth, planPeriod = 3, skipAI = false } = await req.json()
  const yr     = Number(year)
  const sm     = Number(startMonth)
  const em     = Number(endMonth)
  const period = Number(planPeriod) as 1 | 2 | 3 | 6 | 12

  // Fetch all data in parallel
  const [
    monthly, categories, current,
    topRestaurants, statusBreakdown, cancelStats,
    riderStats, platformEarnings, restaurantHealth, peakHours,
  ] = await Promise.all([
    getMonthlyBreakdown(yr, sm, em),
    getCategoryBreakdown(yr, sm, em),
    getMonthRangeSummary(yr, sm, em),
    getTopRestaurants(yr, sm, em),
    getOrderStatusBreakdown(yr, sm, em),
    getCancelStats(yr, sm, em),
    getRiderStats(),
    getPlatformEarnings(yr, sm, em),
    getRestaurantHealthStats(),
    getPeakHours(yr, sm, em),
  ])

  // Growth: compare with previous period of same length
  const monthCount   = em - sm + 1
  let prevEndMonth   = sm - 1
  let prevStartMonth = prevEndMonth - monthCount + 1
  let prevYear       = yr
  if (prevEndMonth <= 0) {
    prevYear       = yr - 1
    prevEndMonth  += 12
    prevStartMonth += 12
  }
  const prev = prevStartMonth >= 1
    ? await getMonthRangeSummary(prevYear, prevStartMonth, prevEndMonth)
    : null
  const growth = prev && prev.revenue > 0
    ? (((current?.revenue ?? 0) - prev.revenue) / prev.revenue * 100).toFixed(1)
    : null

  if (skipAI) {
    return NextResponse.json({ growth, current, monthly, categories })
  }

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey || apiKey === 'your-anthropic-api-key-here') {
    return NextResponse.json({ error: 'API key not set', growth, current, monthly, categories }, { status: 500 })
  }

  const periodLabel = sm === 1 && em === 12
    ? `ทั้งปี ${yr}`
    : sm === em
    ? `${MONTH_TH_FULL[sm]} ${yr}`
    : `${MONTH_ABBR[sm]}–${MONTH_ABBR[em]} ${yr}`

  const monthNames: string[] = []
  for (let m = sm; m <= em; m++) monthNames.push(MONTH_TH_FULL[m])

  // Format peak hours
  const peakHoursText = peakHours.length > 0
    ? peakHours.map(h => `  ${String(h.hour).padStart(2, '0')}:00–${String(h.hour + 1).padStart(2, '0')}:00 (${h.orderCount} ออเดอร์)`).join('\n')
    : '  ไม่มีข้อมูล'

  // Format order status
  const statusText = statusBreakdown.length > 0
    ? statusBreakdown.map(s => `  ${s.status}: ${s.count} รายการ`).join('\n')
    : '  ไม่มีข้อมูล'

  // Rider demand ratio
  const ordersPerRider = riderStats.totalRiders > 0
    ? (cancelStats.total / riderStats.totalRiders).toFixed(1)
    : 'N/A'

  const history = await getQuarterlyHistory()

  // One section per month regardless of planPeriod
  const monthPlanTemplate = monthNames.map((name, i) => `### เดือนที่ ${i + 1}: ${name}
**เป้าหมายรายได้:** ระบุตัวเลขบาท และอธิบายเหตุผลว่าทำไมตั้งเป้าระดับนี้ โดยอิงจากข้อมูลที่มี
**แผนปฏิบัติการ:**
- ด้านร้านอาหาร: ระบุสิ่งที่ต้องทำ และบอกเหตุผลว่าทำไมถึงต้องทำสิ่งนี้ในเดือนนี้ อิงจากข้อมูลอะไร
- ด้านไรเดอร์: ระบุสิ่งที่ต้องทำ และบอกเหตุผลว่าทำไมถึงต้องทำสิ่งนี้ในเดือนนี้ อิงจากข้อมูลอะไร
- ด้าน Marketing/Promotion: ระบุสิ่งที่ต้องทำ และบอกเหตุผลว่าทำไมถึงต้องทำสิ่งนี้ในเดือนนี้ อิงจากข้อมูลอะไร
- ด้านการดำเนินงาน: ระบุสิ่งที่ต้องทำ และบอกเหตุผลว่าทำไมถึงต้องทำสิ่งนี้ในเดือนนี้ อิงจากข้อมูลอะไร
**KPI ที่ต้องติดตาม:** ระบุ 2-3 ตัวชี้วัด พร้อม target ตัวเลข และเหตุผลว่าทำไมถึงเลือก KPI นี้`).join('\n\n')

  const prompt = `คุณเป็นที่ปรึกษาธุรกิจ Food Delivery แพลตฟอร์ม "Zest & Savory" ที่เชี่ยวชาญด้าน Data Analytics

═══ ข้อมูลธุรกิจ ช่วง ${periodLabel} ═══

【รายได้และออเดอร์】
- รายได้รวม: ${(current?.revenue ?? 0).toLocaleString('th-TH')} บาท
- Commission ที่แพลตฟอร์มได้รับ: ${platformEarnings.commission.toLocaleString('th-TH')} บาท
- ออเดอร์ทั้งหมด: ${cancelStats.total.toLocaleString()} รายการ
- ออเดอร์สำเร็จ: ${(current?.orderCount ?? 0).toLocaleString()} รายการ
- อัตรา Cancel: ${cancelStats.cancelRate}% (${cancelStats.cancelled} รายการ)
- มูลค่าเฉลี่ย/ออเดอร์: ${(current?.avgOrderValue ?? 0).toFixed(0)} บาท
${growth ? `- การเติบโต vs ช่วงก่อนหน้า: ${growth}%` : '- การเติบโต: ไม่มีข้อมูลช่วงก่อน'}

【สถานะออเดอร์แยกประเภท】
${statusText}

【ช่วง Peak Hours (Top 5)】
${peakHoursText}

【รายได้รายเดือน】
${monthly.map(m => `- ${m.monthName}: ${m.revenue.toLocaleString('th-TH')} บาท (${m.orderCount} ออเดอร์)`).join('\n')}

【ร้านอาหาร Top 5】
${topRestaurants.length > 0
  ? topRestaurants.map((r, i) => `${i + 1}. ${r.name}: ${r.revenue.toLocaleString('th-TH')} บาท | ${r.orderCount} ออเดอร์ | ⭐ ${r.avgRating}`).join('\n')
  : 'ไม่มีข้อมูล'}

【สุขภาพร้านอาหาร (ทั้งหมดในระบบ)】
- ร้านทั้งหมด: ${restaurantHealth.total} ร้าน
- Active: ${restaurantHealth.active} | Inactive: ${restaurantHealth.inactive} | รอตรวจสอบ: ${restaurantHealth.pending}
- Rating เฉลี่ยทั้งระบบ: ${restaurantHealth.avgRating} ⭐

【หมวดอาหาร (Top Categories)】
${categories.slice(0, 6).map(c => `- ${c.category}: ${c.revenue.toLocaleString('th-TH')} บาท (${c.share}%)`).join('\n')}

【ไรเดอร์】
- ไรเดอร์ทั้งหมด: ${riderStats.totalRiders} คน (Online ขณะนี้: ${riderStats.onlineRiders} คน)
- Rating เฉลี่ย: ${riderStats.avgRating} ⭐
- Deliveries ที่ทำมาแล้ว (รวม): ${riderStats.totalCompletedRuns.toLocaleString()} ครั้ง
- สัดส่วนออเดอร์/ไรเดอร์: ${ordersPerRider} ออเดอร์/คน

【ข้อมูลย้อนหลัง 4 ไตรมาส】
${history.slice(0, 4).map(h => `- Q${h.quarter}/${h.year}: ${h.revenue.toLocaleString('th-TH')} บาท, ${h.orderCount} ออเดอร์`).join('\n')}

═══════════════════════════════════

จากข้อมูลข้างต้น กรุณาวิเคราะห์และวางแผนธุรกิจ **${periodLabel}** (${monthNames.length} เดือน) ดังนี้:

## สรุปภาพรวมและปัญหาที่ตรวจพบ
(3-4 ประโยค อ้างอิงตัวเลขจริง: รายได้, แนวโน้ม, cancel rate, ไรเดอร์, ร้าน inactive พร้อมบอกว่าข้อมูลตัวเลขนั้นบ่งบอกอะไร)

## แผนปฏิบัติการรายเดือน
(วางแผนให้ครบทุกเดือนด้านล่าง แต่ละเดือนต้องมีเหตุผลกำกับทุกข้อ)

${monthPlanTemplate}

## คำแนะนำภาพรวมสำหรับช่วงนี้
- **ด้านขยายธุรกิจ:** ระบุว่าควรขยายรัศมี delivery หรือเพิ่มร้านหมวดไหน และบอกเหตุผลโดยอิงจากข้อมูลที่มี
- **ด้านไรเดอร์:** ระบุว่าควรรับเพิ่มไหม ช่วงไหน กี่คน และบอกเหตุผลโดยอิงจากสัดส่วนออเดอร์/ไรเดอร์และ peak hour
- **ด้าน Promotion:** ระบุช่วงเวลา หมวดอาหาร หรือกลุ่มลูกค้าที่ควร focus และบอกเหตุผลโดยอิงจากข้อมูล category และ peak hour
- **ด้านร้านอาหาร:** ระบุว่าร้านไหนต้อง activate หรือพัฒนา และบอกเหตุผลโดยอิงจากจำนวน inactive และ rating

ตอบภาษาไทย กระชับ มืออาชีพ อ้างอิงตัวเลขจากข้อมูลจริงเสมอทุกข้อ ห้ามคาดเดาโดยไม่มีฐานจากข้อมูล`

  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: 'system', content: 'คุณเป็นที่ปรึกษาธุรกิจ Food Delivery ผู้เชี่ยวชาญ วิเคราะห์จากข้อมูลจริง ให้คำแนะนำที่นำไปปฏิบัติได้ทันที อ้างอิงตัวเลขเสมอ' },
        { role: 'user', content: prompt },
      ],
      stream: false,
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    return NextResponse.json({ error: err, growth, current, monthly, categories }, { status: res.status })
  }

  const data = await res.json()
  const analysis = data.choices?.[0]?.message?.content ?? ''
  return NextResponse.json({ analysis, growth, current, monthly, categories })
}
