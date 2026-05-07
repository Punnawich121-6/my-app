# Data Queries Documentation — Zest & Savory Admin Portal

เอกสารนี้อธิบายว่าแต่ละหน้า/ส่วนในระบบ แสดงข้อมูลอะไร และต้องใช้ SQL Query อย่างไรเพื่อดึงข้อมูลนั้นมา

---

## สารบัญ

1. [Database Tables](#1-database-tables)
2. [Dashboard Page](#2-dashboard-page)
3. [Orders Page](#3-orders-page)
4. [Restaurants Page](#4-restaurants-page)
5. [Fleet Page](#5-fleet-page)
6. [Financials Page](#6-financials-page)
7. [Settings Page](#7-settings-page)
8. [Login Page](#8-login-page)

---

## 1. Database Tables

ตาราง Database ที่ใช้ในระบบ:

| ตาราง | ใช้ใน | คอลัมน์หลักที่สำคัญ |
|-------|--------|----------------------|
| `Order` | ทุก Query ที่เกี่ยวกับ Order | `id`, `orderNumber`, `status`, `totalAmount`, `createdAt`, `restaurantId`, `customerId` |
| `Restaurant` | Dashboard Top Performers | `id`, `name`, `imageUrl` |
| `Customer` | Dashboard Live Orders | `id`, `name` |
| `Rider` | Dashboard Active Riders | `id`, `status` (`ONLINE`, `ON_DELIVERY`, etc.) |
| `adminuser` | Login | `id`, `email`, `passwordHash` |

**สถานะ Order (`status`) ที่ใช้บ่อย:**
- Active: `PENDING`, `CONFIRMED`, `PREPARING`, `OUT_FOR_DELIVERY`
- ปัญหา: `DELAYED`, `REFUNDED`
- สิ้นสุด: `CANCELLED`, `DELIVERED`

---

## 2. Dashboard Page

**ไฟล์:** `app/dashboard/page.tsx`
**ไฟล์ Data:** `app/lib/dashboard.ts`
**Route:** `/dashboard`

Dashboard แสดง 3 ส่วนหลัก: KPI Cards, Live Order Table, และ Top Performers

---

### 2.1 KPI Cards (4 การ์ดบนสุด)

#### Total Revenue (รายได้วันนี้)

**แสดง:**
- ยอดรายได้รวมวันนี้ (บาท)
- เปอร์เซ็นต์เปลี่ยนแปลงเทียบกับเมื่อวาน (+/-)

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getDashboardStats()`):
```sql
SELECT
  COALESCE(SUM(CASE WHEN DATE(createdAt) = CURDATE() THEN totalAmount ELSE 0 END), 0) AS today,
  COALESCE(SUM(CASE WHEN DATE(createdAt) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN totalAmount ELSE 0 END), 0) AS yesterday
FROM `Order`
WHERE status NOT IN ('CANCELLED', 'REFUNDED')
  AND DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
```

**ผลลัพธ์ที่ได้:**
```typescript
[{ today: number; yesterday: number }]
```

**การคำนวณต่อจาก Query:**
```typescript
const totalRevenue = revenueRows[0].today
const revenueChangePercent =
  yesterday === 0 ? 100 : ((today - yesterday) / yesterday) * 100
```

**อธิบาย Query:**
- `COALESCE(..., 0)` — ถ้า SUM เป็น NULL (ไม่มี Order เลย) ให้คืนค่า 0 แทน
- `CASE WHEN DATE(createdAt) = CURDATE()` — นับเฉพาะ Order วันนี้
- `DATE_SUB(CURDATE(), INTERVAL 1 DAY)` — เมื่อวาน
- `WHERE status NOT IN ('CANCELLED', 'REFUNDED')` — ไม่นับ Order ที่ยกเลิกหรือคืนเงิน

---

#### Active Orders (จำนวน Order ที่กำลังดำเนินการ)

**แสดง:**
- จำนวน Order ที่ยังไม่เสร็จสิ้น (อยู่ในสถานะ active)

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getDashboardStats()`):
```sql
SELECT COUNT(*) AS count
FROM `Order`
WHERE status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY')
```

**ผลลัพธ์ที่ได้:**
```typescript
[{ count: number }]
```

**การใช้ค่า:**
```typescript
const activeOrders = orderRows[0].count
```

---

#### Active Riders (จำนวน Rider ที่ออนไลน์)

**แสดง:**
- จำนวน Rider ที่กำลังทำงานอยู่ (Online หรือกำลังส่ง)

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getDashboardStats()`):
```sql
SELECT COUNT(*) AS count
FROM Rider
WHERE status IN ('ONLINE', 'ON_DELIVERY')
```

**ผลลัพธ์ที่ได้:**
```typescript
[{ count: number }]
```

**การใช้ค่า:**
```typescript
const activeRiders = riderRows[0].count
```

---

#### Pending Issues (ปัญหาที่รอแก้ไขวันนี้)

**แสดง:**
- จำนวน Order ที่มีปัญหาวันนี้ (DELAYED หรือ REFUNDED)

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getDashboardStats()`):
```sql
SELECT COUNT(*) AS count
FROM `Order`
WHERE status IN ('DELAYED', 'REFUNDED')
  AND DATE(createdAt) = CURDATE()
```

**ผลลัพธ์ที่ได้:**
```typescript
[{ count: number }]
```

**การใช้ค่า:**
```typescript
const pendingIssues = issueRows[0].count
```

---

### 2.2 Live Order Monitoring (ตาราง Order สด)

**แสดง:**
- 5 Order ล่าสุดที่ยังอยู่ในสถานะ active
- คอลัมน์: Order ID, ร้านอาหาร, ลูกค้า, สถานะ, เวลาสั่ง

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getLiveOrders()`):
```sql
SELECT
  o.orderNumber,
  r.name  AS restaurantName,
  c.name  AS customerName,
  o.status,
  o.createdAt
FROM `Order` o
JOIN Restaurant r ON o.restaurantId = r.id
JOIN Customer   c ON o.customerId   = c.id
WHERE o.status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELAYED')
ORDER BY o.createdAt DESC
LIMIT 5
```

**ผลลัพธ์ที่ได้:**
```typescript
[{
  orderNumber: string
  restaurantName: string
  customerName: string
  status: string
  createdAt: Date
}]
```

**อธิบาย Query:**
- `JOIN Restaurant` และ `JOIN Customer` — ดึงชื่อร้านและลูกค้าแทนที่จะแสดงแค่ ID
- `ORDER BY createdAt DESC` — เรียง Order ใหม่สุดขึ้นก่อน
- `LIMIT 5` — แสดงแค่ 5 รายการ

---

### 2.3 Top Performers (ร้านอาหารยอดนิยมวันนี้)

**แสดง:**
- 4 ร้านที่มียอด Order สูงสุดวันนี้
- แสดง: รูปร้าน, ชื่อร้าน, จำนวน Order, รายได้

**Query** (ไฟล์: `app/lib/dashboard.ts` → ฟังก์ชัน `getTopPerformers()`):
```sql
SELECT
  r.id,
  r.name,
  r.imageUrl,
  COUNT(o.id)                     AS orderCount,
  COALESCE(SUM(o.totalAmount), 0) AS revenue
FROM Restaurant r
LEFT JOIN `Order` o
  ON r.id = o.restaurantId
  AND DATE(o.createdAt) = CURDATE()
  AND o.status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY r.id, r.name, r.imageUrl
ORDER BY orderCount DESC
LIMIT 4
```

**ผลลัพธ์ที่ได้:**
```typescript
[{
  id: number
  name: string
  imageUrl: string
  orderCount: number
  revenue: number
}]
```

**อธิบาย Query:**
- `LEFT JOIN` — รวมทุกร้าน แม้แต่ร้านที่ไม่มี Order วันนี้ (orderCount = 0)
- เงื่อนไข `AND DATE(o.createdAt) = CURDATE()` อยู่ใน `ON` ไม่ใช่ `WHERE` เพื่อให้ LEFT JOIN ยังทำงานถูกต้อง
- `GROUP BY r.id, r.name, r.imageUrl` — จัดกลุ่มตามร้าน
- `ORDER BY orderCount DESC LIMIT 4` — เรียงจากมากไปน้อย เอาแค่ 4 อันดับ

---

## 3. Orders Page

**ไฟล์:** `app/orders/page.tsx`
**ไฟล์ Data:** `app/lib/order.ts`
**Route:** `/orders`

> **หมายเหตุ:** หน้านี้ปัจจุบันใช้ข้อมูล hardcode (mock data) ทั้งหมด — ยังไม่ได้เชื่อมต่อ Database
> ไฟล์ `app/lib/order.ts` มี Query และ Type พร้อมใช้งานแล้ว แต่ยังไม่ถูก import เข้าหน้านี้

---

### Exported Types จาก `app/lib/order.ts`

#### `AllOrder` — ใช้แสดงรายการ Order ในตาราง

```typescript
export type AllOrder = {
  orderNumber: string      // หมายเลขคำสั่งซื้อ เช่น "ORD-9021"
  restaurantName: string   // ชื่อร้านอาหาร
  customerName: string     // ชื่อลูกค้า
  riderName: string | null // ชื่อไรเดอร์ (null ถ้ายังไม่มีไรเดอร์รับ)
  status: string           // สถานะ เช่น 'PREPARING', 'OUT_FOR_DELIVERY', 'DELAYED'
  createdAt: Date          // วันเวลาที่สั่ง
}
```

**ใช้แสดงใน:** ตาราง Order (คอลัมน์ Order Details, Restaurant, Customer, Rider, Status)

---

#### `Order` (internal) — ใช้แสดง Stats Cards

> type นี้ยังไม่ได้ `export` ออกมา — ใช้ภายใน `getOrder()` เท่านั้น

```typescript
// ผลลัพธ์จาก getOrder() — object เดี่ยว ไม่ใช่ array
{
  totalActive: number    // การ์ด "Total Active" — Order ที่ active ทั้งหมด
  preparing: number      // การ์ด "Preparing"
  outForDelivery: number // การ์ด "Out for Delivery"
  delayed: number        // การ์ด "Delayed"
  changePercent: number  // % เปลี่ยนแปลงเทียบกับเมื่อวาน (+/-)
}
```

---

### 3.1 Stats Cards — พร้อมเชื่อมต่อ ⚠️ (ยังใช้ mock)

ฟังก์ชัน `getOrder()` ดึงข้อมูลทั้ง 5 ค่าในครั้งเดียว:

| การ์ด | Field | mock value ปัจจุบัน |
|-------|-------|---------------------|
| Total Active | `totalActive` + `changePercent` | 142, +12% |
| Preparing | `preparing` | 56 |
| Out for Delivery | `outForDelivery` | 81 |
| Delayed | `delayed` | 5 |

**Queries ที่ `getOrder()` ใช้:**

```sql
-- totalActive
SELECT COUNT(id) AS totalActive
FROM `Order`
WHERE status IN ('PENDING', 'PREPARING', 'OUT_FOR_DELIVERY', 'CONFIRMED', 'DELAYED')

-- changePercent (คำนวณเทียบกับจำนวน Order ทั้งหมดเมื่อวาน)
SELECT COUNT(id) AS totalYesterday
FROM `Order`
WHERE DATE(createdAt) = SUBDATE(CURDATE(), 1)

-- preparing
SELECT COUNT(id) AS preparing FROM `Order` WHERE status = 'PREPARING'

-- outForDelivery
SELECT COUNT(id) AS outForDelivery FROM `Order` WHERE status = 'OUT_FOR_DELIVERY'

-- delayed
SELECT COUNT(id) AS delayed FROM `Order` WHERE status = 'DELAYED'
```

---

### 3.2 Order Table — ต้องเพิ่ม Query ⚠️ (ยังใช้ mock)

ตารางต้องการ type `AllOrder` — Query ที่ควรสร้างฟังก์ชัน `getAllOrders()`:

```sql
SELECT
  o.orderNumber,
  r.name  AS restaurantName,
  c.name  AS customerName,
  ri.name AS riderName,       -- JOIN Rider (LEFT JOIN เพราะอาจยังไม่มีไรเดอร์)
  o.status,
  o.createdAt
FROM `Order` o
JOIN Restaurant r  ON o.restaurantId = r.id
JOIN Customer   c  ON o.customerId   = c.id
LEFT JOIN Rider ri ON o.riderId      = ri.id
WHERE o.status IN ('PENDING', 'PREPARING', 'OUT_FOR_DELIVERY', 'CONFIRMED', 'DELAYED')
ORDER BY o.createdAt DESC
LIMIT 20
```

**ผลลัพธ์ตรงกับ `AllOrder` type ทุก field**

---

## 4. Restaurants Page

**ไฟล์:** `app/restaurants/page.tsx`
**Route:** `/restaurants`

> **หมายเหตุ:** หน้านี้ยังใช้ข้อมูล hardcode ทั้งหมด (ยังไม่เชื่อมต่อ Database)

**Query ที่ควรเพิ่ม (ตัวอย่าง):**

```sql
-- ดึงรายชื่อร้านทั้งหมดพร้อมสถิติ
SELECT
  r.id,
  r.name,
  r.imageUrl,
  r.status,
  COUNT(o.id) AS totalOrders,
  COALESCE(SUM(o.totalAmount), 0) AS totalRevenue
FROM Restaurant r
LEFT JOIN `Order` o ON r.id = o.restaurantId
  AND o.status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY r.id, r.name, r.imageUrl, r.status
ORDER BY totalOrders DESC
```

**Stats Cards ที่แสดงอยู่ (mock):**
| การ์ด | ค่าปัจจุบัน (mock) | Query ที่ควรใช้ |
|-------|-------------------|-----------------|
| Total Restaurants | 1,240 | `SELECT COUNT(*) FROM Restaurant` |
| Active | 850 | `SELECT COUNT(*) FROM Restaurant WHERE status = 'ACTIVE'` |
| Pending Approval | 12 | `SELECT COUNT(*) FROM Restaurant WHERE status = 'PENDING'` |

---

## 5. Fleet Page

**ไฟล์:** `app/fleet/page.tsx`
**Route:** `/fleet`

> **หมายเหตุ:** หน้านี้ยังใช้ข้อมูล hardcode ทั้งหมด (ยังไม่เชื่อมต่อ Database)

**Query ที่ควรเพิ่ม (ตัวอย่าง):**

```sql
-- ดึงรายชื่อ Rider ทั้งหมดพร้อมสถานะ
SELECT
  id,
  name,
  status,
  phone,
  vehicleType
FROM Rider
ORDER BY status ASC, name ASC
```

**Stats Cards ที่แสดงอยู่ (mock):**
| การ์ด | ค่าปัจจุบัน (mock) | Query ที่ควรใช้ |
|-------|-------------------|-----------------|
| Total Riders | 1,240 | `SELECT COUNT(*) FROM Rider` |
| Active | 850 | `SELECT COUNT(*) FROM Rider WHERE status = 'ONLINE'` |
| On Delivery | 420 | `SELECT COUNT(*) FROM Rider WHERE status = 'ON_DELIVERY'` |
| Pending | 15 | `SELECT COUNT(*) FROM Rider WHERE status = 'PENDING'` |

---

## 6. Financials Page

**ไฟล์:** `app/financials/page.tsx`
**Route:** `/financials`

> **หมายเหตุ:** หน้านี้ยังใช้ข้อมูล hardcode ทั้งหมด (ยังไม่เชื่อมต่อ Database)

**Query ที่ควรเพิ่ม (ตัวอย่าง):**

```sql
-- รายได้รวมแยกตามวัน (7 วันล่าสุด)
SELECT
  DATE(createdAt) AS date,
  COALESCE(SUM(totalAmount), 0) AS revenue,
  COUNT(id) AS orderCount
FROM `Order`
WHERE status NOT IN ('CANCELLED', 'REFUNDED')
  AND DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY DATE(createdAt)
ORDER BY date ASC

-- รายได้รวมเดือนนี้
SELECT COALESCE(SUM(totalAmount), 0) AS monthRevenue
FROM `Order`
WHERE status NOT IN ('CANCELLED', 'REFUNDED')
  AND MONTH(createdAt) = MONTH(CURDATE())
  AND YEAR(createdAt) = YEAR(CURDATE())
```

---

## 7. Settings Page

**ไฟล์:** `app/settings/page.tsx`
**Route:** `/settings`

> **หมายเหตุ:** หน้านี้ยังใช้ข้อมูล hardcode (3 admin users จำลอง)

**Query ที่ควรเพิ่ม (ตัวอย่าง):**

```sql
-- ดึงรายชื่อ Admin ทั้งหมด
SELECT id, email, role, createdAt
FROM adminuser
ORDER BY createdAt ASC
```

---

## 8. Login Page

**ไฟล์:** `app/login/page.tsx`
**ไฟล์ Action:** `app/actions/auth.ts`
**Route:** `/login`

หน้านี้ **เชื่อมต่อ Database จริงแล้ว** ผ่าน Server Action `login()`

### กระบวนการ Login

1. User กรอก email และ password
2. Server Action `login()` ถูกเรียก
3. Query หา admin user จาก email
4. ตรวจสอบ password ด้วย bcrypt
5. สร้าง JWT session cookie (อายุ 7 วัน)

**Query** (ไฟล์: `app/actions/auth.ts` → ฟังก์ชัน `login()`):
```sql
SELECT id, passwordHash
FROM adminuser
WHERE email = ?
LIMIT 1
```

**Parameters:** `[email]` (ค่าจาก form input)

**ผลลัพธ์ที่ได้:**
```typescript
[{ id: number; passwordHash: string }]
```

**ขั้นตอนหลัง Query:**
```typescript
// ถ้าไม่เจอ user → return error "Invalid credentials"
// ถ้าเจอ user → ตรวจสอบ password
const isValid = await bcrypt.compare(password, user.passwordHash)
// ถ้า password ถูก → สร้าง JWT แล้ว redirect ไป /dashboard
// ถ้า password ผิด → return error "Invalid credentials"
```

---

## สรุปภาพรวม

### Exported Types ทั้งหมดที่พร้อมใช้ใน Frontend

| Type | ไฟล์ | ใช้แสดงใน | Fields หลัก |
|------|------|-----------|-------------|
| `DashboardStats` | `lib/dashboard.ts` | Dashboard — KPI Cards | `totalRevenue`, `revenueChangePercent`, `activeOrders`, `activeRiders`, `pendingIssues` |
| `LiveOrder` | `lib/dashboard.ts` | Dashboard — Live Order Table | `orderNumber`, `restaurantName`, `customerName`, `status`, `createdAt` |
| `TopPerformer` | `lib/dashboard.ts` | Dashboard — Top Performers | `id`, `name`, `imageUrl`, `orderCount`, `revenue` |
| `DailyRevenue` | `lib/dashboard.ts` | Dashboard — Revenue Chart | `date`, `revenue`, `orderCount` |
| `StatusBreakdown` | `lib/dashboard.ts` | Dashboard — Order Breakdown | `status`, `count` |
| `AllOrder` | `lib/order.ts` | Orders — Order Table | `orderNumber`, `restaurantName`, `customerName`, `riderName`, `status`, `createdAt` |

> **หมายเหตุ:** `Order` (ผลลัพธ์จาก `getOrder()`) ยังไม่ได้ export — ใช้ภายในไฟล์เท่านั้น

---

### หน้าที่เชื่อมต่อ Database จริงแล้ว ✅

| หน้า | ฟังก์ชัน | Types ที่ใช้ |
|------|----------|-------------|
| Dashboard | `getDashboardStats()`, `getLiveOrders()`, `getTopPerformers()`, `getDailyRevenue()`, `getOrderStatusBreakdown()` | `DashboardStats`, `LiveOrder`, `TopPerformer`, `DailyRevenue`, `StatusBreakdown` |
| Login | `login()` | — (ไม่มี type แสดงผล) |

### หน้าที่ยังใช้ Mock Data ⚠️

| หน้า | Type ที่พร้อมใช้ | สิ่งที่ต้องทำ |
|------|----------------|--------------|
| Orders — Stats Cards | ผลลัพธ์จาก `getOrder()` | เรียก `getOrder()` แล้ว replace ค่า hardcode |
| Orders — Order Table | `AllOrder` | สร้างฟังก์ชัน `getAllOrders()` แล้ว import |
| Restaurants | ยังไม่มี type | สร้าง `lib/restaurant.ts` |
| Fleet | ยังไม่มี type | สร้าง `lib/fleet.ts` |
| Financials | ยังไม่มี type | สร้าง `lib/financials.ts` |
| Settings | ยังไม่มี type | สร้าง `lib/settings.ts` |

---

## Authentication & Middleware

**ไฟล์:** `proxy.ts` (Next.js Middleware)

- ตรวจสอบ JWT cookie ในทุก request
- **Protected routes:** `/dashboard`, `/orders`, `/restaurants`, `/fleet`, `/financials`, `/settings`, `/help`
- **Public routes:** `/login`, `/`
- Session หมดอายุใน 7 วัน
- ใช้ `SESSION_SECRET` จาก environment variable

---

*อัพเดทล่าสุด: 2026-05-07*
