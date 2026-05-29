// seed_menus.js — Add 10 menu items per store for stores without menus
const db = require('../db');

const UNSPLASH = (id) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=400&q=80`;

const STORE_MENUS = {
  // ก๋วยเตี๋ยวเรือโบราณ
  '56271161-251d-4ca8-8bc5-b6b6f0632fab': {
    categories: ['ก๋วยเตี๋ยว', 'เครื่องเคียง', 'เครื่องดื่ม'],
    items: [
      { name: 'ก๋วยเตี๋ยวเรือหมู', desc: 'น้ำซุปเข้มข้น ต้มยาวนาน หมูนุ่ม', price: 60, cat: 0, img: UNSPLASH('photo-1569718212165-3a8278d5f624') },
      { name: 'ก๋วยเตี๋ยวเรือเนื้อ', desc: 'เนื้อสไลซ์บางนุ่ม น้ำซุปหอมกลมกล่อม', price: 70, cat: 0, img: UNSPLASH('photo-1547592180-85f173990554') },
      { name: 'ก๋วยเตี๋ยวต้มยำ', desc: 'น้ำซุปต้มยำรสจัด หอมมะนาว', price: 65, cat: 0, img: UNSPLASH('photo-1562565652-a0d8f0c59eb4') },
      { name: 'ก๋วยเตี๋ยวหมูแดง', desc: 'หมูแดงหวานนุ่ม ราดน้ำซุปใส', price: 60, cat: 0, img: UNSPLASH('photo-1512058564366-18510be2db19') },
      { name: 'ก๋วยเตี๋ยวเส้นหมี่', desc: 'เส้นหมี่บางเหนียวนุ่ม น้ำใสหอม', price: 55, cat: 0, img: UNSPLASH('photo-1569050467447-ce54b3bbc37d') },
      { name: 'ก๋วยเตี๋ยวผัดซีอิ๊ว', desc: 'เส้นใหญ่ผัดซีอิ๊วดำ หอมไหม้', price: 65, cat: 0, img: UNSPLASH('photo-1559314809-0d155014e29e') },
      { name: 'ลูกชิ้นทอด', desc: 'ลูกชิ้นหมูทอดกรอบ เสิร์ฟพร้อมน้ำจิ้ม', price: 40, cat: 1, img: UNSPLASH('photo-1534422298391-e4f8c172dddb') },
      { name: 'หมูกรอบ', desc: 'หมูสามชั้นทอดกรอบ น้ำจิ้มแจ่ว', price: 50, cat: 1, img: UNSPLASH('photo-1555939594-58d7cb561ad1') },
      { name: 'น้ำเปล่า', desc: 'น้ำดื่มบรรจุขวด', price: 15, cat: 2, img: UNSPLASH('photo-1548839140-29a749e1cf4d') },
      { name: 'ชาไทย', desc: 'ชาไทยหวานมัน ใส่นมข้นหวาน', price: 35, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
    ],
  },

  // ข้าวมันไก่ต้นตำรับ
  '5972e066-1e21-4b4c-b6cc-f6ea09f80222': {
    categories: ['ข้าวมันไก่', 'เครื่องเคียง', 'เครื่องดื่ม'],
    items: [
      { name: 'ข้าวมันไก่ต้ม', desc: 'ไก่ต้มนุ่ม ข้าวหอมมัน น้ำซุปร้อน', price: 55, cat: 0, img: UNSPLASH('photo-1604908176997-125f25cc6f3d') },
      { name: 'ข้าวมันไก่ทอด', desc: 'ไก่ทอดกรอบ ข้าวมันหอม', price: 65, cat: 0, img: UNSPLASH('photo-1562802378-063ec186a863') },
      { name: 'ข้าวมันไก่พิเศษ', desc: 'ไก่ต้ม+ทอด ข้าวมัน ซุปร้อน', price: 80, cat: 0, img: UNSPLASH('photo-1555939594-58d7cb561ad1') },
      { name: 'ข้าวมันไก่ตุ๋น', desc: 'ไก่ตุ๋นซีอิ๊ว เนื้อนุ่มหลุดกระดูก', price: 70, cat: 0, img: UNSPLASH('photo-1547592180-85f173990554') },
      { name: 'ข้าวมันไก่ไซส์เล็ก', desc: 'ข้าวมันไก่ไซส์เล็ก เหมาะสำหรับเด็ก', price: 45, cat: 0, img: UNSPLASH('photo-1512058564366-18510be2db19') },
      { name: 'ซุปไก่', desc: 'ซุปไก่ใสๆ หวานธรรมชาติ', price: 35, cat: 1, img: UNSPLASH('photo-1547592166-23ac45744acd') },
      { name: 'น้ำจิ้มไก่พิเศษ', desc: 'น้ำจิ้มสูตรต้นตำรับ รสเปรี้ยวหวานเผ็ด', price: 10, cat: 1, img: UNSPLASH('photo-1534422298391-e4f8c172dddb') },
      { name: 'ไข่ต้ม', desc: 'ไข่ไก่ต้มสุก เสิร์ฟคู่ข้าวมัน', price: 15, cat: 1, img: UNSPLASH('photo-1586816001966-79b736744398') },
      { name: 'น้ำเต้าหู้', desc: 'น้ำเต้าหู้อุ่นหวานมัน', price: 25, cat: 2, img: UNSPLASH('photo-1548839140-29a749e1cf4d') },
      { name: 'โอเลี้ยง', desc: 'กาแฟโบราณเย็นๆ', price: 30, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
    ],
  },

  // ซูชิฮานะ
  '24c28a8c-5648-45ac-b03c-b1c52edabdee': {
    categories: ['ซูชิ & มากิ', 'ราเมน & อุด้ง', 'เครื่องดื่ม'],
    items: [
      { name: 'ซัลมอนไนกิริ (2 ชิ้น)', desc: 'ข้าวปั้นหน้าแซลมอนสด เนื้อนุ่มมัน', price: 120, cat: 0, img: UNSPLASH('photo-1553621042-f6e147245754') },
      { name: 'ทูน่าไนกิริ (2 ชิ้น)', desc: 'ข้าวปั้นหน้าทูน่าสด รสชาติเข้มข้น', price: 110, cat: 0, img: UNSPLASH('photo-1579584425555-c3ce17fd4351') },
      { name: 'แคลิฟอร์เนียโรล (8 ชิ้น)', desc: 'มากิไส้ปูอัด แตงกวา อะโวคาโด', price: 150, cat: 0, img: UNSPLASH('photo-1553621042-f6e147245754') },
      { name: 'ซัลมอนโรล (8 ชิ้น)', desc: 'มากิไส้แซลมอน ครีมชีส แตงกวา', price: 180, cat: 0, img: UNSPLASH('photo-1563612116625-3012372fccce') },
      { name: 'เทมปุระโรล (8 ชิ้น)', desc: 'กุ้งเทมปุระม้วนสาหร่าย กรอบอร่อย', price: 160, cat: 0, img: UNSPLASH('photo-1579584425555-c3ce17fd4351') },
      { name: 'ราเมนซุปเข้มข้น', desc: 'ซุปหมูต้มนานหลายชั่วโมง เส้นเหนียวนุ่ม', price: 180, cat: 1, img: UNSPLASH('photo-1557872943-16a5ac26437e') },
      { name: 'อุด้งน้ำใส', desc: 'เส้นอุด้งใหญ่นุ่ม ซุปใสหอมดาชิ', price: 160, cat: 1, img: UNSPLASH('photo-1569050467447-ce54b3bbc37d') },
      { name: 'ราเมนต้มยำ', desc: 'ฟิวชั่นราเมนรสต้มยำ เผ็ดหอม', price: 190, cat: 1, img: UNSPLASH('photo-1547592180-85f173990554') },
      { name: 'ชาเขียวมัทฉะเย็น', desc: 'ชาเขียวญี่ปุ่นแท้ หวานน้อย', price: 65, cat: 2, img: UNSPLASH('photo-1556679343-c7306c1976bc') },
      { name: 'ยูซุเลมอน', desc: 'น้ำยูซุสด รสเปรี้ยวหอม', price: 70, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
    ],
  },

  // ต้มยำกุ้งริมน้ำ
  '8a2a8510-d680-425f-84a1-e93d99da8ae6': {
    categories: ['อาหารทะเล', 'ต้มยำ & แกง', 'เครื่องดื่ม'],
    items: [
      { name: 'ต้มยำกุ้งน้ำข้น', desc: 'กุ้งสดขนาดใหญ่ น้ำต้มยำข้นรสจัด', price: 220, cat: 0, img: UNSPLASH('photo-1562565652-a0d8f0c59eb4') },
      { name: 'ปลาหมึกผัดพริกเกลือ', desc: 'ปลาหมึกสดผัดกระเทียมพริก กรอบหอม', price: 180, cat: 0, img: UNSPLASH('photo-1559847844-5315695dadae') },
      { name: 'กุ้งแม่น้ำเผา', desc: 'กุ้งแม่น้ำสดเผา เสิร์ฟกับน้ำจิ้มซีฟู้ด', price: 350, cat: 0, img: UNSPLASH('photo-1565299507177-b0ac66763828') },
      { name: 'หอยแมลงภู่ผัดพริก', desc: 'หอยแมลงภู่สดผัดพริกขิง หอมเผ็ด', price: 160, cat: 0, img: UNSPLASH('photo-1555939594-58d7cb561ad1') },
      { name: 'ปลากะพงนึ่งมะนาว', desc: 'ปลากะพงขาวนึ่ง น้ำจิ้มมะนาวเผ็ด', price: 280, cat: 0, img: UNSPLASH('photo-1559742117-08b6967f3953') },
      { name: 'ต้มยำกุ้งน้ำใส', desc: 'น้ำซุปใสหอมตะไคร้ กุ้งสด', price: 200, cat: 1, img: UNSPLASH('photo-1562565652-a0d8f0c59eb4') },
      { name: 'แกงส้มกุ้ง', desc: 'แกงส้มรสเปรี้ยวหวาน ผักสด กุ้งสด', price: 180, cat: 1, img: UNSPLASH('photo-1455619452474-d2be8b1e70cd') },
      { name: 'ต้มข่าทะเล', desc: 'ต้มข่าครีมมี่ อาหารทะเลรวม', price: 190, cat: 1, img: UNSPLASH('photo-1547592166-23ac45744acd') },
      { name: 'น้ำมะพร้าว', desc: 'น้ำมะพร้าวสดเย็นชื่นใจ', price: 45, cat: 2, img: UNSPLASH('photo-1548839140-29a749e1cf4d') },
      { name: 'สิงห์โซดา', desc: 'โซดาน้ำแร่เย็น', price: 30, cat: 2, img: UNSPLASH('photo-1625772299848-391b6a87d7b3') },
    ],
  },

  // บ้านผัดไทย
  'd83e3c20-9fb5-4ea5-9ce4-902057c1ade4': {
    categories: ['ผัดไทย', 'เมนูผัด', 'เครื่องดื่ม'],
    items: [
      { name: 'ผัดไทยกุ้งสด', desc: 'ผัดไทยสูตรต้นตำรับ กุ้งสดตัวใหญ่', price: 120, cat: 0, img: UNSPLASH('photo-1559314809-0d155014e29e') },
      { name: 'ผัดไทยไก่', desc: 'ผัดไทยไก่สับ รสหวานเค็มพอดี', price: 90, cat: 0, img: UNSPLASH('photo-1548943487-a2e4e43b4853') },
      { name: 'ผัดไทยหมู', desc: 'ผัดไทยหมูสับ ใส่ไข่ ถั่วงอก', price: 85, cat: 0, img: UNSPLASH('photo-1559314809-0d155014e29e') },
      { name: 'ผัดไทยเจ', desc: 'ผัดไทยไม่ใส่เนื้อสัตว์ เต้าหู้ ถั่วงอก', price: 75, cat: 0, img: UNSPLASH('photo-1512058564366-18510be2db19') },
      { name: 'ผัดไทยห่อไข่', desc: 'ผัดไทยห่อในไข่เจียวบาง กรอบหอม', price: 130, cat: 0, img: UNSPLASH('photo-1586816001966-79b736744398') },
      { name: 'ผัดซีอิ๊วหมู', desc: 'เส้นใหญ่ผัดซีอิ๊ว หมูนุ่ม ไข่', price: 80, cat: 1, img: UNSPLASH('photo-1547592180-85f173990554') },
      { name: 'ข้าวผัดกุ้ง', desc: 'ข้าวผัดกุ้งสด ใส่ไข่ หอมต้น', price: 110, cat: 1, img: UNSPLASH('photo-1512058564366-18510be2db19') },
      { name: 'ผัดกะเพราไก่ไข่ดาว', desc: 'กะเพราไก่สับรสจัด ไข่ดาวกรอบ', price: 80, cat: 1, img: UNSPLASH('photo-1455619452474-d2be8b1e70cd') },
      { name: 'น้ำมะนาว', desc: 'น้ำมะนาวคั้นสด หวานเปรี้ยวสดชื่น', price: 30, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
      { name: 'ชาไทยเย็น', desc: 'ชาไทยสีส้มหวานมัน เติมนมข้น', price: 35, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
    ],
  },

  // พิซซ่า Roma
  'cd388b43-6108-406d-a9f6-3b1cde68923c': {
    categories: ['พิซซ่า', 'พาสต้า & จาน', 'เครื่องดื่ม'],
    items: [
      { name: 'มาร์เกอริต้า', desc: 'ซอสมะเขือเทศ มอสซาเรลล่า ใบโหระพา', price: 220, cat: 0, img: UNSPLASH('photo-1565299624946-b28f40a0ae38') },
      { name: 'เปปเปอโรนี', desc: 'เปปเปอโรนีเต็มถาด มอสซาเรลล่าอบละลาย', price: 260, cat: 0, img: UNSPLASH('photo-1513104890138-7c749659a591') },
      { name: 'ฟอร์แมกจิโอ (สี่ชีส)', desc: 'ริคอตต้า พาร์เมซาน มอสซาเรลล่า กอร์กอนโซล่า', price: 290, cat: 0, img: UNSPLASH('photo-1565299624946-b28f40a0ae38') },
      { name: 'BBQ ไก่', desc: 'ซอส BBQ ไก่ย่าง หัวหอม พริกหยวก', price: 270, cat: 0, img: UNSPLASH('photo-1565299624946-b28f40a0ae38') },
      { name: 'ซีฟู้ดสเปเชียล', desc: 'กุ้ง หอย ปลาหมึก บนซอสมะเขือเทศ', price: 320, cat: 0, img: UNSPLASH('photo-1565299624946-b28f40a0ae38') },
      { name: 'พาสต้าคาโบนาร่า', desc: 'ซอสครีมแบบ authentic ไม่ใส่ครีม ไข่แดงสด เบคอน', price: 210, cat: 1, img: UNSPLASH('photo-1555949258-eb67b1ef0ceb') },
      { name: 'พาสต้าโบโลเนส', desc: 'ซอสเนื้อบดสูตรอิตาลี ต้มนาน 3 ชม.', price: 200, cat: 1, img: UNSPLASH('photo-1621996346565-e3dbc646d9a9') },
      { name: 'พาสต้าอาราเบียต้า', desc: 'ซอสมะเขือเทศเผ็ดเล็กน้อย กระเทียม', price: 180, cat: 1, img: UNSPLASH('photo-1555949258-eb67b1ef0ceb') },
      { name: 'น้ำส้มคั้น', desc: 'น้ำส้มสดคั้น ไม่เติมน้ำตาล', price: 65, cat: 2, img: UNSPLASH('photo-1461023058943-07fcbe16d735') },
      { name: 'โค้กเย็น', desc: 'โค้กใส่น้ำแข็ง เสิร์ฟในแก้ว', price: 45, cat: 2, img: UNSPLASH('photo-1625772299848-391b6a87d7b3') },
    ],
  },

  // เบอร์เกอร์ Junction
  'debfabc2-c161-4486-a930-018967073a05': {
    categories: ['เบอร์เกอร์', 'ของทอด & เพิ่มเติม', 'เครื่องดื่ม'],
    items: [
      { name: 'คลาสสิกเบอร์เกอร์', desc: 'เนื้อวัว 180g ผักสด ซอสพิเศษ', price: 180, cat: 0, img: UNSPLASH('photo-1568901346375-23c9450c58cd') },
      { name: 'ดับเบิ้ลชีส', desc: 'เนื้อวัว 2 ชั้น ชีส 2 แผ่น ซอสพิเศษ', price: 240, cat: 0, img: UNSPLASH('photo-1550547660-d9450f859349') },
      { name: 'ไก่ทอดเบอร์เกอร์', desc: 'ไก่ชุบแป้งทอดกรอบ คอลสลอว์ ซอสพิเศษ', price: 160, cat: 0, img: UNSPLASH('photo-1562802378-063ec186a863') },
      { name: 'BBQ เบอร์เกอร์', desc: 'เนื้อย่าง ซอส BBQ สโมก เบคอน', price: 220, cat: 0, img: UNSPLASH('photo-1568901346375-23c9450c58cd') },
      { name: 'มัชรูมสวิส', desc: 'เนื้อวัว เห็ดผัด ชีสสวิส ออนิออน', price: 210, cat: 0, img: UNSPLASH('photo-1550547660-d9450f859349') },
      { name: 'เฟรนช์ฟราย', desc: 'มันฝรั่งทอดกรอบ ซอสมายองเนส', price: 70, cat: 1, img: UNSPLASH('photo-1541592106381-b31e9677c0e5') },
      { name: 'ออนิออนริง', desc: 'หัวหอมชุบแป้งทอดกรอบ', price: 80, cat: 1, img: UNSPLASH('photo-1626082927389-6cd097cee6a9') },
      { name: 'ชีสฟราย', desc: 'มันฝรั่งทอด ราดซอสชีส', price: 90, cat: 1, img: UNSPLASH('photo-1541592106381-b31e9677c0e5') },
      { name: 'โค้กเย็น', desc: 'โค้กใส่น้ำแข็ง ไซส์ L', price: 45, cat: 2, img: UNSPLASH('photo-1625772299848-391b6a87d7b3') },
      { name: 'มิลค์เชคช็อกโกแลต', desc: 'มิลค์เชคข้นเข้มข้น ช็อกโกแลตแท้', price: 95, cat: 2, img: UNSPLASH('photo-1572490122747-3968b75cc699') },
    ],
  },
};

async function seed() {
  let totalAdded = 0;

  for (const [storeId, data] of Object.entries(STORE_MENUS)) {
    const [[{ cnt }]] = await db.query(
      'SELECT COUNT(*) as cnt FROM menu_items WHERE store_id = ?', [storeId]
    );
    if (cnt > 0) {
      console.log(`Skipping store ${storeId} (already has ${cnt} items)`);
      continue;
    }

    const catIds = [];
    for (let i = 0; i < data.categories.length; i++) {
      const [result] = await db.query(
        'INSERT INTO menu_categories (store_id, name, sort_order) VALUES (?, ?, ?)',
        [storeId, data.categories[i], i + 1]
      );
      catIds.push(result.insertId);
    }

    for (let i = 0; i < data.items.length; i++) {
      const item = data.items[i];
      await db.query(
        'INSERT INTO menu_items (store_id, category_id, name, description, price, image_url, is_available, sort_order) VALUES (?,?,?,?,?,?,1,?)',
        [storeId, catIds[item.cat], item.name, item.desc, item.price, item.img, i + 1]
      );
    }

    console.log(`✓ Added ${data.items.length} items to store ${storeId}`);
    totalAdded += data.items.length;
  }

  console.log(`\nDone. Total items added: ${totalAdded}`);
  process.exit(0);
}

seed().catch(e => { console.error(e); process.exit(1); });
