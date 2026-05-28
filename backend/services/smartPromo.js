const db = require('../db');

const AI_BASE_URL = process.env.AI_BASE_URL || 'https://gen.ai.kku.ac.th/api/v1';
const AI_API_KEY  = process.env.AI_API_KEY  || '';
const AI_MODEL    = process.env.AI_MODEL    || 'deepseek-v3.2';

async function analyzeStore(storeId) {
  try {
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];

    const [[salesRow]] = await db.query(
      `SELECT COALESCE(SUM(totalAmount), 0) AS todaySales, COUNT(*) AS todayOrders
       FROM \`Order\`
       WHERE restaurantId = ? AND DATE(createdAt) = ? AND status NOT IN ('cancelled')`,
      [storeId, todayStr]
    );

    const [[storeRow]] = await db.query(
      'SELECT id, name FROM Restaurant WHERE id = ? LIMIT 1',
      [storeId]
    );
    if (!storeRow) return null;

    const threeHoursAgo = new Date(today.getTime() - 3 * 60 * 60 * 1000);
    const [slowMenus] = await db.query(
      `SELECT mi.id, mi.name, mi.price
       FROM menu_items mi
       WHERE mi.store_id = ?
         AND mi.is_available = 1
         AND mi.id NOT IN (
           SELECT DISTINCT oi.menu_item_id
           FROM order_items oi
           JOIN \`Order\` o ON o.id = oi.order_id
           WHERE o.restaurantId = ? AND o.createdAt >= ?
         )
       LIMIT 5`,
      [storeId, storeId, threeHoursAgo]
    );

    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    const sevenDaysAgo  = new Date(today.getTime() -  7 * 24 * 60 * 60 * 1000);
    const [[inactiveRow]] = await db.query(
      `SELECT COUNT(DISTINCT customerId) AS inactiveCount
       FROM \`Order\`
       WHERE restaurantId = ?
         AND createdAt >= ? AND createdAt < ?
         AND status NOT IN ('cancelled')`,
      [storeId, thirtyDaysAgo, sevenDaysAgo]
    );

    const targetDailySales = 1500;
    const todaySales       = parseFloat(salesRow.todaySales) || 0;
    const todayOrders      = parseInt(salesRow.todayOrders)  || 0;
    const inactiveCount    = parseInt(inactiveRow.inactiveCount) || 0;
    const slowMenuNames    = slowMenus.map(m => m.name).join(', ') || 'ไม่มี';

    const currentHour = today.getHours();
    const prompt = `คุณเป็น AI ที่วิเคราะห์ข้อมูลร้านอาหารและตัดสินใจว่าควรสร้างโปรโมชั่นอัตโนมัติหรือไม่

ข้อมูลร้านอาหาร: ${storeRow.name}
- ยอดขายวันนี้: ฿${todaySales.toFixed(2)} (เป้าหมาย: ฿${targetDailySales})
- จำนวนออเดอร์วันนี้: ${todayOrders} รายการ
- เมนูที่ไม่มีออเดอร์ใน 3 ชั่วโมงที่ผ่านมา: ${slowMenuNames}
- ลูกค้าที่สั่งใน 30 วันที่แล้วแต่ไม่สั่งใน 7 วันนี้: ${inactiveCount} คน
- เวลาปัจจุบัน: ${currentHour}:00 น.

วิเคราะห์และตัดสินใจว่าควรสร้างโปรโมชั่นหรือไม่ ตอบเป็น JSON เท่านั้น ห้ามมีข้อความอื่น:
{
  "shouldCreate": true หรือ false,
  "triggerType": "low_sales" หรือ "slow_menu" หรือ "inactive_customer" หรือ "peak_upcoming",
  "promoType": "flash_sale" หรือ "bogo" หรือ "free_delivery" หรือ "discount",
  "title": "ชื่อโปรโมชั่น (ภาษาไทย)",
  "description": "คำอธิบายโปรโมชั่น (ภาษาไทย)",
  "discountType": "percentage" หรือ "fixed" หรือ "free_delivery",
  "discountValue": <ตัวเลข เช่น 20 คือ 20% หรือ 50 คือลด 50 บาท>,
  "durationMinutes": <ระยะเวลาโปรโมชั่น เช่น 60 หรือ 120>,
  "reasoning": "เหตุผลที่ควรหรือไม่ควรสร้างโปรโมชั่น (ภาษาไทย)",
  "expectedRevenue": <รายได้ที่คาดว่าจะได้เพิ่ม เป็นตัวเลข>,
  "expectedCost": <ต้นทุนโปรโมชั่นโดยประมาณ เป็นตัวเลข>
}`;

    const res = await fetch(`${AI_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${AI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: AI_MODEL,
        messages: [
          {
            role: 'system',
            content: 'คุณเป็น AI ผู้เชี่ยวชาญด้านการตลาดร้านอาหาร วิเคราะห์ข้อมูลและแนะนำโปรโมชั่นที่เหมาะสม ตอบเป็น JSON เท่านั้น',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0.3,
      }),
    });

    if (!res.ok) {
      console.error('[smartPromo] AI API error:', res.status);
      return null;
    }

    const data = await res.json();
    const raw  = data.choices?.[0]?.message?.content?.trim() || '{}';
    const match = raw.match(/\{[\s\S]*\}/);
    if (!match) return null;

    return JSON.parse(match[0]);
  } catch (err) {
    console.error('[smartPromo] analyzeStore error:', err.message);
    return null;
  }
}

module.exports = { analyzeStore };
