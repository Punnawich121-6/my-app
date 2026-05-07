# Database Setup Guide — Zest & Savory Admin Portal

> **สถานะปัจจุบัน:** โปรเจกต์นี้เป็น Frontend-only ทั้งหมด ข้อมูลยังเป็น mock/hardcoded อยู่ใน component ยังไม่มี database, API routes, หรือ authentication backend

---

## สารบัญ

1. [เลือก Database](#1-เลือก-database)
2. [ติดตั้ง Dependencies](#2-ติดตั้ง-dependencies)
3. [ตั้งค่า Environment Variables](#3-ตั้งค่า-environment-variables)
4. [Prisma Schema (ทุก Table)](#4-prisma-schema-ทุก-table)
5. [Relations ระหว่าง Table](#5-relations-ระหว่าง-table)
6. [รัน Migration](#6-รัน-migration)
7. [Seed ข้อมูลเริ่มต้น](#7-seed-ข้อมูลเริ่มต้น)
8. [API Routes ที่ต้องสร้าง](#8-api-routes-ที่ต้องสร้าง)
9. [Authentication Setup](#9-authentication-setup)
10. [เชื่อม Frontend กับ Backend](#10-เชื่อม-frontend-กับ-backend)

---

## 1. เลือก Database

| ตัวเลือก | แนะนำ | เหมาะกับ |
|---|---|---|
| **PostgreSQL** | ✅ แนะนำที่สุด | Production, scalable |
| MySQL | ✓ ทางเลือก | ถ้าทีมถนัด MySQL |
| SQLite | dev only | ทดสอบ local เท่านั้น |

**แนะนำใช้ PostgreSQL** เพราะรองรับ JSON fields, Full-text search, และ scale ได้ดี

---

## 2. ติดตั้ง Dependencies

```bash
npm install @prisma/client next-auth bcryptjs jsonwebtoken zod
npm install -D prisma @types/bcryptjs @types/jsonwebtoken
```

สำหรับ PostgreSQL:
```bash
npm install pg
npm install -D @types/pg
```

สำหรับ MySQL (ทางเลือก):
```bash
npm install mysql2
```

**Dependencies ที่ต้องเพิ่มใน `package.json`:**

```json
{
  "@prisma/client": "^5.x",
  "next-auth": "^5.x",
  "bcryptjs": "^2.4.x",
  "jsonwebtoken": "^9.x",
  "zod": "^3.x",
  "pg": "^8.x"
}
```

---

## 3. ตั้งค่า Environment Variables

สร้างไฟล์ `.env.local` ที่ root ของโปรเจกต์:

```env
# ============================================================
# DATABASE
# ============================================================
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/zest_savory_db"

# Shadow DB สำหรับ Prisma migrations (ต้องมีถ้าใช้ PostgreSQL)
SHADOW_DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/zest_savory_shadow"

# ============================================================
# AUTHENTICATION (NextAuth)
# ============================================================
NEXTAUTH_SECRET="your-super-secret-key-min-32-chars"
NEXTAUTH_URL="http://localhost:3000"

# ============================================================
# APP CONFIG
# ============================================================
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
RESTAURANT_COMMISSION_PERCENT="15"
BASE_SERVICE_FEE="2.99"
MAX_DELIVERY_RADIUS_KM="12.5"
```

สร้างไฟล์ `.env.example` สำหรับทีม (ไม่ใส่ค่าจริง):

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DB_NAME"
SHADOW_DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DB_NAME_shadow"
NEXTAUTH_SECRET="generate-with: openssl rand -base64 32"
NEXTAUTH_URL="http://localhost:3000"
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
RESTAURANT_COMMISSION_PERCENT="15"
BASE_SERVICE_FEE="2.99"
MAX_DELIVERY_RADIUS_KM="12.5"
```

> อย่าลืมเพิ่ม `.env.local` ใน `.gitignore`

---

## 4. DBML Schema (ทุก Table)

> ใช้ paste ที่ [dbdiagram.io](https://dbdiagram.io) เพื่อดู diagram ได้เลย

```dbml
// Use DBML to define your database structure
// Docs: https://dbml.dbdiagram.io/docs

// ============================================================
// ADMIN USERS — ผู้ใช้งานระบบ Admin
// ============================================================
Table AdminUser {
  id                varchar      [primary key]
  email             varchar      [unique, not null]
  passwordHash      varchar      [not null]
  name              varchar      [not null]
  role              varchar      [default: 'EDITOR', note: 'SUPER_ADMIN | MANAGER | EDITOR']
  isActive          boolean      [default: true]
  twoFactorEnabled  boolean      [default: false]
  sessionTimeoutMin integer      [default: 30]
  lastLogin         timestamp
  createdAt         timestamp    [default: `now()`]
  updatedAt         timestamp
}
เเ
// ============================================================
// ADMIN SESSIONS — ใช้ track login sessions
// ============================================================
Table AdminSession {
  id          varchar   [primary key]
  adminUserId varchar   [not null]
  token       varchar   [unique, not null]
  ipAddress   varchar
  userAgent   varchar    
  createdAt   timestamp [default: `now()`]
  expiresAt   timestamp [not null]
}

// ============================================================
// RESTAURANTS — ร้านอาหารในระบบ
// ============================================================
Table Restaurant {
  id             varchar [primary key]
  name           varchar [not null]
  category       varchar [not null]
  rating         float   [default: 0]
  totalOrders    integer [default: 0]
  status         varchar [default: 'ACTIVE', note: 'ACTIVE | INACTIVE | SUSPENDED']
  commissionRate float   [default: 15.0] 
  serviceFeeRate float   [default: 2.99]
  address        varchar
  phone          varchar
  email          varchar
  imageUrl       varchar
  createdAt      timestamp [default: `now()`]
  updatedAt      timestamp
}

// ============================================================
// CUSTOMERS — ลูกค้าที่สั่งอาหาร
// ============================================================
Table Customer {
  id        varchar   [primary key]
  name      varchar   [not null]
  email     varchar   [unique, not null]
  phone     varchar
  address   varchar
  createdAt timestamp [default: `now()`]
  updatedAt timestamp
}

// ============================================================
// RIDERS — ไรเดอร์ในระบบ Fleet
// ============================================================
Table Rider {
  id            varchar   [primary key]
  name          varchar   [not null]
  email         varchar   [unique, not null]
  phone         varchar
  vehicle       varchar   [not null]
  vehicleType   varchar   [default: 'MOTORCYCLE', note: 'MOTORCYCLE | BICYCLE | CAR']
  status        varchar   [default: 'OFFLINE', note: 'ONLINE | OFFLINE | ON_DELIVERY']
  rating        float     [default: 0]
  runsCompleted integer   [default: 0]
  isVerified    boolean   [default: false]
  createdAt     timestamp [default: `now()`]
  updatedAt     timestamp
}

// ============================================================
// ORDERS — คำสั่งซื้อ
// ============================================================
Table Order {
  id           varchar   [primary key]
  orderNumber  varchar   [unique, not null]
  restaurantId varchar   [not null]
  customerId   varchar   [not null]
  riderId      varchar
  status       varchar   [default: 'PENDING', note: 'PENDING | CONFIRMED | PREPARING | OUT_FOR_DELIVERY | DELIVERED | CANCELLED | REFUNDED']
  totalAmount  float     [not null]
  tax          float     [default: 0]
  serviceFee   float     [default: 0]
  commission   float     [default: 0]
  notes        varchar
  createdAt    timestamp [default: `now()`]
  updatedAt    timestamp
}

// ============================================================
// TRANSACTIONS — รายการทางการเงิน
// ============================================================
Table Transaction {
  id            varchar   [primary key]
  orderId       varchar   [unique, not null]
  restaurantId  varchar   [not null]
  amount        float     [not null]
  tax           float     [default: 0]
  commission    float     [default: 0]
  netPayout     float     [not null]
  paymentMethod varchar   [default: 'CARD', note: 'CARD | CASH | WALLET | BANK_TRANSFER']
  status        varchar   [default: 'COMPLETED', note: 'PENDING | COMPLETED | FAILED | REFUNDED']
  createdAt     timestamp [default: `now()`]
  updatedAt     timestamp
}

// ============================================================
// AUDIT LOGS — บันทึก action ของ admin ทุกอย่าง
// ============================================================
Table AuditLog {
  id          varchar   [primary key]
  adminUserId varchar   [not null]
  action      varchar   [not null]
  resource    varchar   [not null]
  resourceId  varchar
  details     json
  ipAddress   varchar
  createdAt   timestamp [default: `now()`]
}

// ============================================================
// SYSTEM SETTINGS — ค่าตั้งค่าระบบ
// ============================================================
Table SystemSetting {
  id        varchar   [primary key]
  key       varchar   [unique, not null]
  value     varchar   [not null]
  updatedAt timestamp
}

// ============================================================
// RELATIONS
// ============================================================
Ref: AdminSession.adminUserId > AdminUser.id [delete: cascade]
Ref: AuditLog.adminUserId > AdminUser.id

Ref: Order.restaurantId > Restaurant.id
Ref: Order.customerId > Customer.id
Ref: Order.riderId > Rider.id

Ref: Transaction.orderId - Order.id
Ref: Transaction.restaurantId > Restaurant.id
```

---

## 5. Relations ระหว่าง Table

```
AdminUser
├── has_many → AdminSession (login sessions)
└── has_many → AuditLog (action history)

Restaurant
├── has_many → Order
└── has_many → Transaction

Customer
└── has_many → Order

Rider
└── has_many → Order (assigned deliveries)

Order
├── belongs_to → Restaurant
├── belongs_to → Customer
├── belongs_to → Rider (nullable)
└── has_one   → Transaction

Transaction
├── belongs_to → Order (1:1)
└── belongs_to → Restaurant
```

---

## 6. รัน Migration

```bash
# Initialize Prisma (ครั้งแรกอย่างเดียว)
npx prisma init

# สร้าง migration จาก schema
npx prisma migrate dev --name init

# Push schema ไปที่ DB โดยตรง (เหมาะสำหรับ dev เร็ว)
npx prisma db push

# Generate Prisma Client
npx prisma generate

# เปิด Prisma Studio (UI จัดการ DB)
npx prisma studio
```

**เพิ่ม script ใน `package.json`:**

```json
{
  "scripts": {
    "db:migrate": "prisma migrate dev",
    "db:push": "prisma db push",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "db:reset": "prisma migrate reset"
  }
}
```

---

## 7. Seed ข้อมูลเริ่มต้น

สร้างไฟล์ `prisma/seed.ts`:

```typescript
import { PrismaClient, AdminRole, RestaurantStatus, RiderStatus, VehicleType } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding database...')

  // --- Admin Users ---
  const hashedPassword = await bcrypt.hash('Admin@1234', 12)

  await prisma.adminUser.createMany({
    data: [
      {
        email: 'sarah.jenkins@zestandsavory.com',
        passwordHash: hashedPassword,
        name: 'Sarah Jenkins',
        role: AdminRole.SUPER_ADMIN,
        twoFactorEnabled: true,
      },
      {
        email: 'marcus.reed@zestandsavory.com',
        passwordHash: hashedPassword,
        name: 'Marcus Reed',
        role: AdminRole.MANAGER,
      },
      {
        email: 'emma.lin@zestandsavory.com',
        passwordHash: hashedPassword,
        name: 'Emma Lin',
        role: AdminRole.EDITOR,
      },
    ],
    skipDuplicates: true,
  })

  // --- Restaurants ---
  await prisma.restaurant.createMany({
    data: [
      { name: 'Burger Joint Co.', category: 'Burgers', rating: 4.8, totalOrders: 1243, status: RestaurantStatus.ACTIVE, commissionRate: 15 },
      { name: 'Sushi Master', category: 'Japanese', rating: 4.9, totalOrders: 987, status: RestaurantStatus.ACTIVE, commissionRate: 15 },
      { name: 'Green Bowl Salads', category: 'Healthy', rating: 4.7, totalOrders: 654, status: RestaurantStatus.ACTIVE, commissionRate: 12 },
      { name: 'Taco Fiesta', category: 'Mexican', rating: 4.6, totalOrders: 432, status: RestaurantStatus.INACTIVE, commissionRate: 15 },
      { name: "Luigi's Oven", category: 'Italian', rating: 4.5, totalOrders: 321, status: RestaurantStatus.ACTIVE, commissionRate: 15 },
      { name: 'Bangkok Spice', category: 'Thai', rating: 4.8, totalOrders: 876, status: RestaurantStatus.ACTIVE, commissionRate: 13 },
      { name: 'Artisan Pizza Hub', category: 'Pizza', rating: 4.7, totalOrders: 543, status: RestaurantStatus.SUSPENDED, commissionRate: 15 },
    ],
    skipDuplicates: true,
  })

  // --- Riders ---
  await prisma.rider.createMany({
    data: [
      { name: 'Marcus Johnson', email: 'marcus.j@fleet.com', phone: '+1-555-0101', vehicle: 'Honda PCX', vehicleType: VehicleType.MOTORCYCLE, status: RiderStatus.ONLINE, rating: 4.9, runsCompleted: 342, isVerified: true },
      { name: 'Sarah Chen', email: 'sarah.c@fleet.com', phone: '+1-555-0102', vehicle: 'Trek FX3', vehicleType: VehicleType.BICYCLE, status: RiderStatus.ON_DELIVERY, rating: 4.8, runsCompleted: 278, isVerified: true },
      { name: 'David Jones', email: 'david.j@fleet.com', phone: '+1-555-0103', vehicle: 'Yamaha NMAX', vehicleType: VehicleType.MOTORCYCLE, status: RiderStatus.OFFLINE, rating: 4.7, runsCompleted: 195, isVerified: true },
      { name: 'Alex Rivera', email: 'alex.r@fleet.com', phone: '+1-555-0104', vehicle: 'Kawasaki Z300', vehicleType: VehicleType.MOTORCYCLE, status: RiderStatus.ONLINE, rating: 4.6, runsCompleted: 421, isVerified: false },
    ],
    skipDuplicates: true,
  })

  // --- System Settings ---
  await prisma.systemSetting.createMany({
    data: [
      { key: 'RESTAURANT_COMMISSION_PERCENT', value: '15' },
      { key: 'BASE_SERVICE_FEE', value: '2.99' },
      { key: 'MAX_DELIVERY_RADIUS_KM', value: '12.5' },
      { key: 'PLATFORM_NAME', value: 'Zest & Savory' },
    ],
    skipDuplicates: true,
  })

  console.log('Seeding complete!')
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
```

เพิ่มใน `package.json`:

```json
{
  "prisma": {
    "seed": "ts-node --compiler-options {\"module\":\"CommonJS\"} prisma/seed.ts"
  }
}
```

รัน seed:

```bash
npx prisma db seed
```

---

## 8. API Routes ที่ต้องสร้าง

โปรเจกต์ยังไม่มี `/app/api/` เลย ต้องสร้างทั้งหมดดังนี้:

| Method | Route | หน้าที่ | ใช้ใน page |
|--------|-------|---------|-----------|
| GET | `/api/orders` | ดึงรายการ order ทั้งหมด (filter/paginate) | `app/orders/page.tsx` |
| GET | `/api/orders/[id]` | ดึง order รายชิ้น | - |
| PATCH | `/api/orders/[id]` | อัพเดต status | `app/orders/page.tsx` |
| GET | `/api/restaurants` | ดึงรายการร้าน | `app/restaurants/page.tsx` |
| POST | `/api/restaurants` | เพิ่มร้านใหม่ | `app/restaurants/page.tsx` |
| PATCH | `/api/restaurants/[id]` | แก้ไขข้อมูลร้าน | - |
| GET | `/api/fleet` | ดึงรายการ rider | `app/fleet/page.tsx` |
| PATCH | `/api/fleet/[id]` | แก้ไข rider | - |
| GET | `/api/financials` | ดึงข้อมูลการเงิน (KPIs + chart) | `app/financials/page.tsx` |
| GET | `/api/transactions` | ดึงรายการ transaction | `app/financials/page.tsx` |
| GET | `/api/dashboard` | ดึง KPI summary สำหรับ dashboard | `app/dashboard/page.tsx` |
| GET | `/api/users` | ดึงรายการ admin user | `app/settings/page.tsx` |
| POST | `/api/users` | เพิ่ม admin user ใหม่ | `app/settings/page.tsx` |
| PATCH | `/api/users/[id]` | แก้ไข admin user | - |
| DELETE | `/api/users/[id]` | ลบ admin user | - |
| POST | `/api/auth/login` | Login | `app/login/page.tsx` |
| POST | `/api/auth/logout` | Logout | - |
| GET | `/api/settings` | ดึง system settings | `app/settings/page.tsx` |
| PATCH | `/api/settings` | อัพเดต system settings | `app/settings/page.tsx` |

**ตัวอย่าง API Route** (`app/api/restaurants/route.ts`):

```typescript
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  const restaurants = await prisma.restaurant.findMany({
    orderBy: { createdAt: 'desc' },
  })
  return NextResponse.json(restaurants)
}
```

**สร้าง Prisma Client singleton** (`lib/prisma.ts`):

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma: PrismaClient }

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({ log: ['query'] })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

---

## 9. Authentication Setup

ติดตั้ง NextAuth v5:

```bash
npm install next-auth@beta
```

สร้างไฟล์ `auth.ts` ที่ root:

```typescript
import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null

        const user = await prisma.adminUser.findUnique({
          where: { email: credentials.email as string },
        })

        if (!user || !user.isActive) return null

        const isValid = await bcrypt.compare(credentials.password as string, user.passwordHash)
        if (!isValid) return null

        return { id: user.id, email: user.email, name: user.name, role: user.role }
      },
    }),
  ],
  callbacks: {
    jwt({ token, user }) {
      if (user) token.role = (user as any).role
      return token
    },
    session({ session, token }) {
      if (session.user) (session.user as any).role = token.role
      return session
    },
  },
  pages: {
    signIn: '/login',
  },
})
```

สร้าง `app/api/auth/[...nextauth]/route.ts`:

```typescript
import { handlers } from '@/auth'
export const { GET, POST } = handlers
```

---

## 10. เชื่อม Frontend กับ Backend

Pages ที่มี mock data และต้องแก้ไข:

| File | Mock Data อยู่ที่ | แทนที่ด้วย |
|------|-----------------|-----------|
| `app/dashboard/page.tsx` | hardcoded KPI values | `fetch('/api/dashboard')` |
| `app/orders/page.tsx` | hardcoded orders array | `fetch('/api/orders')` |
| `app/restaurants/page.tsx` | hardcoded restaurants array | `fetch('/api/restaurants')` |
| `app/fleet/page.tsx` | hardcoded riders array | `fetch('/api/fleet')` |
| `app/financials/page.tsx` | hardcoded transactions array | `fetch('/api/transactions')` |
| `app/settings/page.tsx` | hardcoded admin users list | `fetch('/api/users')` |
| `app/login/page.tsx` | ยังไม่มี backend | ใช้ NextAuth `signIn()` |

---

## Quick Start (ทำตามลำดับ)

```bash
# 1. ติดตั้ง dependencies
npm install @prisma/client next-auth@beta bcryptjs zod pg
npm install -D prisma @types/bcryptjs

# 2. สร้าง Prisma
npx prisma init

# 3. แทน schema.prisma ด้วย schema ข้างบน

# 4. สร้าง .env.local ใส่ DATABASE_URL

# 5. รัน migration
npx prisma migrate dev --name init

# 6. Seed ข้อมูล
npx prisma db seed

# 7. เปิด Prisma Studio ตรวจสอบ
npx prisma studio

# 8. สร้าง API routes ตามตาราง Section 8

# 9. เปลี่ยน mock data เป็น fetch จาก API
```

---

## Checklist

- [ ] ติดตั้ง Prisma และ DB driver
- [ ] สร้าง `.env.local` พร้อม `DATABASE_URL`
- [ ] วาง `prisma/schema.prisma` ตาม schema ด้านบน
- [ ] รัน `npx prisma migrate dev --name init`
- [ ] รัน `npx prisma db seed`
- [ ] สร้าง `lib/prisma.ts` (singleton client)
- [ ] ตั้งค่า NextAuth (`auth.ts`)
- [ ] สร้าง `/app/api/` routes ทั้งหมด
- [ ] แทน mock data ใน pages ด้วย API calls
- [ ] ทดสอบ login/logout flow
- [ ] ทดสอบ CRUD ร้านอาหาร, orders, fleet
