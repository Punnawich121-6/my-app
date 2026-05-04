const express = require('express');
const router = express.Router();
const db = require('../db');

// ── Register rider ────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { firebase_uid, phone, name } = req.body;
  if (!phone || !name) return res.status(400).json({ error: 'phone and name required' });
  try {
    const [existing] = await db.query('SELECT id FROM users WHERE phone = ?', [phone]);
    if (existing.length > 0) {
      await db.query('UPDATE users SET name = ?, role = ? WHERE phone = ?', [name, 'rider', phone]);
      return res.json({ success: true, user_id: existing[0].id });
    }
    const [result] = await db.query(
      'INSERT INTO users (phone, name, role) VALUES (?,?,?)',
      [phone, name, 'rider']
    );
    res.json({ success: true, user_id: result.insertId });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get rider profile ─────────────────────────────────────────────────────────
router.get('/profile/:riderId', async (req, res) => {
  try {
    const [[user]] = await db.query(
      'SELECT id, phone, name, role FROM users WHERE id = ? AND role = ?',
      [req.params.riderId, 'rider']
    );
    if (!user) return res.status(404).json({ error: 'Rider not found' });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Get rider by phone ────────────────────────────────────────────────────────
router.get('/by-phone/:phone', async (req, res) => {
  try {
    const [[user]] = await db.query(
      'SELECT id, phone, name, role FROM users WHERE phone = ? AND role = ?',
      [req.params.phone, 'rider']
    );
    if (!user) return res.status(404).json({ error: 'Not found' });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Available orders (status = ready, no rider assigned yet) ──────────────────
router.get('/orders/available', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.id, o.customer_name, o.customer_phone, o.address, o.note,
              o.total_amount, o.delivery_fee, o.status, o.created_at,
              s.name AS store_name, s.address AS store_address,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary
       FROM orders o
       JOIN stores s ON o.store_id = s.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.status = 'ready' AND o.rider_id IS NULL
       GROUP BY o.id
       ORDER BY o.created_at ASC`
    );
    res.json(orders);
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
      'SELECT id, status, rider_id FROM orders WHERE id = ?', [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.status !== 'ready') return res.status(400).json({ error: 'Order not available' });
    if (order.rider_id) return res.status(400).json({ error: 'Already taken by another rider' });

    await db.query(
      'UPDATE orders SET rider_id = ?, status = ? WHERE id = ?',
      [rider_id, 'delivering', orderId]
    );
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
      'SELECT id, status, rider_id, store_id, total_amount, delivery_fee FROM orders WHERE id = ?',
      [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.rider_id !== rider_id) return res.status(403).json({ error: 'Not your order' });
    if (order.status !== 'delivering') return res.status(400).json({ error: 'Order not in delivering status' });

    await db.query('UPDATE orders SET status = ? WHERE id = ?', ['completed', orderId]);

    // คำนวณรายได้ร้าน (อาหาร - 15%)
    const foodAmount = parseFloat(order.total_amount) - parseFloat(order.delivery_fee || 0);
    const storeNet = foodAmount * 0.85;
    await db.query(
      'INSERT INTO earnings (store_id, order_id, amount, type, status) VALUES (?,?,?,?,?)',
      [order.store_id, orderId, storeNet.toFixed(2), 'order', 'paid']
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
      `SELECT o.id, o.customer_name, o.customer_phone, o.address, o.note,
              o.total_amount, o.delivery_fee, o.status, o.created_at,
              s.name AS store_name, s.address AS store_address,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary
       FROM orders o
       JOIN stores s ON o.store_id = s.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.rider_id = ? AND o.status = 'delivering'
       GROUP BY o.id
       ORDER BY o.updated_at DESC
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
      `SELECT o.id, o.customer_name, o.address, o.total_amount, o.delivery_fee,
              o.status, o.created_at, s.name AS store_name
       FROM orders o
       JOIN stores s ON o.store_id = s.id
       WHERE o.rider_id = ? AND o.status IN ('completed','cancelled')
       ORDER BY o.updated_at DESC`,
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
      `SELECT COALESCE(SUM(delivery_fee), 0) AS amount, COUNT(*) AS count
       FROM orders
       WHERE rider_id = ? AND status = 'completed' AND DATE(updated_at) = CURDATE()`,
      [req.params.riderId]
    );
    const [[week]] = await db.query(
      `SELECT COALESCE(SUM(delivery_fee), 0) AS amount, COUNT(*) AS count
       FROM orders
       WHERE rider_id = ? AND status = 'completed'
         AND updated_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)`,
      [req.params.riderId]
    );
    const [[total]] = await db.query(
      `SELECT COALESCE(SUM(delivery_fee), 0) AS amount, COUNT(*) AS count
       FROM orders WHERE rider_id = ? AND status = 'completed'`,
      [req.params.riderId]
    );
    res.json({ today, week, total });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
