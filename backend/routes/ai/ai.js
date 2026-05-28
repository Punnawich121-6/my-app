const express = require('express');
const router = express.Router();
const OpenAI = require('openai');

const client = new OpenAI({
  baseURL: 'https://gen.ai.kku.ac.th/api/v1',
  apiKey: 'sk_SderG5Z7noy9obK7wKq4oD5pcSK3Y5mWM09wn9icKNa9qwJBhmJqaJe9JakO29Ti', // ← วาง API Key ของคุณที่นี่
});


router.post('/scan-food', async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'ไม่พบรูปภาพ' });

    const base64Data = image.includes(',') ? image.split(',')[1] : image;
    const mediaType = image.startsWith('data:image/png') ? 'image/png' : 'image/jpeg';

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        {
          role: 'system',
          content: 'คุณเป็นผู้เชี่ยวชาญด้านโภชนาการ วิเคราะห์อาหารจากภาพและให้ข้อมูลโภชนาการที่แม่นยำ ตอบเป็น JSON เท่านั้น',
        },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: `data:${mediaType};base64,${base64Data}` },
            },
            {
              type: 'text',
              text: `วิเคราะห์อาหารในภาพและประเมินคุณค่าโภชนาการ ตอบเป็น JSON เท่านั้น ไม่มีข้อความอื่น:
{
  "foodName": "ชื่ออาหาร (ภาษาไทย)",
  "foodNameEn": "Food name (English)",
  "description": "คำอธิบาย 1-2 ประโยค (ภาษาไทย)",
  "servingSize": "ปริมาณต่อ 1 ที่ เช่น '1 จาน (~350g)'",
  "calories": 0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0,
  "fiber": 0.0,
  "sugar": 0.0,
  "sodium": 0,
  "healthScore": 0,
  "healthNote": "คำแนะนำด้านสุขภาพ (ภาษาไทย)"
}
หน่วย: calories=kcal, protein/carbs/fat/fiber/sugar=กรัม, sodium=มิลลิกรัม, healthScore=1-10 (10=ดีที่สุด)
ถ้าไม่เห็นอาหารในภาพชัดเจน ตอบ: {"error": "ไม่พบอาหารในภาพ กรุณาถ่ายภาพใหม่"}`,
            },
          ],
        },
      ],
    });

    const text = completion.choices[0].message.content.trim();
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return res.status(500).json({ error: 'ไม่สามารถวิเคราะห์ได้ กรุณาลองใหม่' });

    res.json(JSON.parse(match[0]));
  } catch (err) {
    console.error('scan-food error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' });
  }
});

router.post('/match-food', async (req, res) => {
  try {
    const db = require('../../db');
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'ไม่พบรูปภาพ' });

    const base64Data = image.includes(',') ? image.split(',')[1] : image;
    const mediaType = image.startsWith('data:image/png') ? 'image/png' : 'image/jpeg';

    // Step 1: AI identifies food name + keywords
    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        { role: 'system', content: 'ระบุชื่ออาหารจากภาพ ตอบเป็น JSON เท่านั้น ไม่มีข้อความอื่น' },
        {
          role: 'user',
          content: [
            { type: 'image_url', image_url: { url: `data:${mediaType};base64,${base64Data}` } },
            {
              type: 'text',
              text: `ระบุชื่ออาหารในภาพ ตอบ JSON:
{
  "foodName": "ชื่ออาหารหลักภาษาไทย",
  "keywords": ["คำค้นหา1", "คำค้นหา2", "คำค้นหา3"]
}
keywords = ชื่อเรียกอื่น ชื่อย่อ หรือส่วนประกอบหลัก 3-5 คำ
ถ้าไม่มีอาหารในภาพ: {"error": "ไม่พบอาหารในภาพ กรุณาถ่ายใหม่"}`,
            },
          ],
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return res.status(500).json({ error: 'ไม่สามารถวิเคราะห์ได้' });

    const identified = JSON.parse(jsonMatch[0]);
    if (identified.error) return res.json({ identified: null, matches: [], message: identified.error });

    // Step 2: Search DB with keywords
    const keywords = [identified.foodName, ...(identified.keywords || [])].filter(Boolean).slice(0, 6);
    const conditions = keywords.map(() => 'mi.name LIKE ?').join(' OR ');
    const params = keywords.map(k => `%${k}%`);

    const [rows] = await db.query(`
      SELECT mi.id, mi.name, mi.price, mi.image_url, mi.description,
             r.id AS store_id, r.name AS store_name, r.category AS store_type,
             r.imageUrl AS store_image, r.address AS store_address,
             COALESCE(r.rating, 0) AS store_rating
      FROM menu_items mi
      JOIN restaurant r ON mi.store_id = r.id
      WHERE mi.is_available = 1 AND r.status = 'active'
        AND (${conditions})
      ORDER BY r.rating DESC
      LIMIT 20
    `, params);

    res.json({
      identified: identified.foodName,
      matches: rows.map(r => ({
        item: { id: r.id, name: r.name, price: r.price, image_url: r.image_url, description: r.description },
        store: { id: r.store_id, name: r.store_name, type: r.store_type, image_url: r.store_image, address: r.store_address, rating: r.store_rating, is_open: 1 },
      })),
    });
  } catch (err) {
    console.error('match-food error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' });
  }
});

