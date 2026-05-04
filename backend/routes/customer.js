const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/stores', async (req, res) => {
  try {
    const [stores] = await db.query(
      `SELECT id, name, type, address, is_open, image_url, rating, review_count, open_time, close_time
       FROM stores WHERE status = 'approved' ORDER BY is_open DESC, rating DESC`
    );
    res.json(stores);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/by-phone/:phone', async (req, res) => {
  try {
    const [[user]] = await db.query(
      'SELECT * FROM users WHERE phone = ?',
      [req.params.phone]
    );
    res.json(user || null);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/register', async (req, res) => {
  const { phone, name } = req.body;
  try {
    const [[existing]] = await db.query('SELECT id FROM users WHERE phone = ?', [phone]);
    if (existing) {
      return res.json({ user_id: existing.id });
    }
    const [result] = await db.query(
      'INSERT INTO users (phone, name, role) VALUES (?, ?, "customer")',
      [phone, name]
    );
    res.json({ user_id: result.insertId });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/orders', async (req, res) => {
  const { customer_id, customer_name, customer_phone, store_id, items, address, note } = req.body;
  const deliveryFee = 30;
  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const total = subtotal + deliveryFee;
  try {
    const [result] = await db.query(
      `INSERT INTO orders (store_id, customer_id, customer_name, customer_phone, address, note, status, total_amount, delivery_fee)
       VALUES (?,?,?,?,?,?,?,?,?)`,
      [store_id, customer_id || null, customer_name, customer_phone, address, note || '', 'pending', total.toFixed(2), deliveryFee]
    );
    const orderId = result.insertId;
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

router.get('/orders/detail/:orderId', async (req, res) => {
  try {
    const [[order]] = await db.query(
      `SELECT o.*, s.name as store_name, s.address as store_address
       FROM orders o LEFT JOIN stores s ON o.store_id = s.id WHERE o.id = ?`,
      [req.params.orderId]
    );
    if (!order) return res.status(404).json({ error: 'Not found' });
    const [items] = await db.query('SELECT * FROM order_items WHERE order_id = ?', [req.params.orderId]);
    res.json({ ...order, items });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/orders/:customerId', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.*, s.name as store_name,
       GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') as items_summary
       FROM orders o
       LEFT JOIN stores s ON o.store_id = s.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.customer_id = ?
       GROUP BY o.id ORDER BY o.created_at DESC`,
      [req.params.customerId]
    );
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/profile/:id', async (req, res) => {
  const { name } = req.body;
  try {
    await db.query('UPDATE users SET name = ? WHERE id = ?', [name, req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
