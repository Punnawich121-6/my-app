const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/:storeId', async (req, res) => {
  try {
    const [[store]] = await db.query('SELECT * FROM stores WHERE id = ?', [req.params.storeId]);
    if (!store) return res.status(404).json({ error: 'Not found' });
    res.json(store);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:storeId', async (req, res) => {
  const { name, type, address, lat, lng, open_time, close_time, image_url } = req.body;
  try {
    await db.query(
      'UPDATE stores SET name=?, type=?, address=?, lat=?, lng=?, open_time=?, close_time=?, image_url=? WHERE id=?',
      [name, type, address, lat, lng, open_time, close_time, image_url || null, req.params.storeId]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/:storeId/reviews', async (req, res) => {
  try {
    const [reviews] = await db.query(
      'SELECT * FROM reviews WHERE store_id = ? ORDER BY created_at DESC',
      [req.params.storeId]
    );
    const [[avg]] = await db.query(
      'SELECT AVG(rating) as avg, COUNT(*) as count FROM reviews WHERE store_id = ?',
      [req.params.storeId]
    );
    res.json({ reviews, average: avg.avg || 0, count: avg.count });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
