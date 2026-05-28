const db = require('../db');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// ── Create minimal placeholder images ────────────────────────────────────────
// Minimal 1×1 JPEG bytes (different tints to simulate food photos)
const jpegBytes = Buffer.from(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8U' +
  'HRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgN' +
  'DRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy' +
  'MjL/wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAA' +
  'AAAAAAAAAAAAAP/EABQBAQAAAAAAAAAAAAAAAAAAAAD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA' +
  '/9oADAMBAAIRAxEAPwCwABmX/9k=',
  'base64'
);

const reviewUploadDir = path.join(__dirname, '..', 'uploads', 'reviews');
if (!fs.existsSync(reviewUploadDir)) fs.mkdirSync(reviewUploadDir, { recursive: true });

function saveImage(filename) {
  const filepath = path.join(reviewUploadDir, filename);
  if (!fs.existsSync(filepath)) fs.writeFileSync(filepath, jpegBytes);
  return `http://localhost:3001/uploads/reviews/${filename}`;
}

// Pre-generate placeholder image files
const imgFiles = [
  'review_food1.jpg', 'review_food2.jpg', 'review_food3.jpg',
  'review_food4.jpg', 'review_food5.jpg', 'review_food6.jpg',
];
const imgUrls = imgFiles.map(saveImage);

// ── Review data ───────────────────────────────────────────────────────────────
// รีวิวจาก account 0881248456 — จะใส่ให้ทุกร้าน
const reviews0881248456 = [
  { rating: 5, comment: 'อาหารอร่อยมากเลยครับ รสชาติดี สั่งครั้งต่อไปแน่นอน', daysAgo: 1 },
  { rating: 4, comment: 'โดยรวมดีมากครับ อาหารสด รสชาติจัดจ้าน แค่รอนานหน่อยแต่คุ้มค่าเลย', daysAgo: 5 },
  { rating: 5, comment: 'ประทับใจมากครับ เมนูเด็ดสุดยอด เผ็ดร้อนกำลังดี จะกลับมาสั่งอีกแน่นอน', daysAgo: 12 },
  { rating: 5, comment: 'บริการดีมากๆ อาหารร้อนถึงมือ แพ็คเก็จดีไม่หก ขอบคุณมากครับ', daysAgo: 20 },
  { rating: 3, comment: 'อาหารโอเคนะครับ รสชาติพอใช้ได้ แต่ปริมาณน้อยไปนิดนึง', daysAgo: 30 },
  { rating: 5, comment: 'เมนูหลากหลายมากเลยครับ อร่อยทุกอย่าง ราคาสมเหตุสมผล', daysAgo: 7 },
  { rating: 4, comment: 'อาหารสดใหม่ทุกวันครับ รสชาติคงที่ดี ชอบมากเลย', daysAgo: 14 },
  { rating: 5, comment: 'ร้านนี้ดีมากๆ ครับ อร่อยทุกเมนู บริการรวดเร็ว ประทับใจ', daysAgo: 3 },
  { rating: 4, comment: 'ไม่ผิดหวังเลยครับ อาหารอร่อย ราคาโอเค จะแนะนำเพื่อนให้มาสั่ง', daysAgo: 18 },
  { rating: 5, comment: 'ยอดเยี่ยมมากครับ ทั้งรสชาติและบริการ ร้านโปรดเลย', daysAgo: 25 },
  { rating: 5, comment: 'สั่งบ่อยมากเลยครับ ไม่เคยผิดหวัง อาหารอร่อยและสดใหม่เสมอ', daysAgo: 8 },
];

const otherReviews = [
  {
    customer_name: 'สมชาย ใจดี',
    rating: 5,
    comment: 'ข้าวมันไก่อร่อยมากเลยค่ะ ไก่นุ่ม น้ำจิ้มรสเด็ด กลับมาสั่งอีกแน่นอน',
    daysAgo: 2,
    images: [imgUrls[0], imgUrls[1]],
  },
  {
    customer_name: 'มาลี รักษ์ดี',
    rating: 5,
    comment: 'ต้มยำกุ้งรสจัดมากๆ เลยค่ะ กุ้งสดใหม่ เห็ดหอมเต็มถ้วย อร่อยสุดๆ',
    daysAgo: 3,
    images: [imgUrls[2]],
  },
  {
    customer_name: 'นภา สุขสันต์',
    rating: 4,
    comment: 'ส้มตำไทยอร่อยมากค่ะ เปรี้ยวหวานเค็มกำลังดี ปูเค็มอร่อยด้วย แต่รอนาน 40 นาที',
    daysAgo: 7,
    images: [imgUrls[3], imgUrls[4]],
  },
  {
    customer_name: 'วิชัย ทองดี',
    rating: 5,
    comment: 'แกงเขียวหวานไก่อร่อยมากๆ ครับ ซอสข้นกำลังดี กะทิหอมมัน ข้าวหอมมะลิด้วย สุดยอด',
    daysAgo: 9,
    images: [imgUrls[5], imgUrls[0]],
  },
  {
    customer_name: 'อนุชา ประเสริฐ',
    rating: 4,
    comment: 'ผัดซีอิ๊วอร่อยนะครับ เส้นใหญ่นุ่มดี ไข่ดาวสวย แต่หวานนิดนึง โดยรวมโอเคมาก',
    daysAgo: 14,
    images: [imgUrls[1], imgUrls[2]],
  },
  {
    customer_name: 'พิมพ์ใจ สดใส',
    rating: 5,
    comment: 'ข้าวเหนียวมะม่วงอร่อยมากค่ะ มะม่วงสุกพอดี ข้าวเหนียวมะพร้าวหอมหวาน ของหวานอร่อยมาก',
    daysAgo: 18,
    images: [imgUrls[3]],
  },
  {
    customer_name: 'กิตติ มั่นคง',
    rating: 5,
    comment: 'หมูกระทะอร่อยมากครับ เนื้อสดใหม่ น้ำจิ้มสูตรพิเศษ บรรยากาศดี คุ้มค่ามากๆ',
    daysAgo: 22,
    images: [imgUrls[4], imgUrls[5], imgUrls[0]],
  },
  {
    customer_name: 'วรรณา ชื่นบาน',
    rating: 3,
    comment: 'อาหารโอเคค่ะ ไม่ได้แย่แต่ไม่ได้ดีเป็นพิเศษ ราคาพอสมควร บริการเร็วดี',
    daysAgo: 25,
    images: [imgUrls[1]],
  },
  {
    customer_name: 'ธนวัฒน์ สวัสดี',
    rating: 5,
    comment: 'ข้าวผัดกุ้งอร่อยมากครับ กุ้งตัวใหญ่ ข้าวไม่แฉะ กลิ่นหอมเตาไฟดีมาก เป็นร้านโปรดเลย',
    daysAgo: 28,
    images: [imgUrls[2], imgUrls[3]],
  },
  {
    customer_name: 'สุดา รุ่งเรือง',
    rating: 4,
    comment: 'น้ำมะนาวสดชื่นมากค่ะ เปรี้ยวหวานกำลังดี ชาไทยก็อร่อย ดีใจที่มีเครื่องดื่มหลากหลาย',
    daysAgo: 35,
    images: [imgUrls[4]],
  },
];

