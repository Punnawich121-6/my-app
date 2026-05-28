const express = require('express');
const router = express.Router();
const db = require('../../db');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function saveImage(base64Data, req) {
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
    const uploadDir = path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    const filepath = path.join(uploadDir, filename);
    fs.writeFileSync(filepath, buffer);
    const baseUrl = req ? `http://${req.get('host')}` : 'http://localhost:3001';
    return baseUrl + '/uploads/' + filename;
  } catch (e) {
    return null;
  }
}

function fixImageUrl(url, req) {
  if (!url || !req) return url;
  return url.replace(/^http:\/\/localhost:3001/, `http://${req.get('host')}`);
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
    if (existing) {
      await db.query(
        `UPDATE restaurant SET
           name=COALESCE(NULLIF(?,\'\'),name),
           category=COALESCE(NULLIF(?,\'\'),category),
           address=COALESCE(NULLIF(?,\'\'),address),
           email=COALESCE(NULLIF(?,\'\'),email),
           owner_name=COALESCE(NULLIF(?,\'\'),owner_name),
           line_id=COALESCE(NULLIF(?,\'\'),line_id),
           bank_name=COALESCE(NULLIF(?,\'\'),bank_name),
           account_name=COALESCE(NULLIF(?,\'\'),account_name),
           account_no=COALESCE(NULLIF(?,\'\'),account_no),
           id_card=COALESCE(NULLIF(?,\'\'),id_card),
           business_license=COALESCE(NULLIF(?,\'\'),business_license),
           open_time=COALESCE(NULLIF(?,\'\'),open_time),
           close_time=COALESCE(NULLIF(?,\'\'),close_time),
           lat=COALESCE(?,lat), lng=COALESCE(?,lng),
           status='active'
         WHERE id=?`,
        [
          name||null, category||null, address||null, email||null,
          owner_name||null, line_id||null,
          bank_name||null, account_name||null, account_no||null,
          id_card||null, business_license||null,
          open_time||null, close_time||null,
          lat||null, lng||null,
          existing.id,
        ]
      );
      return res.json({ store_id: existing.id });
    }

    const id = crypto.randomUUID();
    await db.query(
      `INSERT INTO restaurant
         (id, name, category, address, phone, email, status, commissionRate, serviceFeeRate,
          owner_name, line_id, bank_name, account_name, account_no,
          id_card, business_license, open_time, close_time, lat, lng)
       VALUES (?, ?, ?, ?, ?, ?, 'active', 15, 5, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
    if (store.image_url) store.image_url = fixImageUrl(store.image_url, req);
    res.json(store);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/:storeId', async (req, res) => {
  const { name, type, address, image_url, open_time, close_time, lat, lng } = req.body;
  try {
    if (image_url !== undefined) {
      await db.query(
        'UPDATE restaurant SET name=?, category=?, address=?, imageUrl=?, open_time=?, close_time=?, lat=?, lng=? WHERE id=?',
        [name, type, address, image_url || null, open_time || null, close_time || null, lat || null, lng || null, req.params.storeId]
      );
    } else {
      await db.query(
        'UPDATE restaurant SET name=?, category=?, address=?, open_time=?, close_time=?, lat=?, lng=? WHERE id=?',
        [name, type, address, open_time || null, close_time || null, lat || null, lng || null, req.params.storeId]
      );
    }
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
    const url = saveImage(image, req);
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
      `SELECT r.id, r.rating, r.comment, r.reply, r.images,
              r.createdAt AS created_at,
              COALESCE(c.name, r.customer_name, 'Customer') AS customer_name
       FROM reviews r
       LEFT JOIN customer c ON r.customer_id = c.id
       WHERE r.store_id = ?
       ORDER BY r.createdAt DESC
       LIMIT 50`,
      [req.params.storeId]
    );
    const baseUrl = `http://${req.get('host')}`;
    const fixedReviews = reviews.map(r => {
      if (!r.images) return r;
      try {
        const imgs = JSON.parse(r.images);
        const fixed = imgs.map(u => u.replace(/^http:\/\/[^/]+/, baseUrl));
        return { ...r, images: JSON.stringify(fixed) };
      } catch (_) { return r; }
    });
    const [[agg]] = await db.query(
      `SELECT COUNT(*) AS total, COALESCE(AVG(rating), 0) AS average
       FROM reviews WHERE store_id = ?`,
      [req.params.storeId]
    );
    res.json({ reviews: fixedReviews, total: agg.total, count: agg.total, average: parseFloat(agg.average).toFixed(1) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── Reply to a review ────────────────────────────────────────────────────────
router.post('/:storeId/reviews/:reviewId/reply', async (req, res) => {
  const { reply } = req.body;
  if (reply === undefined) return res.status(400).json({ error: 'reply required' });
  try {
    await db.query(
      'UPDATE reviews SET reply = ? WHERE id = ? AND store_id = ?',
      [reply || null, req.params.reviewId, req.params.storeId]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
