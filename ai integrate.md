# AI Integration — Zest & Savory Platform

เอกสารนี้รวบรวม AI ทั้งหมดที่ใช้ในแพลตฟอร์ม ครอบคลุมทุก app และ web admin

---

## โครงสร้าง AI ของระบบ

```
┌─────────────────────────────────────────────────────────┐
│                  gen.ai.kku.ac.th/api/v1                │
│              (OpenAI-compatible proxy endpoint)          │
└────────────────────────┬────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
  Gemini 2.5        Gemini 2.5       Claude / o4-mini
  Flash Lite        Flash            (via same proxy)
  (backend)         (web admin)      (web admin)
```

**Base URL :** `https://gen.ai.kku.ac.th/api/v1`
**API Key  :** เก็บใน `.env.local` และ hardcode ใน `backend/routes/ai.js`

---

## 1. Backend (`backend/routes/ai.js`)

Model หลัก : **`gemini-2.5-flash-lite`**
Library    : `openai` npm package (OpenAI-compatible client)

---

### 1.1 สแกนอาหารจากรูป (`POST /api/ai/scan-food`)

**ใช้ใน :** Customer App → หน้าสแกนอาหาร
**เงื่อนไขเรียก :** ผู้ใช้ถ่ายหรือเลือกรูปอาหาร

**System Prompt :**
```
คุณเป็นผู้เชี่ยวชาญด้านโภชนาการ
วิเคราะห์อาหารจากภาพและให้ข้อมูลโภชนาการที่แม่นยำ
ตอบเป็น JSON เท่านั้น
```

**User Prompt :**
```
วิเคราะห์อาหารในภาพและประเมินคุณค่าโภชนาการ
ตอบเป็น JSON เท่านั้น ไม่มีข้อความอื่น:
{
  "foodName": "ชื่ออาหาร (ภาษาไทย)",
  "foodNameEn": "Food name (English)",
  "description": "คำอธิบาย 1-2 ประโยค (ภาษาไทย)",
  "servingSize": "ปริมาณต่อ 1 ที่",
  "calories": 0,       ← kcal
  "protein": 0.0,      ← กรัม
  "carbs": 0.0,        ← กรัม
  "fat": 0.0,          ← กรัม
  "fiber": 0.0,        ← กรัม
  "sugar": 0.0,        ← กรัม
  "sodium": 0,         ← มิลลิกรัม
  "healthScore": 0,    ← 1-10 (10 = ดีที่สุด)
  "healthNote": "คำแนะนำสุขภาพ"
}
ถ้าไม่เห็นอาหารในภาพ → {"error": "ไม่พบอาหารในภาพ กรุณาถ่ายภาพใหม่"}
```

**Input  :** base64 image (JPEG/PNG)
**Output :** JSON โภชนาการ

---

### 1.2 จับคู่อาหารกับเมนูในระบบ (`POST /api/ai/match-food`)

**ใช้ใน :** Customer App → ค้นหาด้วยรูปภาพ
**เงื่อนไขเรียก :** ผู้ใช้ถ่ายรูปอาหารแล้วต้องการหาเมนูที่คล้ายกัน

**ขั้นตอน (2-step) :**

Step 1 — AI ระบุชื่ออาหาร:
```
System: "ระบุชื่ออาหารจากภาพ ตอบเป็น JSON เท่านั้น ไม่มีข้อความอื่น"

User: ระบุชื่ออาหารในภาพ ตอบ JSON:
{
  "foodName": "ชื่ออาหารหลักภาษาไทย",
  "keywords": ["คำค้นหา1", "คำค้นหา2", "คำค้นหา3"]
}
keywords = ชื่อเรียกอื่น / ชื่อย่อ / ส่วนประกอบหลัก 3-5 คำ
ถ้าไม่มีอาหาร → {"error": "ไม่พบอาหารในภาพ กรุณาถ่ายใหม่"}
```

Step 2 — Query DB ด้วย keywords ที่ได้ → ค้นใน `menu_items` + `restaurant`

**Output :** รายการเมนูที่ตรงกัน พร้อมข้อมูลร้าน

---

### 1.3 แนะนำเมนูอาหาร (`POST /api/ai/suggest-food`)

**ใช้ใน :** Customer App → ระบบแนะนำอาหาร
**เงื่อนไขเรียก :** ผู้ใช้บอก preference หรือขอแนะนำแบบ random

**Logic :**
1. Query DB ดึงเมนูที่ตรง keyword (สูงสุด 60 รายการ)
2. ถ้ามีมากกว่า 1 รายการ → ส่งให้ AI เลือก

