import pool from './db'
import { RowDataPacket } from 'mysql2'

export type RiderWalletRow = {
  id: string
  name: string
  phone: string
  balance: number
  total_advanced: number
  total_topup: number
  last_transaction_at: Date | null
}

export type RiderWalletTransaction = {
  id: string
  rider_id: string
  type: 'advance' | 'topup' | 'deduction'
  amount: number
  description: string | null
  reference_id: string | null
  created_at: Date
}

export type RiderWalletStats = {
  total_debt: number        // sum of negative balances (how much company is owed)
  riders_in_debt: number
  total_advanced: number    // lifetime total advanced
}

async function ensureRiderWalletTables() {
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

export async function getRiderWalletStats(): Promise<RiderWalletStats> {
  await ensureRiderWalletTables()
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT
      COALESCE(ABS(SUM(CASE WHEN balance < 0 THEN balance ELSE 0 END)), 0) AS total_debt,
      COUNT(CASE WHEN balance < 0 THEN 1 END)                              AS riders_in_debt
    FROM rider_wallets
  `)
  const [advRows] = await pool.query<RowDataPacket[]>(`
    SELECT COALESCE(SUM(amount), 0) AS total_advanced
    FROM rider_wallet_transactions
    WHERE type = 'advance'
  `)
  const row = rows[0]
  return {
    total_debt:     Number(row.total_debt),
    riders_in_debt: Number(row.riders_in_debt),
    total_advanced: Number(advRows[0].total_advanced),
  }
}

export async function getRiderWalletSummary(): Promise<RiderWalletRow[]> {
  await ensureRiderWalletTables()
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT
      r.id,
      r.name,
      r.phone,
      COALESCE(w.balance, 0) AS balance,
      COALESCE(SUM(CASE WHEN t.type = 'advance' THEN t.amount ELSE 0 END), 0) AS total_advanced,
      COALESCE(SUM(CASE WHEN t.type = 'topup'   THEN t.amount ELSE 0 END), 0) AS total_topup,
      MAX(t.created_at) AS last_transaction_at
    FROM Rider r
    INNER JOIN rider_wallets w ON r.id = w.rider_id
    LEFT JOIN rider_wallet_transactions t ON r.id = t.rider_id
    GROUP BY r.id, r.name, r.phone, w.balance
    ORDER BY w.balance ASC
  `)
  return rows.map(r => ({
    id:                  r.id,
    name:                r.name,
    phone:               r.phone ?? '',
    balance:             Number(r.balance),
    total_advanced:      Number(r.total_advanced),
    total_topup:         Number(r.total_topup),
    last_transaction_at: r.last_transaction_at ? new Date(r.last_transaction_at) : null,
  }))
}

export async function getRiderWalletTransactions(riderId: string): Promise<RiderWalletTransaction[]> {
  await ensureRiderWalletTables()
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT id, rider_id, type, amount, description, reference_id, created_at
     FROM rider_wallet_transactions
     WHERE rider_id = ?
     ORDER BY created_at DESC
     LIMIT 100`,
    [riderId]
  )
  return rows.map(r => ({
    id:           r.id,
    rider_id:     r.rider_id,
    type:         r.type,
    amount:       Number(r.amount),
    description:  r.description ?? null,
    reference_id: r.reference_id ?? null,
    created_at:   new Date(r.created_at),
  }))
}

export type RiderLoanRequest = {
  id: string
  rider_id: string
  rider_name: string
  rider_phone: string
  amount: number
  reason: string | null
  status: 'pending' | 'approved' | 'rejected'
  admin_note: string | null
  current_balance: number
  created_at: Date
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

export async function getPendingLoanRequests(): Promise<RiderLoanRequest[]> {
  await ensureLoanTable()
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT l.*, r.name AS rider_name, r.phone AS rider_phone,
           COALESCE(w.balance, 0) AS current_balance
    FROM rider_loan_requests l
    JOIN Rider r ON r.id = l.rider_id
    LEFT JOIN rider_wallets w ON w.rider_id = l.rider_id
    WHERE l.status = 'pending'
    ORDER BY l.created_at ASC
  `)
  return rows.map(r => ({
    id:              r.id,
    rider_id:        r.rider_id,
    rider_name:      r.rider_name,
    rider_phone:     r.rider_phone ?? '',
    amount:          Number(r.amount),
    reason:          r.reason ?? null,
    status:          r.status,
    admin_note:      r.admin_note ?? null,
    current_balance: Number(r.current_balance),
    created_at:      new Date(r.created_at),
  }))
}

export async function getAllRidersForWallet() {
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT id, name, phone FROM Rider WHERE isVerified = 1 ORDER BY name ASC`
  )
  return rows.map(r => ({ id: r.id as string, name: r.name as string, phone: (r.phone ?? '') as string }))
}
