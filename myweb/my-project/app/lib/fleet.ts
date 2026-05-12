import pool from "./db";
import { ResultSetHeader, RowDataPacket } from "mysql2";

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export type RiderStatus = "Available" | "Busy" | "Offline" | "Pending";

export type Rider = {
  id: string;
  name: string;
  email: string;
  phone: string;
  vehicle: string;
  vehicleType: string;
  status: RiderStatus;
  rating: number | null;
  runsCompleted: number;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type RiderStats = {
  totalRider: number;
  activeRider: number;      // status = 'Available'
  onDeliveryRider: number;  // status = 'Busy'
  pendingRider: number;     // isVerified = false (รอ verify)
};

export type RidersPage = {
  riders: Rider[];
  total: number;
  pageSize: number;
};

export type PendingRider = {
  id: string;
  name: string;
  phone: string;
  email: string;
  vehicle: string;
  createdAt: Date;
};

// ─────────────────────────────────────────────
// Helper: map raw DB row → Rider
// ─────────────────────────────────────────────

function toRider(row: RowDataPacket): Rider {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone ?? "",
    vehicle: row.vehicle,
    vehicleType: row.vehicleType,
    status: row.status as RiderStatus,
    rating: row.rating ?? null,
    runsCompleted: row.runsCompleted ?? 0,
    isVerified: Boolean(row.isVerified),
    createdAt: new Date(row.createdAt),
    updatedAt: new Date(row.updatedAt),
  };
}

// ─────────────────────────────────────────────
// 1. KPI Stats  →  ใช้ใน KPI Cards ด้านบน
// ─────────────────────────────────────────────

export async function getRiderStats(): Promise<RiderStats> {
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT
      COUNT(*)                                        AS totalRider,
      SUM(status = 'Available')                       AS activeRider,
      SUM(status = 'Busy')                            AS onDeliveryRider,
      SUM(isVerified = FALSE AND status = 'Pending')  AS pendingRider
    FROM Rider
  `);

  const row = rows[0];
  return {
    totalRider:      Number(row.totalRider),
    activeRider:     Number(row.activeRider),
    onDeliveryRider: Number(row.onDeliveryRider),
    pendingRider:    Number(row.pendingRider),
  };
}

// ─────────────────────────────────────────────
// 2. Fleet Directory  →  ใช้ใน ตาราง Rider list
//    - page     : หน้าปัจจุบัน (เริ่มที่ 1)
//    - pageSize : จำนวนต่อหน้า (default 20)
//    - status   : filter ตาม status (null = ดูทั้งหมด)
// ─────────────────────────────────────────────

export async function getRiders(
  page: number = 1,
  pageSize: number = 20,
  status?: RiderStatus | null
): Promise<RidersPage> {
  const offset = (page - 1) * pageSize;

  // สร้าง WHERE clause แบบ dynamic
  const conditions: string[] = [];
  const params: (string | number)[] = [];

  if (status) {
    conditions.push("status = ?");
    params.push(status);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

  // Query จำนวน total (สำหรับ pagination)
  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total FROM Rider ${where}`,
    params
  );
  const total = Number(countRows[0].total);

  // Query ข้อมูล rider พร้อม pagination
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT
       id, name, email, phone,
       vehicle, vehicleType, status,
       rating, runsCompleted, isVerified,
       createdAt, updatedAt
     FROM Rider
     ${where}
     ORDER BY
       FIELD(status, 'Available', 'Busy', 'Offline', 'Pending'),
       runsCompleted DESC
     LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );

  return {
    riders: rows.map(toRider),
    total,
    pageSize,
  };
}

// ─────────────────────────────────────────────
// 3. All Riders with filters + pagination  →  ใช้ใน /riders management page
// ─────────────────────────────────────────────

export type RidersFilter = {
  status?: string
  search?: string
  page?: number
  pageSize?: number
}

export async function getAllRiders({
  status = 'ALL',
  search = '',
  page = 1,
  pageSize = 10,
}: RidersFilter = {}): Promise<RidersPage> {
  const offset = (page - 1) * pageSize
  const conditions: string[] = []
  const params: (string | number)[] = []

  if (status && status !== 'ALL') {
    conditions.push('status = ?')
    params.push(status)
  }
  if (search) {
    conditions.push('(name LIKE ? OR phone LIKE ?)')
    params.push(`%${search}%`, `%${search}%`)
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : ''

  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total FROM Rider ${where}`,
    params,
  )
  const total = Number(countRows[0].total)

  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT id, name, email, phone, vehicle, vehicleType, status,
            rating, runsCompleted, isVerified, createdAt, updatedAt
     FROM Rider
     ${where}
     ORDER BY FIELD(status, 'Available', 'Busy', 'Offline', 'Pending'), runsCompleted DESC
     LIMIT ? OFFSET ?`,
    [...params, pageSize, offset],
  )

  return { riders: rows.map(toRider), total, pageSize }
}

// ─────────────────────────────────────────────
// 3. Pending Riders  →  รายชื่อที่รอ verify
// ─────────────────────────────────────────────

export async function getPendingRiders(): Promise<PendingRider[]> {
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT id, name, phone, email, vehicle, createdAt
    FROM Rider
    WHERE isVerified = FALSE
      AND status = 'Pending'
    ORDER BY createdAt ASC
  `);

  return rows.map((r) => ({
    id:        r.id,
    name:      r.name,
    phone:     r.phone ?? '',
    email:     r.email ?? '',
    vehicle:   r.vehicle ?? 'motorcycle',
    createdAt: new Date(r.createdAt),
  }));
}

// ─────────────────────────────────────────────
// 4. Single Rider  →  ใช้ตอนกด row ใน table
// ─────────────────────────────────────────────

export async function getRiderById(id: string): Promise<Rider | null> {
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT
       id, name, email, phone,
       vehicle, vehicleType, status,
       rating, runsCompleted, isVerified,
       createdAt, updatedAt
     FROM Rider
     WHERE id = ?
     LIMIT 1`,
    [id]
  );

  return rows.length > 0 ? toRider(rows[0]) : null;
}

// ─────────────────────────────────────────────
// 5. Update Rider Status  →  เปลี่ยน status rider
// ─────────────────────────────────────────────

export async function updateRiderStatus(
  id: string,
  status: RiderStatus
): Promise<boolean> {
  const [result] = await pool.query<ResultSetHeader>(
    `UPDATE Rider
     SET status = ?, updatedAt = NOW()
     WHERE id = ?`,
    [status, id]
  );

  return result.affectedRows > 0;
}

// ─────────────────────────────────────────────
// 6. Verify Rider  →  อนุมัติ rider ที่ pending
// ─────────────────────────────────────────────

export async function verifyRider(id: string): Promise<boolean> {
  const [result] = await pool.query<ResultSetHeader>(
    `UPDATE Rider
     SET isVerified = TRUE,
         status     = 'Available',
         updatedAt  = NOW()
     WHERE id = ?
       AND isVerified = FALSE`,
    [id]
  );

  return result.affectedRows > 0;
}