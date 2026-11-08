/**
 * Product Routes
 *
 * Provides read-only endpoints for browsing the product catalogue.
 * All queries are routed to the read-replica for horizontal scalability.
 */

const express = require('express');
const db = require('../db');
const metrics = require('../metrics');

const router = express.Router();

// ---------------------------------------------------------------------------
// GET /products — List all products
// ---------------------------------------------------------------------------
router.get('/', async (req, res) => {
  try {
    metrics.incrementProductRequests();

    const result = await db.query(
      'SELECT id, name, description, price, category, stock_quantity, created_at FROM products ORDER BY id',
      [],
      true, // useReplica
    );

    // Debug header so operators can verify replica routing
    res.set('X-DB-Source', 'replica');
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (err) {
    console.error('[products] Error listing products:', err.message);
    res.status(500).json({ success: false, error: 'Failed to fetch products' });
  }
});

// ---------------------------------------------------------------------------
// GET /products/:id — Get a single product by ID
// ---------------------------------------------------------------------------
router.get('/:id', async (req, res) => {
  try {
    metrics.incrementProductRequests();

    const { id } = req.params;
    const result = await db.query(
      'SELECT id, name, description, price, category, stock_quantity, created_at FROM products WHERE id = $1',
      [id],
      true, // useReplica
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Product not found' });
    }

    res.set('X-DB-Source', 'replica');
    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error('[products] Error fetching product:', err.message);
    res.status(500).json({ success: false, error: 'Failed to fetch product' });
  }
});

module.exports = router;