router.post('/match-food-text', async (req, res) => {
  try {
    const db = require('../../db');
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: 'ไม่พบชื่ออาหาร' });

    const keywords = [name];
    const conditions = keywords.map(() => 'mi.name LIKE ?').join(' OR ');
    const params = keywords.map(k => `%${k}%`);

    const [rows] = await db.query(`
      SELECT mi.id, mi.name, mi.price, mi.image_url, mi.description,
             r.id AS store_id, r.name AS store_name, r.category AS store_type,
             r.imageUrl AS store_image, r.address AS store_address,
             COALESCE(r.rating, 0) AS store_rating
      FROM menu_items mi
      JOIN restaurant r ON mi.store_id = r.id
      WHERE mi.is_available = 1 AND r.status = 'active'
        AND (${conditions})
      ORDER BY r.rating DESC
      LIMIT 20
    `, params);

    res.json({
      identified: name,
      matches: rows.map(r => ({
        item: { id: r.id, name: r.name, price: r.price, image_url: r.image_url, description: r.description },
        store: { id: r.store_id, name: r.store_name, type: r.store_type, image_url: r.store_image, address: r.store_address, rating: r.store_rating, is_open: 1 },
      })),
    });
  } catch (err) {
    console.error('match-food-text error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' });
  }
});

router.post('/suggest-food', async (req, res) => {
  try {
    const db = require('../../db');
    const { preference, excludeStoreId, excludeItemId, sameStoreId } = req.body;

    const baseSelect = `
      SELECT mi.id, mi.name, mi.description, mi.price, mi.image_url,
             r.id AS store_id, r.name AS store_name, r.category AS store_type,
             r.imageUrl AS store_image, r.address AS store_address,
             COALESCE(r.rating, 0) AS store_rating
      FROM menu_items mi
      JOIN restaurant r ON mi.store_id = r.id
      WHERE mi.is_available = 1 AND r.status = 'active'
    `;
    const baseParams = [];
    let baseWhere = '';
    if (sameStoreId)   { baseWhere += ' AND r.id = ?';  baseParams.push(sameStoreId); }
    if (excludeStoreId){ baseWhere += ' AND r.id != ?'; baseParams.push(excludeStoreId); }
    if (excludeItemId) { baseWhere += ' AND mi.id != ?'; baseParams.push(excludeItemId); }

    let items = [];
    let selected;

    if (preference && preference.trim()) {
      // 1st pass: find items whose name or description contains the preference keyword
      const pref = preference.trim();
      const keywords = pref.split(/\s+/).filter(k => k.length > 1);
      const likeClauses = keywords.map(() => '(mi.name LIKE ? OR mi.description LIKE ?)').join(' OR ');
      const likeParams = keywords.flatMap(k => [`%${k}%`, `%${k}%`]);

      if (likeClauses) {
        const [matched] = await db.query(
          `${baseSelect} ${baseWhere} AND (${likeClauses}) LIMIT 60`,
          [...baseParams, ...likeParams]
        );
        if (matched.length) items = matched;
      }

      // 2nd pass: fall back only when NOT doing a same-item search across stores
      if (!items.length) {
        if (excludeStoreId) return res.status(404).json({ error: 'ไม่มีเมนูนี้ที่ร้านอื่น' });
        const [all] = await db.query(`${baseSelect} ${baseWhere} ORDER BY RAND() LIMIT 60`, baseParams);
        items = all;
      }
      if (!items.length) return res.status(404).json({ error: 'ไม่พบเมนูอาหาร' });

      // If only 1 match, use it directly; otherwise let AI pick the best
      if (items.length === 1) {
        selected = items[0];
      } else {
        const list = items.slice(0, 60).map((it, i) =>
          `${i + 1}. ${it.name} (${it.store_name}) ฿${it.price}`
        ).join('\n');

        const completion = await client.chat.completions.create({
          model: 'gemini-2.5-flash-lite',
          stream: false,
          messages: [
            { role: 'system', content: 'เลือกเมนูที่ตรงกับความต้องการมากที่สุด ตอบแค่ตัวเลขลำดับเดียวเท่านั้น เช่น 3 ห้ามตอบอื่น' },
            { role: 'user', content: `ต้องการ: "${pref}"\n\n${list}` },
          ],
        });

        const raw = completion.choices[0].message.content.trim();
        const idx = parseInt(raw.match(/\d+/)?.[0] ?? '0') - 1;
        selected = (idx >= 0 && idx < items.length) ? items[idx] : items[0];
      }
    } else {
      const [all] = await db.query(`${baseSelect} ${baseWhere} ORDER BY RAND() LIMIT 60`, baseParams);
      items = all;
      if (!items.length) return res.status(404).json({ error: 'ไม่พบเมนูอาหาร' });
      selected = items[Math.floor(Math.random() * items.length)];
    }

    res.json({
      item: {
        id: selected.id, name: selected.name,
        description: selected.description, price: selected.price,
        image_url: selected.image_url,
      },
      store: {
        id: selected.store_id, name: selected.store_name,
        type: selected.store_type, image_url: selected.store_image,
        address: selected.store_address, rating: selected.store_rating,
        is_open: 1,
      },
    });
  } catch (err) {
    console.error('suggest-food error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' });
  }
});

