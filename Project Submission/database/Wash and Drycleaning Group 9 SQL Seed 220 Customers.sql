USE mydb;

-- Make sure item types exist
INSERT INTO item_types (item_name, base_price)
SELECT 'Shirt', 10.00
WHERE NOT EXISTS (SELECT 1 FROM item_types WHERE item_name = 'Shirt');

INSERT INTO item_types (item_name, base_price)
SELECT 'Pants', 10.00
WHERE NOT EXISTS (SELECT 1 FROM item_types WHERE item_name = 'Pants');

INSERT INTO item_types (item_name, base_price)
SELECT 'Coat', 15.00
WHERE NOT EXISTS (SELECT 1 FROM item_types WHERE item_name = 'Coat');

INSERT INTO item_types (item_name, base_price)
SELECT 'Jacket', 15.00
WHERE NOT EXISTS (SELECT 1 FROM item_types WHERE item_name = 'Jacket');


DROP PROCEDURE IF EXISTS generate_220_real_customers;

DELIMITER $$

CREATE PROCEDURE generate_220_real_customers()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE new_customer_id INT;
    DECLARE new_order_id INT;

    DECLARE first_name_value VARCHAR(50);
    DECLARE last_name_value VARCHAR(50);
    DECLARE phone_value VARCHAR(20);
    DECLARE email_value VARCHAR(100);

    DECLARE shirt_id INT;
    DECLARE pants_id INT;
    DECLARE shirt_price DECIMAL(10,2);
    DECLARE pants_price DECIMAL(10,2);

    SELECT item_type_id, base_price
    INTO shirt_id, shirt_price
    FROM item_types
    WHERE item_name = 'Shirt'
    LIMIT 1;

    SELECT item_type_id, base_price
    INTO pants_id, pants_price
    FROM item_types
    WHERE item_name = 'Pants'
    LIMIT 1;

    WHILE i <= 220 DO

        SET first_name_value = ELT(
            MOD(i - 1, 40) + 1,
            'Emily', 'Daniel', 'Sarah', 'Michael', 'Jessica',
            'David', 'Amanda', 'Chris', 'Olivia', 'Kevin',
            'Sophia', 'Ryan', 'Grace', 'Jason', 'Chloe',
            'Brian', 'Hannah', 'Andrew', 'Rachel', 'Alex',
            'Maria', 'Jose', 'Linda', 'Robert', 'Angela',
            'Mark', 'Anna', 'John', 'Katie', 'Peter',
            'Putri', 'Budi', 'Sari', 'Dewi', 'Rina',
            'Andi', 'Maya', 'Bayu', 'Minji', 'Jihoon'
        );

        SET last_name_value = ELT(
            MOD(i - 1, 35) + 1,
            'Smith', 'Johnson', 'Brown', 'Lee', 'Kim',
            'Nguyen', 'Garcia', 'Martinez', 'Davis', 'Wilson',
            'Anderson', 'Taylor', 'Chen', 'Park', 'Patel',
            'Tan', 'Wong', 'Siregar', 'Hulu', 'Pratama',
            'Santos', 'Lopez', 'Miller', 'Clark', 'Adams',
            'Young', 'Morgan', 'Turner', 'Scott', 'Hill',
            'Baker', 'Collins', 'Rivera', 'Carter', 'Reed'
        );

        SET phone_value = CONCAT('617-555-', LPAD(2000 + i, 4, '0'));

        SET email_value = CONCAT(
            LOWER(first_name_value),
            '.',
            LOWER(last_name_value),
            i,
            '@example.com'
        );

        INSERT INTO customers (
            first_name,
            last_name,
            phone,
            email,
            created_at
        )
        VALUES (
            first_name_value,
            last_name_value,
            phone_value,
            email_value,
            NOW()
        )
        ON DUPLICATE KEY UPDATE
            first_name = VALUES(first_name),
            last_name = VALUES(last_name),
            email = VALUES(email),
            customer_id = LAST_INSERT_ID(customer_id);

        SET new_customer_id = LAST_INSERT_ID();

        -- Add one order only if this customer does not already have an order
        IF NOT EXISTS (
            SELECT 1
            FROM orders
            WHERE customer_id = new_customer_id
        ) THEN

            INSERT INTO orders (
                customer_id,
                dropoff_date,
                promised_date,
                payment_status,
                order_status,
                notes,
                total_items,
                total_amount
            )
            VALUES (
                new_customer_id,
                DATE_SUB(CURDATE(), INTERVAL MOD(i, 60) DAY),
                DATE_ADD(DATE_SUB(CURDATE(), INTERVAL MOD(i, 60) DAY), INTERVAL 3 DAY),
                CASE
                    WHEN MOD(i, 3) = 0 THEN 'Unpaid'
                    WHEN MOD(i, 3) = 1 THEN 'Paid'
                    ELSE 'Partial'
                END,
                CASE
                    WHEN MOD(i, 4) = 0 THEN 'Received'
                    WHEN MOD(i, 4) = 1 THEN 'Cleaning'
                    WHEN MOD(i, 4) = 2 THEN 'Ready'
                    ELSE 'Picked Up'
                END,
                'Generated sample order for project demo',
                3,
                (shirt_price * 2) + (pants_price * 1)
            );

            SET new_order_id = LAST_INSERT_ID();

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
            (
                new_order_id,
                shirt_id,
                'Standard',
                2,
                shirt_price,
                shirt_price * 2,
                'Received'
            ),
            (
                new_order_id,
                pants_id,
                'Standard',
                1,
                pants_price,
                pants_price * 1,
                'Received'
            );

        END IF;

        SET i = i + 1;

    END WHILE;
END$$

DELIMITER ;

CALL generate_220_real_customers();

-- Check result
SELECT COUNT(*) AS total_customers
FROM customers;

-- Preview the first 30 customers
SELECT customer_id, first_name, last_name, phone, email
FROM customers
ORDER BY customer_id
LIMIT 30;