**Prompt เลือกเมนู :**
```
System: "เลือกเมนูที่ตรงกับความต้องการมากที่สุด
         ตอบแค่ตัวเลขลำดับเดียวเท่านั้น เช่น 3
         ห้ามตอบอื่น"

User: ต้องการ: "{preference}"

1. ชื่อเมนู (ชื่อร้าน) ฿ราคา
2. ...
```

**เงื่อนไขพิเศษ :**
- `excludeStoreId` — ไม่แนะนำจากร้านนี้ (กรณีหาร้านอื่นที่มีเมนูเดียวกัน)
- `excludeItemId` — ไม่แนะนำเมนูนี้ซ้ำ
- `sameStoreId` — แนะนำเฉพาะภายในร้านนี้

---

### 1.4 ข้อมูลโภชนาการจากชื่อ (`POST /api/ai/nutrition-by-name`)

**ใช้ใน :** Customer App → หน้ารายละเอียดเมนู
**เงื่อนไขเรียก :** ผู้ใช้กดดูข้อมูลโภชนาการของเมนูที่ไม่มีรูป

**System Prompt :**
```
คุณเป็นผู้เชี่ยวชาญด้านโภชนาการ
ประเมินคุณค่าโภชนาการของอาหารไทยจากชื่ออาหาร
ตอบเป็น JSON เท่านั้น
```

**User Prompt :** เหมือน scan-food แต่ใช้ชื่ออาหารแทนรูป
**Input :** `{ foodName, storeName }`
**Output :** JSON โภชนาการ (format เดียวกับ scan-food)

---

### 1.5 โค้ชไรเดอร์ (`POST /api/ai/rider-plan`)

**ใช้ใน :** Rider App → หน้า Dashboard ไรเดอร์
**เงื่อนไขเรียก :** ไรเดอร์กดขอคำแนะนำ หรือเมื่อเปิดหน้า earnings

**System Prompt :**
```
คุณเป็น AI โค้ชส่วนตัวสำหรับไรเดอร์ส่งอาหาร
ให้คำแนะนำที่กระตุ้น ใช้งานได้จริง และให้กำลังใจ
```

**User Prompt :**
```
วางแผนให้ไรเดอร์วันนี้:
- ส่งแล้ว: {todayCount} รอบ ได้ ฿{todayEarned}
- เป้าหมาย: ฿{targetAmount}
- เฉลี่ย/รอบ: ฿{avgPerDelivery}
- เหลืออีก: {remainingDeliveries} รอบ
ให้คำแนะนำ 2-3 ประโยค ภาษาไทย กระชับ ให้กำลังใจ
และแนะนำว่าควรทำอย่างไร
```

**Output :** ข้อความแนะนำ 2-3 ประโยค

---

### 1.6 Auto-Crop รูปภาพ (`POST /api/ai/auto-crop`)

**ใช้ใน :** Merchant App → อัปโหลดรูปเมนู, Web Admin → เพิ่มร้านอาหาร
**เงื่อนไขเรียก :** ผู้ใช้อัปโหลดรูปอาหาร ก่อน crop

**System Prompt :**
```
วิเคราะห์ตำแหน่งอาหารในภาพ
ตอบ JSON เท่านั้น ไม่มีข้อความอื่น
```

**User Prompt :**
```
หาตำแหน่งกรอบครอบอาหารหลักในภาพ
ตอบ JSON ค่าเป็นสัดส่วน 0.0-1.0 ของขนาดภาพ
ให้พื้นที่รอบอาหารเพิ่มอีก 8%:
{"x": 0.0, "y": 0.0, "w": 1.0, "h": 1.0}
x,y = มุมซ้ายบน, w,h = ความกว้างและสูง
ถ้าอาหารเต็มภาพ → {"x":0,"y":0,"w":1,"h":1}
```

**Output :** `{ x, y, w, h }` normalized 0.0–1.0

---

### 1.7 ข้อความแจ้งลูกค้าอัตโนมัติ (`POST /api/ai/rider-notification`)

**ใช้ใน :** Rider App → ระหว่างส่งอาหาร
**เงื่อนไขเรียก :** ไรเดอร์กดปุ่มแจ้งสถานะ (`at_store` หรือ `picking_up`)

**System Prompt :**
```
คุณเป็นไรเดอร์ส่งอาหาร เขียนข้อความ chat ส่งให้ลูกค้า
ต้องสุภาพ เป็นกันเอง กระชับ ใช้ emoji 1-2 ตัว
ตอบภาษาไทยเท่านั้น ไม่เกิน 30 คำ
ตอบเป็นข้อความ chat เท่านั้น ไม่มีคำอธิบายเพิ่ม
```