router.post('/nutrition-by-name', async (req, res) => {
  try {
    const { foodName, storeName } = req.body;
    if (!foodName) return res.status(400).json({ error: 'ไม่พบชื่ออาหาร' });

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        {
          role: 'system',
          content: 'คุณเป็นผู้เชี่ยวชาญด้านโภชนาการ ประเมินคุณค่าโภชนาการของอาหารไทยจากชื่ออาหาร ตอบเป็น JSON เท่านั้น',
        },
        {
          role: 'user',
          content: `ประเมินคุณค่าโภชนาการของ "${foodName}"${storeName ? ` จากร้าน ${storeName}` : ''} ตอบเป็น JSON เท่านั้น ไม่มีข้อความอื่น:
{
  "foodName": "ชื่ออาหาร (ภาษาไทย)",
  "foodNameEn": "Food name (English)",
  "description": "คำอธิบาย 1-2 ประโยค (ภาษาไทย)",
  "servingSize": "ปริมาณต่อ 1 ที่ เช่น '1 จาน (~350g)'",
  "calories": 0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0,
  "fiber": 0.0,
  "sugar": 0.0,
  "sodium": 0,
  "healthScore": 0,
  "healthNote": "คำแนะนำด้านสุขภาพ (ภาษาไทย)"
}
หน่วย: calories=kcal, protein/carbs/fat/fiber/sugar=กรัม, sodium=มิลลิกรัม, healthScore=1-10 (10=ดีที่สุด)`,
        },
      ],
    });

    const text = completion.choices[0].message.content.trim();
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return res.status(500).json({ error: 'ไม่สามารถวิเคราะห์ได้' });

    res.json(JSON.parse(match[0]));
  } catch (err) {
    console.error('nutrition-by-name error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' });
  }
});

router.post('/rider-plan', async (req, res) => {
  try {
    const { todayEarned, todayCount, avgPerDelivery, targetAmount, remainingDeliveries } = req.body;
    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        { role: 'system', content: 'คุณเป็น AI โค้ชส่วนตัวสำหรับไรเดอร์ส่งอาหาร ให้คำแนะนำที่กระตุ้น ใช้งานได้จริง และให้กำลังใจ' },
        { role: 'user', content: `วางแผนให้ไรเดอร์วันนี้:
- ส่งแล้ว: ${todayCount} รอบ ได้ ฿${todayEarned}
- เป้าหมาย: ฿${targetAmount}
- เฉลี่ย/รอบ: ฿${avgPerDelivery}
- เหลืออีก: ${remainingDeliveries} รอบ
ให้คำแนะนำ 2-3 ประโยค ภาษาไทย กระชับ ให้กำลังใจ และแนะนำว่าควรทำอย่างไร` },
      ],
    });
    res.json({ tip: completion.choices[0].message.content.trim() });
  } catch (err) {
    console.error('rider-plan error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด' });
  }
});

