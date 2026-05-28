import { NextRequest, NextResponse } from 'next/server'

const BASE_URL = process.env.AI_BASE_URL          ?? 'https://gen.ai.kku.ac.th/api/v1'
const MODEL    = process.env.AI_DESCRIPTION_MODEL ?? process.env.AI_MODEL ?? 'gemini-2.5-flash'

export async function POST(req: NextRequest) {
  const { name, category, address } = await req.json()

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey || apiKey === 'your-anthropic-api-key-here') {
    return NextResponse.json({ error: 'API key not set' }, { status: 500 })
  }

  const prompt = `เขียนคำอธิบายร้านอาหารสั้นๆ ภาษาไทย 2-3 ประโยค น่าสนใจและดึงดูดใจลูกค้า สำหรับร้าน "${name}" ประเภท ${category}${address ? ` ตั้งอยู่ที่ ${address}` : ''}. ตอบเฉพาะคำอธิบายเท่านั้น ไม่ต้องมีคำนำหรือคำลงท้าย`

  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: 'system', content: 'คุณเป็นผู้เชี่ยวชาญด้านการเขียนคำอธิบายร้านอาหารภาษาไทย' },
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
  const description = data.choices?.[0]?.message?.content ?? ''
  return NextResponse.json({ description })
}