**User Prompt :**
```
สถานการณ์: {ctx}{etaText}
ชื่อลูกค้า: {customerName}
เขียนข้อความแจ้งลูกค้าว่าสถานะปัจจุบันคืออะไร
```

**ctx mapping :**
- `at_store` → "ถึงร้าน '{storeName}' แล้ว กำลังรับอาหาร"
- `picking_up` → "รับอาหารจากร้าน '{storeName}' เรียบร้อยแล้ว กำลังออกเดินทางมาส่ง"

**Output :** ข้อความ chat ≤30 คำ พร้อม emoji

---

### 1.8 สร้างคำอธิบาย / ชื่อร้าน / Bio (`POST /api/ai/generate-description`)

**ใช้ใน :** Merchant App (เมนู), Merchant App (ชื่อร้าน), Rider App (Bio), Web Admin
**เงื่อนไขเรียก :** ผู้ใช้กดปุ่ม "สร้างอัตโนมัติ"

| context | ใช้ใน | Prompt |
|---------|-------|--------|
| `menu` (default) | Merchant App — เพิ่มเมนู | `เขียนคำอธิบายเมนู "{itemName}" ร้าน {storeName} ให้น่าสนใจ 1-2 ประโยค ภาษาไทย บอกรสชาติหรือจุดเด่น ตอบแค่คำอธิบายเท่านั้น` |
| `rider` | Rider App — โปรไฟล์ | `สร้าง bio สั้นๆ สำหรับไรเดอร์ชื่อ "{storeName}" ที่ส่งสำเร็จไปแล้ว {itemName} รอบ ให้ฟังดูเป็นมืออาชีพ น่าเชื่อถือ และมีพลังงาน 1-2 ประโยค` |
| `store_name` | Merchant App — สร้างร้าน | `ตั้งชื่อร้านอาหารไทยให้ฟังดูน่าสนใจ อิงจากประเภอาหาร: "{storeName}" ห้ามซ้ำกับชื่อที่มีในระบบ` |

**เงื่อนไขพิเศษ `store_name` :**
- Query ดึงชื่อร้านทั้งหมดใน DB → ส่งให้ AI หลีกเลี่ยง
- ลอง generate สูงสุด 5 รอบจนกว่าจะไม่ซ้ำ
- ถ้าซ้ำทุกรอบ → append random 4 หลัก

---

## 2. Web Admin (`myweb/my-project/app/api/ai/`)

---

### 2.1 Admin Chat Assistant (`POST /api/ai/chat`)

**Model :** `claude-sonnet-4-6` (env: `AI_MODEL`)
**ใช้ใน :** Web Admin → ปุ่ม AI Chat (ทุกหน้า)
**เงื่อนไขเรียก :** Admin พิมพ์คำถาม
**Response :** **Streaming** (Server-Sent Events)

**Context ที่ดึงจาก DB ก่อนส่ง Prompt :**
- ยอดขายวันนี้ / เดือนนี้
- จำนวนออเดอร์ทั้งหมด / active
- รายการออเดอร์ active ทั้งหมด (พร้อมสถานะ)
- รายชื่อไรเดอร์ทุกคน (ชื่อ, สถานะ, rating, รอบที่ทำ)
- รายชื่อร้านอาหารทุกร้าน (ชื่อ, ประเภท, สถานะ, rating)
- รายการลูกค้า (ชื่อ, เบอร์, วันที่สมัคร)
- ออเดอร์ล่าสุด 20 รายการ
- ธุรกรรมการเงินล่าสุด
- รีวิวไรเดอร์ล่าสุด
- ข้อความ chat ล่าสุด

**System Prompt :**
```
คุณคือ AI Assistant ของแพลตฟอร์ม Food Delivery "Zest & Savory"
ตอบเป็นภาษาไทย กระชับ ชัดเจน ใช้ข้อมูลจริงจาก dashboard
อย่าประดิษฐ์ข้อมูลที่ไม่มีใน context
[+ ข้อมูลทั้งหมดจาก DB แบบ real-time]
```

**ตัวอย่าง built-in suggestions :**
- "ยอดขายวันนี้เป็นอย่างไร?"
- "แนะนำกลยุทธ์เพิ่มยอดขาย"
- "ไรเดอร์คนไหนทำงานดีที่สุด?"

---