async function seed() {
  try {
    // ── Ensure images column exists ─────────────────────────────────────────
    await db.query(`ALTER TABLE reviews ADD COLUMN images TEXT DEFAULT NULL`).catch(() => {});

    // ── Find/create customer 0881248456 ─────────────────────────────────────
    let [[cust]] = await db.query('SELECT id, name FROM customer WHERE phone = ?', ['0881248456']);
    if (!cust) {
      const custId = crypto.randomUUID();
      await db.query(
        'INSERT INTO customer (id, name, email, phone) VALUES (?, ?, ?, ?)',
        [custId, 'บอส ทดสอบ', '0881248456@customerapp.local', '0881248456']
      );
      [[cust]] = await db.query('SELECT id, name FROM customer WHERE phone = ?', ['0881248456']);
    }
    console.log(`Customer 0881248456: id=${cust.id}, name=${cust.name}`);

    // ── Get all restaurants ─────────────────────────────────────────────────
    const [restaurants] = await db.query('SELECT id, name FROM restaurant LIMIT 10');
    if (!restaurants.length) {
      console.log('ไม่พบร้านอาหารในระบบ');
      process.exit(0);
    }

    let inserted = 0;

    // ── Seed reviews from 0881248456 — ทุกร้าน ─────────────────────────────
    for (let si = 0; si < restaurants.length; si++) {
      const store = restaurants[si];
      const r = reviews0881248456[si % reviews0881248456.length];
      const createdAt = new Date();
      createdAt.setDate(createdAt.getDate() - r.daysAgo);

      const [[dup]] = await db.query(
        'SELECT id FROM reviews WHERE customer_id = ? AND store_id = ?',
        [cust.id, store.id]
      );
      if (dup) continue;

      await db.query(
        `INSERT INTO reviews (store_id, customer_id, customer_name, rating, comment, images, createdAt)
         VALUES (?, ?, ?, ?, ?, NULL, ?)`,
        [store.id, cust.id, cust.name, r.rating, r.comment, createdAt]
      );
      inserted++;
    }
    console.log(`✅ เพิ่ม ${inserted} รีวิวจาก account 0881248456 (ทุกร้าน)`);

    // ── Seed reviews from other accounts with images ─────────────────────────
    let otherInserted = 0;
    for (let i = 0; i < otherReviews.length; i++) {
      const r = otherReviews[i];
      const store = restaurants[i % restaurants.length];
      const createdAt = new Date();
      createdAt.setDate(createdAt.getDate() - r.daysAgo);
      const imagesJson = JSON.stringify(r.images);

      const [[dup2]] = await db.query(
        'SELECT id FROM reviews WHERE store_id = ? AND customer_name = ? AND rating = ? AND comment = ?',
        [store.id, r.customer_name, r.rating, r.comment]
      );
      if (dup2) continue;

      await db.query(
        `INSERT INTO reviews (store_id, customer_id, customer_name, rating, comment, images, createdAt)
         VALUES (?, NULL, ?, ?, ?, ?, ?)`,
        [store.id, r.customer_name, r.rating, r.comment, imagesJson, createdAt]
      );
      otherInserted++;
    }
    console.log(`✅ เพิ่ม ${otherInserted} รีวิวจาก account อื่นๆ (พร้อมรูปภาพ)`);

    // ── Update ratings for all affected restaurants ───────────────────────────
    for (const store of restaurants) {
      await db.query(
        `UPDATE restaurant SET
           rating = COALESCE((SELECT AVG(rating) FROM reviews WHERE store_id = ?), 0)
         WHERE id = ?`,
        [store.id, store.id]
      ).catch(() => {});
    }
    console.log('✅ อัปเดต rating ร้านทั้งหมดแล้ว');

    console.log('\nเสร็จสิ้น!');
    process.exit(0);
  } catch (e) {
    console.error('เกิดข้อผิดพลาด:', e.message);
    process.exit(1);
  }
}

seed();
