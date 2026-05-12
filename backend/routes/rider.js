const express = require('express');
const router = express.Router();
const db = require('../db');
const crypto = require('crypto');

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
  try {
    const [[rider]] = await db.query(
      'SELECT id, name, phone, status, rating, runsCompleted FROM Rider WHERE id = ?',
      [req.params.riderId]
    );
    if (!rider) return res.status(404).json({ error: 'Rider not found' });
    res.json(rider);
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
              r.name        AS store_name,
              r.address     AS store_address,
              c.name        AS customer_name,
              c.phone       AS customer_phone,
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
      'SELECT id, status, riderId, restaurantId, totalAmount, serviceFee FROM `Order` WHERE id = ?',
      [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.riderId !== rider_id) return res.status(403).json({ error: 'Not your order' });
    const activeStatuses = ['delivering', 'at_store', 'picking_up'];
    if (!activeStatuses.includes(order.status.toLowerCase())) {
      return res.status(400).json({ error: 'Order not in active delivery status' });
    }

    await db.query('UPDATE `Order` SET status = ? WHERE id = ?', ['completed', orderId]);

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
              r.name        AS store_name,
              r.address     AS store_address,
              c.name        AS customer_name,
              c.phone       AS customer_phone,
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

module.exports = router;
