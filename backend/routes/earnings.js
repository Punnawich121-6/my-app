const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  const { period = 'day' } = req.query;
  try {
    let interval;
    if (period === 'week') interval = '7 DAY';
    else if (period === 'month') interval = '30 DAY';
    else interval = '1 DAY';

    const [[summary]] = await db.query(
      `SELECT COALESCE(SUM(amount),0) as total, COUNT(*) as count
       FROM earnings WHERE store_id=? AND created_at >= DATE_SUB(NOW(), INTERVAL ${interval})`,
      [storeId]
    );

    const [[pending]] = await db.query(
      `SELECT COALESCE(SUM(amount),0) as amount FROM earnings WHERE store_id=? AND status='pending'`,
      [storeId]
    );

    const [[paid]] = await db.query(
      `SELECT COALESCE(SUM(amount),0) as amount FROM earnings WHERE store_id=? AND status='paid'`,
      [storeId]
    );

    const [transactions] = await db.query(
      `SELECT e.*, o.customer_name, o.created_at as order_date
       FROM earnings e LEFT JOIN orders o ON e.order_id = o.id
       WHERE e.store_id=? AND e.created_at >= DATE_SUB(NOW(), INTERVAL ${interval})
       ORDER BY e.created_at DESC`,
      [storeId]
    );

    const [chartData] = await db.query(
      `SELECT DATE(created_at) as date, SUM(amount) as revenue
       FROM earnings WHERE store_id=? AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
       GROUP BY DATE(created_at) ORDER BY date ASC`,
      [storeId]
    );

    res.json({ summary, pending: pending.amount, paid: paid.amount, transactions, chart: chartData });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
