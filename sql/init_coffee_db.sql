CREATE DATABASE IF NOT EXISTS coffeeshop;
USE coffeeshop;

DROP TABLE IF EXISTS store_inventory;

CREATE TABLE IF NOT EXISTS store_inventory (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  product_name VARCHAR(50),
  category VARCHAR(30),
  supplier VARCHAR(50),
  cost_price DECIMAL(10,2),
  retail_price DECIMAL(10,2),
  current_stock INT,
  min_stock_level INT,
  last_restocked DATE
);

INSERT INTO store_inventory (product_name, category, supplier, cost_price, retail_price, current_stock, min_stock_level, last_restocked) VALUES
('Espresso', 'Beverages', 'Bean Suppliers Inc', 0.85, 2.50, 45, 20, '2024-01-10'),
('Latte', 'Beverages', 'Bean Suppliers Inc', 1.20, 4.75, 68, 30, '2024-01-12'),
('Croissant', 'Food', 'Bakery Delights', 1.50, 3.75, 22, 15, '2024-01-14'),
('Blueberry Muffin', 'Food', 'Bakery Delights', 1.25, 3.25, 8, 10, '2024-01-08'),
('Cold Brew', 'Beverages', 'Bean Suppliers Inc', 1.00, 4.50, 35, 25, '2024-01-11'),
('Turkey Sandwich', 'Food', 'Fresh Foods Co', 3.50, 8.99, 6, 8, '2024-01-13'),
('Green Tea', 'Beverages', 'Tea Importers Ltd', 0.75, 3.25, 85, 20, '2024-01-09'),
('Chocolate Chip Cookie', 'Food', 'Bakery Delights', 0.80, 2.25, 42, 12, '2024-01-15'),
('Caramel Macchiato', 'Beverages', 'Bean Suppliers Inc', 1.40, 5.75, 58, 25, '2024-01-12'),
('Cappuccino', 'Beverages', 'Bean Suppliers Inc', 1.10, 4.25, 72, 28, '2024-01-11'),
('Double Espresso', 'Beverages', 'Bean Suppliers Inc', 1.00, 3.50, 38, 15, '2024-01-13'),
('Chocolate Croissant', 'Food', 'Bakery Delights', 1.80, 4.25, 15, 10, '2024-01-14'),
('Iced Latte', 'Beverages', 'Bean Suppliers Inc', 1.25, 5.25, 42, 20, '2024-01-12'),
('Bagel with Cream Cheese', 'Food', 'Bakery Delights', 2.00, 4.75, 28, 12, '2024-01-13'),
('Matcha Latte', 'Beverages', 'Tea Importers Ltd', 1.60, 5.50, 31, 15, '2024-01-10'),
('Ham and Cheese Panini', 'Food', 'Fresh Foods Co', 4.00, 9.25, 18, 8, '2024-01-14'),
('Oatmeal Cookie', 'Food', 'Bakery Delights', 0.90, 2.75, 55, 15, '2024-01-11'),
('Americano', 'Beverages', 'Bean Suppliers Inc', 0.95, 4.00, 62, 25, '2024-01-12'),
('Vanilla Scone', 'Food', 'Bakery Delights', 1.40, 3.50, 32, 10, '2024-01-13'),
('Mocha Frappe', 'Beverages', 'Bean Suppliers Inc', 1.80, 6.75, 25, 12, '2024-01-11'),
('Chicken Caesar Wrap', 'Food', 'Fresh Foods Co', 3.75, 8.50, 14, 8, '2024-01-14'),
('Chai Tea Latte', 'Beverages', 'Tea Importers Ltd', 1.30, 4.75, 48, 20, '2024-01-10'),
('Banana Bread', 'Food', 'Bakery Delights', 1.60, 3.95, 26, 10, '2024-01-13'),
('Iced Tea', 'Beverages', 'Tea Importers Ltd', 0.65, 3.75, 78, 30, '2024-01-09'),
('Breakfast Burrito', 'Food', 'Fresh Foods Co', 3.25, 7.25, 22, 8, '2024-01-14'),
('Flat White', 'Beverages', 'Bean Suppliers Inc', 1.15, 4.50, 51, 20, '2024-01-12'),
('Cinnamon Roll', 'Food', 'Bakery Delights', 1.90, 4.50, 19, 10, '2024-01-13'),
('Hot Chocolate', 'Beverages', 'Sweet Treats Co', 1.10, 4.25, 65, 25, '2024-01-11'),
('Veggie Panini', 'Food', 'Fresh Foods Co', 3.85, 8.75, 16, 8, '2024-01-14'),
('Caramel Frappe', 'Beverages', 'Bean Suppliers Inc', 1.75, 6.50, 29, 12, '2024-01-11'),
('Apple Danish', 'Food', 'Bakery Delights', 1.70, 3.95, 24, 10, '2024-01-13'),
('Turkish Coffee', 'Beverages', 'Bean Suppliers Inc', 1.05, 4.00, 33, 15, '2024-01-12'),
('Caprese Sandwich', 'Food', 'Fresh Foods Co', 4.25, 9.50, 12, 8, '2024-01-14'),
('Iced Americano', 'Beverages', 'Bean Suppliers Inc', 1.00, 4.25, 47, 20, '2024-01-12'),
('Chocolate Muffin', 'Food', 'Bakery Delights', 1.45, 3.75, 21, 10, '2024-01-13');
CREATE USER IF NOT EXISTS 'coffee_admin'@'localhost' IDENTIFIED BY 'Coffee@2024';
GRANT SELECT, INSERT, UPDATE ON coffeeshop.* TO 'coffee_admin'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database initialized successfully!' as Status;