router.post('/auto-crop', async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'ไม่พบรูปภาพ' });
    const base64Data = image.includes(',') ? image.split(',')[1] : image;
    const mediaType = image.startsWith('data:image/png') ? 'image/png' : 'image/jpeg';

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        { role: 'system', content: 'วิเคราะห์ตำแหน่งอาหารในภาพ ตอบ JSON เท่านั้น ไม่มีข้อความอื่น' },
        {
          role: 'user',
          content: [
            { type: 'image_url', image_url: { url: `data:${mediaType};base64,${base64Data}` } },
            {
              type: 'text',
              text: `หาตำแหน่งกรอบครอบอาหารหลักในภาพ ตอบ JSON ค่าเป็นสัดส่วน 0.0-1.0 ของขนาดภาพ ให้พื้นที่รอบอาหารเพิ่มอีก 8%:
{"x": 0.0, "y": 0.0, "w": 1.0, "h": 1.0}
x,y = มุมซ้ายบน, w,h = ความกว้างและสูง. ถ้าอาหารเต็มภาพ ตอบ {"x":0,"y":0,"w":1,"h":1}`,
            },
          ],
        },
      ],
    });

    const text = completion.choices[0].message.content.trim();
    const match = text.match(/\{[\s\S]*?\}/);
    if (!match) return res.json({ x: 0, y: 0, w: 1, h: 1 });

    const crop = JSON.parse(match[0]);
    const clamp = (v, lo, hi) => Math.min(Math.max(Number(v) || 0, lo), hi);
    const x = clamp(crop.x, 0, 0.9);
    const y = clamp(crop.y, 0, 0.9);
    res.json({ x, y, w: clamp(crop.w, 0.05, 1 - x), h: clamp(crop.h, 0.05, 1 - y) });
  } catch (err) {
    console.error('auto-crop error:', err.message);
    res.json({ x: 0, y: 0, w: 1, h: 1 });
  }
});

router.post('/rider-notification', async (req, res) => {
  try {
    const { step, storeName, customerName, riderName, etaMinutes } = req.body;
    if (!step) return res.status(400).json({ error: 'ไม่พบข้อมูล' });

    const stepCtx = {
      at_store:   `ถึงร้าน "${storeName || 'ร้านค้า'}" แล้ว กำลังรับอาหาร`,
      picking_up: `รับอาหารจากร้าน "${storeName || 'ร้านค้า'}" เรียบร้อยแล้ว กำลังออกเดินทางมาส่ง`,
    };
    const ctx = stepCtx[step] || `อัพเดทสถานะ: ${step}`;
    const etaText = etaMinutes ? ` คาดว่าอีกประมาณ ${etaMinutes} นาทีจะถึง` : '';
    const customer = customerName || 'ครับ/ค่ะ';

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        {
          role: 'system',
          content: 'คุณเป็นไรเดอร์ส่งอาหาร เขียนข้อความ chat ส่งให้ลูกค้า ต้องสุภาพ เป็นกันเอง กระชับ ใช้ emoji 1-2 ตัว ตอบภาษาไทยเท่านั้น ไม่เกิน 30 คำ ตอบเป็นข้อความ chat เท่านั้น ไม่มีคำอธิบายเพิ่ม',
        },
        {
          role: 'user',
          content: `สถานการณ์: ${ctx}${etaText}\nชื่อลูกค้า: ${customer}\nเขียนข้อความแจ้งลูกค้าว่าสถานะปัจจุบันคืออะไร`,
        },
      ],
    });

    const message = completion.choices[0].message.content.trim();
    res.json({ message });
  } catch (err) {
    console.error('rider-notification error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด' });
  }
});

