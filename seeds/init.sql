-- ===========================================================================
-- E-Commerce Database Seed Script
--
-- Creates the products and orders tables (if they do not already exist) and
-- inserts a realistic set of sample products.  The INSERT uses
-- ON CONFLICT DO NOTHING so the script is fully idempotent.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Products Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255)   NOT NULL,
    description     TEXT,
    price           DECIMAL(10,2)  NOT NULL,
    category        VARCHAR(100),
    stock_quantity  INTEGER        DEFAULT 0,
    created_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Orders Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    product_id      INTEGER        REFERENCES products(id),
    quantity        INTEGER        NOT NULL,
    total_price     DECIMAL(10,2)  NOT NULL,
    status          VARCHAR(50)    DEFAULT 'pending',
    created_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Add a unique constraint on product name so ON CONFLICT works correctly
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'products_name_unique'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT products_name_unique UNIQUE (name);
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- Seed Products — 18 realistic items across 5 categories
-- ---------------------------------------------------------------------------
INSERT INTO products (name, description, price, category, stock_quantity) VALUES
    -- Electronics
    ('Wireless Bluetooth Headphones',   'Over-ear noise-cancelling headphones with 30-hour battery life',                    79.99,  'Electronics',    150),
    ('USB-C Fast Charger',              '65 W GaN charger with dual USB-C ports',                                           34.99,  'Electronics',    300),
    ('4K Webcam',                       '4K Ultra HD webcam with auto-focus and built-in ring light',                        129.99, 'Electronics',     85),
    ('Portable SSD 1 TB',               'Compact external SSD with USB 3.2 Gen 2 interface, up to 1050 MB/s',               89.99,  'Electronics',    200),

    -- Clothing
    ('Classic Denim Jacket',            'Timeless medium-wash denim jacket, unisex, cotton blend',                           59.99,  'Clothing',       120),
    ('Merino Wool Crew Socks (3-Pack)', 'Breathable merino wool socks, moisture-wicking, fits sizes 8-12',                   24.99,  'Clothing',       500),
    ('Lightweight Running Shorts',      'Quick-dry athletic shorts with zip pocket and reflective trim',                     29.99,  'Clothing',       250),
    ('Organic Cotton T-Shirt',          'Soft ring-spun organic cotton tee, relaxed fit',                                    19.99,  'Clothing',       400),

    -- Home & Kitchen
    ('Stainless Steel French Press',    '34 oz double-wall insulated French press coffee maker',                             39.99,  'Home & Kitchen', 175),
    ('Bamboo Cutting Board Set',        'Set of 3 eco-friendly bamboo cutting boards with juice grooves',                    27.99,  'Home & Kitchen', 220),
    ('Cast Iron Skillet 12"',           'Pre-seasoned 12-inch cast iron skillet, oven-safe to 500 °F',                       44.99,  'Home & Kitchen', 130),
    ('LED Desk Lamp',                   'Adjustable LED desk lamp with 5 brightness levels and USB charging port',           36.99,  'Home & Kitchen', 190),

    -- Sports
    ('Yoga Mat Premium 6 mm',           'Non-slip TPE yoga mat with alignment lines, 72 × 24 inches',                       34.99,  'Sports',         160),
    ('Adjustable Dumbbell Set',         'Pair of adjustable dumbbells, 5–25 lb each, compact design',                       149.99, 'Sports',          75),
    ('Insulated Water Bottle 32 oz',    'Double-wall vacuum insulated stainless steel bottle, keeps cold 24 h',              22.99,  'Sports',         350),

    -- Books
    ('Clean Code',                      'Robert C. Martin — A handbook of agile software craftsmanship',                     37.49,  'Books',          100),
    ('Designing Data-Intensive Apps',   'Martin Kleppmann — Principles behind reliable, scalable systems',                   42.99,  'Books',           90),
    ('The Pragmatic Programmer',        'David Thomas & Andrew Hunt — 20th anniversary edition',                             39.99,  'Books',          110)
ON CONFLICT (name) DO NOTHING;
