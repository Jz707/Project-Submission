USE mydb;

SET SQL_SAFE_UPDATES = 0;

-- 1. Check duplicate phone numbers
SELECT phone, COUNT(*) AS duplicate_count
FROM customers
WHERE phone IS NOT NULL AND phone <> ''
GROUP BY phone
HAVING COUNT(*) > 1;

-- 2. Keep the first customer with each phone number.
-- Change the duplicate customers' phone numbers to demo phone numbers.
CREATE TEMPORARY TABLE duplicate_customers AS
SELECT c.customer_id
FROM customers c
JOIN (
    SELECT phone, MIN(customer_id) AS keep_customer_id
    FROM customers
    WHERE phone IS NOT NULL AND phone <> ''
    GROUP BY phone
    HAVING COUNT(*) > 1
) d
ON c.phone = d.phone
WHERE c.customer_id <> d.keep_customer_id;

UPDATE customers c
JOIN duplicate_customers d
ON c.customer_id = d.customer_id
SET c.phone = CONCAT('555-', LPAD(c.customer_id, 6, '0'));

-- 3. Fix blank phone numbers too
UPDATE customers
SET phone = CONCAT('555-', LPAD(customer_id, 6, '0'))
WHERE phone IS NULL OR phone = '';

-- 4. Check again. This should return no rows.
SELECT phone, COUNT(*) AS duplicate_count
FROM customers
WHERE phone IS NOT NULL AND phone <> ''
GROUP BY phone
HAVING COUNT(*) > 1;

-- 5. Now add the unique rule
ALTER TABLE customers
ADD CONSTRAINT uq_customers_phone UNIQUE (phone);

SET SQL_SAFE_UPDATES = 1;