'use server'

import pool from '@/app/lib/db'
import { revalidatePath } from 'next/cache'
import crypto from 'crypto'

export type RestaurantFormState = {
    success: boolean
    error: string | null
}

export async function addRestaurant(
    _prev: RestaurantFormState,
    formData: FormData,
): Promise<RestaurantFormState> {
    const name     = (formData.get('name')     as string | null)?.trim()
    const category = (formData.get('category') as string | null)?.trim()
    const address  = (formData.get('address')  as string | null)?.trim()
    const phone    = (formData.get('phone')    as string | null)?.trim()
    const email    = (formData.get('email')    as string | null)?.trim()
    const status   = (formData.get('status')   as string | null)?.trim() || 'pending'

    if (!name)  return { success: false, error: 'กรุณากรอกชื่อร้านอาหาร' }
    if (!phone) return { success: false, error: 'กรุณากรอกเบอร์โทรศัพท์' }

    try {
        const [[existing]]: any = await pool.query(
            'SELECT id FROM Restaurant WHERE phone = ?',
            [phone],
        )
        if (existing) return { success: false, error: 'เบอร์โทรนี้ถูกใช้งานแล้ว' }

        const id = crypto.randomUUID()
        await pool.query(
            `INSERT INTO Restaurant (id, name, category, address, phone, email, status, commissionRate, serviceFeeRate)
             VALUES (?, ?, ?, ?, ?, ?, ?, 15, 5)`,
            [id, name, category || 'ร้านอาหาร', address || '', phone, email || '', status],
        )

        revalidatePath('/restaurants')
        return { success: true, error: null }
    } catch (e: any) {
        return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่' }
    }
}

export async function updateRestaurant(
    _prev: RestaurantFormState,
    formData: FormData,
): Promise<RestaurantFormState> {
    const g = (k: string) => (formData.get(k) as string | null)?.trim() || null

    const restaurantId      = g('restaurantId')
    const name              = g('name')
    const category          = g('category')
    const address           = g('address')
    const phone             = g('phone')
    const email             = g('email')
    const status            = g('status') ?? 'pending'
    const owner_name        = g('owner_name')
    const line_id           = g('line_id')
    const bank_name         = g('bank_name')
    const account_name      = g('account_name')
    const account_no        = g('account_no')
    const id_card           = g('id_card')
    const business_license  = g('business_license')
    const open_time         = g('open_time')
    const close_time        = g('close_time')
    const latRaw            = g('lat')
    const lngRaw            = g('lng')
    const lat = latRaw ? parseFloat(latRaw) : null
    const lng = lngRaw ? parseFloat(lngRaw) : null

    if (!restaurantId) return { success: false, error: 'ไม่พบข้อมูลร้านอาหาร' }
    if (!name)  return { success: false, error: 'กรุณากรอกชื่อร้านอาหาร' }
    if (!phone) return { success: false, error: 'กรุณากรอกเบอร์โทรศัพท์' }

    try {
        const [[existing]]: any = await pool.query(
            'SELECT id FROM Restaurant WHERE phone = ? AND id != ?',
            [phone, restaurantId],
        )
        if (existing) return { success: false, error: 'เบอร์โทรนี้ถูกใช้งานแล้ว' }

        await pool.query(
            `UPDATE Restaurant SET
               name = ?, category = ?, address = ?, phone = ?, email = ?, status = ?,
               owner_name = ?, line_id = ?,
               bank_name = ?, account_name = ?, account_no = ?,
               id_card = ?, business_license = ?,
               open_time = ?, close_time = ?,
               lat = ?, lng = ?
             WHERE id = ?`,
            [
                name, category || 'ร้านอาหาร', address || '', phone, email || '', status,
                owner_name, line_id,
                bank_name, account_name, account_no,
                id_card, business_license,
                open_time, close_time,
                lat, lng,
                restaurantId,
            ],
        )

        revalidatePath('/restaurants')
        return { success: true, error: null }
    } catch (e: any) {
        return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่' }
    }
}

export async function approveRestaurant(restaurantId: string): Promise<void> {
    await pool.query(
        `UPDATE Restaurant SET status = 'active' WHERE id = ?`,
        [restaurantId],
    )
    revalidatePath('/restaurants')
}

export async function rejectRestaurant(restaurantId: string): Promise<void> {
    await pool.query(
        `UPDATE Restaurant SET status = 'inactive' WHERE id = ?`,
        [restaurantId],
    )
    revalidatePath('/restaurants')
}
