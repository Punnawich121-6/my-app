'use server'

import pool from '@/app/lib/db'
import { RowDataPacket } from 'mysql2'
import { revalidatePath } from 'next/cache'

const BANGKOK_SPOTS = [
  [13.7563, 100.5018], // Siam
  [13.7448, 100.5330], // Sukhumvit
  [13.7810, 100.4609], // Chatuchak
  [13.7308, 100.5234], // Silom
  [13.7627, 100.5714], // On Nut
  [13.7500, 100.4860], // Victory Monument
  [13.7236, 100.5271], // Sathorn
  [13.7992, 100.5492], // Min Buri
]

export async function seedRiderLocations() {
  // Ensure columns exist
  for (const sql of [
    'ALTER TABLE Rider ADD COLUMN latitude         DECIMAL(10,8) NULL',
    'ALTER TABLE Rider ADD COLUMN longitude        DECIMAL(11,8) NULL',
    'ALTER TABLE Rider ADD COLUMN locationUpdatedAt DATETIME     NULL',
  ]) {
    try { await pool.query(sql) } catch (_) {}
  }

  const [riders] = await pool.query<RowDataPacket[]>(
    `SELECT id FROM Rider WHERE isVerified = 1 OR status IN ('Available','Busy','Offline') LIMIT 8`,
  )

  for (let i = 0; i < riders.length; i++) {
    const [lat, lng] = BANGKOK_SPOTS[i % BANGKOK_SPOTS.length]
    const jitter = () => (Math.random() - 0.5) * 0.018
    await pool.query(
      'UPDATE Rider SET latitude = ?, longitude = ?, locationUpdatedAt = NOW() WHERE id = ?',
      [lat + jitter(), lng + jitter(), riders[i].id],
    )
  }

  revalidatePath('/fleet')
  return { seeded: riders.length }
}
