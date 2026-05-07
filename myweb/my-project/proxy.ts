import { NextRequest, NextResponse } from 'next/server'
import { decrypt } from '@/app/lib/session'

// หน้าต้อง login ถึงจะเข้าได้
const protectedRoutes = ['/dashboard', '/orders', '/restaurants', '/fleet', '/financials', '/settings', '/help']
// หน้าไม่ต้อง login ก็เข้าได้
const publicRoutes    = ['/login', '/'] 

export default async function proxy(req: NextRequest) {

  //ดึง path จาก URL ว่ามันชื่ออะไร เช่น /dashboard หรือ /login เป็นต้น
  const path = req.nextUrl.pathname

  // เช็คว่า path ที่เข้ามาเป็น protected route ไหม เช่น /dashboard หรือ /orders เป็นต้น
  const isProtected = protectedRoutes.some(r => path.startsWith(r))

  // เช็คว่า path ที่เข้ามาเป็น public route หรือหน้า  /login
  const isPublic    = publicRoutes.includes(path)

  // หาคุกกี้ที่ชื่อว่า 'session' แล้วดึงเอาข้อมูลที่อยู่ข้างในนั้น
  const token = req.cookies.get('session')?.value

  // เอามถอดรหัส token ที่ได้จากคุกกี้ เพื่อให้ได้ข้อมูล session กลับมา เช่น userId เป็นต้น
  const session     = await decrypt(token)

  // ยังไม่ login แต่พยายามเข้า protected route
  if (isProtected && !session?.userId) {
    return NextResponse.redirect(new URL('/login', req.nextUrl))
  }

  // login แล้ว แต่พยายามเข้า /login อีก
  if (isPublic && session?.userId) {
    return NextResponse.redirect(new URL('/dashboard', req.nextUrl))
  }

  return NextResponse.next()
}
// กำหนดว่า middleware นี้จะทำงานกับ path ไหนบ้าง โดยจะทำงานกับทุก path ที่ไม่ใช่ /api, /_next/static, /_next/image และไฟล์รูปภาพต่างๆ
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|.*\\.png$|.*\\.jpg$).*)'],
}
