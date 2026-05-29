const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// ── PromptPay QR (v2 API) ──────────────────────────────────────────────────
const DIGIPAY_URL  = 'https://octopus-unify.digipay.dev/v2/payment';
const API_ID       = process.env.DIGIPAY_API_ID;
const API_KEY      = process.env.DIGIPAY_API_KEY;
const PARTNER_ID   = process.env.DIGIPAY_PARTNER_ID;
const MERCHANT_ID  = process.env.DIGIPAY_MERCHANT_ID;
const SIGN_KEY     = Buffer.from(process.env.DIGIPAY_SIGN_KEY, 'base64');

// ── Credit Card / Bank (v1 Redirect API) ───────────────────────────────────
// Use CARD_* env vars if set, otherwise fall back to the same credentials used by QR
const CARD_API_ID      = process.env.CARD_API_ID      || process.env.DIGIPAY_API_ID;
const CARD_API_KEY     = process.env.CARD_API_KEY      || process.env.DIGIPAY_API_KEY;
const CARD_MERCHANT_ID = process.env.CARD_MERCHANT_ID  || process.env.DIGIPAY_MERCHANT_ID;
// v1 sign key is the raw string from the portal (same value stored in DIGIPAY_SIGN_KEY env)
const CARD_SIGN_KEY    = process.env.CARD_SIGN_KEY     || process.env.DIGIPAY_SIGN_KEY;
const BACKEND_URL      = process.env.BACKEND_URL       || 'http://localhost:3001';

// SHA256(merchant_id.order_id.amount.card_masking.term_month.card_issuer + sign_key)
// Per DigiPay v1 spec — amount must be the same string sent in the form field
function cardSign(merchantId, orderId, amount, cardMasking = '', termMonth = '', cardIssuer = '') {
  const data = `${merchantId}.${orderId}.${amount}.${cardMasking}.${termMonth}.${cardIssuer}`;
  return crypto.createHash('sha256').update(data + CARD_SIGN_KEY).digest('hex');
}

// Verify incoming notify/callback sign
function verifyCardSign(dataObj, receivedSign) {
  const values = Object.values(dataObj).map(v => (v === null || v === undefined) ? '' : String(v));
  const data = values.join('');
  const expected = crypto.createHash('sha256').update(data + CARD_SIGN_KEY).digest('hex');
  return expected === receivedSign;
}

// In-memory card payment sessions (keyed by token, expires after 30 min)
const _cardSessions = new Map();
setInterval(() => {
  const cutoff = Date.now() - 30 * 60 * 1000;
  for (const [k, v] of _cardSessions) {
    if (v.createdAt < cutoff) _cardSessions.delete(k);
  }
}, 5 * 60 * 1000);

function dbOrderId(digipayId) {
  return typeof digipayId === 'string' && digipayId.startsWith('ORD')
    ? digipayId.slice(3)
    : digipayId;
}

function sign(body) {
  return crypto
    .createHmac('sha256', SIGN_KEY)
    .update(JSON.stringify(body))
    .digest('base64');
}

// GET /api/payment/test-sign — verify signature matches Postman
router.get('/test-sign', (req, res) => {
  const testBody = { mid: '2756498347', order_id: 'Test1022', description: 'Boba Milk Tea', amount: 100.55 };
  const bodyString = JSON.stringify(testBody);
  const signature = sign(testBody);
  console.log('[Test Body String]', bodyString);
  console.log('[Test Signature]', signature);
  res.json({ bodyString, signature });
});

