import 'server-only'
import { cookies } from 'next/headers'
import crypto from 'crypto'
import pool from '@/app/lib/db'

// สร้าง Token สุ่มที่เดาไม่ได้
function generateToken() {
  return crypto.randomBytes(32).toString('hex')
}

export async function createSession(
  adminUserId: string, 
  timeoutMin: number | null, 
  ipAddress: string, 
  userAgent: string
) {
  // 1. คำนวณเวลาหมดอายุ (ถ้าไม่ได้ตั้งค่าไว้ใน DB ให้ค่าเริ่มต้นที่ 1 วัน = 1440 นาที)
  const sessionMinutes = timeoutMin || 1440; 
  const expiresAt = new Date(Date.now() + sessionMinutes * 60 * 1000)
  
  // 2. สร้าง Session Token
  const token = generateToken()
  const sessionId = crypto.randomUUID() // สร้าง ID สำหรับตาราง adminsession

  // 3. บันทึกลง Database ตาราง adminsession
  await pool.query(
    `INSERT INTO adminsession (id, adminUserId, token, ipAddress, userAgent, expiresAt) 
     VALUES (?, ?, ?, ?, ?, ?)`,
    [sessionId, adminUserId, token, ipAddress, userAgent, expiresAt]
  )

  // การเก็บ Session Token ใน Cookie บันทึก Token ลง Cookie (เพื่อให้ Browser ส่งมาทุกครั้ง)
  const cookieStore = await cookies()
  cookieStore.set('session', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    expires: expiresAt,
    path: '/',
  })
}

// ฟังก์ชันสำหรับดึงและตรวจสอบ Session ว่ายัง Valid อยู่ไหม (ใช้แทน decrypt)
export async function verifySession() {
  const cookieStore = await cookies()
  const token = cookieStore.get('session')?.value

  if (!token) return null

  // ค้นหา Token ใน Database และต้องยังไม่หมดอายุ
  const [rows] = await pool.query(
    `SELECT adminUserId, expiresAt 
     FROM adminsession 
     WHERE token = ? AND expiresAt > NOW() 
     LIMIT 1`,
    [token]
  ) as [{ adminUserId: string; expiresAt: Date }[], unknown]

  const session = rows[0]
  if (!session) return null

  return { userId: session.adminUserId, expiresAt: session.expiresAt }
}

export async function deleteSession() {
  const cookieStore = await cookies()
  const token = cookieStore.get('session')?.value

  // 1. ถ้ามี Token ให้ลบออกจาก Database ด้วย
  if (token) {
    await pool.query('DELETE FROM adminsession WHERE token = ?', [token])
  }

  // 2. ลบออกจาก Cookie
  cookieStore.delete('session')
}