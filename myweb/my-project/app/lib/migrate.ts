import pool from './db'

let done = false

export async function ensureDescriptionColumn() {
  if (done) return
  try {
    const [cols]: any = await pool.query(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Restaurant' AND COLUMN_NAME = 'description'`
    )
    if ((cols as any[]).length === 0) {
      await pool.query('ALTER TABLE Restaurant ADD COLUMN description TEXT NULL')
    }
    done = true
  } catch {
    // skip if migration fails (e.g. permissions)
  }
}
