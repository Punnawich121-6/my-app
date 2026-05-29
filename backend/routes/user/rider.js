const express = require('express');
const router = express.Router();
const db = require('../../db');
const crypto = require('crypto');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const _uploadDir = path.join(__dirname, '../../uploads/riders');
fs.mkdirSync(_uploadDir, { recursive: true });

const _photoUpload = multer({
  storage: multer.diskStorage({
    destination: _uploadDir,
    filename: (req, _file, cb) => cb(null, `rider_${req.params.riderId}_${Date.now()}.jpg`),
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => cb(null, file.mimetype.startsWith('image/')),
});

// ── Register rider ────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { phone, name } = req.body;
  if (!phone || !name) return res.status(400).json({ error: 'phone and name required' });

  try {
    const normalized = phone.startsWith('0') ? phone : '0' + phone;
    const email = `${normalized}@riderapp.local`;

    const [[existing]] = await db.query('SELECT id FROM Rider WHERE phone = ?', [normalized]);
    if (existing) {
      await db.query('UPDATE Rider SET name = ? WHERE id = ?', [name, existing.id]);
      return res.json({ success: true, user_id: existing.id });
    }

    const id = crypto.randomUUID();
    await db.query(
      `INSERT INTO Rider (id, name, email, phone, vehicle, vehicleType, status)
       VALUES (?, ?, ?, ?, 'motorcycle', 'MOTORCYCLE', 'OFFLINE')`,
      [id, name, email, normalized]
    );
    res.json({ success: true, user_id: id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Update rider GPS location ─────────────────────────────────────────────────
router.patch('/:riderId/location', async (req, res) => {
  const { latitude, longitude } = req.body;
  if (latitude == null || longitude == null) {
    return res.status(400).json({ error: 'latitude and longitude required' });
  }
  try {
    await db.query(
      'UPDATE Rider SET latitude = ?, longitude = ?, locationUpdatedAt = NOW() WHERE id = ?',
      [latitude, longitude, req.params.riderId],
    );
    req.app.get('io')?.to('admin').emit('rider_location_updated', {
      id: req.params.riderId,
      latitude,
      longitude,
      locationUpdatedAt: new Date().toISOString(),
    });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get all riders with last known location ───────────────────────────────────
router.get('/locations', async (req, res) => {
  try {
    const [riders] = await db.query(
      `SELECT id, name, status, vehicle, latitude, longitude, locationUpdatedAt
       FROM Rider
       WHERE latitude IS NOT NULL AND longitude IS NOT NULL
       ORDER BY locationUpdatedAt DESC`,
    );
    res.json(riders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get rider by phone ────────────────────────────────────────────────────────
router.get('/by-phone/:phone', async (req, res) => {
  try {
    const phone = req.params.phone;
    const normalized = phone.startsWith('0') ? phone : '0' + phone;
    const [[rider]] = await db.query(
      'SELECT id, name, phone, status, isVerified FROM Rider WHERE phone = ?',
      [normalized]
    );
    if (!rider) return res.status(404).json({ error: 'Not found' });
    res.json(rider);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get rider profile ─────────────────────────────────────────────────────────
router.get('/profile/:riderId', async (req, res) => {
  await db.query('ALTER TABLE Rider ADD COLUMN IF NOT EXISTS profile_photo VARCHAR(500) DEFAULT NULL').catch(() => {});
  try {
    const [[rider]] = await db.query(
      'SELECT id, name, phone, status, rating, runsCompleted, description, profile_photo FROM Rider WHERE id = ?',
      [req.params.riderId]
    );
    if (!rider) return res.status(404).json({ error: 'Rider not found' });
    res.json(rider);
  } catch (e) {
    try {
      const [[rider]] = await db.query(
        'SELECT id, name, phone, status, rating, runsCompleted FROM Rider WHERE id = ?',
        [req.params.riderId]
      );
      if (!rider) return res.status(404).json({ error: 'Rider not found' });
      res.json({ ...rider, description: null, profile_photo: null });
    } catch (e2) {
      res.status(500).json({ error: e2.message });
    }
  }
});

// ── Upload rider profile photo ────────────────────────────────────────────────
router.post('/:riderId/photo', _photoUpload.single('photo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No image uploaded' });
  const photoUrl = `/uploads/riders/${req.file.filename}`;
  try {
    await db.query('ALTER TABLE Rider ADD COLUMN IF NOT EXISTS profile_photo VARCHAR(500) DEFAULT NULL').catch(() => {});
    await db.query('UPDATE Rider SET profile_photo = ? WHERE id = ?', [photoUrl, req.params.riderId]);
    res.json({ success: true, photo_url: photoUrl });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Update rider profile ──────────────────────────────────────────────────────
router.patch('/:riderId/profile', async (req, res) => {
  const { name, description } = req.body;
  try {
    await db.query('ALTER TABLE Rider ADD COLUMN description VARCHAR(500) DEFAULT NULL').catch(() => {});
    if (name) await db.query('UPDATE Rider SET name = ? WHERE id = ?', [name, req.params.riderId]);
    if (description !== undefined) await db.query('UPDATE Rider SET description = ? WHERE id = ?', [description || null, req.params.riderId]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Rider analytics (prescriptive) ───────────────────────────────────────────
router.get('/analytics/:riderId', async (req, res) => {
  try {
    const [[today]] = await db.query(
      `SELECT COALESCE(SUM(serviceFee),0) AS amount, COUNT(*) AS count
       FROM \`Order\` WHERE riderId=? AND LOWER(status)='completed' AND DATE(createdAt)=CURDATE()`,
      [req.params.riderId]
    );
    const [[allTime]] = await db.query(
      `SELECT COALESCE(SUM(serviceFee),0) AS amount, COUNT(*) AS count
       FROM \`Order\` WHERE riderId=? AND LOWER(status)='completed'`,
      [req.params.riderId]
    );
    const [hourlyStats] = await db.query(
      `SELECT HOUR(createdAt) AS hour, COUNT(*) AS count
       FROM \`Order\`
       WHERE riderId=? AND LOWER(status)='completed' AND createdAt >= DATE_SUB(NOW(), INTERVAL 30 DAY)
       GROUP BY HOUR(createdAt) ORDER BY count DESC LIMIT 3`,
      [req.params.riderId]
    );
    const avgPerDelivery = parseInt(allTime.count) > 0
      ? Math.round(parseFloat(allTime.amount) / parseInt(allTime.count))
      : 40;
    res.json({ today, allTime, avgPerDelivery, peakHours: hourlyStats });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Available orders (status = ready, riderId IS NULL) ────────────────────────
router.get('/orders/available', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status,
              o.totalAmount AS total_amount,
              o.serviceFee  AS delivery_fee,
              o.notes,
              o.createdAt   AS created_at,
              o.deliveryLatitude  AS delivery_lat,
              o.deliveryLongitude AS delivery_lng,
              ANY_VALUE(r.name)    AS store_name,
              ANY_VALUE(r.address) AS store_address,
              ANY_VALUE(c.name)    AS customer_name,
              ANY_VALUE(c.phone)   AS customer_phone,
              CASE WHEN o.notes LIKE '% | %'
                   THEN TRIM(SUBSTRING_INDEX(o.notes, ' | ', 1))
                   ELSE TRIM(o.notes) END AS address,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary
       FROM \`Order\` o
       JOIN restaurant r ON o.restaurantId = r.id
       LEFT JOIN customer c ON o.customerId = c.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE LOWER(o.status) = 'ready' AND o.riderId IS NULL
       GROUP BY o.id
       ORDER BY o.createdAt ASC`,
    );
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Update delivery step (at_store / picking_up) ─────────────────────────────
router.patch('/orders/:orderId/step', async (req, res) => {
  const { orderId } = req.params;
  const { rider_id, step, latitude, longitude } = req.body;
  const allowed = ['at_store', 'picking_up'];
  if (!rider_id || !allowed.includes(step)) {
    return res.status(400).json({ error: 'rider_id and valid step required' });
  }
  try {
    await db.query(
      'UPDATE `Order` SET status = ? WHERE id = ? AND riderId = ?',
      [step, orderId, rider_id]
    );
    if (latitude != null && longitude != null) {
      await db.query(
        'UPDATE Rider SET latitude = ?, longitude = ?, locationUpdatedAt = NOW() WHERE id = ?',
        [latitude, longitude, rider_id]
      );
    }
    req.app.get('io')?.to(`order_${orderId}`).emit('order_updated', { order_id: orderId, status: step });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Accept order ──────────────────────────────────────────────────────────────
router.post('/orders/:orderId/accept', async (req, res) => {
  const { orderId } = req.params;
  const { rider_id } = req.body;
  if (!rider_id) return res.status(400).json({ error: 'rider_id required' });

  try {
    const [[order]] = await db.query(
      'SELECT id, status, riderId FROM `Order` WHERE id = ?',
      [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.status.toLowerCase() !== 'ready') return res.status(400).json({ error: 'Order not available' });
    if (order.riderId) return res.status(400).json({ error: 'Already taken by another rider' });

    const [result] = await db.query(
      'UPDATE `Order` SET riderId = ?, status = ? WHERE id = ? AND riderId IS NULL',
      [rider_id, 'delivering', orderId]
    );
    if (result.affectedRows === 0) return res.status(400).json({ error: 'Already taken by another rider' });

    await db.query('UPDATE Rider SET status = ? WHERE id = ?', ['ON_DELIVERY', rider_id]);
    req.app.get('io')?.to(`order_${orderId}`).emit('order_updated', { order_id: orderId, status: 'delivering' });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Complete delivery ─────────────────────────────────────────────────────────
router.post('/orders/:orderId/complete', async (req, res) => {
  const { orderId } = req.params;
  const { rider_id } = req.body;
  if (!rider_id) return res.status(400).json({ error: 'rider_id required' });

  try {
    const [[order]] = await db.query(
      'SELECT id, status, riderId, restaurantId, totalAmount, serviceFee, deliveryLatitude, deliveryLongitude FROM `Order` WHERE id = ?',
      [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.riderId !== rider_id) return res.status(403).json({ error: 'Not your order' });
    const activeStatuses = ['delivering', 'at_store', 'picking_up'];
    if (!activeStatuses.includes(order.status.toLowerCase())) {
      return res.status(400).json({ error: 'Order not in active delivery status' });
    }

    await db.query('UPDATE `Order` SET status = ? WHERE id = ?', ['completed', orderId]);
    req.app.get('io')?.to(`order_${orderId}`).emit('order_updated', { order_id: orderId, status: 'completed' });

    // Store net payout (total - delivery fee - 15% commission)
    const foodAmount = parseFloat(order.totalAmount) - parseFloat(order.serviceFee || 0);
    const storeNet = foodAmount * 0.85;
    const txId = crypto.randomUUID();
    await db.query(
      `INSERT INTO transaction (id, orderId, restaurantId, amount, netPayout, status)
       VALUES (?, ?, ?, ?, ?, 'completed')
       ON DUPLICATE KEY UPDATE status = 'completed'`,
      [txId, orderId, order.restaurantId, foodAmount.toFixed(2), storeNet.toFixed(2)]
    );

    // อัปเดต location ไรเดอร์ = จุดส่งอาหารล่าสุด
    if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
      await db.query(
        'UPDATE Rider SET latitude = ?, longitude = ?, locationUpdatedAt = NOW() WHERE id = ?',
        [order.deliveryLatitude, order.deliveryLongitude, rider_id]
      );
    }

    await db.query(
      'UPDATE Rider SET status = ?, runsCompleted = runsCompleted + 1 WHERE id = ?',
      ['ONLINE', rider_id]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Active delivery for rider ─────────────────────────────────────────────────
router.get('/orders/active/:riderId', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status,
              o.totalAmount AS total_amount,
              o.serviceFee  AS delivery_fee,
              o.notes,
              o.createdAt   AS created_at,
              o.deliveryLatitude  AS delivery_lat,
              o.deliveryLongitude AS delivery_lng,
              ANY_VALUE(r.name)    AS store_name,
              ANY_VALUE(r.address) AS store_address,
              ANY_VALUE(r.lat)     AS store_lat,
              ANY_VALUE(r.lng)     AS store_lng,
              ANY_VALUE(c.name)    AS customer_name,
              ANY_VALUE(c.phone)   AS customer_phone,
              CASE WHEN o.notes LIKE '% | %'
                   THEN TRIM(SUBSTRING_INDEX(o.notes, ' | ', 1))
                   ELSE TRIM(o.notes) END AS address,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary
       FROM \`Order\` o
       JOIN restaurant r ON o.restaurantId = r.id
       LEFT JOIN customer c ON o.customerId = c.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.riderId = ? AND LOWER(o.status) IN ('delivering','at_store','picking_up')
       GROUP BY o.id
       ORDER BY o.createdAt DESC
       LIMIT 1`,
      [req.params.riderId]
    );
    res.json(orders[0] || null);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Delivery history ──────────────────────────────────────────────────────────
router.get('/history/:riderId', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status,
              o.totalAmount AS total_amount,
              o.serviceFee  AS delivery_fee,
              o.createdAt   AS created_at,
              r.name        AS store_name,
              CASE WHEN o.notes LIKE '% | %'
                   THEN TRIM(SUBSTRING_INDEX(o.notes, ' | ', 1))
                   ELSE TRIM(o.notes) END AS address
       FROM \`Order\` o
       JOIN restaurant r ON o.restaurantId = r.id
       WHERE o.riderId = ? AND LOWER(o.status) IN ('completed','cancelled')
       ORDER BY o.createdAt DESC`,
      [req.params.riderId]
    );
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Rider earnings summary ────────────────────────────────────────────────────
router.get('/earnings/:riderId', async (req, res) => {
  try {
    const [[today]] = await db.query(
      `SELECT COALESCE(SUM(serviceFee), 0) AS amount, COUNT(*) AS count
       FROM \`Order\`
       WHERE riderId = ? AND LOWER(status) = 'completed'
         AND DATE(createdAt) = CURDATE()`,
      [req.params.riderId]
    );
    const [[week]] = await db.query(
      `SELECT COALESCE(SUM(serviceFee), 0) AS amount, COUNT(*) AS count
       FROM \`Order\`
       WHERE riderId = ? AND LOWER(status) = 'completed'
         AND createdAt >= DATE_SUB(NOW(), INTERVAL 7 DAY)`,
      [req.params.riderId]
    );
    const [[total]] = await db.query(
      `SELECT COALESCE(SUM(serviceFee), 0) AS amount, COUNT(*) AS count
       FROM \`Order\`
       WHERE riderId = ? AND LOWER(status) = 'completed'`,
      [req.params.riderId]
    );
    res.json({ today, week, total });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get rider reviews ─────────────────────────────────────────────────────────
router.get('/:riderId/reviews', async (req, res) => {
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
    `).catch(() => {});
    const [reviews] = await db.query(
      `SELECT id, rating, comment, customer_name, created_at
       FROM rider_reviews WHERE rider_id = ?
       ORDER BY created_at DESC LIMIT 50`,
      [req.params.riderId]
    );
    const [[agg]] = await db.query(
      `SELECT COUNT(*) AS total, COALESCE(AVG(rating), 0) AS average
       FROM rider_reviews WHERE rider_id = ?`,
      [req.params.riderId]
    );
    res.json({ reviews, total: agg.total, average: parseFloat(agg.average).toFixed(1) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── RIDER WALLET (PRE-PAID) ──────────────────────────────────────────────────

async function ensureRiderWalletTables() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rider_wallets (
      rider_id   VARCHAR(36) PRIMARY KEY,
      balance    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rider_wallet_transactions (
      id           VARCHAR(36) PRIMARY KEY,
      rider_id     VARCHAR(36) NOT NULL,
      type         ENUM('advance','topup','deduction') NOT NULL,
      amount       DECIMAL(10,2) NOT NULL,
      description  VARCHAR(255),
      reference_id VARCHAR(36),
      created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_rwt_rider (rider_id)
    )
  `);
}

// Summary: all riders who have a wallet record (for admin page)
router.get('/wallet/summary', async (req, res) => {
  try {
    await ensureRiderWalletTables();
    const [rows] = await db.query(`
      SELECT
        r.id,
        r.name,
        r.phone,
        COALESCE(w.balance, 0) AS balance,
        COALESCE(SUM(CASE WHEN t.type = 'advance' THEN t.amount ELSE 0 END), 0)  AS total_advanced,
        COALESCE(SUM(CASE WHEN t.type = 'topup'   THEN t.amount ELSE 0 END), 0)  AS total_topup,
        MAX(t.created_at) AS last_transaction_at
      FROM Rider r
      INNER JOIN rider_wallets w ON r.id = w.rider_id
      LEFT JOIN rider_wallet_transactions t ON r.id = t.rider_id
      GROUP BY r.id, r.name, r.phone, w.balance
      ORDER BY w.balance ASC
    `);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Balance for one rider
router.get('/wallet/:riderId', async (req, res) => {
  try {
    await ensureRiderWalletTables();
    const [[wallet]] = await db.query(
      'SELECT balance FROM rider_wallets WHERE rider_id = ?',
      [req.params.riderId]
    );
    res.json({ balance: wallet ? parseFloat(wallet.balance) : 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Transaction history for one rider
router.get('/wallet/:riderId/transactions', async (req, res) => {
  try {
    await ensureRiderWalletTables();
    const [rows] = await db.query(
      `SELECT id, type, amount, description, reference_id, created_at
       FROM rider_wallet_transactions
       WHERE rider_id = ?
       ORDER BY created_at DESC
       LIMIT 100`,
      [req.params.riderId]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Admin advance: company pays for rider → balance decreases (can go negative)
router.post('/wallet/advance', async (req, res) => {
  const { rider_id, amount, description, reference_id } = req.body;
  if (!rider_id || !amount || Number(amount) <= 0) {
    return res.status(400).json({ error: 'rider_id and amount required' });
  }
  try {
    await ensureRiderWalletTables();
    const txId = crypto.randomUUID();
    const amt = Number(amount);
    await db.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [rider_id, -amt]
    );
    await db.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description, reference_id)
       VALUES (?, ?, 'advance', ?, ?, ?)`,
      [txId, rider_id, amt, description || `บริษัทออกเงินล่วงหน้า ฿${amt}`, reference_id || null]
    );
    const [[w]] = await db.query('SELECT balance FROM rider_wallets WHERE rider_id = ?', [rider_id]);
    res.json({ success: true, balance: parseFloat(w.balance) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Topup: rider adds money → balance increases (pays off debt)
router.post('/wallet/topup', async (req, res) => {
  const { rider_id, amount, description } = req.body;
  if (!rider_id || !amount || Number(amount) <= 0) {
    return res.status(400).json({ error: 'rider_id and amount required' });
  }
  try {
    await ensureRiderWalletTables();
    const txId = crypto.randomUUID();
    const amt = Number(amount);
    await db.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [rider_id, amt]
    );
    await db.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description)
       VALUES (?, ?, 'topup', ?, ?)`,
      [txId, rider_id, amt, description || `ไรเดอร์เติมเงิน ฿${amt}`]
    );
    const [[w]] = await db.query('SELECT balance FROM rider_wallets WHERE rider_id = ?', [rider_id]);
    res.json({ success: true, balance: parseFloat(w.balance) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── RIDER LOAN REQUESTS ──────────────────────────────────────────────────────

async function ensureLoanTable() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rider_loan_requests (
      id          VARCHAR(36) PRIMARY KEY,
      rider_id    VARCHAR(36) NOT NULL,
      amount      DECIMAL(10,2) NOT NULL,
      reason      VARCHAR(500),
      status      ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
      admin_note  VARCHAR(255),
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_loan_rider (rider_id),
      INDEX idx_loan_status (status)
    )
  `);
}

// Rider submits loan request
router.post('/loan/request', async (req, res) => {
  const { rider_id, amount, reason } = req.body;
  if (!rider_id || !amount || amount <= 0) return res.status(400).json({ error: 'rider_id and amount required' });
  try {
    await ensureLoanTable();
    const id = require('crypto').randomUUID();
    await db.query(
      `INSERT INTO rider_loan_requests (id, rider_id, amount, reason) VALUES (?, ?, ?, ?)`,
      [id, rider_id, amount, reason || null]
    );
    res.json({ success: true, id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Rider gets their own loan history
router.get('/loan/:riderId', async (req, res) => {
  try {
    await ensureLoanTable();
    const [rows] = await db.query(
      `SELECT * FROM rider_loan_requests WHERE rider_id = ? ORDER BY created_at DESC LIMIT 20`,
      [req.params.riderId]
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: get all pending loan requests
router.get('/loan/pending/all', async (req, res) => {
  try {
    await ensureLoanTable();
    const [rows] = await db.query(`
      SELECT l.*, r.name AS rider_name, r.phone AS rider_phone,
             COALESCE(w.balance, 0) AS current_balance
      FROM rider_loan_requests l
      JOIN Rider r ON r.id = l.rider_id
      LEFT JOIN rider_wallets w ON w.rider_id = l.rider_id
      WHERE l.status = 'pending'
      ORDER BY l.created_at ASC
    `);
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: approve → advance wallet
router.put('/loan/:id/approve', async (req, res) => {
  const { admin_note } = req.body;
  try {
    await ensureLoanTable();
    await ensureRiderWalletTables();
    const [[loan]] = await db.query(`SELECT * FROM rider_loan_requests WHERE id = ? AND status = 'pending'`, [req.params.id]);
    if (!loan) return res.status(404).json({ error: 'Not found or already processed' });

    await db.query(`UPDATE rider_loan_requests SET status = 'approved', admin_note = ? WHERE id = ?`, [admin_note || null, req.params.id]);

    const amt = parseFloat(loan.amount);
    await db.query(
      `INSERT INTO rider_wallets (rider_id, balance) VALUES (?, ?) ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)`,
      [loan.rider_id, -amt]
    );
    const txId = require('crypto').randomUUID();
    await db.query(
      `INSERT INTO rider_wallet_transactions (id, rider_id, type, amount, description, reference_id) VALUES (?, ?, 'advance', ?, ?, ?)`,
      [txId, loan.rider_id, amt, `ยืมเงินจากบริษัท${admin_note ? ' — ' + admin_note : ''}`, req.params.id]
    );
    const [[w]] = await db.query('SELECT balance FROM rider_wallets WHERE rider_id = ?', [loan.rider_id]);
    res.json({ success: true, balance: parseFloat(w.balance) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: reject
router.put('/loan/:id/reject', async (req, res) => {
  const { admin_note } = req.body;
  try {
    await ensureLoanTable();
    const [[loan]] = await db.query(`SELECT id FROM rider_loan_requests WHERE id = ? AND status = 'pending'`, [req.params.id]);
    if (!loan) return res.status(404).json({ error: 'Not found or already processed' });
    await db.query(`UPDATE rider_loan_requests SET status = 'rejected', admin_note = ? WHERE id = ?`, [admin_note || null, req.params.id]);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
