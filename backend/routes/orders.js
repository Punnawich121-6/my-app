const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  const { status } = req.query;
  try {
    let where = 'WHERE o.store_id = ?';
    const params = [storeId];
    if (status && status !== 'all') {
      if (status === 'active') {
        where += " AND o.status IN ('pending','accepted','preparing')";
      } else if (status === 'delivering') {
        where += " AND o.status IN ('ready','delivering')";
      } else if (status === 'completed') {
        where += " AND o.status = 'completed'";
      } else if (status === 'cancelled') {
        where += " AND o.status = 'cancelled'";
      }
    }

    const [orders] = await db.query(
      `SELECT o.*, GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') as items_summary
       FROM orders o LEFT JOIN order_items oi ON o.id = oi.order_id
       ${where} GROUP BY o.id ORDER BY o.created_at DESC`,
      params
    );
    res.json(orders);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/detail/:orderId', async (req, res) => {
  const { orderId } = req.params;
  try {
    const [[order]] = await db.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (!order) return res.status(404).json({ error: 'Order not found' });

    const [items] = await db.query(
      'SELECT * FROM order_items WHERE order_id = ?', [orderId]
    );
    res.json({ ...order, items });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:orderId/status', async (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;
  const validStatuses = ['accepted','preparing','ready','delivering','completed','cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }
  try {
    await db.query('UPDATE orders SET status = ? WHERE id = ?', [status, orderId]);

    if (status === 'completed') {
      const [[order]] = await db.query(
        'SELECT store_id, total_amount, delivery_fee FROM orders WHERE id = ?',
        [orderId]
      );
      // หักค่าส่งออกก่อน แล้วค่อยหักค่าบริการ 15%
      const foodAmount = parseFloat(order.total_amount) - parseFloat(order.delivery_fee || 0);
      const net = foodAmount * 0.85;
      await db.query(
        'INSERT INTO earnings (store_id, order_id, amount, type, status) VALUES (?,?,?,?,?)',
        [order.store_id, orderId, net.toFixed(2), 'order', 'paid']
      );
      // อัปเดต rating ร้าน (คำนวณเฉลี่ยใหม่)
      await db.query(
        `UPDATE stores s SET
          review_count = (SELECT COUNT(*) FROM orders WHERE store_id = s.id AND status = 'completed')
        WHERE s.id = ?`,
        [order.store_id]
      );
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Test Order Creator (DEV only)
router.post('/test-order', async (req, res) => {
  const { store_id, items } = req.body; // items: [{menu_item_id, name, price, quantity}]
  if (!store_id || !items || !items.length) {
    return res.status(400).json({ error: 'store_id and items are required' });
  }
  const customerNames = ['สมชาย', 'ณัฐนันท์', 'กิตติ', 'พิชา', 'วราภรณ์'];
  const customerName = customerNames[Math.floor(Math.random() * customerNames.length)];
  const phones = ['081-234-5678', '086-123-4567', '089-876-5432'];
  const phone = phones[Math.floor(Math.random() * phones.length)];
  const notes = ['ไม่เผ็ด', 'เอาข้าวเพิ่ม', 'ซอสเพิ่ม', ''];
  const note = notes[Math.floor(Math.random() * notes.length)];

  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const deliveryFee = 30;
  const totalAmount = subtotal + deliveryFee;

  try {
    const [result] = await db.query(
      `INSERT INTO orders (store_id, customer_name, customer_phone, address, note, status, total_amount, delivery_fee)
       VALUES (?,?,?,?,?,?,?,?)`,
      [store_id, customerName, phone, '123 ถ.ทดสอบ กรุงเทพฯ', note, 'pending', totalAmount.toFixed(2), deliveryFee]
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

module.exports = router;