### 2.2 สร้างคำอธิบายร้านอาหาร (`POST /api/ai/description`)

**Model :** `gemini-2.5-flash` (env: `AI_DESCRIPTION_MODEL`)
**ใช้ใน :** Web Admin → หน้าร้านอาหาร → เพิ่ม/แก้ไขร้าน
**เงื่อนไขเรียก :** Admin กดปุ่ม "สร้าง AI"

**System Prompt :**
```
คุณเป็นผู้เชี่ยวชาญด้านการเขียนคำอธิบายร้านอาหารภาษาไทย
```

**User Prompt :**
```
เขียนคำอธิบายร้านอาหารสั้นๆ ภาษาไทย 2-3 ประโยค
น่าสนใจและดึงดูดใจลูกค้า สำหรับร้าน: {storeName}
```

**Output :** คำอธิบายร้าน 2-3 ประโยค

---

### 2.3 วิเคราะห์ธุรกิจเชิงกลยุทธ์ (`POST /api/ai/analytics`)

**Model :** `grok-4.3` (env: `AI_ANALYTICS_MODEL`)
**ใช้ใน :** Web Admin → หน้า Analytics AI
**เงื่อนไขเรียก :** Admin เลือกระยะเวลาและกดสร้างแผน
**Response :** Non-streaming (รอผล)

**Context ที่ดึงจาก DB :**
- รายได้รายเดือน (ย้อนหลัง 12 เดือน)
- สัดส่วนรายได้ตามประเภทอาหาร
- อัตราการเติบโต (เทียบงวดก่อน)
- Top 5 ร้านที่ขายดี
- สัดส่วนสถานะออเดอร์
- Peak hours Top 5
- สถานะสุขภาพร้าน (active/inactive)
- จำนวนไรเดอร์, rating เฉลี่ย, รอบที่ทำ
- รายได้รายไตรมาส (ย้อนหลัง 4 ไตรมาส)
- รายได้แพลตฟอร์ม vs ร้านค้า

**Prompt เงื่อนไข :**
```
สร้างแผนธุรกิจ {planMonths} เดือน (เดือน {startMonth}–{endMonth})
อ้างอิงตัวเลขจริงจาก data ทุกครั้ง ห้ามประดิษฐ์ตัวเลข

สำหรับแต่ละเดือนให้ระบุ:
1. เป้าหมายรายได้ (พร้อมเหตุผลอ้างอิงข้อมูล)
2. แผนร้านอาหาร (onboard ใหม่ / กระตุ้นร้านเงียบ)
3. แผนไรเดอร์ (รับเพิ่ม / พัฒนา rating)
4. แผนการตลาด (โปรโมชัน / loyalty)
5. แผน operation (ลด cancellation / เพิ่ม peak capacity)
6. KPI ที่ต้องติดตาม

จากนั้นสรุป Recommendations ภาพรวม:
- Growth opportunities
- ความเสี่ยงที่ต้องระวัง
- Quick wins (ทำได้ใน 30 วัน)
```

**Output :** Markdown แผนธุรกิจ (ยาว ~800-2000 tokens)

---

### 2.4 AI Draft Reply (Support Chat) (`POST /api/support/[storeId]/ai-draft`)

**Model :** ใช้ผ่าน backend AI endpoint
**ใช้ใน :** Web Admin → หน้า Support Chat → ปุ่ม "ให้ AI ร่างตอบ"
**เงื่อนไขเรียก :** Admin เลือก thread แล้วกดปุ่ม AI Draft

**Logic :**
1. ดึง message ทั้งหมดของ thread นั้นจาก DB
2. ส่งประวัติการสนทนาให้ AI
3. AI ร่างคำตอบ → แสดงใน input box ให้ admin แก้ก่อนส่ง

**System Prompt :**
```
คุณเป็น Admin ของแพลตฟอร์ม Food Delivery "Zest & Savory"
กำลังตอบร้านค้าในระบบ Support Chat
ตอบภาษาไทย กระชับ สุภาพ เป็นมืออาชีพ
```

**User Prompt :**
```
ประวัติการสนทนา:
[store]: {message1}
[admin]: {message2}
...
[store]: {lastMessage}   ← message ล่าสุดของร้าน

ร่างคำตอบให้ admin ตอบร้านค้า
```

**Output :** ข้อความตอบกลับ (admin ยังแก้ไขได้ก่อนส่ง)

---

## 3. สรุปภาพรวม

