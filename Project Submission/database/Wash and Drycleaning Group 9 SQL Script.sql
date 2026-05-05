USE mydb;

INSERT INTO customers (first_name, last_name, phone, email, created_at)
VALUES
('Lucio', 'Kuhlman', '617-555-9378', 'Kuhlman@email.com', NOW()),
('Gerry', 'Miller', '617-555-7463', 'Miller@email.com', NOW()),
('Lavinia', 'Bailey', '617-555-8164', 'Bailey@email.com', NOW()),
('Patsy', 'DuBuque', '857-555-6891', 'DuBuque@email.com', NOW()),
('Devin', 'Lesch', '617-555-1730', 'Lesch@email.com', NOW()),
('Selina', 'Jacobi', '617-555-9190', 'Jacobi@email.com', NOW());

INSERT INTO item_types (item_name, base_price)
VALUES
('Pants', 10.00),
('Coat', 15.00),
('Shirt', 10.00),
('Jacket', 15.00),
('Overcoat', 15.00),
('Blouse', 15.00),
('Tshirt', 10.00),
('Suit', 15.00),
('Skirt', 10.00);

INSERT INTO vendors (vendor_name, phone, category, notes)
VALUES
('CleanSupply Co', '617-555-1000', 'Detergent', 'Main detergent supplier'),
('PackRight', '617-555-2000', 'Packaging', 'Provides plastic covers and tags');

INSERT INTO orders (
    customer_id,
    dropoff_date,
    promised_date,
    ready_date,
    pickup_date,
    payment_status,
    order_status,
    total_items,
    total_amount,
    notes
)
VALUES
(1, '2026-02-02', '2026-02-03', NULL, NULL, 'Yes', 'DroppedOff', 3, 35.00, NULL),
(2, '2026-02-02', '2026-02-03', NULL, NULL, 'No', 'DroppedOff', 5, 60.00, NULL),
(3, '2026-02-03', '2026-02-04', NULL, NULL, 'Yes', 'Cleaning', 3, 45.00, NULL),
(4, '2026-02-04', '2026-02-05', NULL, NULL, 'Yes', 'Cleaning', 2, 20.00, NULL),
(5, '2026-02-04', '2026-02-05', NULL, NULL, 'Yes', 'DroppedOff', 7, 75.00, NULL),
(6, '2026-02-06', '2026-02-07', NULL, NULL, 'No', 'Cleaning', 5, 55.00, NULL);

INSERT INTO order_items (
    order_id,
    item_type_id,
    care_type,
    quantity,
    unit_price,
    line_total,
    item_status
)
VALUES
-- Order 1
(1, 1, 'Standard', 1, 10.00, 10.00, 'Cleaning'),
(1, 2, 'Specialty', 1, 15.00, 15.00, 'Cleaning'),
(1, 3, 'Standard', 1, 10.00, 10.00, 'Cleaning'),

-- Order 2
(2, 4, 'Specialty', 2, 15.00, 30.00, 'Cleaning'),
(2, 3, 'Standard', 3, 10.00, 30.00, 'Cleaning'),

-- Order 3
(3, 4, 'Specialty', 1, 15.00, 15.00, 'Ready'),
(3, 5, 'Specialty', 1, 15.00, 15.00, 'Ready'),
(3, 6, 'Specialty', 1, 15.00, 15.00, 'Ready'),

-- Order 4
(4, 3, 'Standard', 2, 10.00, 20.00, 'Ready'),

-- Order 5
(5, 1, 'Standard', 1, 10.00, 10.00, 'Cleaning'),
(5, 4, 'Specialty', 1, 15.00, 15.00, 'Cleaning'),
(5, 7, 'Standard', 5, 10.00, 50.00, 'Cleaning'),

-- Order 6
(6, 1, 'Standard', 2, 10.00, 20.00, 'Ready'),
(6, 8, 'Specialty', 1, 15.00, 15.00, 'Ready'),
(6, 9, 'Standard', 2, 10.00, 20.00, 'Ready');

INSERT INTO vendor_deliveries (
    vendor_id,
    delivery_date,
    supply_name,
    quantity,
    unit_cost,
    total_cost,
    notes
)
VALUES
(1, '2026-02-01', 'Detergent Box', 5, 18.00, 90.00, 'Monthly restock'),
(2, '2026-02-01', 'Plastic Covers', 100, 0.30, 30.00, 'Weekly restock');

SELECT * FROM customers;
SELECT * FROM item_types;
SELECT * FROM vendors;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM vendor_deliveries;

SELECT o.order_id, c.first_name, c.last_name, o.order_status, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

SELECT oi.order_item_id, o.order_id, it.item_name, oi.quantity, oi.care_type, oi.line_total
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN item_types it ON oi.item_type_id = it.item_type_id;

SELECT vd.delivery_id, v.vendor_name, vd.supply_name, vd.quantity, vd.total_cost
FROM vendor_deliveries vd
JOIN vendors v ON vd.vendor_id = v.vendor_id;