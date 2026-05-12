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
       FROM transaction WHERE restaurantId=? AND createdAt >= DATE_SUB(NOW(), INTERVAL ${interval})`,
      [storeId]
    );

    const [[pending]] = await db.query(
      `SELECT COALESCE(SUM(amount),0) as amount FROM transaction
       WHERE restaurantId=? AND LOWER(status)='pending'`,
      [storeId]
    );

    const [[paid]] = await db.query(
      `SELECT COALESCE(SUM(amount),0) as amount FROM transaction
       WHERE restaurantId=? AND LOWER(status) IN ('paid','completed')`,
      [storeId]
    );

    const [transactions] = await db.query(
      `SELECT t.*, c.name AS customer_name, o.createdAt as order_date
       FROM transaction t
       LEFT JOIN \`order\` o ON t.orderId = o.id
       LEFT JOIN customer c ON o.customerId = c.id
       WHERE t.restaurantId=? AND t.createdAt >= DATE_SUB(NOW(), INTERVAL ${interval})
       ORDER BY t.createdAt DESC`,
      [storeId]
    );

    const [chartData] = await db.query(
      `SELECT DATE(createdAt) as date, COALESCE(SUM(totalAmount),0) as revenue
       FROM \`Order\` WHERE restaurantId=? AND LOWER(status)='completed'
         AND createdAt >= DATE_SUB(NOW(), INTERVAL 30 DAY)
       GROUP BY DATE(createdAt) ORDER BY date ASC`,
      [storeId]
    );

    res.json({ summary, pending: pending.amount, paid: paid.amount, transactions, chart: chartData });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
