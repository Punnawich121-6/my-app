const express = require('express');
const router = express.Router();
const db = require('../db');
const crypto = require('crypto');

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
  const { name, type, address, image_url } = req.body;
  try {
    await db.query(
      'UPDATE restaurant SET name=?, category=?, address=?, imageUrl=? WHERE id=?',
      [name, type, address, image_url || null, req.params.storeId]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
