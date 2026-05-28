import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get('q')?.trim()
  if (!q) return NextResponse.json({ results: [] })

  const key = process.env.UNSPLASH_ACCESS_KEY
  if (!key) {
    return NextResponse.json({ error: 'UNSPLASH_ACCESS_KEY not set in .env.local' }, { status: 500 })
  }

  const res = await fetch(
    `https://api.unsplash.com/search/photos?query=${encodeURIComponent(q)}&per_page=12&orientation=squarish`,
    { headers: { Authorization: `Client-ID ${key}` } }
  )

  if (!res.ok) {
    const err = await res.text()
    return NextResponse.json({ error: err }, { status: res.status })
  }

  const data = await res.json()
  const results = (data.results ?? []).map((p: any) => ({
    id: p.id,
    thumb: p.urls.thumb,
    regular: p.urls.regular,
    alt: p.alt_description || q,
    author: p.user?.name ?? '',
  }))

  return NextResponse.json({ results })
}
