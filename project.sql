CREATE DATABASE food_app_project;

USE food_app_project;

-- 1) customers: independent
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255) ,
    city VARCHAR(100),
    signup_date DATE not null,
    gender VARCHAR(10)
);


-- 2) restaurants: independent
CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    cuisine VARCHAR(100),
    rating DECIMAL(3,2)
);

-- 3) delivery_agents: independent
CREATE TABLE delivery_agents (
    agent_id INT PRIMARY KEY,
    agent_name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    joining_date DATE,
    rating DECIMAL(3,2)
);

-- 4) orders: depends on customers and restaurants
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_amount DECIMAL(10,2),
    discount DECIMAL(5,2),
    payment_method VARCHAR(50),
    delivery_time_min INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- 5) order_item: depends on orders
CREATE TABLE order_item (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    item_name VARCHAR(255),
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- PHASE 8-- Performance Optimization
--  Index on order_date (for monthly reports)
CREATE INDEX idx_order_date ON orders(order_date);


-- Index on customer_name (for joins)
CREATE INDEX idx_customer_name ON customers(name);

-- Index on restaurant_name
CREATE INDEX idx_restaurant_name ON restaurants(restaurant_name);


-- PHASE 9 —Automation Logic

-- auto log high value order
CREATE TABLE high_value_order_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    customer_id INT,
    restaurant_id INT,
    order_amount DECIMAL(10,2),
    log_date datetime DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER log_high_value_order
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_amount IS NOT NULL AND NEW.order_amount > 1000 THEN
        INSERT INTO high_value_order_log (order_id, customer_id, restaurant_id, order_amount)
        VALUES (NEW.order_id, NEW.customer_id, NEW.restaurant_id, COALESCE(NEW.order_amount,0) - COALESCE(NEW.discount,0));
    END IF;
END;

-- example inserts (ensure restaurant_id present)
INSERT INTO orders VALUES (1011, 230, 137, '2024-01-01', 1200.00, 100.00, 'Credit Card', 30);
INSERT INTO orders VALUES (1016, 233, 140, '2024-01-03', 800.00, 50.00, 'Cash', 25);


-- TRIGGER 1 — Prevent Negative Discount

CREATE TRIGGER prevent_negative_discount
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.discount < 0 THEN
        SET NEW.discount = 0;
    END IF;
END ;

INSERT INTO orders VALUES (1015, 231, 138, '2024-01-01', 100.00, -10.00, 'Credit Card', 30);
 SELECT * FROM orders WHERE order_id = 1015;

-- 2 — Delivery Delay Warning

CREATE TABLE delivery_delay_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    customer_id INT,
    restaurant_id INT,
    delivery_time_min INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TRIGGER delivery_delay_warning
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.delivery_time_min IS NOT NULL AND NEW.delivery_time_min > 45 THEN
        INSERT INTO delivery_delay_log (
            order_id, customer_id, restaurant_id, delivery_time_min
        )
        VALUES (
            NEW.order_id, NEW.customer_id, NEW.restaurant_id, NEW.delivery_time_min
        );
    END IF;
END;


Insert INTO orders VALUES (1018, 232, 139, '2024-01-02', 150.00, 20.00, 'Cash', 50);
 SELECT * FROM delivery_delay_log WHERE order_id = 1018;
