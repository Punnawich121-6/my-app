const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const uploadDir = path.join(__dirname, '..', 'uploads', 'reviews');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

function crc32(buf) {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
  const t = Buffer.from(type);
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, crc]);
}

function createPng(r, g, b) {
  const W = 80, H = 80;
  const rows = [];
  for (let y = 0; y < H; y++) {
    const row = Buffer.alloc(1 + W * 3);
    row[0] = 0;
    for (let x = 0; x < W; x++) { row[1+x*3]=r; row[2+x*3]=g; row[3+x*3]=b; }
    rows.push(row);
  }
  const raw = Buffer.concat(rows);
  const idat = zlib.deflateSync(raw, { level: 1 });
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4);
  ihdr[8]=8; ihdr[9]=2;
  return Buffer.concat([
    Buffer.from([137,80,78,71,13,10,26,10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const colors = [
  [255,140,0], [76,153,0], [220,60,60],
  [255,200,0], [100,160,220], [180,100,200],
];

// Use .png extension for correct content-type
const oldFiles = ['review_food1.jpg','review_food2.jpg','review_food3.jpg','review_food4.jpg','review_food5.jpg','review_food6.jpg'];
const newFiles = ['review_food1.png','review_food2.png','review_food3.png','review_food4.png','review_food5.png','review_food6.png'];

// Delete old .jpg files
oldFiles.forEach(name => {
  const fp = path.join(uploadDir, name);
  if (fs.existsSync(fp)) { fs.unlinkSync(fp); console.log(`Deleted ${name}`); }
});

// Create new .png files
newFiles.forEach((name, i) => {
  const [r,g,b] = colors[i];
  const png = createPng(r,g,b);
  fs.writeFileSync(path.join(uploadDir, name), png);
  console.log(`Created ${name} (${png.length} bytes)`);
});

// Update DB: replace .jpg with .png in review images
const db = require('../db');
async function updateDb() {
  const [rows] = await db.query("SELECT id, images FROM reviews WHERE images IS NOT NULL AND images LIKE '%review_food%'");
  for (const row of rows) {
    const fixed = row.images.replace(/review_food(\d+)\.jpg/g, 'review_food$1.png');
    await db.query('UPDATE reviews SET images = ? WHERE id = ?', [fixed, row.id]);
    console.log(`Updated review id=${row.id}`);
  }
  console.log('DB updated. Done!');
  process.exit(0);
}
updateDb().catch(e => { console.error(e.message); process.exit(1); });
