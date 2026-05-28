const db = require('../db');

async function run() {
  const [result] = await db.query(`
    DELETE r1 FROM reviews r1
    INNER JOIN reviews r2
    ON r1.store_id = r2.store_id
       AND r1.customer_name = r2.customer_name
       AND r1.rating = r2.rating
       AND r1.comment = r2.comment
       AND r1.id > r2.id
  `);
  console.log('Deleted duplicates:', result.affectedRows);
  const [[{cnt}]] = await db.query('SELECT COUNT(*) as cnt FROM reviews');
  console.log('Reviews remaining:', cnt);
  process.exit(0);
}
run().catch(e => { console.error(e.message); process.exit(1); });
