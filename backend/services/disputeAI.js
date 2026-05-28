const AI_BASE_URL = process.env.AI_BASE_URL || 'https://gen.ai.kku.ac.th/api/v1';
const AI_API_KEY  = process.env.AI_API_KEY  || process.env.ANTHROPIC_API_KEY || '';
const AI_MODEL    = process.env.AI_DISPUTE_MODEL || process.env.AI_MODEL || 'deepseek-v3.2';

const REASON_LABELS = {
  not_received:  'ไม่ได้รับอาหาร',
  wrong_item:    'ได้รับอาหารผิดรายการ',
  late_delivery: 'อาหารส่งช้ามาก',
  quality_issue: 'คุณภาพอาหารไม่ตรงมาตรฐาน',
  overcharged:   'ถูกเรียกเก็บเงินผิด',
  other:         'ปัญหาอื่นๆ',
};

async function analyzeDispute(evidence) {
  const {
    orderNumber, reasonType, description, orderStatus,
    orderItems, totalAmount, orderAge,
    customerDisputeCount, restaurantName, riderName, hasPhoto,
  } = evidence;

  const itemList = orderItems.map(i => `- ${i.name} x${i.quantity} (${i.price} บาท)`).join('\n');

  const prompt = `วิเคราะห์ dispute ต่อไปนี้และตอบเป็น JSON เท่านั้น:

ข้อมูล Dispute:
- หมายเลขออเดอร์: ${orderNumber}
- ประเภทปัญหา: ${REASON_LABELS[reasonType] || reasonType}
- คำอธิบายจากลูกค้า: ${description || '(ไม่ระบุ)'}
- สถานะออเดอร์ปัจจุบัน: ${orderStatus}
- เวลาตั้งแต่สั่งอาหารจนแจ้งปัญหา: ${orderAge} นาที
- มีรูปหลักฐานแนบมา: ${hasPhoto ? 'ใช่' : 'ไม่มี'}

รายการอาหาร:
${itemList}
มูลค่ารวม: ฿${totalAmount}

ร้านอาหาร: ${restaurantName || 'ไม่ทราบ'}
ไรเดอร์: ${riderName || 'ยังไม่มีไรเดอร์รับงาน'}

ประวัติลูกค้า:
- จำนวน dispute ที่เคยแจ้งมาก่อน: ${customerDisputeCount} ครั้ง

กฎการประเมินตามประเภทปัญหา:

[A] ไม่ได้รับอาหาร (not_received):
  A1. สถานะ completed + มีไรเดอร์ → ผิดไรเดอร์ → confidence 80-90%, fault=rider, refund=full
  A2. สถานะ completed + ไม่มีไรเดอร์ → ผิดร้าน → confidence 70-80%, fault=merchant, refund=full
  A3. สถานะ delivering/at_store → อาจยังระหว่างส่ง → confidence 40-55%, fault=none, refund=none, verdict=inconclusive
  A4. สถานะ cancelled → ออเดอร์ถูกยกเลิกแล้ว → confidence 85%, fault=merchant, refund=full

[B] ได้รับผิดรายการ (wrong_item):
  B1. มีรูปหลักฐาน → ผิดที่ร้าน → confidence 85-92%, fault=merchant, refund=partial (เฉพาะรายการที่ผิด)
  B2. ไม่มีรูป + อธิบายชัดเจน → confidence 60-70%, fault=merchant, refund=partial
  B3. ไม่มีรูป + อธิบายคลุมเครือ → confidence 35-50%, verdict=inconclusive

[C] อาหารส่งช้า (late_delivery):
  C1. เวลา > 90 นาที → ช้าจริง → confidence 80-88%, fault=shared (rider+merchant), refund=partial (20-30%)
  C2. เวลา 60-90 นาที → ช้าพอควร → confidence 60-72%, fault=rider, refund=partial (10-20%)
  C3. เวลา 45-60 นาที → กำกวม → confidence 40-55%, verdict=inconclusive
  C4. เวลา < 45 นาที → ยังไม่ถือว่าช้า → confidence 20-35%, fault=none, refund=none, verdict=merchant_wins

[D] คุณภาพอาหารไม่ตรงมาตรฐาน (quality_issue):
  D1. มีรูปหลักฐาน + อธิบายชัด → ผิดร้าน → confidence 75-85%, fault=merchant, refund=partial (30-50%)
  D2. มีรูปหลักฐาน + อธิบายคลุมเครือ → confidence 55-65%, fault=merchant, refund=partial (20-30%)
  D3. ไม่มีรูป → ยืนยันได้ยาก → confidence 30-45%, verdict=inconclusive
  D4. อาหารร้อน/เย็นผิดปกติ + เวลาส่งนาน → รับผิดร่วม (rider+merchant) → refund=partial (15-25%)

[E] ถูกเรียกเก็บเงินผิด (overcharged):
  E1. ยอดในออเดอร์ไม่ตรงกับที่จ่ายจริง (ดูจาก totalAmount) → confidence 85-92%, fault=merchant, refund=partial (ส่วนต่าง)
  E2. อธิบายว่าโดนคิดซ้ำ/คิดผิดรายการ → confidence 70-80%, fault=merchant, refund=partial
  E3. ไม่มีรายละเอียดชัดเจน → confidence 40-55%, verdict=inconclusive

[F] ปัญหาอื่นๆ (other) — อ่านคำอธิบายลูกค้าแล้วจับ pattern:
  F1. คำอธิบายตรงกับกรณี A-E ข้างต้น → ใช้กฎนั้นเลย
  F2. เกี่ยวกับความปลอดภัย/สิ่งแปลกปลอมในอาหาร + มีรูป → confidence 80-88%, fault=merchant, refund=full
  F3. เกี่ยวกับพฤติกรรมไรเดอร์ (หยาบคาย/ไม่ส่งของ) + อธิบายชัด → confidence 65-75%, fault=rider, refund=none
  F4. คำอธิบายชัดเจนแต่ไม่ตรงกับกรณีใดเลย → confidence 40-55%, verdict=inconclusive ส่ง admin
  F5. คำอธิบายสั้น/คลุมเครือ/ไม่มีเลย → confidence 20-35%, verdict=inconclusive ส่ง admin

ปัจจัยปรับ confidence (ใช้กับทุกกรณี):
- ลูกค้ามี dispute ≥ 4 ครั้ง → ลด confidence 10-15%
- ลูกค้ามี dispute ≥ 8 ครั้ง → ลด confidence 20%, เพิ่มน้ำหนักว่าอาจเป็น fraud
- ไม่มีรูปในกรณีที่รูปช่วยยืนยันได้ → ลด confidence 10%
- มีรูปหลักฐาน → เพิ่ม confidence 5-10%
- สถานะออเดอร์สอดคล้องกับที่ร้องเรียน → เพิ่ม confidence 5%

ตอบ JSON รูปแบบนี้เท่านั้น ห้ามมีข้อความอื่น:
{
  "confidence": <0-100>,
  "verdict": "<customer_wins|merchant_wins|rider_wins|shared_fault|inconclusive>",
  "fault_party": "<customer|merchant|rider|shared|none>",
  "refund_type": "<full|partial|none>",
  "refund_percentage": <0-100>,
  "reasoning": "<อธิบายเหตุผล 2-3 ประโยค อ้างอิงข้อมูลจริง>"
}`;

  try {
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
            content: 'คุณเป็น AI mediator ที่ยุติธรรมและเที่ยงตรงสำหรับแพลตฟอร์ม Food Delivery วิเคราะห์ dispute จากหลักฐานที่มี ตอบเป็น JSON เท่านั้น ห้ามมีข้อความอื่นนอกจาก JSON',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0.2,
      }),
    });

    if (!res.ok) {
      console.error('[disputeAI] API error:', res.status, await res.text());
      return fallback();
    }

    const data = await res.json();
    const raw = data.choices?.[0]?.message?.content?.trim() || '{}';
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return fallback();

    const p = JSON.parse(jsonMatch[0]);
    return {
      confidence:        Math.max(0, Math.min(100, Number(p.confidence) || 40)),
      verdict:           p.verdict        || 'inconclusive',
      faultParty:        p.fault_party    || 'none',
      refundType:        p.refund_type    || 'none',
      refundPercentage:  Math.max(0, Math.min(100, Number(p.refund_percentage) || 0)),
      reasoning:         p.reasoning      || 'ไม่สามารถวิเคราะห์ได้',
    };
  } catch (err) {
    console.error('[disputeAI] Error:', err.message);
    return fallback();
  }
}

function fallback() {
  return {
    confidence: 35,
    verdict: 'inconclusive',
    faultParty: 'none',
    refundType: 'none',
    refundPercentage: 0,
    reasoning: 'ไม่สามารถวิเคราะห์อัตโนมัติได้ กรุณา admin ตรวจสอบด้วยตนเอง',
  };
}

module.exports = { analyzeDispute };
