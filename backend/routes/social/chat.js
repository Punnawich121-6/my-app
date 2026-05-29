const express = require('express');
const router = express.Router();
const db = require('../../db');
const multer = require('multer');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

let _migrated = false;
async function ensureCols() {
  if (_migrated) return;
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(100) NOT NULL,
        sender_id VARCHAR(100) NOT NULL,
        sender_role ENUM('customer','store','rider') NOT NULL,
        sender_name VARCHAR(100) NOT NULL,
        message TEXT NOT NULL DEFAULT '',
        image_url VARCHAR(500),
        chat_type ENUM('store','rider') NOT NULL DEFAULT 'store',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (_) {}
  try { await db.query(`ALTER TABLE messages ADD COLUMN image_url VARCHAR(500) AFTER message`); } catch (_) {}
  try { await db.query(`ALTER TABLE messages ADD COLUMN chat_type ENUM('store','rider') NOT NULL DEFAULT 'store' AFTER image_url`); } catch (_) {}
  _migrated = true;
}

async function hasAccess(orderId, userId, userRole) {
  try {
    const [rows] = await db.query(
      'SELECT customerId, restaurantId, riderId FROM `order` WHERE id = ?',
      [orderId]
    );
    if (!rows.length) return false;
    const o = rows[0];
    if (userRole === 'customer') return String(o.customerId)   === String(userId);
    if (userRole === 'store')    return String(o.restaurantId) === String(userId);
    if (userRole === 'rider')    return String(o.riderId)      === String(userId);
    return false;
  } catch {
    return false;
  }
}

// GET conversations list for a user
router.get('/conversations/:userRole/:userId', async (req, res) => {
  const { userRole, userId } = req.params;
  const chatType = userRole === 'rider' ? 'rider' : 'store';

  let whereCol = '';
  if      (userRole === 'customer') whereCol = 'o.customerId';
  else if (userRole === 'store')    whereCol = 'o.restaurantId';
  else if (userRole === 'rider')    whereCol = 'o.riderId';
  else return res.status(400).json({ error: 'invalid role' });

  try {
    await ensureCols();
    const [rows] = await db.query(
      `SELECT o.id          AS order_id,
              o.status,
              o.riderId,
              c.name        AS customer_name,
              r.name        AS store_name,
              o.createdAt   AS created_at,
              o.totalAmount AS total_amount,
              COALESCE(ms.msg_count, 0) AS msg_count,
              ms.last_msg,
              ms.last_sender,
              ms.last_msg_at
       FROM \`order\` o
       JOIN  restaurant r ON r.id = o.restaurantId
       LEFT JOIN customer c ON c.id = o.customerId
       LEFT JOIN (
         SELECT order_id,
                COUNT(*)                                                               AS msg_count,
                MAX(created_at)                                                        AS last_msg_at,
                SUBSTRING_INDEX(GROUP_CONCAT(message     ORDER BY created_at DESC SEPARATOR '\x01'), '\x01', 1) AS last_msg,
                SUBSTRING_INDEX(GROUP_CONCAT(sender_name ORDER BY created_at DESC SEPARATOR '\x01'), '\x01', 1) AS last_sender
         FROM   messages
         WHERE  chat_type = ?
         GROUP  BY order_id
       ) ms ON CAST(ms.order_id AS CHAR) = CAST(o.id AS CHAR)
       WHERE ${whereCol} = ?
       ORDER BY COALESCE(ms.last_msg_at, o.createdAt) DESC`,
      [chatType, userId]
    );
    res.json(rows);
  } catch (e) {
    console.error('[chat conversations]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// POST upload image for chat — returns base64 data URI (Render has ephemeral disk)
router.post('/:orderId/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'no file' });
  const b64 = req.file.buffer.toString('base64');
  res.json({ url: `data:${req.file.mimetype};base64,${b64}` });
});

// GET messages for an order
router.get('/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const { userId, userRole, chatType = 'store' } = req.query;

  try {
    if (!await hasAccess(orderId, userId, userRole))
      return res.status(403).json({ error: 'access denied' });

    const [rows] = await db.query(
      'SELECT * FROM messages WHERE order_id = ? AND chat_type = ? ORDER BY created_at ASC',
      [orderId, chatType]
    );
    res.json(rows);
  } catch (e) {
    console.error('[chat GET]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// DELETE all messages for an order
router.delete('/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const { userId, userRole } = req.query;
  try {
    if (!await hasAccess(orderId, userId, userRole))
      return res.status(403).json({ error: 'access denied' });
    await db.query('DELETE FROM messages WHERE order_id = ?', [orderId]);
    res.json({ ok: true });
  } catch (e) {
    console.error('[chat DELETE]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// POST send a message (text and/or image)
router.post('/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const { userId, userRole, senderName, message, chatType = 'store', imageUrl } = req.body;

  if (!message?.trim() && !imageUrl) return res.status(400).json({ error: 'message or image required' });

  try {
    await ensureCols();

    if (!await hasAccess(orderId, userId, userRole))
      return res.status(403).json({ error: 'access denied' });

    const [result] = await db.query(
      'INSERT INTO messages (order_id, sender_id, sender_role, sender_name, message, chat_type, image_url) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [orderId, userId, userRole, senderName, message?.trim() || '', chatType, imageUrl || null]
    );
    const [rows] = await db.query('SELECT * FROM messages WHERE id = ?', [result.insertId]);
    const saved = rows[0];
    req.app.get('io')?.to(`order_${orderId}`).emit('new_message', saved);
    res.json(saved);
  } catch (e) {
    console.error('[chat POST]', e.message);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
