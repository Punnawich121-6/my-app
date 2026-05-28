import { NextRequest, NextResponse } from 'next/server'

// หน้าต้อง login ถึงจะเข้าได้
const protectedRoutes = ['/dashboard', '/orders', '/restaurants', '/fleet', '/financials', '/settings', '/help']
// หน้าไม่ต้อง login ก็เข้าได้
const publicRoutes    = ['/login', '/'] 

// เอา async ออกได้เลย เพราะเราไม่ได้ใช้ await แล้ว
export default function middleware(req: NextRequest) {

  // ดึง path จาก URL ว่ามันชื่ออะไร เช่น /dashboard หรือ /login เป็นต้น
  const path = req.nextUrl.pathname

  // เช็คว่า path ที่เข้ามาเป็น protected route ไหม เช่น /dashboard หรือ /orders เป็นต้น
  const isProtected = protectedRoutes.some(r => path.startsWith(r))

  // เช็คว่า path ที่เข้ามาเป็น public route หรือหน้า /login
  const isPublic    = publicRoutes.includes(path)

  // 💡 เปลี่ยนจาก decrypt เป็นการเช็คแค่ว่า "มี" คุกกี้ชื่อ 'session' หรือเปล่า
  const hasSession = req.cookies.has('session')

  // ยังไม่ login (ไม่มีคุกกี้) แต่พยายามเข้า protected route ให้เด้งไปหน้า login
  if (isProtected && !hasSession) {
    return NextResponse.redirect(new URL('/login', req.nextUrl))
  }

  // login แล้ว (มีคุกกี้) แต่พยายามเข้า /login อีก ให้เด้งไปหน้า dashboard
  if (isPublic && hasSession && path === '/login') {
    return NextResponse.redirect(new URL('/dashboard', req.nextUrl))
  }

  return NextResponse.next()
}

// กำหนดว่า middleware นี้จะทำงานกับ path ไหนบ้าง โดยจะทำงานกับทุก path ที่ไม่ใช่ /api, /_next/static, /_next/image และไฟล์รูปภาพต่างๆ
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|.*\\.png$|.*\\.jpg$).*)'],
}