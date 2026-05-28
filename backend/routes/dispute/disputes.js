const express  = require('express');
const router   = express.Router();
const db       = require('../../db');
const multer   = require('multer');
const path     = require('path');
const fs       = require('fs');
const { analyzeDispute } = require('../../services/disputeAI');

// ── Upload setup ──────────────────────────────────────────────────────────────
const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'disputes');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename:    (req, file, cb) => {
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname)}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

// ── Table bootstrap ───────────────────────────────────────────────────────────
let _ready = false;
async function ensureTables() {
  if (_ready) return;
  await db.query(`
    CREATE TABLE IF NOT EXISTS disputes (
      id                    INT AUTO_INCREMENT PRIMARY KEY,
      order_id              VARCHAR(255),
      order_number          VARCHAR(255),
      customer_id           VARCHAR(255),
      customer_name         VARCHAR(255),
      restaurant_name       VARCHAR(255),
      rider_name            VARCHAR(255),
      reason_type           VARCHAR(50)  DEFAULT 'other',
      description           TEXT,
      evidence_urls         TEXT,
      status                ENUM('analyzing','auto_resolved','pending_review','escalated','admin_resolved','closed')
                            DEFAULT 'analyzing',
      confidence_score      DECIMAL(5,2),
      ai_verdict            VARCHAR(50),
      ai_fault_party        VARCHAR(50),
      ai_reasoning          TEXT,
      refund_type           ENUM('full','partial','none') DEFAULT 'none',
      refund_amount         DECIMAL(10,2) DEFAULT 0,
      admin_override_verdict VARCHAR(100),
      admin_override_notes  TEXT,
      created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      resolved_at           TIMESTAMP NULL,
      resolved_by           VARCHAR(100),
      INDEX idx_order   (order_id),
      INDEX idx_status  (status),
      INDEX idx_created (created_at)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `);
  await db.query(`
    CREATE TABLE IF NOT EXISTS dispute_actions (
      id          INT AUTO_INCREMENT PRIMARY KEY,
      dispute_id  INT NOT NULL,
      action_type VARCHAR(100),
      actor_role  VARCHAR(50),
      notes       TEXT,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_dispute (dispute_id)
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `);
  _ready = true;
}

// ── Autopilot ─────────────────────────────────────────────────────────────────
async function runAutopilot(disputeId, evidence, io) {
  try {
    const { confidence, verdict, faultParty, refundType, refundPercentage, reasoning } = await analyzeDispute(evidence);

    const refundAmount = refundType === 'full'
      ? evidence.totalAmount
      : refundType === 'partial'
      ? parseFloat(((evidence.totalAmount * refundPercentage) / 100).toFixed(2))
      : 0;

    const newStatus = confidence >= 80 ? 'auto_resolved'
      : confidence >= 60 ? 'pending_review'
      : 'escalated';

    await db.query(`
      UPDATE disputes SET
        confidence_score = ?, ai_verdict = ?, ai_fault_party = ?, ai_reasoning = ?,
        refund_type = ?, refund_amount = ?, status = ?,
        resolved_at = IF(? = 'auto_resolved', NOW(), NULL),
        resolved_by = IF(? = 'auto_resolved', 'AI Autopilot', NULL)
      WHERE id = ?
    `, [confidence, verdict, faultParty, reasoning, refundType, refundAmount,
        newStatus, newStatus, newStatus, disputeId]);

    const noteMap = {
      auto_resolved: `AI ตัดสินอัตโนมัติ (confidence ${confidence}%) — ${verdict}. คืนเงิน: ${refundType} (฿${refundAmount})`,
      pending_review: `AI วิเคราะห์แล้ว (confidence ${confidence}%) — รอ admin ตรวจสอบ`,
      escalated: `AI ไม่แน่ใจ (confidence ${confidence}%) — escalate ให้ admin ด่วน`,
    };
    await db.query(
      'INSERT INTO dispute_actions (dispute_id, action_type, actor_role, notes) VALUES (?,?,?,?)',
      [disputeId, newStatus === 'auto_resolved' ? 'auto_resolve' : newStatus === 'pending_review' ? 'queue_review' : 'escalate',
       'AI', noteMap[newStatus]]
    );

    io?.to('admin').emit('dispute_updated', { disputeId, status: newStatus, confidence, verdict });
    console.log(`[Autopilot] Dispute #${disputeId}: confidence=${confidence}% → ${newStatus}`);
  } catch (err) {
    console.error('[Autopilot] Error:', err.message);
    await db.query(
      "UPDATE disputes SET status='escalated', ai_reasoning=? WHERE id=?",
      ['เกิดข้อผิดพลาดในการวิเคราะห์ กรุณา admin ตรวจสอบ', disputeId]
    );
    io?.to('admin').emit('dispute_updated', { disputeId, status: 'escalated' });
  }
}

// ── Routes ────────────────────────────────────────────────────────────────────

