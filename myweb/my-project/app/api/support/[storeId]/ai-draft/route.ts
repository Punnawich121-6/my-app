import { NextRequest, NextResponse } from 'next/server'
import pool from '@/app/lib/db'

const BASE_URL = process.env.AI_BASE_URL ?? 'https://gen.ai.kku.ac.th/api/v1'
const MODEL    = process.env.AI_MODEL     ?? 'o4-mini'

export async function POST(
  _req: NextRequest,
  { params }: { params: Promise<{ storeId: string }> }
) {
  const { storeId } = await params

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey || apiKey === 'your-anthropic-api-key-here') {
    return NextResponse.json({ error: 'API key not set' }, { status: 500 })
  }

  // Fetch conversation history
  const [rows]: any = await pool.query(
    'SELECT sender_role, sender_name, message FROM support_messages WHERE store_id = ? ORDER BY created_at ASC',
    [storeId]
  )

  if (!rows.length) {
    return NextResponse.json({ error: 'ยังไม่มีข้อความในการสนทนา' }, { status: 400 })
  }

  // Format conversation for AI
  const conversation = (rows as any[])
    .map((m: any) => {
      const who = m.sender_role === 'store'
        ? `ร้านค้า (${m.sender_name ?? 'ร้านค้า'})`
        : `Admin (${m.sender_name ?? 'Admin'})`
      return `${who}: ${m.message}`
    })
    .join('\n')

  const lastMsg = (rows as any[]).filter((m: any) => m.sender_role === 'store').at(-1)
  const lastQuestion = lastMsg?.message ?? ''

  const prompt = `ประวัติการสนทนาระหว่าง Admin และร้านค้า:

${conversation}

---
คุณเป็น Admin ของแพลตฟอร์ม Food Delivery "Zest & Savory" ช่วยร่างคำตอบภาษาไทยให้ร้านค้าสำหรับข้อความล่าสุด: "${lastQuestion}"

กฎ:
- ตอบเป็นภาษาไทย สุภาพ เป็นกันเอง กระชับ
- อ้างถึงเนื้อหาที่ร้านค้าถามโดยตรง
- ถ้าไม่มีข้อมูลเพียงพอ ให้บอกว่าจะตรวจสอบและแจ้งกลับ
- ตอบแค่ข้อความที่จะส่งให้ร้านค้าเท่านั้น ไม่ต้องมีคำนำหรือคำอธิบายเพิ่มเติม`

  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: 'system', content: 'คุณเป็น Admin ของแพลตฟอร์ม Food Delivery Zest & Savory ตอบภาษาไทย กระชับ สุภาพ' },
        { role: 'user', content: prompt },
      ],
      stream: false,
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    return NextResponse.json({ error: err }, { status: res.status })
  }

  const data = await res.json()
  const draft = data.choices?.[0]?.message?.content?.trim() ?? ''
  return NextResponse.json({ draft })
}
