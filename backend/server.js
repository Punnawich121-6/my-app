const express = require('express');
const cors = require('cors');
const app = express();
const path = require('path');
const db = require('./db');

async function initTables() {
  // Restaurant (merchant store) table
  await db.query(`
    CREATE TABLE IF NOT EXISTS restaurant (
      id             VARCHAR(36)    PRIMARY KEY,
      name           VARCHAR(200)   NOT NULL,
      category       VARCHAR(100)   NOT NULL DEFAULT 'ร้านอาหาร',
      rating         FLOAT          DEFAULT 0,
      totalOrders    INT            DEFAULT 0,
      status         VARCHAR(20)    DEFAULT 'pending',
      commissionRate FLOAT          DEFAULT 15,
      serviceFeeRate FLOAT          DEFAULT 5,
      address        VARCHAR(500),
      phone          VARCHAR(20),
      email          VARCHAR(100),
      imageUrl       VARCHAR(500),
      createdAt      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
      updatedAt      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  // Customer table
  await db.query(`
    CREATE TABLE IF NOT EXISTS customer (
      id        VARCHAR(36)  PRIMARY KEY,
      name      VARCHAR(200) NOT NULL,
      email     VARCHAR(100),
      phone     VARCHAR(20)  UNIQUE,
      address   TEXT,
      createdAt TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
      updatedAt TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  // Order table
  await db.query(`
    CREATE TABLE IF NOT EXISTS \`order\` (
      id           VARCHAR(36)    PRIMARY KEY,
      orderNumber  VARCHAR(50),
      restaurantId VARCHAR(36),
      customerId   VARCHAR(36),
      riderId      VARCHAR(36),
      status       VARCHAR(20)    DEFAULT 'pending',
      totalAmount  DECIMAL(10,2)  NOT NULL,
      serviceFee   DECIMAL(10,2)  DEFAULT 0,
      notes        TEXT,
      createdAt    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
      updatedAt    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  // Rider table (mirrors zest_savory_db schema)
  await db.query(`
    CREATE TABLE IF NOT EXISTS Rider (
      id            VARCHAR(36)   PRIMARY KEY,
      name          VARCHAR(100)  NOT NULL,
      email         VARCHAR(100)  UNIQUE NOT NULL,
      phone         VARCHAR(20),
      vehicle       VARCHAR(100)  NOT NULL DEFAULT 'motorcycle',
      vehicleType   VARCHAR(50)   DEFAULT 'MOTORCYCLE',
      status        VARCHAR(20)   DEFAULT 'OFFLINE',
      rating        DECIMAL(3,2)  DEFAULT 0,
      runsCompleted INT           DEFAULT 0,
      isVerified    TINYINT(1)    DEFAULT 0,
      createdAt     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
      updatedAt     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  // Menu categories (store_id references Restaurant.id UUID)
  await db.query(`
    CREATE TABLE IF NOT EXISTS menu_categories (
      id         INT AUTO_INCREMENT PRIMARY KEY,
      store_id   VARCHAR(36) NOT NULL,
      name       VARCHAR(100) NOT NULL,
      sort_order INT DEFAULT 0
    )
  `);

  // Menu items
  await db.query(`
    CREATE TABLE IF NOT EXISTS menu_items (
      id           INT AUTO_INCREMENT PRIMARY KEY,
      store_id     VARCHAR(36) NOT NULL,
      category_id  INT,
      name         VARCHAR(200) NOT NULL,
      description  TEXT,
      price        DECIMAL(10,2) NOT NULL DEFAULT 0,
      image_url    VARCHAR(500),
      is_available TINYINT(1) NOT NULL DEFAULT 1,
      sort_order   INT DEFAULT 0
    )
  `);

  // Order items (order_id references Order.id UUID)
  await db.query(`
    CREATE TABLE IF NOT EXISTS order_items (
      id           INT AUTO_INCREMENT PRIMARY KEY,
      order_id     VARCHAR(36) NOT NULL,
      menu_item_id INT,
      name         VARCHAR(200) NOT NULL,
      price        DECIMAL(10,2) NOT NULL,
      quantity     INT NOT NULL DEFAULT 1
    )
  `);
}

initTables().catch(e => console.error('Table init error:', e.message));

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/orders',    require('./routes/orders'));
app.use('/api/menu',      require('./routes/menu'));
app.use('/api/earnings',  require('./routes/earnings'));
app.use('/api/store',     require('./routes/store'));
app.use('/api/rider',     require('./routes/rider'));
app.use('/api/customer',  require('./routes/customer'));

// Config endpoint — lets mobile apps discover the active restaurant UUID
app.get('/api/config', async (req, res) => {
  try {
    const [[store]] = await db.query(
      `SELECT id FROM restaurant WHERE LOWER(status) IN ('active','approved') ORDER BY createdAt ASC LIMIT 1`
    );
    res.json({ store_id: store ? store.id : '' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));
