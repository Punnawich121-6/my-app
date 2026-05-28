import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  const url = req.nextUrl.searchParams.get('url')
  if (!url) return new NextResponse('Missing url param', { status: 400 })

  try {
    const res = await fetch(url)
    if (!res.ok) return new NextResponse('Upstream fetch failed', { status: res.status })

    const blob = await res.blob()
    return new NextResponse(blob, {
      headers: {
        'Content-Type': res.headers.get('content-type') || 'image/jpeg',
        'Cache-Control': 'public, max-age=86400',
      },
    })
  } catch {
    return new NextResponse('Failed to fetch image', { status: 500 })
  }
}
