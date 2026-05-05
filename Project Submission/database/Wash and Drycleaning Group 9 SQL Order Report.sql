USE mydb;

SELECT
    o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.phone,
    c.email,
    o.dropoff_date,
    o.promised_date,
    o.payment_status,
    o.order_status,
    o.total_items,
    o.total_amount,
    o.notes,
    COALESCE(
        GROUP_CONCAT(
            CONCAT(it.item_name, ' x', oi.quantity, ' - ', oi.care_type)
            SEPARATOR ', '
        ),
        'No items'
    ) AS item_details
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN item_types it
    ON oi.item_type_id = it.item_type_id
GROUP BY
    o.order_id,
    o.customer_id,
    c.first_name,
    c.last_name,
    c.phone,
    c.email,
    o.dropoff_date,
    o.promised_date,
    o.payment_status,
    o.order_status,
    o.total_items,
    o.total_amount,
    o.notes
ORDER BY o.order_id DESC;