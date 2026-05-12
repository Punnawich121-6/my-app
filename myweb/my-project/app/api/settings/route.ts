import { NextResponse } from 'next/server'
import pool from '@/app/lib/db'

const DEFAULT_SETTINGS: Record<string, string> = {
  platformName: 'Zest & Savory',
  supportEmail: 'support@zestandsavory.com',
  defaultCurrency: 'USD',
  systemLanguage: 'en',
  maxDeliveryRadius: '12.5',
  baseServiceFee: '2.99',
  restaurantCommission: '15',
  twoFactorAuth: 'true',
  strictPasswordPolicy: 'true',
  sessionTimeout: '30',
  emailNotifications: 'true',
  smsNotifications: 'true',
  marketingPush: 'false',
}

async function ensureTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS SystemSettings (
      \`key\` VARCHAR(100) PRIMARY KEY,
      \`value\` TEXT NOT NULL,
      updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `)
}

export async function GET() {
  try {
    await ensureTable()
    const [rows] = await pool.query('SELECT `key`, `value` FROM SystemSettings') as [{ key: string; value: string }[], unknown]

    const settings = { ...DEFAULT_SETTINGS }
    for (const row of rows) {
      settings[row.key] = row.value
    }

    return NextResponse.json(settings)
  } catch (err) {
    console.error('GET /api/settings error:', err)
    return NextResponse.json(DEFAULT_SETTINGS)
  }
}

export async function PUT(request: Request) {
  try {
    await ensureTable()
    const body = await request.json() as Record<string, string>

    for (const [key, value] of Object.entries(body)) {
      await pool.query(
        'INSERT INTO SystemSettings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?',
        [key, String(value), String(value)]
      )
    }

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('PUT /api/settings error:', err)
    return NextResponse.json({ error: 'Failed to save settings' }, { status: 500 })
  }
}
