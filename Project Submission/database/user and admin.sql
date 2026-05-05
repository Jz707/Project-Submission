CREATE USER IF NOT EXISTS 'register_user'@'localhost' IDENTIFIED BY 'Register123!';
CREATE USER IF NOT EXISTS 'office_user'@'localhost' IDENTIFIED BY 'Office123!';

GRANT INSERT ON mydb.customers TO 'register_user'@'localhost';
GRANT INSERT ON mydb.orders TO 'register_user'@'localhost';
GRANT INSERT ON mydb.order_items TO 'register_user'@'localhost';
GRANT SELECT ON mydb.item_types TO 'register_user'@'localhost';
GRANT SELECT ON mydb.vendors TO 'register_user'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'office_user'@'localhost';

SHOW GRANTS FOR 'register_user'@'localhost';
SHOW GRANTS FOR 'office_user'@'localhost';