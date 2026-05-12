import 'server-only';
import { cookies } from 'next/headers';
import crypto from 'crypto' 
import pool from '@/app/lib/db'

// สร้าง Token สุ่ม 32 ไบต์ format ฐาน 16
function generateToken(){
    return crypto.randomBytes(32).toString('hex');
}

export async function createSession(
    adminUserID: string,
    timeout: number | null,
    ipAddress: string | null ,
    userAgent: string,)
    {
        const sessionMinutes = timeout || 1440;
        const expiresAt = new Date(Date.now()+sessionMinutes*60*1000 )

        const token = generateToken()
        const sessionId = crypto.randomUUID()

        await pool.query(
            `INSERT INTO AdminSessions (sessionId, adminUserID, token, expiresAt, ipAddress, userAgent) 
            VALUES (?, ?, ?, ? ,? ,? )`,
            [sessionId, adminUserID, token, expiresAt, ipAddress, userAgent]
        )

        const cookieStore = await cookies()
        cookieStore.set('session', token, {
            httpOnly: true,
            secure: process.env.NODE_ENV ===  'production',
            expires: expiresAt,
            path: '/',       
        })
    }
    export async function verifySession(){
        const cookieStore = await cookies()
        const token = cookieStore.get('session')?.value

        if (!token) return null

          // ค้นหา Token ใน Database และต้องยังไม่หมดอายุ
        const [rows] = await pool.query(
            `SELECT adminUserId, expiresAt 
            FROM AdminSession 
            WHERE token = ? AND expiresAt > NOW() 
            LIMIT 1`,
            [token]
    ) as [{ adminUserId: string; expiresAt: Date }[], unknown]

    const session = rows[0]
    if (!session) return null;;

    return {userId: session.adminUserId, expiresAT: session.expiresAt}
}

export async function deleteSession(){
    const cookieStore = await cookies()
    const token = cookieStore.get('session')?.value

    if (token){
         await pool.query('DELETE FROM AdminSession WHERE token = ?', [token])

    }

    cookieStore.delete('session')
}

