const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  const { status } = req.query;
  try {
    let where = 'WHERE o.restaurantId = ?';
    const params = [storeId];
    if (status && status !== 'all') {
      if (status === 'active') {
        where += " AND LOWER(o.status) IN ('pending','accepted','preparing')";
      } else if (status === 'delivering') {
        where += " AND LOWER(o.status) IN ('ready','delivering')";
      } else if (status === 'completed') {
        where += " AND LOWER(o.status) = 'completed'";
      } else if (status === 'cancelled') {
        where += " AND LOWER(o.status) = 'cancelled'";
      }
    }

    const [orders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status, o.totalAmount, o.serviceFee, o.notes, o.createdAt,
              c.name AS customer_name, c.phone AS customer_phone, c.address,
              GROUP_CONCAT(CONCAT(oi.quantity,'x ',oi.name) SEPARATOR ', ') as items_summary
       FROM \`order\` o
       LEFT JOIN customer c ON o.customerId = c.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       ${where} GROUP BY o.id ORDER BY o.createdAt DESC`,
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
    const [[order]] = await db.query(
      `SELECT o.*, c.name AS customer_name, c.phone AS customer_phone, c.address
       FROM \`order\` o LEFT JOIN customer c ON o.customerId = c.id
       WHERE o.id = ?`,
      [orderId]
    );
    if (!order) return res.status(404).json({ error: 'Order not found' });

    const [items] = await db.query('SELECT * FROM order_items WHERE order_id = ?', [orderId]);
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
    await db.query('UPDATE `order` SET status = ? WHERE id = ?', [status, orderId]);

    if (status === 'completed') {
      const [[order]] = await db.query(
        'SELECT restaurantId, totalAmount, serviceFee FROM `order` WHERE id = ?',
        [orderId]
      );
      const foodAmount = parseFloat(order.totalAmount) - parseFloat(order.serviceFee || 0);
      const netPayout  = foodAmount * 0.85;
      await db.query(
        `INSERT INTO transaction (id, orderId, restaurantId, amount, netPayout, status)
         VALUES (UUID(),?,?,?,?,?)
         ON DUPLICATE KEY UPDATE status = 'completed'`,
        [orderId, order.restaurantId, foodAmount.toFixed(2), netPayout.toFixed(2), 'completed']
      );
      await db.query(
        `UPDATE restaurant SET totalOrders = (
           SELECT COUNT(*) FROM \`order\` WHERE restaurantId = restaurant.id AND LOWER(status) = 'completed'
         ) WHERE id = ?`,
        [order.restaurantId]
      );
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Backfill serviceFee for orders that have serviceFee = 0 or NULL
router.post('/backfill-service-fee', async (req, res) => {
  try {
    const [result] = await db.query(
      `UPDATE \`Order\` SET serviceFee = 30 WHERE serviceFee IS NULL OR serviceFee = 0`
    );
    res.json({ message: 'Backfill serviceFee complete', updated: result.affectedRows });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Backfill transactions for completed orders that have no transaction record
router.post('/backfill-transactions', async (req, res) => {
  try {
    const [orders] = await db.query(`
      SELECT o.id, o.restaurantId, o.totalAmount, o.serviceFee
      FROM \`Order\` o
      LEFT JOIN transaction t ON t.orderId = o.id
      WHERE LOWER(o.status) = 'completed'
        AND t.id IS NULL
    `);

    if (orders.length === 0) {
      return res.json({ message: 'No missing transactions found', inserted: 0 });
    }

    for (const order of orders) {
      const foodAmount = parseFloat(order.totalAmount) - parseFloat(order.serviceFee || 0);
      const netPayout  = foodAmount * 0.85;
      await db.query(
        `INSERT INTO transaction (id, orderId, restaurantId, amount, netPayout, status)
         VALUES (UUID(), ?, ?, ?, ?, 'completed')
         ON DUPLICATE KEY UPDATE status = 'completed'`,
        [order.id, order.restaurantId, foodAmount.toFixed(2), netPayout.toFixed(2)]
      );
    }

    res.json({ message: 'Backfill complete', inserted: orders.length });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Test Order Creator (DEV only)
router.post('/test-order', async (req, res) => {
  const { store_id, items } = req.body;
  if (!store_id || !items || !items.length) {
    return res.status(400).json({ error: 'store_id and items are required' });
  }
  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const serviceFee = 30;
  const totalAmount = subtotal + serviceFee;

  try {
    let [[testCustomer]] = await db.query('SELECT id FROM customer WHERE email = ?', ['test@test.com']);
    if (!testCustomer) {
      await db.query(
        'INSERT INTO customer (id, name, email, phone, address) VALUES (UUID(), ?, ?, ?, ?)',
        ['ลูกค้าทดสอบ', 'test@test.com', '081-234-5678', '123 ถ.ทดสอบ กรุงเทพฯ']
      );
      [[testCustomer]] = await db.query('SELECT id FROM customer WHERE email = ?', ['test@test.com']);
    }

    const orderId = require('crypto').randomUUID();
    const orderNumber = 'ORD-' + Date.now();
    await db.query(
      `INSERT INTO \`order\` (id, orderNumber, restaurantId, customerId, status, totalAmount, serviceFee, notes)
       VALUES (?,?,?,?,?,?,?,?)`,
      [orderId, orderNumber, store_id, testCustomer.id, 'pending', totalAmount.toFixed(2), serviceFee, '']
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

module.exports = router;
