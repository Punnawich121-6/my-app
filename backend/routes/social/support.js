const express = require('express');
const router = express.Router();
const db = require('../../db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Upload dir
const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'support');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

let _tableReady = false;
async function ensureTable() {
  if (_tableReady) return;
  await db.query(`
    CREATE TABLE IF NOT EXISTS support_messages (
      id          INT AUTO_INCREMENT PRIMARY KEY,
      store_id    VARCHAR(255) NOT NULL,
      store_name  VARCHAR(255),
      sender_role ENUM('store','admin','customer') NOT NULL DEFAULT 'store',
      sender_name VARCHAR(255),
      message     TEXT NOT NULL,
      image_url   VARCHAR(500),
      is_read     TINYINT(1) NOT NULL DEFAULT 0,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_store   (store_id),
      INDEX idx_created (created_at)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `);
  try {
    await db.query(`ALTER TABLE support_messages ADD COLUMN image_url VARCHAR(500) AFTER message`);
  } catch (_) {}
  try {
    await db.query(`ALTER TABLE support_messages MODIFY COLUMN sender_role ENUM('store','admin','customer') NOT NULL DEFAULT 'store'`);
  } catch (_) {}
  _tableReady = true;
}

// GET /api/support/threads — all threads (admin inbox)
router.get('/threads', async (req, res) => {
  try {
    await ensureTable();
    const [rows] = await db.query(`
      SELECT
        sm.store_id,
        MAX(sm.store_name) AS store_name,
        (SELECT message     FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_message,
        (SELECT image_url   FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_image_url,
        (SELECT sender_role FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_role,
        (SELECT created_at  FROM support_messages WHERE store_id = sm.store_id ORDER BY created_at DESC LIMIT 1) AS last_at,
        SUM(CASE WHEN sm.sender_role IN ('store','customer') AND sm.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
      FROM support_messages sm
      GROUP BY sm.store_id
      ORDER BY last_at DESC
    `);
    res.json(rows);
  } catch (e) {
    console.error('[support threads]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// GET /api/support/unread-count — total unread for admin badge
router.get('/unread-count', async (req, res) => {
  try {
    await ensureTable();
    const [rows] = await db.query(
      `SELECT COUNT(*) AS total FROM support_messages WHERE sender_role IN ('store','customer') AND is_read = 0`
    );
    res.json({ count: Number(rows[0].total) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/support/:storeId/upload — upload image, returns { url }
router.post('/:storeId/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  const url = `/uploads/support/${req.file.filename}`;
  res.json({ url });
});

// GET /api/support/:storeId — messages for one store thread
router.get('/:storeId', async (req, res) => {
  try {
    await ensureTable();
    const { storeId } = req.params;
    const [rows] = await db.query(
      'SELECT * FROM support_messages WHERE store_id = ? ORDER BY created_at ASC',
      [storeId]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/support/:storeId — send message (text and/or image)
router.post('/:storeId', async (req, res) => {
  try {
    await ensureTable();
    const { storeId } = req.params;
    const { senderRole = 'store', senderName, storeName, message = '', imageUrl } = req.body;
    if (!message?.trim() && !imageUrl) return res.status(400).json({ error: 'message or image required' });

    const [result] = await db.query(
      'INSERT INTO support_messages (store_id, store_name, sender_role, sender_name, message, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [storeId, storeName || senderName || null, senderRole, senderName || null, (message || '').trim(), imageUrl || null]
    );
    const [rows] = await db.query('SELECT * FROM support_messages WHERE id = ?', [result.insertId]);
    const msg = rows[0];
    const io = req.app.get('io');
    io?.to('admin').emit('new_support_message', { storeId, message: msg });
    io?.to(`support_${storeId}`).emit('new_support_message', { storeId, message: msg });
    res.json(msg);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// DELETE /api/support/:storeId — clear all messages for a store thread
router.delete('/:storeId', async (req, res) => {
  try {
    await ensureTable();
    const { storeId } = req.params;
    await db.query('DELETE FROM support_messages WHERE store_id = ?', [storeId]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/support/:storeId/read — admin marks thread as read
router.put('/:storeId/read', async (req, res) => {
  try {
    await ensureTable();
    const { storeId } = req.params;
    await db.query(
      `UPDATE support_messages SET is_read = 1 WHERE store_id = ? AND sender_role != 'admin'`,
      [storeId]
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
