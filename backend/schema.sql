CREATE DATABASE IF NOT EXISTS zest_savory CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE zest_savory;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100),
  email VARCHAR(100),
  line_id VARCHAR(100),
  role ENUM('customer','restaurant','rider') DEFAULT 'customer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(100),
  address TEXT,
  lat DECIMAL(10,7),
  lng DECIMAL(10,7),
  open_time VARCHAR(10),
  close_time VARCHAR(10),
  is_open TINYINT(1) DEFAULT 1,
  image_url TEXT,
  rating DECIMAL(2,1) DEFAULT 0,
  review_count INT DEFAULT 0,
  bank_name VARCHAR(100),
  account_name VARCHAR(100),
  account_no VARCHAR(30),
  id_card VARCHAR(20),
  business_license VARCHAR(30),
  status ENUM('pending','approved','rejected') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS menu_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS menu_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  category_id INT,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_available TINYINT(1) DEFAULT 1,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  customer_id INT,
  customer_name VARCHAR(100) DEFAULT 'ลูกค้า',
  customer_phone VARCHAR(20),
  rider_id INT,
  status ENUM('pending','accepted','preparing','ready','delivering','completed','cancelled') DEFAULT 'pending',
  total_amount DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  note TEXT,
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (store_id) REFERENCES stores(id)
);

CREATE TABLE IF NOT EXISTS order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  menu_item_id INT,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  note TEXT,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS earnings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  order_id INT,
  amount DECIMAL(10,2) NOT NULL,
  type ENUM('order','adjustment','payout') DEFAULT 'order',
  status ENUM('pending','paid') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (store_id) REFERENCES stores(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  customer_id INT,
  customer_name VARCHAR(100) DEFAULT 'ลูกค้า',
  order_id INT,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  reply TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (store_id) REFERENCES stores(id)
);

-- Seed data สำหรับทดสอบ
INSERT IGNORE INTO users (id, phone, name, email, role) VALUES
(1, '0812345678', 'เจ้าของร้าน', 'owner@test.com', 'restaurant'),
(2, '0898765432', 'ลูกค้า A', 'customer@test.com', 'customer');

INSERT IGNORE INTO stores (id, user_id, name, type, address, lat, lng, open_time, close_time, is_open, rating, review_count, bank_name, account_name, account_no, status) VALUES
(1, 1, 'Zest & Savory', 'อาหารตามสั่ง', '123 ถ.สุขุมวิท กรุงเทพฯ', 13.756331, 100.501762, '08:00', '22:00', 1, 4.5, 128, 'กสิกรไทย', 'เจ้าของร้าน', '1234567890', 'approved');

INSERT IGNORE INTO menu_categories (id, store_id, name, sort_order) VALUES
(1, 1, 'อาหารจานหลัก', 1),
(2, 1, 'เครื่องดื่ม', 2),
(3, 1, 'ของหวาน', 3);

INSERT IGNORE INTO menu_items (id, store_id, category_id, name, description, price, is_available) VALUES
(1, 1, 1, 'ข้าวผัดกุ้ง', 'ข้าวผัดกุ้งสูตรพิเศษ', 89, 1),
(2, 1, 1, 'ผัดกะเพราหมูสับ', 'เผ็ดร้อนถึงใจ เสิร์ฟพร้อมข้าวสวย', 69, 1),
(3, 1, 1, 'ต้มยำกุ้ง', 'ต้มยำน้ำข้น รสจัด', 120, 1),
(4, 1, 2, 'น้ำมะนาว', 'สดชื่น', 25, 1),
(5, 1, 2, 'ชาไทย', 'หวานมันกลมกล่อม', 35, 1),
(6, 1, 3, 'ข้าวเหนียวมะม่วง', 'มะม่วงสุก ข้าวเหนียวมะพร้าว', 79, 0);

INSERT IGNORE INTO orders (id, store_id, customer_id, customer_name, customer_phone, status, total_amount, delivery_fee, address, created_at) VALUES
(1, 1, 2, 'สมชาย ใจดี', '0898765432', 'pending', 183, 30, '456 ถ.ลาดพร้าว กรุงเทพฯ', NOW()),
(2, 1, 2, 'สมหญิง รักดี', '0891234567', 'preparing', 94, 30, '789 ถ.รามคำแหง กรุงเทพฯ', DATE_SUB(NOW(), INTERVAL 15 MINUTE)),
(3, 1, 2, 'ประยุทธ์ ดีใจ', '0876543210', 'completed', 158, 30, '321 ถ.พหลโยธิน กรุงเทพฯ', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(4, 1, 2, 'มานี มีสุข', '0865432109', 'completed', 228, 30, '654 ถ.งามวงศ์วาน กรุงเทพฯ', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 1, 2, 'วิชัย ชัยชนะ', '0854321098', 'cancelled', 89, 30, '987 ถ.บางนา กรุงเทพฯ', DATE_SUB(NOW(), INTERVAL 1 DAY));

INSERT IGNORE INTO order_items (order_id, menu_item_id, name, price, quantity) VALUES
(1, 1, 'ข้าวผัดกุ้ง', 89, 1),
(1, 4, 'น้ำมะนาว', 25, 1),
(1, 3, 'ต้มยำกุ้ง', 120, 1),
(2, 2, 'ผัดกะเพราหมูสับ', 69, 1),
(2, 5, 'ชาไทย', 35, 1),
(3, 1, 'ข้าวผัดกุ้ง', 89, 1),
(3, 3, 'ต้มยำกุ้ง', 120, 1),
(4, 2, 'ผัดกะเพราหมูสับ', 69, 2),
(4, 5, 'ชาไทย', 35, 2),
(5, 1, 'ข้าวผัดกุ้ง', 89, 1);

INSERT IGNORE INTO earnings (store_id, order_id, amount, type, status, created_at) VALUES
(1, 3, 128, 'order', 'paid', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 4, 198, 'order', 'paid', DATE_SUB(NOW(), INTERVAL 1 DAY));

INSERT IGNORE INTO reviews (store_id, customer_id, customer_name, order_id, rating, comment, created_at) VALUES
(1, 2, 'สมชาย ใจดี', 3, 5, 'อร่อยมากๆ บริการดี จัดส่งเร็ว', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 2, 'มานี มีสุข', 4, 4, 'อาหารอร่อย แต่รอนานนิดหน่อย', DATE_SUB(NOW(), INTERVAL 1 DAY));
