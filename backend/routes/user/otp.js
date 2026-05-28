const express = require('express');
const router  = express.Router();
const https   = require('https');
const qs      = require('querystring');

// phone → { code, expiresAt }
const otpStore = new Map();

function genCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendSms(phone, code) {
  const user = process.env.THAIBULKSMS_USER;
  const pass = process.env.THAIBULKSMS_PASS;

  if (!user || !pass) {
    // Dev mode: OTP แสดงใน console แทนการส่ง SMS จริง
    console.log(`\n[OTP DEV]  phone=${phone}  code=${code}\n`);
    return;
  }

  const msisdn  = phone.startsWith('0') ? '66' + phone.slice(1) : phone;
  const message = `รหัส OTP ของคุณคือ ${code} หมดอายุใน 2 นาที`;
  const body    = qs.stringify({ username: user, password: pass, sender: 'ZestSavory', msisdn, message });

  await new Promise((resolve) => {
    const req = https.request(
      {
        hostname: 'www.thaibulksms.com',
        path: '/api/sms/send',
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(body) },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end',  () => { console.log('[SMS]', data); resolve(); });
      }
    );
    req.on('error', (e) => { console.error('[SMS Error]', e.message); resolve(); });
    req.write(body);
    req.end();
  });
}

// POST /api/otp/send
router.post('/send', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'phone required' });

  const code = genCode();
  otpStore.set(phone, { code, expiresAt: Date.now() + 2 * 60 * 1000 });

  await sendSms(phone, code);
  res.json({ success: true });
});

// POST /api/otp/verify
router.post('/verify', (req, res) => {
  const { phone, code } = req.body;
  if (!phone || !code) return res.status(400).json({ error: 'phone and code required' });

  const entry = otpStore.get(phone);
  if (!entry) return res.status(400).json({ error: 'otp_not_found' });
  if (Date.now() > entry.expiresAt) {
    otpStore.delete(phone);
    return res.status(400).json({ error: 'otp_expired' });
  }
  if (entry.code !== code) return res.status(400).json({ error: 'otp_invalid' });

  otpStore.delete(phone);
  res.json({ success: true });
});

module.exports = router;
