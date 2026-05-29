import { NextRequest, NextResponse } from 'next/server'

const BACKEND = process.env.BACKEND_URL ?? 'http://localhost:3001'

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ storeId: string }> }
) {
  const { storeId } = await params
  const formData = await req.formData()

  const res = await fetch(`${BACKEND}/api/support/${storeId}/upload`, {
    method: 'POST',
    headers: { 'ngrok-skip-browser-warning': 'true' },
    body: formData,
  })

  if (!res.ok) {
    const text = await res.text()
    return NextResponse.json({ error: text }, { status: res.status })
  }

  const data = await res.json()
  return NextResponse.json(data)
}
