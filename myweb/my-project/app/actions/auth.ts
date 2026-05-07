'use server'
import { redirect } from 'next/navigation'
import bcrypt from 'bcryptjs'
import pool from '@/app/lib/db'
import { createSession, deleteSession } from '@/app/lib/session'

export type LoginState = {
  error?: string
} | undefined

export async function login(
  _prevState: LoginState,
  formData: FormData
): Promise<LoginState> {
  const email    = formData.get('email')    as string
  const password = formData.get('password') as string

  if (!email || !password) {
    return { error: 'กรุณากรอก Email และ Password' }
  }

  const [rows] = await pool.query(
    'SELECT id, passwordHash FROM adminuser WHERE email = ? LIMIT 1',
    [email]
  ) as [{ id: string; passwordHash: string }[], unknown]

  const user = rows[0]
  if (!user) {
    return { error: 'Email หรือ Password ไม่ถูกต้อง' }
  }

  const isValid = await bcrypt.compare(password, user.passwordHash)
  if (!isValid) {
    return { error: 'Email หรือ Password ไม่ถูกต้อง' }
  }

  await createSession(user.id)
  redirect('/dashboard')
}

export async function logout() {
  await deleteSession()
  redirect('/login')
}
