-- Schema: Olist Brazilian E-Commerce Dataset
-- Tables required for the Price Elasticity of Demand (PED) analysis

-- Drop tables if they already exist (useful for re-running the setup)
DROP TABLE IF EXISTS olist_order_items_dataset;
DROP TABLE IF EXISTS olist_orders_dataset;
DROP TABLE IF EXISTS olist_products_dataset;
DROP TABLE IF EXISTS olist_category_name_translation;

-- 1. Orders

CREATE TABLE olist_orders_dataset (
    order_id                       VARCHAR(32) PRIMARY KEY,
    customer_id                    VARCHAR(32),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

-- 2. Order Items

CREATE TABLE olist_order_items_dataset (
    order_id              VARCHAR(32),
    order_item_id         INTEGER,
    product_id            VARCHAR(32),
    seller_id             VARCHAR(32),
    shipping_limit_date   TIMESTAMP,
    price                 NUMERIC(10,2),
    freight_value         NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset (order_id)
);

-- 3. Products

CREATE TABLE olist_products_dataset (
    product_id                  VARCHAR(32) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght         INTEGER,
    product_description_lenght  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            INTEGER,
    product_length_cm           INTEGER,
    product_height_cm           INTEGER,
    product_width_cm            INTEGER
);

-- 4. Category Name Translation

CREATE TABLE olist_category_name_translation (
    product_category_name          VARCHAR(100) PRIMARY KEY,
    product_category_name_english  VARCHAR(100)
);
