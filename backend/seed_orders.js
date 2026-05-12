const db = require('./db');
const crypto = require('crypto');

const menuItems = [
  { name: 'ข้าวผัดกุ้ง',      price: 89  },
  { name: 'ผัดกะเพราหมูสับ',   price: 69  },
  { name: 'ต้มยำกุ้ง',         price: 120 },
  { name: 'ส้มตำไทย',          price: 59  },
  { name: 'แกงเขียวหวานไก่',   price: 79  },
  { name: 'ข้าวมันไก่',        price: 65  },
  { name: 'หมูกระทะ',          price: 199 },
  { name: 'ชาไทย',            price: 35  },
  { name: 'น้ำมะนาว',          price: 25  },
  { name: 'ข้าวเหนียวมะม่วง', price: 79  },
];

// รายได้เป้าหมายต่อวัน 87 วัน (เก่า → ใหม่)
const dailyTargets = [
   800, 1200,  980, 1450, 2100, 1800,  890,
  1350, 1700, 2400, 1950, 2200, 1100,  750,
  1500, 1850, 2600, 2300, 2800, 1400,  900,
  1600, 2100, 2900, 2500, 3100, 1600, 1050,
  1750, 2200, 3200, 2700, 3300, 1800, 1100,
  1900, 2350, 3400, 2900, 3500, 2000, 1200,
  2000, 2500, 3600, 3100, 3700, 2100, 1300,
  2100, 2600, 3800, 3200, 3900, 2200, 1350,
  2200, 2700, 4000, 3400, 4100, 2300, 1400,
  2300, 2800, 4200, 3500, 4300, 2400, 1500,
  2400, 2900, 4400, 3700, 4500, 2500, 1550,
  2500, 3000, 4600, 3900, 4700, 2600, 1600,
  2700, 3200, 4800,
];

async function seedForStore(storeId, custId) {
  let inserted = 0;
  const total = dailyTargets.length;

  for (let dayIdx = 0; dayIdx < total; dayIdx++) {
    const daysAgo   = total - 1 - dayIdx;
    const target    = dailyTargets[dayIdx];
    const numOrders = Math.max(1, Math.round(target / 180));

    for (let o = 0; o < numOrders; o++) {
      const itemCount = Math.floor(Math.random() * 3) + 1;
      let foodTotal = 0;
      const chosen = [];
      for (let i = 0; i < itemCount; i++) {
        const item = menuItems[Math.floor(Math.random() * menuItems.length)];
        const qty  = Math.floor(Math.random() * 2) + 1;
        chosen.push({ name: item.name, price: item.price, quantity: qty });
        foodTotal += item.price * qty;
      }

      const deliveryFee = 30;
      const totalAmount = foodTotal + deliveryFee;
      const commission  = +(foodTotal * 0.15).toFixed(2);

      const hour = Math.floor(Math.random() * 11) + 10;
      const min  = Math.floor(Math.random() * 60);
      const d    = new Date();
      d.setDate(d.getDate() - daysAgo);
      d.setHours(hour, min, 0, 0);
      const createdAt = d.toISOString().slice(0, 19).replace('T', ' ');

      const orderId     = crypto.randomUUID();
      const orderNumber = `ORD${crypto.randomUUID().replace(/-/g,'').slice(0,12).toUpperCase()}`;

      await db.query(
        `INSERT INTO \`Order\`
           (id, orderNumber, restaurantId, customerId, totalAmount, serviceFee, commission, status, createdAt, updatedAt)
         VALUES (?, ?, ?, ?, ?, ?, ?, 'completed', ?, ?)`,
        [orderId, orderNumber, storeId, custId, totalAmount, deliveryFee, commission, createdAt, createdAt]
      );
      for (const item of chosen) {
        await db.query(
          'INSERT INTO order_items (order_id, name, price, quantity) VALUES (?, ?, ?, ?)',
          [orderId, item.name, item.price, item.quantity]
        );
      }
      inserted++;
    }
  }
  return inserted;
}

async function main() {
  const [[customer]] = await db.query('SELECT id FROM customer LIMIT 1');
  if (!customer) { console.log('No customer found'); process.exit(1); }
  const custId = customer.id;

  // seed ให้ทุก restaurant ยกเว้น id="1" ที่ seed ไปแล้ว
  const [restaurants] = await db.query("SELECT id, name FROM restaurant WHERE id != '1'");
  console.log(`Found ${restaurants.length} restaurants to seed\n`);

  for (const r of restaurants) {
    process.stdout.write(`Seeding "${r.name}"...`);
    const n = await seedForStore(r.id, custId);
    console.log(` ${n} orders done`);
  }

  console.log('\n✅ All done!');
  process.exit(0);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