// POST /api/payment/qr  — create PromptPay QR
router.post('/qr', async (req, res) => {
  try {
    const { order_id, amount, description } = req.body;

    const body = {
      mid: MERCHANT_ID,
      order_id: `ORD${order_id}`,
      description: description || 'Food Order',
      amount: Number(parseFloat(amount).toFixed(2)),
      url_notify: `${BACKEND_URL}/api/payment/notify`,
    };
    const bodyString = JSON.stringify(body);
    const signature = sign(body);
    console.log('[Body String]', bodyString);
    console.log('[Signature]', signature);

    const response = await fetch(DIGIPAY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-ID': API_ID,
        'X-API-Key': API_KEY,
        'X-Partner-ID': PARTNER_ID,
        'X-Content-Signature': signature,
        'Accept-Language': 'th',
      },
      body: bodyString,
    });

    const data = await response.json();
    console.log('[DigiPay response]', JSON.stringify(data, null, 2));
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/payment/card  — create card payment via v2 API (returns redirect_url)
router.post('/card', async (req, res) => {
  try {
    const { order_id, amount, description } = req.body;
    if (!order_id || !amount) {
      return res.status(400).json({ error: 'order_id and amount are required' });
    }

    const body = {
      mid: CARD_MERCHANT_ID,
      order_id: `ORD${order_id}`,
      description: description || 'Food Order',
      amount: Number(parseFloat(amount).toFixed(2)),
      url_notify:   `${BACKEND_URL}/api/payment/notify`,
      url_redirect: `${BACKEND_URL}/api/payment/callback`,
    };
    const bodyString = JSON.stringify(body);
    const signature = sign(body);

    const response = await fetch(DIGIPAY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-ID': API_ID,
        'X-API-Key': API_KEY,
        'X-Partner-ID': PARTNER_ID,
        'X-Content-Signature': signature,
        'Accept-Language': 'th',
      },
      body: bodyString,
    });

    const data = await response.json();
    console.log('[Card v2 response]', JSON.stringify(data, null, 2));

    if (!data.redirect_url) {
      return res.status(500).json({ error: data.res_desc || 'No redirect URL' });
    }

    res.json({ form_url: data.redirect_url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/payment/card-form/:token  — serve auto-submit form to browser
router.get('/card-form/:token', (req, res) => {
  const session = _cardSessions.get(req.params.token);
  if (!session) {
    return res.status(404).send('<h3>Session not found or expired. Please try again in the app.</h3>');
  }
  const { order_id, description } = session;
  // Format amount as 2-decimal string — spec requires "5000.00" format
  // and the sign must be computed with the exact same string sent in the form field
  const amount = parseFloat(session.amount).toFixed(2);
  const sign = cardSign(CARD_MERCHANT_ID, order_id, amount);

  res.send(`<!DOCTYPE html>
<html>
<head>
  <title>Redirecting to DigiPay...</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;
         min-height:100vh;margin:0;background:#f5f5f5;}
    .box{text-align:center;padding:32px;background:#fff;border-radius:16px;
         box-shadow:0 4px 20px rgba(0,0,0,.08);}
    .spinner{width:40px;height:40px;border:4px solid #eee;border-top-color:#FF6B35;
             border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 16px;}
    @keyframes spin{to{transform:rotate(360deg)}}
    p{color:#666;margin:0}
  </style>
</head>
<body>
<div class="box">
  <div class="spinner"></div>
  <p>กำลังเปลี่ยนเส้นทางไปยังหน้าชำระเงิน...</p>
</div>
<form id="f" action="https://octopus-unify.digipay.dev/api/v1/redirect/sale" method="POST">
  <input type="hidden" name="api_id"              value="${CARD_API_ID}">
  <input type="hidden" name="api_key"             value="${CARD_API_KEY}">
  <input type="hidden" name="merchant_id"         value="${CARD_MERCHANT_ID}">
  <input type="hidden" name="order_id"            value="${order_id}">
  <input type="hidden" name="amount"              value="${amount}">
  <input type="hidden" name="payment_type"        value="FULL">
  <input type="hidden" name="url_redirect"        value="${BACKEND_URL}/api/payment/callback">
  <input type="hidden" name="url_notify"          value="${BACKEND_URL}/api/payment/notify">
  <input type="hidden" name="payment_description" value="${description}">
  <input type="hidden" name="sign"                value="${sign}">
</form>
<script>document.getElementById('f').submit();</script>
</body>
</html>`);
});

// GET|POST /api/payment/callback  — DigiPay redirects browser here after payment
router.all('/callback', (req, res) => {
  const params = { ...req.query, ...req.body };
  const { reference, process_status, order_id } = params;
  const io = req.app.get('io');
  const success = process_status === 'true';
  const oid = dbOrderId(order_id);

  if (io && oid) {
    io.to(`order_${oid}`).emit('payment_status', {
      order_id: oid,
      status: success ? 'APPROVED' : 'FAILED',
      reference: reference || null,
    });
  }

  res.send(`<!DOCTYPE html>
<html>
<head>
  <title>${success ? 'Payment Successful' : 'Payment Failed'}</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;
         min-height:100vh;margin:0;background:#f5f5f5;}
    .card{text-align:center;padding:40px 32px;background:#fff;border-radius:20px;
          box-shadow:0 4px 24px rgba(0,0,0,.1);max-width:360px;width:90%;}
    .icon{font-size:64px;margin-bottom:16px;}
    h2{margin:0 0 8px;color:${success ? '#4CAF50' : '#f44336'}}
    p{color:#666;margin:0 0 8px;font-size:14px;}
    .ref{color:#aaa;font-size:12px}
  </style>
</head>
<body>
<div class="card">
  <div class="icon">${success ? '✅' : '❌'}</div>
  <h2>${success ? 'ชำระเงินสำเร็จ!' : 'ชำระเงินไม่สำเร็จ'}</h2>
  <p>${success ? 'คำสั่งซื้อของคุณได้รับการยืนยันแล้ว<br>กรุณากลับไปที่แอปพลิเคชัน' : 'ไม่สามารถดำเนินการชำระเงินได้<br>กรุณาลองใหม่ในแอปพลิเคชัน'}</p>
  ${reference ? `<p class="ref">Reference: ${reference}</p>` : ''}
</div>
</body>
</html>`);
});

function verifyQrSign(rawBody, receivedSign) {
  const expected = crypto.createHmac('sha256', SIGN_KEY).update(rawBody).digest('base64');
  return expected === receivedSign;
}

// POST /api/payment/notify  — webhook called by DigiPay after payment (QR & Card)
router.all('/notify', (req, res) => {
  const io = req.app.get('io');

  // Card payment notify: { data: { order_id, status, reference, ... }, sign }
  if (req.body?.data?.order_id) {
    if (!verifyCardSign(req.body.data, req.body.sign)) {
      console.warn('[payment/notify] card signature mismatch — rejected');
      return res.status(401).json({ ok: false });
    }
    const oid = dbOrderId(req.body.data.order_id);
    const { status, reference } = req.body.data;
    if (io) io.to(`order_${oid}`).emit('payment_status', { order_id: oid, status, reference: reference || null });
    return res.json({ ok: true });
  }

  // QR payment notify: { order_id, status, reference }
  const receivedSign = req.headers['x-content-signature'];
  console.log('[payment/notify] QR raw body:', req.rawBody?.toString());
  console.log('[payment/notify] X-Content-Signature:', receivedSign);
  if (!receivedSign || !verifyQrSign(req.rawBody, receivedSign)) {
    console.warn('[payment/notify] QR signature mismatch — rejected');
    return res.status(401).json({ ok: false });
  }
  const { order_id, status, reference } = req.body;
  const oid = dbOrderId(order_id);
  if (io && oid) {
    io.to(`order_${oid}`).emit('payment_status', { order_id: oid, status, reference: reference || null });
  }
  res.json({ ok: true });
});

module.exports = router;
