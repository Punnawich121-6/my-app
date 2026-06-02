const express = require('express');
const router = express.Router();
const db = require('../../db');
const { uploadBase64 } = require('../../services/cloudinary');

async function saveImage(base64Data) {
  return uploadBase64(base64Data, 'digio/menu');
}

function fixImageUrl(url) { return url || null; }

router.get('/:storeId', async (req, res) => {
  const { storeId } = req.params;
  try {
    const [categories] = await db.query(
      'SELECT * FROM menu_categories WHERE store_id = ? ORDER BY sort_order',
      [storeId]
    );
    const [items] = await db.query(
      'SELECT * FROM menu_items WHERE store_id = ? ORDER BY category_id, sort_order',
      [storeId]
    );
    items.forEach(item => { if (item.image_url) item.image_url = fixImageUrl(item.image_url); });
    res.json({ categories, items });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/category', async (req, res) => {
  const { store_id, name } = req.body;
  try {
    const [[maxSort]] = await db.query(
      'SELECT COALESCE(MAX(sort_order),0)+1 as next FROM menu_categories WHERE store_id=?',
      [store_id]
    );
    const [result] = await db.query(
      'INSERT INTO menu_categories (store_id, name, sort_order) VALUES (?,?,?)',
      [store_id, name, maxSort.next]
    );
    res.json({ id: result.insertId, store_id, name });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.delete('/category/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM menu_categories WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/item', async (req, res) => {
  const { store_id, category_id, name, description, price, image_url, image_base64 } = req.body;
  let finalImageUrl = image_url;
  if (image_base64) {
    finalImageUrl = await saveImage(image_base64) || finalImageUrl;
  }
  try {
    const [result] = await db.query(
      'INSERT INTO menu_items (store_id, category_id, name, description, price, image_url) VALUES (?,?,?,?,?,?)',
      [store_id, category_id || null, name, description || '', price, finalImageUrl || null]
    );
    res.json({ id: result.insertId, ...req.body, is_available: 1 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/item/:id', async (req, res) => {
  const { name, description, price, image_url, image_base64, category_id, is_available } = req.body;
  let finalImageUrl = image_url;
  if (image_base64) {
    finalImageUrl = await saveImage(image_base64) || finalImageUrl;
  }
  try {
    await db.query(
      'UPDATE menu_items SET name=?, description=?, price=?, image_url=?, category_id=?, is_available=? WHERE id=?',
      [name, description, price, finalImageUrl || null, category_id || null, is_available ?? 1, req.params.id]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.put('/item/:id/toggle', async (req, res) => {
  try {
    await db.query('UPDATE menu_items SET is_available = NOT is_available WHERE id = ?', [req.params.id]);
    const [[item]] = await db.query('SELECT is_available FROM menu_items WHERE id = ?', [req.params.id]);
    res.json({ is_available: item.is_available });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.delete('/item/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM menu_items WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
