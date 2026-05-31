const express = require('express');
const router = express.Router();
const db = require('../../db');
const crypto = require('crypto');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ─── Review image upload setup ────────────────────────────────────────────────
const reviewUploadDir = path.join(__dirname, '..', '..', 'uploads', 'reviews');
if (!fs.existsSync(reviewUploadDir)) fs.mkdirSync(reviewUploadDir, { recursive: true });

const reviewStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, reviewUploadDir),
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${crypto.randomBytes(4).toString('hex')}${path.extname(file.originalname)}`);
  },
});
const reviewUpload = multer({
  storage: reviewStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only images allowed'));
  },
});

// Ensure columns exist on startup
db.query(`ALTER TABLE customer ADD COLUMN IF NOT EXISTS profile_image LONGTEXT`).catch(() => {});
db.query(`ALTER TABLE reviews ADD COLUMN IF NOT EXISTS images TEXT DEFAULT NULL`).catch(() => {});
db.query(`ALTER TABLE reviews ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255) DEFAULT 'Customer'`).catch(() => {});
db.query(`ALTER TABLE reviews ADD COLUMN IF NOT EXISTS order_id VARCHAR(36) DEFAULT NULL`).catch(() => {});
db.query(`ALTER TABLE reviews ADD COLUMN IF NOT EXISTS reply TEXT DEFAULT NULL`).catch(() => {});

// ─── GET stores (restaurant table) ───────────────────────────────────────────
router.get('/stores', async (req, res) => {
  try {
    const [stores] = await db.query(
      `SELECT id, name, category AS type, address,
              CASE WHEN status = 'active' THEN 1 ELSE 0 END AS is_open,
              imageUrl AS image_url, COALESCE(rating, 0) AS rating,
              0 AS review_count
       FROM restaurant
       ORDER BY is_open DESC, rating DESC`
    );
    res.json(stores);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET active smart promos for a store (customer-facing) ───────────────────
router.get('/stores/:storeId/active-promos', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, title, description, discount_type, discount_value, ends_at
       FROM smart_promotions
       WHERE store_id = ? AND status = 'active' AND ends_at > NOW()
       ORDER BY starts_at DESC`,
      [req.params.storeId]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET store reviews (public) ───────────────────────────────────────────────