| # | Feature | App | Model | Input | Trigger |
|---|---------|-----|-------|-------|---------|
| 1 | สแกนโภชนาการจากรูป | Customer | Gemini 2.5 Flash Lite | รูปภาพ | ถ่ายรูปอาหาร |
| 2 | จับคู่เมนูจากรูป | Customer | Gemini 2.5 Flash Lite | รูปภาพ | ค้นหาด้วยรูป |
| 3 | แนะนำเมนู | Customer | Gemini 2.5 Flash Lite | preference text | ขอแนะนำ |
| 4 | โภชนาการจากชื่อ | Customer | Gemini 2.5 Flash Lite | ชื่ออาหาร | กดดูข้อมูล |
| 5 | โค้ชไรเดอร์ | Rider | Gemini 2.5 Flash Lite | ตัวเลขรายได้ | เปิดหน้า earnings |
| 6 | แจ้งสถานะลูกค้า | Rider | Gemini 2.5 Flash Lite | step, storeName | กดอัปเดตสถานะ |
| 7 | สร้าง Bio ไรเดอร์ | Rider | Gemini 2.5 Flash Lite | ชื่อ, จำนวนรอบ | กดสร้าง |
| 8 | Auto-Crop รูปอาหาร | Merchant + Admin | Gemini 2.5 Flash Lite | รูปภาพ | อัปโหลดรูป |
| 9 | คำอธิบายเมนู | Merchant | Gemini 2.5 Flash Lite | ชื่อเมนู | กดสร้าง |
| 10 | ชื่อร้านอาหาร | Merchant | Gemini 2.5 Flash Lite | ประเภทอาหาร | กดสร้าง |
| 11 | คำอธิบายร้าน | Admin Web | Gemini 2.5 Flash | ชื่อร้าน | กดสร้าง AI |
| 12 | Admin Chat Assistant | Admin Web | Claude Sonnet 4.6 | คำถาม + DB context | พิมพ์คำถาม |
| 13 | Analytics & แผนธุรกิจ | Admin Web | Grok 4.3 | DB analytics + ระยะเวลา | กดสร้างแผน |
| 14 | AI Draft Reply | Admin Web | (ผ่าน backend) | ประวัติ chat | กดปุ่ม AI Draft |

---

## 4. Environment Variables

| Variable | ใช้ใน | ค่าปัจจุบัน |
|----------|-------|------------|
| `AI_BASE_URL` | Next.js (web admin) | `https://gen.ai.kku.ac.th/api/v1` |
| `AI_MODEL` | Admin Chat | `deepseek-v3.2` |
| `AI_ANALYTICS_MODEL` | Analytics | `grok-4.3` |
| `AI_DESCRIPTION_MODEL` | Restaurant description | `gemini-2.5-flash` |
| `ANTHROPIC_API_KEY` | ทุก AI ใน web admin | `sk_Sder...` |
| hardcoded ใน `ai.js` | Backend AI ทุกตัว | `sk_Sder...` (key เดียวกัน) |

> **หมายเหตุ:** backend ใช้ base URL `https://gen.ai.kku.ac.th/api/v1` hardcode ใน `ai.js` บรรทัด 6

---

## 5. Flow Diagram

```
Customer App
  ├── ถ่ายรูปอาหาร      → /api/ai/scan-food      → Gemini → JSON โภชนาการ
  ├── ค้นหาด้วยรูป      → /api/ai/match-food      → Gemini → รายการเมนู
  ├── ขอแนะนำอาหาร     → /api/ai/suggest-food    → DB + Gemini → เมนูเดียว
  └── ดูโภชนาการเมนู   → /api/ai/nutrition-by-name → Gemini → JSON

Merchant App
  ├── อัปโหลดรูปเมนู   → /api/ai/auto-crop       → Gemini → crop coordinates
  ├── สร้างคำอธิบาย    → /api/ai/generate-description → Gemini → text
  └── ตั้งชื่อร้าน     → /api/ai/generate-description → DB + Gemini → ชื่อ

Rider App
  ├── ดู earnings       → /api/ai/rider-plan       → Gemini → คำแนะนำ
  ├── แจ้งสถานะ        → /api/ai/rider-notification → Gemini → ข้อความ chat
  └── สร้าง Bio        → /api/ai/generate-description → Gemini → bio

Admin Web
  ├── AI Chat           → /api/ai/chat             → Claude Sonnet 4.6 (stream)
  ├── สร้างคำอธิบายร้าน → /api/ai/description      → Gemini 2.5 Flash
  ├── Analytics Plan    → /api/ai/analytics         → Grok 4.3
  └── AI Draft Reply    → /api/support/[id]/ai-draft → backend AI
```
