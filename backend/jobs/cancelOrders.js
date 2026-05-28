const db = require('../db');

const ACTIVE_STATUSES = ['pending', 'accepted', 'preparing', 'ready', 'delivering', 'delayed'];
const STALE_MINUTES   = 15; // pending > 15 นาที = ยังไม่ได้จ่าย

async function cancelStaleOrders(io) {
    // 1. cancel order ที่ค้างชำระ (pending > 15 นาที)
    const [stale] = await db.query(
        `SELECT id FROM \`order\`
         WHERE LOWER(status) = 'pending'
           AND createdAt < DATE_SUB(NOW(), INTERVAL ? MINUTE)`,
        [STALE_MINUTES]
    );

    // 2. cancel order ทุก active status ที่สร้างก่อนวันนี้
    const [old] = await db.query(
        `SELECT id FROM \`order\`
         WHERE LOWER(status) IN (${ACTIVE_STATUSES.map(() => '?').join(',')})
           AND DATE(createdAt) < CURDATE()`,
        ACTIVE_STATUSES
    );

    const ids = [...new Set([...stale, ...old].map(r => r.id))];
    if (ids.length === 0) return;

    await db.query(
        `UPDATE \`order\` SET status = 'cancelled'
         WHERE id IN (${ids.map(() => '?').join(',')})`,
        ids
    );

    if (io) {
        for (const id of ids) {
            io.to(`order_${id}`).emit('order_updated',       { order_id: id, status: 'cancelled' });
            io.to('admin').emit('order_status_changed', { order_id: id, status: 'cancelled' });
        }
    }

    console.log(`[cancelOrders] cancelled ${ids.length} order(s):`, ids);
}

function startCancelJob(io) {
    // รันทันทีตอน boot แล้วทุก 1 นาที
    cancelStaleOrders(io).catch(e => console.error('[cancelOrders] boot error:', e.sqlMessage || e.message || e));
    setInterval(() => {
        cancelStaleOrders(io).catch(e => console.error('[cancelOrders] error:', e.message));
    }, 60 * 1000);
}

module.exports = { startCancelJob };
