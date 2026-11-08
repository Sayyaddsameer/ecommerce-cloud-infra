/**
 * E-Commerce API — Entry Point
 *
 * Initialises Datadog APM tracing (must happen before any other require),
 * then boots an Express server with product and order routes.
 */

// ---------------------------------------------------------------------------
// 1. Datadog APM — MUST be required before every other module
// ---------------------------------------------------------------------------
const tracer = require('dd-trace').init({
  service: process.env.DD_SERVICE || 'ecommerce-api',
  env: process.env.DD_ENV || 'development',
  logInjection: process.env.DD_LOGS_INJECTION === 'true',
  profiling: process.env.DD_PROFILING_ENABLED === 'true',
});

// ---------------------------------------------------------------------------
// 2. Framework & Middleware Imports
// ---------------------------------------------------------------------------
const express = require('express');
const morgan = require('morgan');
const cors = require('cors');

// Route modules
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');

// Database (for graceful shutdown)
const db = require('./db');

// ---------------------------------------------------------------------------
// 3. Express Application
// ---------------------------------------------------------------------------
const app = express();
const PORT = parseInt(process.env.PORT, 10) || 8080;

// --- Middleware ---
app.use(morgan('combined'));          // HTTP request logging
app.use(cors());                      // Cross-Origin Resource Sharing
app.use(express.json());              // Parse JSON request bodies

// --- Routes ---
app.use('/products', productRoutes);
app.use('/orders', orderRoutes);

// --- Health Check ---
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// --- Root ---
app.get('/', (_req, res) => {
  res.json({
    service: 'ecommerce-api',
    version: '1.0.0',
    description: 'E-Commerce REST API with read-replica support and Datadog observability',
    endpoints: {
      health: '/health',
      products: '/products',
      orders: '/orders',
    },
  });
});

// ---------------------------------------------------------------------------
// 4. Start Server
// ---------------------------------------------------------------------------
const server = app.listen(PORT, () => {
  console.log(`[server] E-Commerce API listening on port ${PORT}`);
  console.log(`[server] Environment: ${process.env.DD_ENV || 'development'}`);
});

// ---------------------------------------------------------------------------
// 5. Graceful Shutdown
// ---------------------------------------------------------------------------
function shutdown(signal) {
  console.log(`[server] ${signal} received — starting graceful shutdown…`);

  server.close(async () => {
    console.log('[server] HTTP server closed.');

    try {
      await db.close();
    } catch (err) {
      console.error('[server] Error closing database pools:', err.message);
    }

    console.log('[server] Shutdown complete.');
    process.exit(0);
  });

  // Force exit if graceful shutdown takes too long
  setTimeout(() => {
    console.error('[server] Forced shutdown after timeout.');
    process.exit(1);
  }, 10_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = app;
