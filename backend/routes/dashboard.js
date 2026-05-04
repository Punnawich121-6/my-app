const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  try {
    const today = new Date().toISOString().slice(0, 10);

    const [[store]] = await db.query('SELECT * FROM stores WHERE id = ?', [storeId]);
    if (!store) return res.status(404).json({ error: 'Store not found' });

    const [[todaySales]] = await db.query(
      `SELECT COUNT(*) as count, COALESCE(SUM(total_amount),0) as revenue
       FROM orders WHERE store_id=? AND DATE(created_at)=? AND status='completed'`,
      [storeId, today]
    );

    const [[pendingOrders]] = await db.query(
      `SELECT COUNT(*) as count FROM orders WHERE store_id=? AND status IN ('pending','accepted','preparing')`,
      [storeId]
    );

    const [[readyOrders]] = await db.query(
      `SELECT COUNT(*) as count FROM orders WHERE store_id=? AND status IN ('ready','delivering')`,
      [storeId]
    );

    const [weekSales] = await db.query(
      `SELECT DATE(created_at) as date, COALESCE(SUM(total_amount),0) as revenue
       FROM orders WHERE store_id=? AND status='completed'
       AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
       GROUP BY DATE(created_at) ORDER BY date ASC`,
      [storeId]
    );

    const [recentOrders] = await db.query(
      `SELECT o.*, GROUP_CONCAT(oi.name SEPARATOR ', ') as items_summary
       FROM orders o LEFT JOIN order_items oi ON o.id=oi.order_id
       WHERE o.store_id=? AND o.status IN ('pending','accepted','preparing')
       GROUP BY o.id ORDER BY o.created_at DESC LIMIT 5`,
      [storeId]
    );

    res.json({
      store,
      today_orders: todaySales.count,
      today_revenue: todaySales.revenue,
      pending_orders: pendingOrders.count,
      ready_orders: readyOrders.count,
      week_sales: weekSales,
      recent_orders: recentOrders,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:storeId/toggle', async (req, res) => {
  const { storeId } = req.params;
  try {
    await db.query('UPDATE stores SET is_open = NOT is_open WHERE id = ?', [storeId]);
    const [[store]] = await db.query('SELECT is_open FROM stores WHERE id = ?', [storeId]);
    res.json({ is_open: store.is_open });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
