const express = require('express');
const router = express.Router();
const db = require('../../db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'chat');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

let _colAdded = false;
async function ensureImageCol() {
  if (_colAdded) return;
  try {
    await db.query(`ALTER TABLE messages ADD COLUMN image_url VARCHAR(500) AFTER message`);
  } catch (_) {}
  _colAdded = true;
}

async function hasAccess(orderId, userId, userRole) {
  try {
    const [rows] = await db.query(
      'SELECT customerId, restaurantId, riderId FROM `Order` WHERE id = ?',
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

  let where = '';
  if      (userRole === 'customer') where = 'o.customerId = ?';
  else if (userRole === 'store')    where = 'o.restaurantId = ?';
  else if (userRole === 'rider')    where = 'o.riderId = ?';
  else return res.status(400).json({ error: 'invalid role' });

  try {
    const [rows] = await db.query(
      `SELECT o.id as order_id, o.status, o.riderId,
              c.name as customer_name,
              r.name as store_name,
              o.createdAt as created_at, o.totalAmount as total_amount,
              (SELECT COUNT(*) FROM messages m WHERE m.order_id = o.id AND m.chat_type = ?) as msg_count,
              (SELECT m2.message FROM messages m2 WHERE m2.order_id = o.id AND m2.chat_type = ?
               ORDER BY m2.created_at DESC LIMIT 1) as last_msg,
              (SELECT m3.sender_name FROM messages m3 WHERE m3.order_id = o.id AND m3.chat_type = ?
               ORDER BY m3.created_at DESC LIMIT 1) as last_sender,
              (SELECT m4.created_at FROM messages m4 WHERE m4.order_id = o.id AND m4.chat_type = ?
               ORDER BY m4.created_at DESC LIMIT 1) as last_msg_at
       FROM \`Order\` o
       JOIN restaurant r ON r.id = o.restaurantId
       LEFT JOIN customer c ON c.id = o.customerId
       WHERE ${where}
       ORDER BY COALESCE(
         (SELECT m5.created_at FROM messages m5 WHERE m5.order_id = o.id AND m5.chat_type = ?
          ORDER BY m5.created_at DESC LIMIT 1), o.createdAt) DESC`,
      [chatType, chatType, chatType, chatType, userId, chatType]
    );
    res.json(rows);
  } catch (e) {
    console.error('[chat conversations]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// POST upload image for chat
router.post('/:orderId/upload', upload.single('image'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'no file' });
  res.json({ url: `/uploads/chat/${req.file.filename}` });
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
    await ensureImageCol();

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
