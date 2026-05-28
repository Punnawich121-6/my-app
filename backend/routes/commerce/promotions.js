const express = require('express');
const router  = express.Router();
const db      = require('../../db');
const { analyzeStore } = require('../../services/smartPromo');

async function ensureTables() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS smart_promotions (
      id               INT AUTO_INCREMENT PRIMARY KEY,
      store_id         VARCHAR(36) NOT NULL,
      trigger_type     VARCHAR(50),
      promo_type       VARCHAR(50),
      title            VARCHAR(255),
      description      TEXT,
      discount_type    VARCHAR(50),
      discount_value   DECIMAL(10,2) DEFAULT 0,
      min_order_amount DECIMAL(10,2) DEFAULT 0,
      coupon_code      VARCHAR(50),
      duration_minutes INT DEFAULT 120,
      status           ENUM('pending_approval','active','completed','rejected') DEFAULT 'pending_approval',
      ai_reasoning     TEXT,
      expected_revenue DECIMAL(10,2) DEFAULT 0,
      expected_cost    DECIMAL(10,2) DEFAULT 0,
      actual_orders    INT DEFAULT 0,
      actual_revenue   DECIMAL(10,2) DEFAULT 0,
      starts_at        TIMESTAMP NULL,
      ends_at          TIMESTAMP NULL,
      pending_until    TIMESTAMP NULL,
      approved_at      TIMESTAMP NULL,
      approved_by      VARCHAR(50),
      created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  `);
}

async function migrateStoreId() {
  try {
    const [[col]] = await db.query(
      `SELECT DATA_TYPE FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'smart_promotions' AND COLUMN_NAME = 'store_id'`
    );
    if (col && col.DATA_TYPE !== 'varchar') {
      await db.query(`ALTER TABLE smart_promotions MODIFY store_id VARCHAR(36) NOT NULL`);
    }
  } catch (e) {
    console.error('[promotions] migrateStoreId error:', e.message);
  }
}

ensureTables()
  .then(migrateStoreId)
  .catch(e => console.error('[promotions] ensureTables error:', e.sqlMessage || e.message || e));

router.post('/:storeId/analyze', async (req, res) => {
  try {
    const { storeId } = req.params;

    const [[existing]] = await db.query(
      "SELECT id FROM smart_promotions WHERE store_id = ? AND status IN ('pending_approval','active') LIMIT 1",
      [storeId]
    );
    if (existing) {
      return res.json({ shouldCreate: false, reason: 'promo_exists' });
    }

    const result = await analyzeStore(storeId);
    if (!result) return res.json({ shouldCreate: false, reason: 'ai_error' });

    if (!result.shouldCreate) {
      return res.json({ shouldCreate: false, reasoning: result.reasoning });
    }

    const [ins] = await db.query(
      `INSERT INTO smart_promotions
         (store_id, trigger_type, promo_type, title, description,
          discount_type, discount_value, duration_minutes,
          status, ai_reasoning, expected_revenue, expected_cost)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending_approval', ?, ?, ?)`,
      [
        storeId,
        result.triggerType    || 'low_sales',
        result.promoType      || 'discount',
        result.title          || 'โปรโมชั่นพิเศษ',
        result.description    || '',
        result.discountType   || 'percentage',
        result.discountValue  || 10,
        result.durationMinutes || 120,
        result.reasoning      || '',
        result.expectedRevenue || 0,
        result.expectedCost    || 0,
      ]
    );

    const [[promo]] = await db.query(
      'SELECT * FROM smart_promotions WHERE id = ?',
      [ins.insertId]
    );

    const io = req.app.get('io');
    if (io) io.to(`store_${storeId}`).emit('promo_suggestion', promo);

    res.json(promo);
  } catch (err) {
    console.error('[promotions] analyze error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.get('/:storeId', async (req, res) => {
  try {
    const { storeId } = req.params;

    const [rows] = await db.query(
      'SELECT * FROM smart_promotions WHERE store_id = ? ORDER BY created_at DESC',
      [storeId]
    );

    const grouped = { pending: [], active: [], completed: [], rejected: [] };
    for (const row of rows) {
      if (row.status === 'pending_approval') grouped.pending.push(row);
      else if (row.status === 'active')       grouped.active.push(row);
      else if (row.status === 'completed')    grouped.completed.push(row);
      else if (row.status === 'rejected')     grouped.rejected.push(row);
    }

    res.json(grouped);
  } catch (err) {
    console.error('[promotions] get error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;

    const [[promo]] = await db.query(
      'SELECT * FROM smart_promotions WHERE id = ? LIMIT 1',
      [id]
    );
    if (!promo) return res.status(404).json({ error: 'Not found' });

    await db.query(
      `UPDATE smart_promotions
       SET status = 'active',
           starts_at   = NOW(),
           ends_at     = DATE_ADD(NOW(), INTERVAL duration_minutes MINUTE),
           approved_at = NOW(),
           approved_by = 'owner'
       WHERE id = ?`,
      [id]
    );

    const [[updated]] = await db.query(
      'SELECT * FROM smart_promotions WHERE id = ?',
      [id]
    );

    const io = req.app.get('io');
    if (io) io.to(`store_${promo.store_id}`).emit('promo_activated', updated);

    res.json(updated);
  } catch (err) {
    console.error('[promotions] approve error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    await db.query(
      "UPDATE smart_promotions SET status = 'rejected' WHERE id = ?",
      [id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('[promotions] reject error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [[promo]] = await db.query('SELECT id FROM smart_promotions WHERE id = ? LIMIT 1', [id]);
    if (!promo) return res.status(404).json({ error: 'Not found' });
    await db.query('DELETE FROM smart_promotions WHERE id = ?', [id]);
    res.json({ success: true });
  } catch (err) {
    console.error('[promotions] delete error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/:storeId/finalize', async (req, res) => {
  try {
    const { storeId } = req.params;

    const [expired] = await db.query(
      "SELECT * FROM smart_promotions WHERE store_id = ? AND status = 'active' AND ends_at < NOW()",
      [storeId]
    );

    for (const promo of expired) {
      const [[stats]] = await db.query(
        `SELECT COUNT(*) AS cnt, COALESCE(SUM(totalAmount), 0) AS rev
         FROM \`Order\`
         WHERE restaurantId = ? AND createdAt BETWEEN ? AND ? AND status NOT IN ('cancelled')`,
        [storeId, promo.starts_at, promo.ends_at]
      );

      await db.query(
        `UPDATE smart_promotions
         SET status = 'completed', actual_orders = ?, actual_revenue = ?
         WHERE id = ?`,
        [stats.cnt, stats.rev, promo.id]
      );
    }

    res.json({ finalized: expired.length });
  } catch (err) {
    console.error('[promotions] finalize error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
