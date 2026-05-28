const db = require('./db');
const crypto = require('crypto');

const reviews = [
  { customer_name: 'สมชาย ใจดี',     rating: 5, comment: 'ส่งเร็วมากเลยครับ อาหารยังร้อนอยู่เลย ขอบคุณมากนะ ประทับใจมาก', daysAgo: 0 },
  { customer_name: 'นภา สุขสันต์',    rating: 5, comment: 'น้องไรเดอร์สุภาพมากค่ะ แพ็คข้าวมาดี ไม่หกเลยสักหยด ดีมากๆ', daysAgo: 1 },
  { customer_name: 'วิชัย ทองดี',     rating: 4, comment: 'ส่งตรงเวลา แจ้งสถานะตลอด แค่ข้าวเริ่มเย็นนิดหน่อยแต่โอเคนะครับ', daysAgo: 2 },
  { customer_name: 'มาลี รักษ์ดี',    rating: 5, comment: 'น่ารักมากค่ะ ส่งถึงหน้าประตูห้องเลย ไม่ต้องลงไปรับเอง สะดวกมาก', daysAgo: 3 },
  { customer_name: 'อนุชา ประเสริฐ',  rating: 5, comment: 'แจ้งสถานะตลอดเส้นทางเลยครับ รู้ว่าของมาถึงไหนแล้ว ชอบมากๆ', daysAgo: 4 },
  { customer_name: 'พิมพ์ใจ สดใส',   rating: 4, comment: 'โดยรวมดีมากค่ะ ส่งไว ข้าวยังกินได้ พอใจมากเลย จะสั่งอีก', daysAgo: 5 },
  { customer_name: 'กิตติ มั่นคง',    rating: 5, comment: 'บริการดีเยี่ยมเลยครับ ยิ้มแย้มแจ่มใส ส่งระวังดี ข้าวไม่พลิกเลย', daysAgo: 6 },
  { customer_name: 'วรรณา ชื่นบาน',   rating: 3, comment: 'ส่งช้าหน่อยค่ะ แต่โทรมาแจ้งก่อนนะ อาหารยังกินได้ ครั้งหน้าจะสั่งอีก', daysAgo: 8 },
  { customer_name: 'ธนวัฒน์ สวัสดี',  rating: 5, comment: 'ขอบคุณมากนะครับ ระวังดีมาก ข้าวไม่หก น้ำไม่รั่ว เป็นไรเดอร์ที่ดีมากเลย', daysAgo: 10 },
  { customer_name: 'สุดา รุ่งเรือง',   rating: 4, comment: 'ส่งถูกที่ ไม่มีปัญหาอะไรเลยค่ะ ดีมาก จะแนะนำเพื่อนให้ใช้บริการ', daysAgo: 12 },
];

async function seed() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS rider_reviews (
        id VARCHAR(36) PRIMARY KEY,
        rider_id VARCHAR(36) NOT NULL,
        customer_id VARCHAR(36),
        customer_name VARCHAR(255),
        order_id VARCHAR(36),
        rating TINYINT NOT NULL,
        comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    const [riders] = await db.query('SELECT id, name FROM Rider');
    if (!riders.length) {
      console.log('ไม่พบ rider ในระบบ กรุณาสมัครไรเดอร์ก่อน');
      process.exit(0);
    }

    for (const rider of riders) {
      // ลบรีวิวเก่าของ rider นี้ออกก่อน (ถ้ามี) เพื่อไม่ให้ซ้ำ
      await db.query('DELETE FROM rider_reviews WHERE rider_id = ?', [rider.id]);

      for (const r of reviews) {
        const createdAt = new Date();
        createdAt.setDate(createdAt.getDate() - r.daysAgo);

        await db.query(
          `INSERT INTO rider_reviews (id, rider_id, customer_name, rating, comment, created_at)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [crypto.randomUUID(), rider.id, r.customer_name, r.rating, r.comment, createdAt]
        );
      }
      console.log(`✅ เพิ่ม ${reviews.length} รีวิวให้ไรเดอร์: ${rider.name} (${rider.id})`);
    }

    console.log('\nเสร็จสิ้น!');
    process.exit(0);
  } catch (e) {
    console.error('เกิดข้อผิดพลาด:', e.message);
    process.exit(1);
  }
}

seed();