router.post('/rider-insight', async (req, res) => {
  try {
    const {
      todayEarned, todayCount,
      weekEarned, weekCount,
      totalEarned, totalCount,
      avgPerDelivery, peakHours,
      targetAmount, dayOfWeek,
      avgRating, recentComments,
    } = req.body;

    const peakText = Array.isArray(peakHours) && peakHours.length > 0
      ? `ช่วงเวลาที่วิ่งได้มากที่สุด: ${peakHours.map(h => `${h.hour}:00 น. (${h.count} รอบ)`).join(', ')}`
      : 'ยังไม่มีข้อมูลช่วงเวลา';

    const reviewText = avgRating
      ? `คะแนนรีวิวจากลูกค้า: ${avgRating}/5 ดาว\nความคิดเห็นล่าสุด:\n${(recentComments || []).map((c, i) => `  ${i + 1}. "${c}"`).join('\n')}`
      : 'ยังไม่มีรีวิวจากลูกค้า';

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        {
          role: 'system',
          content: 'คุณเป็น AI โค้ชส่วนตัวสำหรับไรเดอร์ส่งอาหาร วิเคราะห์ข้อมูลทั้งรายได้และรีวิวจากลูกค้าอย่างละเอียด ให้คำแนะนำที่เป็นประโยชน์และใช้ได้จริง โดยอ้างอิงสิ่งที่ลูกค้าพูดถึงด้วย ตอบเป็น JSON เท่านั้น ห้ามมีข้อความอื่น',
        },
        {
          role: 'user',
          content: `วิเคราะห์ประสิทธิภาพและให้คำแนะนำแก่ไรเดอร์ส่งอาหาร:

[ข้อมูลรายได้]
- วันนี้ (${dayOfWeek || 'ไม่ระบุ'}): ${todayCount} รอบ ได้ ฿${todayEarned} (เป้า: ฿${targetAmount})
- 7 วันล่าสุด: ${weekCount} รอบ ได้ ฿${weekEarned}
- รวมทั้งหมด: ${totalCount} รอบ ได้ ฿${totalEarned}
- เฉลี่ย/รอบ: ฿${avgPerDelivery}
- ${peakText}

[รีวิวจากลูกค้า]
${reviewText}

วิเคราะห์จุดแข็งและจุดที่ควรปรับปรุงจากรีวิว แล้วให้คำแนะนำที่เชื่อมโยงกับสิ่งที่ลูกค้าพูดถึง
ตอบ JSON รูปแบบนี้เท่านั้น ห้ามมีข้อความนอก JSON:
{
  "score": <1-10 โดยคำนึงถึงทั้งรายได้และรีวิว>,
  "scoreLabel": "<ต้องพัฒนา/พอใช้/ดี/ดีมาก/ยอดเยี่ยม/ระดับมือโปร>",
  "insights": [
    {"title": "<หัวข้อสั้น>", "detail": "<รายละเอียดที่อ้างอิงข้อมูลจริง 1 ประโยค>"},
    {"title": "<หัวข้อสั้น>", "detail": "<รายละเอียดที่อ้างอิงข้อมูลจริง 1 ประโยค>"},
    {"title": "<หัวข้อสั้น>", "detail": "<รายละเอียดที่อ้างอิงข้อมูลจริง 1 ประโยค>"}
  ],
  "recommendations": [
    "<คำแนะนำที่อิงจากรีวิวหรือรายได้จริง ใช้ได้จริง 1>",
    "<คำแนะนำที่อิงจากรีวิวหรือรายได้จริง ใช้ได้จริง 2>",
    "<คำแนะนำที่อิงจากรีวิวหรือรายได้จริง ใช้ได้จริง 3>"
  ],
  "motivation": "<ข้อความให้กำลังใจที่สะท้อนสิ่งที่ลูกค้าชื่นชม 1-2 ประโยค พร้อม emoji 1-2 ตัว>"
}`,
        },
      ],
    });

    const text = completion.choices[0].message.content.trim();
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return res.status(500).json({ error: 'ไม่สามารถวิเคราะห์ได้' });

    res.json(JSON.parse(match[0]));
  } catch (err) {
    console.error('rider-insight error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด' });
  }
});

router.post('/smart-price', async (req, res) => {
  try {
    const db = require('../../db');
    const { itemName } = req.body;
    if (!itemName) return res.status(400).json({ error: 'ไม่พบชื่อเมนู' });

    const keywords = itemName.trim().split(/\s+/).filter(Boolean).slice(0, 4);
    if (!keywords.length) return res.json({ count: 0 });

    const conditions = keywords.map(() => 'mi.name LIKE ?').join(' OR ');
    const params = keywords.map(k => `%${k}%`);

    const [rows] = await db.query(`
      SELECT mi.price FROM menu_items mi
      JOIN restaurant r ON mi.store_id = r.id
      WHERE mi.is_available = 1 AND r.status = 'active' AND (${conditions})
    `, params);

    if (!rows.length) return res.json({ count: 0 });
    const prices = rows.map(r => parseFloat(r.price)).filter(p => p > 0);
    if (!prices.length) return res.json({ count: 0 });

    const min = Math.min(...prices);
    const max = Math.max(...prices);
    const avg = prices.reduce((a, b) => a + b, 0) / prices.length;
    const suggestion = Math.round(avg / 5) * 5;

    res.json({ count: prices.length, min: Math.round(min), max: Math.round(max), avg: Math.round(avg), suggestion });
  } catch (err) {
    console.error('smart-price error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด' });
  }
});

