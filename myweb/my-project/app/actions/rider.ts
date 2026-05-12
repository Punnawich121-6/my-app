'use server'

import pool from '@/app/lib/db'
import { revalidatePath } from 'next/cache'
import crypto from 'crypto'

export type RiderFormState = {
    success: boolean
    error: string | null
}

export async function addRider(
    _prev: RiderFormState,
    formData: FormData,
): Promise<RiderFormState> {
    const name    = (formData.get('name')    as string | null)?.trim()
    const phone   = (formData.get('phone')   as string | null)?.trim()
    const email   = (formData.get('email')   as string | null)?.trim()
    const vehicle = (formData.get('vehicle') as string | null)?.trim() || 'motorcycle'
    const status  = (formData.get('status')  as string | null)?.trim() || 'Pending'

    if (!name)  return { success: false, error: 'กรุณากรอกชื่อไรเดอร์' }
    if (!phone) return { success: false, error: 'กรุณากรอกเบอร์โทรศัพท์' }

    const normalized = phone.startsWith('0') ? phone : '0' + phone
    const emailFinal = email || `${normalized}@riderapp.local`

    try {
        const [[existing]]: any = await pool.query(
            'SELECT id FROM Rider WHERE phone = ?',
            [normalized],
        )
        if (existing) return { success: false, error: 'เบอร์โทรนี้ถูกใช้งานแล้ว' }

        const id = crypto.randomUUID()
        await pool.query(
            `INSERT INTO Rider (id, name, email, phone, vehicle, vehicleType, status, isVerified)
             VALUES (?, ?, ?, ?, ?, ?, ?, 0)`,
            [id, name, emailFinal, normalized, vehicle, vehicle.toUpperCase(), status],
        )

        revalidatePath('/riders')
        revalidatePath('/fleet')
        return { success: true, error: null }
    } catch (e: any) {
        return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่' }
    }
}

export async function updateRider(
    _prev: RiderFormState,
    formData: FormData,
): Promise<RiderFormState> {
    const g = (k: string) => (formData.get(k) as string | null)?.trim() || null

    const riderId    = g('riderId')
    const name       = g('name')
    const phone      = g('phone')
    const email      = g('email')
    const vehicle    = g('vehicle') || 'motorcycle'
    const status     = g('status') || 'Offline'
    const isVerified = formData.get('isVerified') === '1' ? 1 : 0

    if (!riderId) return { success: false, error: 'ไม่พบข้อมูลไรเดอร์' }
    if (!name)    return { success: false, error: 'กรุณากรอกชื่อไรเดอร์' }
    if (!phone)   return { success: false, error: 'กรุณากรอกเบอร์โทรศัพท์' }

    const normalized = phone.startsWith('0') ? phone : '0' + phone

    try {
        const [[existing]]: any = await pool.query(
            'SELECT id FROM Rider WHERE phone = ? AND id != ?',
            [normalized, riderId],
        )
        if (existing) return { success: false, error: 'เบอร์โทรนี้ถูกใช้งานแล้ว' }

        await pool.query(
            `UPDATE Rider SET
               name = ?, phone = ?, email = ?,
               vehicle = ?, vehicleType = ?,
               status = ?, isVerified = ?,
               updatedAt = NOW()
             WHERE id = ?`,
            [
                name, normalized, email || `${normalized}@riderapp.local`,
                vehicle, vehicle.toUpperCase(),
                status, isVerified, riderId,
            ],
        )

        revalidatePath('/riders')
        revalidatePath('/fleet')
        return { success: true, error: null }
    } catch (e: any) {
        return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่' }
    }
}

export async function approveRider(riderId: string): Promise<void> {
    await pool.query(
        `UPDATE Rider SET isVerified = 1, status = 'Available', updatedAt = NOW() WHERE id = ?`,
        [riderId],
    )
    revalidatePath('/fleet')
    revalidatePath('/riders')
}

export async function rejectRider(riderId: string): Promise<void> {
    await pool.query(
        `UPDATE Rider SET status = 'Offline', updatedAt = NOW() WHERE id = ?`,
        [riderId],
    )
    revalidatePath('/fleet')
    revalidatePath('/riders')
}
