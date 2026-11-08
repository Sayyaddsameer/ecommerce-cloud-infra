/**
 * Order Routes
 *
 * Provides endpoints for listing and creating orders.
 * Reads go to the replica; writes go to the primary (writer) pool.
 */

const express = require('express');
const db = require('../db');

const router = express.Router();

// ---------------------------------------------------------------------------
// GET /orders — List all orders
// ---------------------------------------------------------------------------
router.get('/', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT o.id, o.product_id, p.name AS product_name,
              o.quantity, o.total_price, o.status, o.created_at
       FROM orders o
       LEFT JOIN products p ON p.id = o.product_id
       ORDER BY o.created_at DESC`,
      [],
      true, // useReplica — read query
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (err) {
    console.error('[orders] Error listing orders:', err.message);
    res.status(500).json({ success: false, error: 'Failed to fetch orders' });
  }
});

// ---------------------------------------------------------------------------
// POST /orders — Create a new order
// ---------------------------------------------------------------------------
router.post('/', async (req, res) => {
  try {
    const { product_id, quantity } = req.body;

    // ----- Input validation ------------------------------------------------
    if (!product_id || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'product_id and quantity are required',
      });
    }

    if (!Number.isInteger(quantity) || quantity <= 0) {
      return res.status(400).json({
        success: false,
        error: 'quantity must be a positive integer',
      });
    }

    // ----- Look up the product (writer pool for strong consistency) ---------
    const productResult = await db.query(
      'SELECT id, name, price, stock_quantity FROM products WHERE id = $1',
      [product_id],
      false, // use writer for consistency
    );

    if (productResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Product not found' });
    }

    const product = productResult.rows[0];

    // ----- Check stock availability ----------------------------------------
    if (product.stock_quantity < quantity) {
      return res.status(400).json({
        success: false,
        error: `Insufficient stock. Available: ${product.stock_quantity}`,
      });
    }

    // ----- Calculate total and insert the order ----------------------------
    const totalPrice = (parseFloat(product.price) * quantity).toFixed(2);

    const orderResult = await db.query(
      `INSERT INTO orders (product_id, quantity, total_price, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING id, product_id, quantity, total_price, status, created_at`,
      [product_id, quantity, totalPrice],
      false, // writer pool — this is a write operation
    );

    // ----- Decrement stock (best-effort; a real system would use a tx) -----
    await db.query(
      'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE id = $2',
      [quantity, product_id],
      false,
    );

    res.status(201).json({
      success: true,
      data: {
        ...orderResult.rows[0],
        product_name: product.name,
      },
    });
  } catch (err) {
    console.error('[orders] Error creating order:', err.message);
    res.status(500).json({ success: false, error: 'Failed to create order' });
  }
});

module.exports = router;
