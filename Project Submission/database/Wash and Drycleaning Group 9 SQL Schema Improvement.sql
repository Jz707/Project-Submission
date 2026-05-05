USE mydb;

SELECT DISTINCT payment_status FROM orders;
SELECT DISTINCT order_status FROM orders;
SELECT item_name, COUNT(*) 
FROM item_types
GROUP BY item_name
HAVING COUNT(*) > 1;

SET SQL_SAFE_UPDATES = 0;

UPDATE orders
SET payment_status = 'Paid'
WHERE payment_status = 'Yes';

UPDATE orders
SET payment_status = 'Unpaid'
WHERE payment_status = 'No';

UPDATE orders
SET order_status = 'Received'
WHERE order_status = 'DroppedOff';

SET SQL_SAFE_UPDATES = 1;

SELECT DISTINCT payment_status FROM orders;
SELECT DISTINCT order_status FROM orders;

ALTER TABLE orders
MODIFY payment_status ENUM('Paid', 'Unpaid', 'Partial') NOT NULL;

ALTER TABLE orders
MODIFY order_status ENUM('Received', 'Cleaning', 'Ready', 'Picked Up') NOT NULL;

ALTER TABLE order_items
MODIFY care_type ENUM('Standard', 'Specialty', 'Express') NOT NULL;

ALTER TABLE order_items
MODIFY item_status ENUM('Received', 'Cleaning', 'Ready', 'Picked Up') NOT NULL;

ALTER TABLE item_types
ADD CONSTRAINT uq_item_types_item_name UNIQUE (item_name);

ALTER TABLE item_types
ADD CONSTRAINT chk_item_types_base_price
CHECK (base_price >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_total_items
CHECK (total_items >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_total_amount
CHECK (total_amount >= 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_items_quantity
CHECK (quantity > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_items_unit_price
CHECK (unit_price >= 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_items_line_total
CHECK (line_total >= 0);

ALTER TABLE vendor_deliveries
ADD CONSTRAINT chk_vendor_deliveries_quantity
CHECK (quantity > 0);

ALTER TABLE vendor_deliveries
ADD CONSTRAINT chk_vendor_deliveries_unit_cost
CHECK (unit_cost >= 0);

ALTER TABLE vendor_deliveries
ADD CONSTRAINT chk_vendor_deliveries_total_cost
CHECK (total_cost >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_promised_date
CHECK (promised_date >= dropoff_date);

SHOW CREATE TABLE orders;
SHOW CREATE TABLE order_items;
SHOW CREATE TABLE item_types;
SHOW CREATE TABLE vendor_deliveries;