const express = require('express');
const router = express.Router();
const db = require('../../db');

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  try {
    const today = new Date().toISOString().slice(0, 10);

    const [[store]] = await db.query(
      `SELECT id, name, category AS type, address, imageUrl AS image_url,
              COALESCE(rating, 0) AS rating,
              CASE WHEN LOWER(status) = 'active' THEN 1 ELSE 0 END AS is_open
       FROM restaurant WHERE id = ?`,
      [storeId]
    );
    if (!store) return res.status(404).json({ error: 'Store not found' });

    const [[todaySales]] = await db.query(
      `SELECT COUNT(*) as count, COALESCE(SUM(totalAmount),0) as revenue
       FROM \`order\` WHERE restaurantId=? AND DATE(createdAt)=? AND LOWER(status)='completed'`,
      [storeId, today]
    );

    const [[pendingOrders]] = await db.query(
      `SELECT COUNT(*) as count FROM \`order\`
       WHERE restaurantId=? AND LOWER(status) IN ('pending','accepted','preparing')`,
      [storeId]
    );

    const [[readyOrders]] = await db.query(
      `SELECT COUNT(*) as count FROM \`order\`
       WHERE restaurantId=? AND LOWER(status) IN ('ready','delivering')`,
      [storeId]
    );

    const [weekSales] = await db.query(
      `SELECT DATE(createdAt) as date, COALESCE(SUM(totalAmount),0) as revenue
       FROM \`order\` WHERE restaurantId=? AND LOWER(status)='completed'
       AND createdAt >= DATE_SUB(NOW(), INTERVAL 7 DAY)
       GROUP BY DATE(createdAt) ORDER BY date ASC`,
      [storeId]
    );

    const [recentOrders] = await db.query(
      `SELECT o.id, o.orderNumber, o.status, o.totalAmount, o.notes, o.createdAt,
              c.name AS customer_name, c.phone AS customer_phone,
              GROUP_CONCAT(oi.name SEPARATOR ', ') as items_summary
       FROM \`order\` o
       LEFT JOIN customer c ON o.customerId = c.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       WHERE o.restaurantId=? AND LOWER(o.status) IN ('pending','accepted','preparing')
       GROUP BY o.id ORDER BY o.createdAt DESC LIMIT 5`,
      [storeId]
    );

    // Popular items — join with menu_items to get live image/price, filter deleted items
    const [popularItems] = await db.query(
      `SELECT mi.id, mi.name, mi.image_url, mi.price, SUM(oi.quantity) AS total_sold
       FROM order_items oi
       JOIN \`order\` o ON oi.order_id = o.id
       JOIN menu_items mi ON mi.store_id = o.restaurantId AND mi.name = oi.name AND mi.is_available = 1
       WHERE o.restaurantId = ? AND o.createdAt >= DATE_SUB(NOW(), INTERVAL 7 DAY)
       GROUP BY mi.id, mi.name, mi.image_url, mi.price
       ORDER BY total_sold DESC
       LIMIT 4`,
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
      popular_items: popularItems,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:storeId/toggle', async (req, res) => {
  const { storeId } = req.params;
  try {
    const [[store]] = await db.query('SELECT status FROM restaurant WHERE id = ?', [storeId]);
    const newStatus = store.status.toLowerCase() === 'active' ? 'inactive' : 'active';
    await db.query('UPDATE restaurant SET status = ? WHERE id = ?', [newStatus, storeId]);
    res.json({ is_open: newStatus === 'active' ? 1 : 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
