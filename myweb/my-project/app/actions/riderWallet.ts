'use server'

import pool from '@/app/lib/db'
import { revalidatePath } from 'next/cache'
import crypto from 'crypto'
import { getRiderWalletTransactions } from '@/app/lib/riderWallet'

export type WalletActionState = {
  success: boolean
  error: string | null
  balance?: number
}

async function ensureTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS rider_wallets (
      rider_id   VARCHAR(36) PRIMARY KEY,
      balance    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS rider_wallet_transactions (
      id           VARCHAR(36) PRIMARY KEY,
      rider_id     VARCHAR(36) NOT NULL,
      type         ENUM('advance','topup','deduction') NOT NULL,
      amount       DECIMAL(10,2) NOT NULL,
      description  VARCHAR(255),
      reference_id VARCHAR(36),
      created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_rwt_rider (rider_id)
    )
  `)
}

export async function advanceRiderWallet(
  _prev: WalletActionState,
  formData: FormData,
): Promise<WalletActionState> {
  const rider_id    = (formData.get('rider_id') as string)?.trim()
  const amountStr   = (formData.get('amount') as string)?.trim()
  const description = (formData.get('description') as string)?.trim()

  if (!rider_id) return { success: false, error: 'กรุณาเลือกไรเดอร์' }
  const amount = parseFloat(amountStr)
  if (!amount || amount <= 0) return { success: false, error: 'กรุณากรอกจำนวนเงินที่ถูกต้อง' }

  try {
    await ensureTables()
    const txId = crypto.randomUUID()
    await pool.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [rider_id, -amount]
    )
    await pool.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description)
       VALUES (?, ?, 'advance', ?, ?)`,
      [txId, rider_id, amount, description || `บริษัทออกเงินล่วงหน้า ฿${amount}`]
    )
    const [[w]]: any = await pool.query(
      'SELECT balance FROM rider_wallets WHERE rider_id = ?',
      [rider_id]
    )
    revalidatePath('/fleet')
    return { success: true, error: null, balance: parseFloat(w.balance) }
  } catch (e: any) {
    return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด' }
  }
}

export async function topupRiderWallet(
  _prev: WalletActionState,
  formData: FormData,
): Promise<WalletActionState> {
  const rider_id  = (formData.get('rider_id') as string)?.trim()
  const amountStr = (formData.get('amount') as string)?.trim()
  const description = (formData.get('description') as string)?.trim()

  if (!rider_id) return { success: false, error: 'กรุณาเลือกไรเดอร์' }
  const amount = parseFloat(amountStr)
  if (!amount || amount <= 0) return { success: false, error: 'กรุณากรอกจำนวนเงินที่ถูกต้อง' }

  try {
    await ensureTables()
    const txId = crypto.randomUUID()
    await pool.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [rider_id, amount]
    )
    await pool.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description)
       VALUES (?, ?, 'topup', ?, ?)`,
      [txId, rider_id, amount, description || `ไรเดอร์เติมเงิน ฿${amount}`]
    )
    const [[w]]: any = await pool.query(
      'SELECT balance FROM rider_wallets WHERE rider_id = ?',
      [rider_id]
    )
    revalidatePath('/fleet')
    return { success: true, error: null, balance: parseFloat(w.balance) }
  } catch (e: any) {
    return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด' }
  }
}

export async function fetchRiderTransactions(riderId: string) {
  try {
    const rows = await getRiderWalletTransactions(riderId)
    return rows.map(r => ({
      ...r,
      created_at: r.created_at.toISOString(),
    }))
  } catch {
    return []
  }
}

async function ensureLoanTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS rider_loan_requests (
      id          VARCHAR(36) PRIMARY KEY,
      rider_id    VARCHAR(36) NOT NULL,
      amount      DECIMAL(10,2) NOT NULL,
      reason      VARCHAR(500),
      status      ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
      admin_note  VARCHAR(255),
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_loan_rider (rider_id),
      INDEX idx_loan_status (status)
    )
  `)
}

export async function approveLoanRequest(
  _prev: WalletActionState,
  formData: FormData,
): Promise<WalletActionState> {
  const loanId    = (formData.get('loan_id') as string)?.trim()
  const adminNote = (formData.get('admin_note') as string)?.trim()
  if (!loanId) return { success: false, error: 'ไม่พบ loan id' }

  try {
    await ensureLoanTable()
    await ensureTables()
    const [[loan]]: any = await pool.query(
      `SELECT * FROM rider_loan_requests WHERE id = ? AND status = 'pending'`, [loanId]
    )
    if (!loan) return { success: false, error: 'ไม่พบคำขอ หรือดำเนินการแล้ว' }

    await pool.query(
      `UPDATE rider_loan_requests SET status = 'approved', admin_note = ? WHERE id = ?`,
      [adminNote || null, loanId]
    )
    const amt = parseFloat(loan.amount)
    await pool.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [loan.rider_id, -amt]
    )
    const txId = crypto.randomUUID()
    await pool.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description, reference_id)
       VALUES (?, ?, 'advance', ?, ?, ?)`,
      [txId, loan.rider_id, amt, `ยืมเงินจากบริษัท${adminNote ? ' — ' + adminNote : ''}`, loanId]
    )
    revalidatePath('/fleet')
    return { success: true, error: null }
  } catch (e: any) {
    return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด' }
  }
}

export async function rejectLoanRequest(
  _prev: WalletActionState,
  formData: FormData,
): Promise<WalletActionState> {
  const loanId    = (formData.get('loan_id') as string)?.trim()
  const adminNote = (formData.get('admin_note') as string)?.trim()
  if (!loanId) return { success: false, error: 'ไม่พบ loan id' }

  try {
    await ensureLoanTable()
    await pool.query(
      `UPDATE rider_loan_requests SET status = 'rejected', admin_note = ? WHERE id = ? AND status = 'pending'`,
      [adminNote || null, loanId]
    )
    revalidatePath('/fleet')
    return { success: true, error: null }
  } catch (e: any) {
    return { success: false, error: e.message ?? 'เกิดข้อผิดพลาด' }
  }
}
