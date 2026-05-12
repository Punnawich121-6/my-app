const express = require('express');
const router = express.Router();
const db = require('../db');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function saveImage(base64Data) {
  if (!base64Data) return null;
  try {
    const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    let buffer, ext = '.jpg';
    if (matches && matches.length === 3) {
      buffer = Buffer.from(matches[2], 'base64');
      if (matches[1].includes('png')) ext = '.png';
    } else {
      buffer = Buffer.from(base64Data, 'base64');
    }
    const filename = Date.now() + ext;
    const filepath = path.join(__dirname, '../public/uploads', filename);
    fs.writeFileSync(filepath, buffer);
    return 'http://localhost:3000/uploads/' + filename;
  } catch (e) {
    return null;
  }
}

// ─── GET store by owner phone ─────────────────────────────────────────────────
router.get('/by-phone/:phone', async (req, res) => {
  try {
    const [[store]] = await db.query(
      `SELECT id, name, category, address, status, imageUrl, phone, email
       FROM restaurant WHERE phone = ?`,
      [req.params.phone]
    );
    res.json(store || null);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── POST register new restaurant ────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const {
    phone, name, category, address, email,
    owner_name, line_id,
    bank_name, account_name, account_no,
    id_card, business_license,
    open_time, close_time,
    lat, lng,
  } = req.body;
  try {
    const [[existing]] = await db.query(
      'SELECT id FROM restaurant WHERE phone = ?', [phone]
    );
    if (existing) return res.json({ store_id: existing.id });

    const id = crypto.randomUUID();
    await db.query(
      `INSERT INTO restaurant
         (id, name, category, address, phone, email, status, commissionRate, serviceFeeRate,
          owner_name, line_id, bank_name, account_name, account_no,
          id_card, business_license, open_time, close_time, lat, lng)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', 15, 5, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id, name, category || 'ร้านอาหาร', address || '', phone, email || '',
        owner_name || null, line_id || null,
        bank_name || null, account_name || null, account_no || null,
        id_card || null, business_license || null,
        open_time || null, close_time || null,
        lat || null, lng || null,
      ]
    );
    res.json({ store_id: id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET store by ID ──────────────────────────────────────────────────────────
router.get('/:storeId', async (req, res) => {
  try {
    const [[store]] = await db.query(
      `SELECT id, name, category AS type, address, imageUrl AS image_url,
              COALESCE(rating, 0) AS rating,
              CASE WHEN status = 'active' THEN 1 ELSE 0 END AS is_open
       FROM restaurant WHERE id = ?`,
      [req.params.storeId]
    );
    if (!store) return res.status(404).json({ error: 'Not found' });
    res.json(store);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:storeId', async (req, res) => {
  const { name, type, address, image_url, open_time, close_time, lat, lng } = req.body;
  try {
    await db.query(
      'UPDATE restaurant SET name=?, category=?, address=?, imageUrl=?, open_time=?, close_time=?, lat=?, lng=? WHERE id=?',
      [name, type, address, image_url || null, open_time || null, close_time || null, lat || null, lng || null, req.params.storeId]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── Upload store image (base64) ─────────────────────────────────────────────
router.post('/:storeId/image', async (req, res) => {
  const { image } = req.body;
  if (!image) return res.status(400).json({ error: 'image required' });
  try {
    const url = saveImage(image);
    if (!url) return res.status(500).json({ error: 'Failed to save image' });
    await db.query('UPDATE restaurant SET imageUrl=? WHERE id=?', [url, req.params.storeId]);
    res.json({ image_url: url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── GET reviews for a store ──────────────────────────────────────────────────
router.get('/:storeId/reviews', async (req, res) => {
  try {
    const [reviews] = await db.query(
      `SELECT r.id, r.rating, r.comment, r.createdAt,
              c.name AS customer_name
       FROM reviews r
       LEFT JOIN customer c ON r.customer_id = c.id
       WHERE r.store_id = ?
       ORDER BY r.createdAt DESC
       LIMIT 50`,
      [req.params.storeId]
    );
    const [[agg]] = await db.query(
      `SELECT COUNT(*) AS total, COALESCE(AVG(rating), 0) AS average
       FROM reviews WHERE store_id = ?`,
      [req.params.storeId]
    );
    res.json({ reviews, total: agg.total, average: parseFloat(agg.average).toFixed(1) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
