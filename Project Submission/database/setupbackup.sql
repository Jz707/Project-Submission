-- ==========================================================
-- Wash & Drycleaning System
-- ==========================================================

DROP DATABASE IF EXISTS mydb;
CREATE DATABASE mydb;
USE mydb;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS item_types;
DROP TABLE IF EXISTS vendor_deliveries;
DROP TABLE IF EXISTS system_users;

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- TABLES
-- ==========================================================

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE item_types (
    item_type_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(50) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    dropoff_date DATE NOT NULL,
    promised_date DATE NOT NULL,
    ready_date DATE NULL,
    pickup_date DATE NULL,
    payment_status VARCHAR(20) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    total_items INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    notes VARCHAR(255),
    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    item_type_id INT NOT NULL,
    care_type VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    item_status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_item_types
        FOREIGN KEY (item_type_id)
        REFERENCES item_types(item_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- IMPORTANT:
-- This table uses vendor_name instead of vendor_id because your current app.py
-- inserts vendor_name directly from vendor.html.
CREATE TABLE vendor_deliveries (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name VARCHAR(100) NOT NULL,
    delivery_date DATE NOT NULL,
    supply_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,
    notes VARCHAR(255)
) ENGINE = InnoDB;

-- Your app.py already creates this automatically with initialize_users(),
-- but including it here makes setup.sql complete.
CREATE TABLE system_users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

-- ==========================================================
-- SAMPLE DATA
-- ==========================================================

INSERT INTO item_types (item_name, base_price) VALUES
('Shirt', 6.99),
('Pants', 8.99),
('Suit Jacket', 14.99),
('Dress', 16.99),
('Coat', 18.99),
('Sweater', 9.99),
('Skirt', 8.49),
('Blouse', 7.99),
('Tie', 4.99),
('Comforter', 24.99),
('Curtains', 19.99),
('Jacket', 13.99);

INSERT INTO customers (first_name, last_name, phone, email, created_at) VALUES
('Liam','Williams','617-555-1001','liam.williams1@example.com','2026-01-11 09:01:00'),
('Olivia','Garcia','617-555-1002','olivia.garcia2@example.com','2026-01-12 09:02:00'),
('Noah','Rodriguez','617-555-1003','noah.rodriguez3@example.com','2026-01-13 09:03:00'),
('Emma','Lopez','617-555-1004','emma.lopez4@example.com','2026-01-14 09:04:00'),
('Oliver','Anderson','617-555-1005','oliver.anderson5@example.com','2026-01-15 09:05:00'),
('Ava','Moore','617-555-1006','ava.moore6@example.com','2026-01-16 09:06:00'),
('Elijah','Lee','617-555-1007','elijah.lee7@example.com','2026-01-17 09:07:00'),
('Sophia','White','617-555-1008','sophia.white8@example.com','2026-01-18 09:08:00'),
('James','Clark','617-555-1009','james.clark9@example.com','2026-01-19 09:09:00'),
('Isabella','Robinson','617-555-1010','isabella.robinson10@example.com','2026-01-20 09:10:00');

INSERT INTO orders
(customer_id, dropoff_date, promised_date, ready_date, pickup_date, payment_status, order_status, total_items, total_amount, notes)
VALUES
(1, '2026-01-11', '2026-01-16', NULL, NULL, 'Unpaid', 'Cleaning', 6, 93.92, 'Small stain on sleeve'),
(2, '2026-01-12', '2026-01-14', '2026-01-14', NULL, 'Partial', 'Ready', 7, 114.75, 'Customer requested rush service'),
(3, '2026-01-13', '2026-01-16', '2026-01-14', '2026-01-16', 'Paid', 'Picked Up', 2, 44.96, 'Handle with care'),
(4, '2026-01-14', '2026-01-16', NULL, NULL, 'Unpaid', 'Received', 8, 105.22, 'Separate dark colors'),
(5, '2026-01-15', '2026-01-20', NULL, NULL, 'Partial', 'Cleaning', 5, 43.95, 'Call when ready'),
(6, '2026-01-16', '2026-01-18', '2026-01-18', NULL, 'Paid', 'Ready', 7, 94.82, 'Delicate fabric'),
(7, '2026-01-17', '2026-01-20', '2026-01-19', '2026-01-20', 'Unpaid', 'Picked Up', 1, 22.48, 'Prepaid order'),
(8, '2026-01-18', '2026-01-20', NULL, NULL, 'Partial', 'Received', 3, 43.01, 'Check pockets'),
(9, '2026-01-19', '2026-01-22', NULL, NULL, 'Paid', 'Cleaning', 1, 37.48, 'VIP customer'),
(10, '2026-01-20', '2026-01-22', '2026-01-22', NULL, 'Unpaid', 'Ready', 4, 119.93, 'No special notes');

INSERT INTO order_items
(order_id, item_type_id, care_type, quantity, unit_price, line_total, item_status)
VALUES
(1, 1, 'Standard', 2, 6.99, 13.98, 'Cleaning'),
(1, 2, 'Standard', 4, 8.99, 35.96, 'Cleaning'),
(2, 3, 'Specialty', 2, 14.99, 29.98, 'Ready'),
(2, 4, 'Express', 5, 16.99, 84.95, 'Ready'),
(3, 5, 'Standard', 2, 18.99, 37.98, 'Picked Up'),
(4, 1, 'Standard', 8, 6.99, 55.92, 'Received'),
(5, 6, 'Standard', 5, 9.99, 49.95, 'Cleaning'),
(6, 2, 'Express', 7, 8.99, 62.93, 'Ready'),
(7, 9, 'Standard', 1, 4.99, 4.99, 'Picked Up'),
(8, 8, 'Specialty', 3, 7.99, 23.97, 'Received'),
(9, 10, 'Standard', 1, 24.99, 24.99, 'Cleaning'),
(10, 11, 'Specialty', 4, 19.99, 79.96, 'Ready');

INSERT INTO vendor_deliveries
(vendor_name, delivery_date, supply_name, quantity, unit_cost, total_cost, notes)
VALUES
('CleanPro Supplies', '2026-05-01', 'Detergent', 20, 5.50, 110.00, 'Monthly detergent restock'),
('FreshWash Co.', '2026-05-02', 'Fabric Softener', 15, 6.00, 90.00, 'Standard restock'),
('SparkleChem', '2026-05-03', 'Bleach', 10, 4.00, 40.00, 'Cleaning chemicals'),
('CleanPro Supplies', '2026-05-04', 'Hangers', 100, 0.25, 25.00, 'Bulk hanger order'),
('EcoClean Inc.', '2026-05-05', 'Eco Detergent', 18, 7.50, 135.00, 'Eco-friendly supply'),
('LaundryPlus', '2026-05-06', 'Stain Remover', 12, 8.00, 96.00, 'Specialty cleaning'),
('FreshWash Co.', '2026-05-07', 'Dry Cleaning Fluid', 8, 20.00, 160.00, 'High-cost chemical'),
('SparkleChem', '2026-05-08', 'Spot Cleaner', 14, 9.00, 126.00, 'Daily use'),
('CleanPro Supplies', '2026-05-09', 'Garment Bags', 25, 1.50, 37.50, 'Packaging'),
('EcoClean Inc.', '2026-05-10', 'Organic Soap', 10, 10.00, 100.00, 'Eco product'),
('LaundryPlus', '2026-05-11', 'Lint Rollers', 30, 2.00, 60.00, 'Counter supplies'),
('FreshWash Co.', '2026-05-12', 'Fabric Spray', 16, 6.50, 104.00, 'Garment finishing'),
('SparkleChem', '2026-05-13', 'Degreaser', 9, 11.00, 99.00, 'Heavy cleaning'),
('CleanPro Supplies', '2026-05-14', 'Plastic Covers', 80, 0.40, 32.00, 'Packaging restock'),
('EcoClean Inc.', '2026-05-15', 'Eco Bleach', 11, 6.00, 66.00, 'Eco cleaning'),
('LaundryPlus', '2026-05-16', 'Press Pads', 7, 15.00, 105.00, 'Pressing station'),
('FreshWash Co.', '2026-05-17', 'Iron Cleaner', 5, 12.00, 60.00, 'Machine maintenance'),
('SparkleChem', '2026-05-18', 'Odor Neutralizer', 13, 7.00, 91.00, 'Odor removal'),
('CleanPro Supplies', '2026-05-19', 'Tags', 200, 0.10, 20.00, 'Order tracking tags'),
('EcoClean Inc.', '2026-05-20', 'Natural Stain Remover', 9, 13.00, 117.00, 'Premium eco item'),
('LaundryPlus', '2026-05-21', 'Steam Cleaner Fluid', 6, 18.00, 108.00, 'Machine fluid'),
('FreshWash Co.', '2026-05-22', 'Fabric Conditioner', 14, 5.50, 77.00, 'Laundry finishing'),
('SparkleChem', '2026-05-23', 'Heavy Duty Cleaner', 10, 14.00, 140.00, 'Deep cleaning'),
('CleanPro Supplies', '2026-05-24', 'Laundry Baskets', 12, 9.00, 108.00, 'Shop supplies'),
('EcoClean Inc.', '2026-05-25', 'Eco Softener', 15, 6.50, 97.50, 'Eco softener'),
('LaundryPlus', '2026-05-26', 'Cleaning Cloths', 40, 1.00, 40.00, 'General cleaning'),
('FreshWash Co.', '2026-05-27', 'Perfume Spray', 8, 11.00, 88.00, 'Finishing scent'),
('SparkleChem', '2026-05-28', 'Solvent Cleaner', 7, 19.00, 133.00, 'Dry cleaning solvent'),
('CleanPro Supplies', '2026-05-29', 'Receipt Paper', 50, 0.50, 25.00, 'Register supplies'),
('EcoClean Inc.', '2026-05-30', 'Green Detergent', 20, 7.00, 140.00, 'Eco detergent restock');

-- ==========================================================
-- OPTIONAL MYSQL USERS
-- These are database-level users, not the Flask login users.
-- The Flask app creates cashier/admin accounts automatically.
-- ==========================================================

CREATE USER IF NOT EXISTS 'register_user'@'localhost' IDENTIFIED BY 'Register123!';
CREATE USER IF NOT EXISTS 'office_user'@'localhost' IDENTIFIED BY 'Office123!';

GRANT INSERT ON mydb.customers TO 'register_user'@'localhost';
GRANT INSERT ON mydb.orders TO 'register_user'@'localhost';
GRANT INSERT ON mydb.order_items TO 'register_user'@'localhost';
GRANT SELECT ON mydb.item_types TO 'register_user'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'office_user'@'localhost';