// POST /api/disputes — Customer files a dispute
router.post('/', upload.array('evidence', 5), async (req, res) => {
  try {
    await ensureTables();
    console.log('[disputes POST] content-type:', req.headers['content-type']);
    console.log('[disputes POST] body:', JSON.stringify(req.body));
    const { orderId, customerId, reasonType = 'other', description = '' } = req.body;
    if (!orderId || !customerId) return res.status(400).json({ error: 'orderId and customerId required' });

    // Pull order + related data
    const [[order]] = await db.query(`
      SELECT o.id, o.orderNumber, o.status, o.totalAmount, o.serviceFee, o.createdAt,
             r.name AS restaurantName,
             c.name AS customerName,
             ri.name AS riderName
      FROM \`Order\` o
      LEFT JOIN Restaurant r  ON o.restaurantId = r.id
      LEFT JOIN Customer   c  ON o.customerId   = c.id
      LEFT JOIN Rider      ri ON o.riderId       = ri.id
      WHERE o.id = ?
    `, [orderId]);
    if (!order) return res.status(404).json({ error: 'Order not found' });

    const [items] = await db.query('SELECT name, price, quantity FROM order_items WHERE order_id = ?', [orderId]);
    const [[hist]] = await db.query('SELECT COUNT(*) AS cnt FROM disputes WHERE customer_id = ?', [customerId]);
    const orderAge = Math.round((Date.now() - new Date(order.createdAt).getTime()) / 60000);
    const evidenceUrls = (req.files || []).map(f => `/uploads/disputes/${f.filename}`);

    const [result] = await db.query(`
      INSERT INTO disputes
        (order_id, order_number, customer_id, customer_name, restaurant_name, rider_name,
         reason_type, description, evidence_urls, status)
      VALUES (?,?,?,?,?,?,?,?,?,'analyzing')
    `, [orderId, order.orderNumber, customerId, order.customerName,
        order.restaurantName, order.riderName || null,
        reasonType, description, JSON.stringify(evidenceUrls)]);

    const disputeId = result.insertId;
    await db.query(
      'INSERT INTO dispute_actions (dispute_id, action_type, actor_role, notes) VALUES (?,?,?,?)',
      [disputeId, 'created', 'customer', `ลูกค้าแจ้งปัญหา: ${reasonType}`]
    );

    const io = req.app.get('io');
    io?.to('admin').emit('new_dispute', { disputeId, reasonType, customerName: order.customerName });

    const evidenceData = {
      orderNumber: order.orderNumber, reasonType, description,
      orderStatus: order.status, orderItems: items,
      totalAmount: parseFloat(order.totalAmount),
      orderAge, customerDisputeCount: Number(hist?.cnt || 0),
      restaurantName: order.restaurantName, riderName: order.riderName || null,
      hasPhoto: evidenceUrls.length > 0,
    };
    setImmediate(() => runAutopilot(disputeId, evidenceData, io));

    res.status(201).json({ id: disputeId, status: 'analyzing' });
  } catch (e) {
    console.error('[disputes POST]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// GET /api/disputes/stats
router.get('/stats', async (req, res) => {
  try {
    await ensureTables();
    const [[stats]] = await db.query(`
      SELECT
        COUNT(*)                                                           AS total,
        SUM(status = 'auto_resolved')                                      AS auto_resolved,
        SUM(status = 'pending_review')                                     AS pending_review,
        SUM(status = 'escalated')                                          AS escalated,
        SUM(status = 'admin_resolved')                                     AS admin_resolved,
        SUM(status = 'analyzing')                                          AS analyzing,
        SUM(CASE WHEN refund_type != 'none' THEN refund_amount ELSE 0 END) AS total_refunded,
        ROUND(AVG(confidence_score), 1)                                    AS avg_confidence
      FROM disputes
    `);
    res.json(stats);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/disputes — List disputes (admin)
router.get('/', async (req, res) => {
  try {
    await ensureTables();
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const params = [];
    let where = '';
    if (status && status !== 'all') { where = 'WHERE status = ?'; params.push(status); }

    const [[countRow]] = await db.query(`SELECT COUNT(*) AS total FROM disputes ${where}`, params);
    const [rows] = await db.query(
      `SELECT id, order_id, order_number, customer_name, restaurant_name, rider_name,
              reason_type, status, confidence_score, ai_verdict, ai_fault_party,
              refund_type, refund_amount, created_at, resolved_at
       FROM disputes ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, Number(limit), offset]
    );
    res.json({ disputes: rows, total: countRow.total, page: Number(page), limit: Number(limit) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/disputes/:id — Detail
router.get('/:id', async (req, res) => {
  try {
    await ensureTables();
    const [[dispute]] = await db.query('SELECT * FROM disputes WHERE id = ?', [req.params.id]);
    if (!dispute) return res.status(404).json({ error: 'Not found' });
    const [actions] = await db.query(
      'SELECT * FROM dispute_actions WHERE dispute_id = ? ORDER BY created_at ASC',
      [req.params.id]
    );
    res.json({ ...dispute, actions });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/disputes/:id/override — Admin override
router.put('/:id/override', async (req, res) => {
  try {
    await ensureTables();
    const { verdict, notes, refundType = 'none', refundAmount = 0 } = req.body;
    await db.query(`
      UPDATE disputes SET
        status = 'admin_resolved', admin_override_verdict = ?, admin_override_notes = ?,
        refund_type = ?, refund_amount = ?, resolved_at = NOW(), resolved_by = 'admin'
      WHERE id = ?
    `, [verdict, notes, refundType, refundAmount, req.params.id]);

    await db.query(
      'INSERT INTO dispute_actions (dispute_id, action_type, actor_role, notes) VALUES (?,?,?,?)',
      [req.params.id, 'admin_override', 'admin', `Admin ตัดสิน: ${verdict}. ${notes || ''}`]
    );

    const io = req.app.get('io');
    io?.to('admin').emit('dispute_updated', { disputeId: req.params.id, status: 'admin_resolved' });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