router.post('/generate-description', async (req, res) => {
  try {
    const { itemName, storeName, context: ctx } = req.body;
    if (!itemName && !storeName) return res.status(400).json({ error: 'ไม่พบข้อมูล' });

    let prompt
    if (ctx === 'rider') {
      prompt = `สร้าง bio สั้นๆ สำหรับไรเดอร์ส่งอาหารชื่อ "${storeName || 'ไรเดอร์'}"${itemName ? ` ที่ส่งสำเร็จไปแล้ว ${itemName} รอบ` : ''} ให้ฟังดูเป็นมืออาชีพ น่าเชื่อถือ และมีพลังงาน 1-2 ประโยคภาษาไทย ตอบแค่ bio เท่านั้น`
    } else if (ctx === 'store_name') {
      const db = require('../../db');
      const [existingRows] = await db.query('SELECT name FROM restaurant LIMIT 500');
      const existingNames = new Set(existingRows.map(r => (r.name || '').trim().toLowerCase()).filter(Boolean));

      const triedNames = [];
      let finalName = '';

      for (let attempt = 0; attempt < 5; attempt++) {
        const takenLine = triedNames.length > 0
          ? `\nชื่อที่เคยแนะนำไปแล้วและยังซ้ำอยู่ (ห้ามใช้อีก): ${triedNames.join(', ')}`
          : '';
        const avoidLine = existingRows.length > 0
          ? `\nชื่อที่มีอยู่ในระบบแล้ว (ห้ามซ้ำ): ${existingRows.map(r => r.name).join(', ')}`
          : '';
        const p = `ตั้งชื่อร้านอาหารไทยให้ฟังดูน่าสนใจและน่าจดจำ โดยอิงจากประเภทอาหาร: "${storeName || 'ร้านอาหาร'}"${avoidLine}${takenLine}\nตอบแค่ชื่อร้านเท่านั้น ไม่ต้องมีคำอธิบาย ตัวอย่างรูปแบบ: "ครัวคุณแม่", "บ้านข้าวหอม", "เตาถ่านสด"`;

        const c = await client.chat.completions.create({
          model: 'gemini-2.5-flash-lite',
          stream: false,
          messages: [
            { role: 'system', content: 'คุณเป็นผู้ตั้งชื่อร้านอาหาร ห้ามใช้ชื่อที่ซ้ำกับรายการที่ระบุ ตอบแค่ชื่อร้านเท่านั้น' },
            { role: 'user', content: p },
          ],
        });

        const candidate = c.choices[0].message.content.trim().replace(/^["']|["']$/g, '');
        triedNames.push(candidate);

        if (!existingNames.has(candidate.trim().toLowerCase())) {
          finalName = candidate;
          break;
        }
      }

      // last resort: append random suffix if all attempts were taken
      if (!finalName) finalName = `${triedNames[0]} ${Math.floor(1000 + Math.random() * 9000)}`;

      res.json({ description: finalName });
      return;
    } else {
      prompt = `เขียนคำอธิบายเมนู "${itemName}"${storeName ? ` ร้าน ${storeName}` : ''} ให้น่าสนใจ 1-2 ประโยค ภาษาไทย บอกรสชาติหรือจุดเด่น ตอบแค่คำอธิบายเท่านั้น`
    }

    const completion = await client.chat.completions.create({
      model: 'gemini-2.5-flash-lite',
      stream: false,
      messages: [
        { role: 'system', content: 'คุณเป็นผู้เชี่ยวชาญด้านอาหาร เขียนคำอธิบายอาหารให้น่าสนใจ กระชับ' },
        { role: 'user', content: prompt },
      ],
    });

    const description = completion.choices[0].message.content.trim();
    res.json({ description });
  } catch (err) {
    console.error('generate-description error:', err.message);
    res.status(500).json({ error: 'เกิดข้อผิดพลาด' });
  }
});

module.exports = router;
