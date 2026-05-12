// seed_menus.js — add 4 categories + 10 menu items to every restaurant
const db = require('./db');

const CATEGORIES = [
  'อาหารจานหลัก',
  'เครื่องดื่ม',
  'อาหารเรียกน้ำย่อย',
  'ของหวาน',
];

// 10 items: 6 main, 2 drink, 1 appetizer, 1 dessert
const MENU_ITEMS = [
  { name: 'ผัดกะเพราหมูสับ',    cat: 'อาหารจานหลัก',     price: 79,  desc: 'ผัดกะเพราหมูสับไข่ดาว หอมกลิ่นพริก กะเพรา เสิร์ฟพร้อมข้าวสวย',       img: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800&h=600&fit=crop' },
  { name: 'ต้มยำกุ้ง',          cat: 'อาหารจานหลัก',     price: 129, desc: 'ต้มยำกุ้งน้ำข้น รสเด็ด ใส่เห็ดหอม ตะไคร้ ใบมะกรูด',                    img: 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800&h=600&fit=crop' },
  { name: 'ส้มตำไทย',           cat: 'อาหารจานหลัก',     price: 69,  desc: 'ส้มตำไทยรสจัด ใส่ถั่วฝักยาว มะเขือเทศ กุ้งแห้ง ถั่วลิสง',              img: 'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=800&h=600&fit=crop' },
  { name: 'ข้าวมันไก่',         cat: 'อาหารจานหลัก',     price: 59,  desc: 'ข้าวมันไก่ต้ม เนื้อนุ่ม ข้าวหุงด้วยน้ำซุปไก่ เสิร์ฟพร้อมน้ำจิ้ม',      img: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800&h=600&fit=crop' },
  { name: 'ผัดไทยกุ้งสด',       cat: 'อาหารจานหลัก',     price: 99,  desc: 'ผัดไทยเส้นจันท์ กุ้งสด ไข่ ถั่วงอก ต้นหอม เสิร์ฟพร้อมมะนาว',         img: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=800&h=600&fit=crop' },
  { name: 'แกงเขียวหวานไก่',     cat: 'อาหารจานหลัก',     price: 89,  desc: 'แกงเขียวหวานไก่ หอมกลิ่นกะทิ ใบมะกรูด พริกเขียว มะเขือ',              img: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800&h=600&fit=crop' },
  { name: 'ชาไทยเย็น',          cat: 'เครื่องดื่ม',       price: 35,  desc: 'ชาไทยใบเฉพาะ หวานมัน นมข้นหวาน ใส่น้ำแข็ง',                           img: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800&h=600&fit=crop' },
  { name: 'น้ำมะพร้าว',         cat: 'เครื่องดื่ม',       price: 45,  desc: 'น้ำมะพร้าวสดจากลูก หวานธรรมชาติ เย็นชื่นใจ',                           img: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=800&h=600&fit=crop' },
  { name: 'ทอดมันปลากราย',       cat: 'อาหารเรียกน้ำย่อย', price: 65,  desc: 'ทอดมันปลากรายแท้ ผสมใบมะกรูด พริกแกง ทอดกรอบ เสิร์ฟน้ำจิ้มอาจาด',   img: 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=800&h=600&fit=crop' },
  { name: 'ข้าวเหนียวมะม่วง',    cat: 'ของหวาน',           price: 79,  desc: 'ข้าวเหนียวมูนกะทิหอม เสิร์ฟคู่มะม่วงน้ำดอกไม้สุก',                   img: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&h=600&fit=crop' },
];

async function run() {
  const [stores] = await db.query('SELECT id, name FROM restaurant');
  console.log(`Found ${stores.length} restaurants`);

  for (const store of stores) {
    console.log(`\n── ${store.name} (${store.id})`);

    // ── 1. ensure categories exist ────────────────────────────────────────────
    const [existingCats] = await db.query(
      'SELECT name FROM menu_categories WHERE store_id = ?', [store.id]
    );
    const existingCatNames = new Set(existingCats.map(c => c.name));

    const catIdMap = {};
    // load existing ones first
    const [allCats] = await db.query(
      'SELECT id, name FROM menu_categories WHERE store_id = ?', [store.id]
    );
    for (const c of allCats) catIdMap[c.name] = c.id;

    for (let i = 0; i < CATEGORIES.length; i++) {
      const catName = CATEGORIES[i];
      if (!existingCatNames.has(catName)) {
        const [result] = await db.query(
          'INSERT INTO menu_categories (store_id, name, sort_order) VALUES (?, ?, ?)',
          [store.id, catName, i + 1]
        );
        catIdMap[catName] = result.insertId;
        console.log(`  + category: ${catName}`);
      } else {
        console.log(`  ✓ category exists: ${catName}`);
      }
    }

    // ── 2. ensure menu items exist ────────────────────────────────────────────
    const [existingItems] = await db.query(
      'SELECT name FROM menu_items WHERE store_id = ?', [store.id]
    );
    const existingItemNames = new Set(existingItems.map(i => i.name));

    for (const item of MENU_ITEMS) {
      if (existingItemNames.has(item.name)) {
        console.log(`  ✓ item exists: ${item.name}`);
        continue;
      }
      const catId = catIdMap[item.cat];
      await db.query(
        'INSERT INTO menu_items (store_id, category_id, name, description, price, image_url, is_available) VALUES (?,?,?,?,?,?,1)',
        [store.id, catId || null, item.name, item.desc, item.price, item.img]
      );
      console.log(`  + item: ${item.name} (฿${item.price})`);
    }
  }

  console.log('\nDone!');
  process.exit(0);
}

run().catch(e => { console.error(e); process.exit(1); });