router.get('/stores/:storeId/reviews', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, customer_name, rating, comment, images, createdAt AS created_at
       FROM reviews
       WHERE store_id = ?
       ORDER BY createdAt DESC
       LIMIT 100`,
      [req.params.storeId]
    );
    const baseUrl = `http://${req.get('host')}`;
    const fixed = rows.map(r => {
      if (!r.images) return r;
      try {
        const imgs = JSON.parse(r.images);
        return { ...r, images: JSON.stringify(imgs.map(u => u.replace(/^http:\/\/[^/]+/, baseUrl))) };
      } catch (_) { return r; }
    });
    res.json(fixed);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET customer by phone ────────────────────────────────────────────────────
router.get('/by-phone/:phone', async (req, res) => {
  try {
    const [[user]] = await db.query(
      'SELECT id, name, phone, address, profile_image FROM customer WHERE phone = ?',
      [req.params.phone]
    );
    res.json(user || null);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── POST register ────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { phone, name } = req.body;
  try {
    const [[existing]] = await db.query(
      'SELECT id FROM customer WHERE phone = ?', [phone]
    );
    if (existing) return res.json({ user_id: existing.id });

    const id = crypto.randomUUID();
    const email = `${phone}@customerapp.local`;
    await db.query(
      'INSERT INTO customer (id, name, email, phone) VALUES (?, ?, ?, ?)',
      [id, name, email, phone]
    );
    res.json({ user_id: id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── POST place order ─────────────────────────────────────────────────────────
router.post('/orders', async (req, res) => {
  const { customer_id, customer_name, customer_phone, store_id, items, address, latitude, longitude, note, promo_id } = req.body;
  const subtotal = items.reduce((s, i) => s + i.price * i.quantity, 0);
  let deliveryFee = 30;
  let discountAmount = 0;

  if (promo_id) {
    try {
      const [[promo]] = await db.query(
        "SELECT discount_type, discount_value FROM smart_promotions WHERE id = ? AND store_id = ? AND status = 'active' AND ends_at > NOW() LIMIT 1",
        [promo_id, store_id]
      );
      if (promo) {
        const val = parseFloat(promo.discount_value) || 0;
        if (promo.discount_type === 'percentage') discountAmount = subtotal * val / 100;
        else if (promo.discount_type === 'fixed') discountAmount = Math.min(val, subtotal);
        else if (promo.discount_type === 'free_delivery') deliveryFee = 0;
      }
    } catch (_) {}
  }

  const total = Math.max(0, subtotal - discountAmount + deliveryFee);
  const orderNumber = `ORD-${Date.now()}`;
  const notesField = [address, note].filter(Boolean).join(' | ');

  try {
    const orderId = crypto.randomUUID();
    await db.query(
      `INSERT INTO \`order\` (id, orderNumber, restaurantId, customerId, status, totalAmount, serviceFee, notes, deliveryLatitude, deliveryLongitude)
       VALUES (?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?)`,
      [orderId, orderNumber, store_id, customer_id || null, total.toFixed(2), deliveryFee.toFixed(2), notesField, latitude ?? null, longitude ?? null]
    );
    for (const item of items) {
      await db.query(
        'INSERT INTO order_items (order_id, menu_item_id, name, price, quantity) VALUES (?,?,?,?,?)',
        [orderId, item.menu_item_id, item.name, item.price, item.quantity]
      );
    }
    req.app.get('io')?.to('admin').emit('new_order', {
      order_id: orderId,
      orderNumber,
      store_id,
      customer_name: customer_name || 'Customer',
      total: total.toFixed(2),
    });
    res.json({ success: true, order_id: orderId });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET order detail ─────────────────────────────────────────────────────────
router.get('/orders/detail/:orderId', async (req, res) => {
  try {
    const [[order]] = await db.query(
      `SELECT o.id, o.orderNumber, o.status, o.totalAmount AS total_amount,
              o.notes, o.createdAt AS created_at,
              o.deliveryLatitude AS delivery_lat, o.deliveryLongitude AS delivery_lng,
              r.name AS store_name, r.address AS store_address
       FROM \`order\` o
       LEFT JOIN restaurant r ON o.restaurantId = r.id
       WHERE o.id = ?`,
      [req.params.orderId]
    );
    if (!order) return res.status(404).json({ error: 'Not found' });
    const [items] = await db.query(
      'SELECT * FROM order_items WHERE order_id = ?',
      [req.params.orderId]
    );
    const [address, note] = (order.notes || '').split(' | ');
    res.json({ ...order, address: address || '', note: note || '', delivery_fee: 30, items });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── DEBUG: order status summary ─────────────────────────────────────────────
router.get('/debug/orders/:customerId', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, orderNumber, status, totalAmount, createdAt FROM \`order\` WHERE customerId = ? ORDER BY createdAt DESC LIMIT 50`,
      [req.params.customerId]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET orders by customer ───────────────────────────────────────────────────
router.get('/orders/:customerId', async (req, res) => {
  try {
    await db.query('SET SESSION group_concat_max_len = 4096');
    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status,
              o.totalAmount AS total_amount,
              o.createdAt AS created_at,
              o.restaurantId AS store_id,
              o.riderId AS rider_id,
              r.name AS store_name,
              r.imageUrl AS store_image,
              GROUP_CONCAT(DISTINCT CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary,
              EXISTS(SELECT 1 FROM reviews WHERE order_id = o.id) AS is_reviewed
       FROM \`order\` o
       LEFT JOIN restaurant r ON o.restaurantId = r.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.customerId = ?
       GROUP BY o.id, o.orderNumber, o.status, o.totalAmount, o.createdAt,
                o.restaurantId, o.riderId, r.name, r.imageUrl
       ORDER BY o.createdAt DESC
       LIMIT 200`,
      [req.params.customerId]
    );
    console.log(`[customer orders] customerId=${req.params.customerId} → ${orders.length} orders`);
    res.json(orders);
  } catch (e) {
    console.error('[customer orders] error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// ─── PUT update profile ───────────────────────────────────────────────────────
router.put('/profile/:id', async (req, res) => {
  const { name, profileImage } = req.body;
  try {
    // ensure column exists
    await db.query(`ALTER TABLE customer ADD COLUMN IF NOT EXISTS profile_image LONGTEXT`).catch(() => {});
    if (profileImage !== undefined) {
      await db.query('UPDATE customer SET name = ?, profile_image = ? WHERE id = ?', [name, profileImage, req.params.id]);
    } else {
      await db.query('UPDATE customer SET name = ? WHERE id = ?', [name, req.params.id]);
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET reviews submitted by a customer ─────────────────────────────────────
router.get('/reviews/:customerId', async (req, res) => {
  try {
    const [storeReviews] = await db.query(
      `SELECT r.id, 'store' AS type, rv.name AS target_name, rv.imageUrl AS target_image,
              r.rating, r.comment, r.createdAt AS created_at
       FROM reviews r
       LEFT JOIN restaurant rv ON r.store_id = rv.id
       WHERE r.customer_id = ?
       ORDER BY r.createdAt DESC
       LIMIT 100`,
      [req.params.customerId]
    );
    const [riderReviews] = await db.query(
      `SELECT rr.id, 'rider' AS type, COALESCE(rd.name, 'Rider') AS target_name,
              NULL AS target_image,
              rr.rating, rr.comment, rr.created_at
       FROM rider_reviews rr
       LEFT JOIN Rider rd ON rr.rider_id = rd.id
       WHERE rr.customer_id = ?
       ORDER BY rr.created_at DESC
       LIMIT 100`,
      [req.params.customerId]
    ).catch(() => [[]]);
    const all = [...storeReviews, ...riderReviews]
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    res.json(all);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── POST store review (supports multipart with up to 5 images) ───────────────
router.post('/review/store', reviewUpload.array('images', 5), async (req, res) => {
  const { order_id, customer_id, customer_name, store_id, rating, comment } = req.body;
  if (!store_id || !rating) return res.status(400).json({ error: 'store_id and rating required' });
  try {
    let existing;
    if (order_id) {
      [[existing]] = await db.query(
        'SELECT id FROM reviews WHERE order_id = ? AND store_id = ?',
        [order_id, store_id]
      );
    } else if (customer_id) {
      [[existing]] = await db.query(
        'SELECT id FROM reviews WHERE customer_id = ? AND store_id = ? AND order_id IS NULL',
        [customer_id, store_id]
      );
    }
    if (existing) return res.json({ success: true, alreadyReviewed: true });

    const proto = req.get('x-forwarded-proto') || req.protocol;
    const baseUrl = `${proto}://${req.get('host')}`;
    const imageUrls = (req.files || []).map(f => `${baseUrl}/uploads/reviews/${f.filename}`);
    const imagesJson = imageUrls.length ? JSON.stringify(imageUrls) : null;

    await db.query(
      `INSERT INTO reviews (store_id, customer_id, customer_name, order_id, rating, comment, images)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [store_id, customer_id || null, customer_name || 'Customer', order_id || null, rating, comment || null, imagesJson]
    );
    await db.query(
      `UPDATE restaurant SET rating = COALESCE((SELECT AVG(rating) FROM reviews WHERE store_id = ?), 0) WHERE id = ?`,
      [store_id, store_id]
    ).catch(() => {});
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── POST rider review ────────────────────────────────────────────────────────
router.post('/review/rider', async (req, res) => {
  const { order_id, customer_id, customer_name, rider_id, rating, comment } = req.body;
  if (!rider_id || !rating) return res.status(400).json({ error: 'rider_id and rating required' });
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
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_order_rider (order_id, rider_id)
      )
    `).catch(() => {});

    const id = crypto.randomUUID();
    const [result] = await db.query(
      `INSERT IGNORE INTO rider_reviews (id, rider_id, customer_id, customer_name, order_id, rating, comment)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, rider_id, customer_id || null, customer_name || 'Customer', order_id || null, rating, comment || null]
    );
    if (result.affectedRows > 0) {
      await db.query(
        `UPDATE Rider SET rating = (SELECT AVG(rating) FROM rider_reviews WHERE rider_id = ?) WHERE id = ?`,
        [rider_id, rider_id]
      );
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── WALLET ───────────────────────────────────────────────────────────────────

async function ensureWalletTables(db) {
  await db.query(`
    CREATE TABLE IF NOT EXISTS wallets (
      customer_id VARCHAR(36) PRIMARY KEY,
      balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);
  await db.query(`
    CREATE TABLE IF NOT EXISTS wallet_transactions (
      id VARCHAR(36) PRIMARY KEY,
      customer_id VARCHAR(36) NOT NULL,
      type ENUM('topup','payment','refund') NOT NULL,
      amount DECIMAL(10,2) NOT NULL,
      description VARCHAR(255),
      reference_id VARCHAR(36),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_wallet_customer (customer_id)
    )
  `);
}

router.get('/wallet/:customerId', async (req, res) => {
  try {
    await ensureWalletTables(db);
    const [[wallet]] = await db.query(
      'SELECT balance FROM wallets WHERE customer_id = ?',
      [req.params.customerId]
    );
    res.json({ balance: wallet ? parseFloat(wallet.balance) : 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/wallet/:customerId/transactions', async (req, res) => {
  try {
    await ensureWalletTables(db);
    const [rows] = await db.query(
      `SELECT id, type, amount, description, reference_id, created_at
       FROM wallet_transactions
       WHERE customer_id = ?
       ORDER BY created_at DESC
       LIMIT 100`,
      [req.params.customerId]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/wallet/topup', async (req, res) => {
  const { customer_id, amount } = req.body;
  if (!customer_id || !amount || amount <= 0) {
    return res.status(400).json({ error: 'customer_id and amount required' });
  }
  try {
    await ensureWalletTables(db);
    const txId = crypto.randomUUID();
    await db.query(
      `INSERT INTO wallets (customer_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [customer_id, amount]
    );
    await db.query(
      `INSERT INTO wallet_transactions (id, customer_id, type, amount, description)
       VALUES (?, ?, 'topup', ?, ?)`,
      [txId, customer_id, amount, `เติมเงิน ฿${amount}`]
    );
    const [[wallet]] = await db.query(
      'SELECT balance FROM wallets WHERE customer_id = ?',
      [customer_id]
    );
    res.json({ success: true, balance: parseFloat(wallet.balance) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/wallet/pay', async (req, res) => {
  const { customer_id, amount, order_id, description } = req.body;
  if (!customer_id || !amount || amount <= 0) {
    return res.status(400).json({ error: 'customer_id and amount required' });
  }
  try {
    await ensureWalletTables(db);
    const [[wallet]] = await db.query(
      'SELECT balance FROM wallets WHERE customer_id = ?',
      [customer_id]
    );
    const balance = wallet ? parseFloat(wallet.balance) : 0;
    if (balance < amount) {
      return res.status(400).json({ error: 'insufficient_balance', balance });
    }
    await db.query(
      'UPDATE wallets SET balance = balance - ? WHERE customer_id = ?',
      [amount, customer_id]
    );
    const txId = crypto.randomUUID();
    await db.query(
      `INSERT INTO wallet_transactions (id, customer_id, type, amount, description, reference_id)
       VALUES (?, ?, 'payment', ?, ?, ?)`,
      [txId, customer_id, amount, description || `ชำระค่าอาหาร ฿${amount}`, order_id || null]
    );
    const [[updated]] = await db.query(
      'SELECT balance FROM wallets WHERE customer_id = ?',
      [customer_id]
    );
    res.json({ success: true, balance: parseFloat(updated.balance) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
