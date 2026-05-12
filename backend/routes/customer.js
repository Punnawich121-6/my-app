const express = require('express');
const router = express.Router();
const db = require('../db');
const crypto = require('crypto');

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

// ─── GET customer by phone ────────────────────────────────────────────────────
router.get('/by-phone/:phone', async (req, res) => {
  try {
    const [[user]] = await db.query(
      'SELECT id, name, phone, address FROM customer WHERE phone = ?',
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
  const { customer_id, customer_name, customer_phone, store_id, items, address, latitude, longitude, note } = req.body;
  const deliveryFee = 30;
  const subtotal = items.reduce((s, i) => s + i.price * i.quantity, 0);
  const total = subtotal + deliveryFee;
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

// ─── GET orders by customer ───────────────────────────────────────────────────
router.get('/orders/:customerId', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status,
              o.totalAmount AS total_amount,
              o.createdAt AS created_at,
              r.name AS store_name,
              r.imageUrl AS store_image,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') AS items_summary
       FROM \`order\` o
       LEFT JOIN restaurant r ON o.restaurantId = r.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.customerId = ?
       GROUP BY o.id
       ORDER BY o.createdAt DESC`,
      [req.params.customerId]
    );
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── PUT update profile ───────────────────────────────────────────────────────
router.put('/profile/:id', async (req, res) => {
  const { name } = req.body;
  try {
    await db.query('UPDATE customer SET name = ? WHERE id = ?', [name, req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
