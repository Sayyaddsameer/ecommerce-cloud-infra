/**
 * Database Module — Read / Write Pool Routing
 *
 * Maintains two pg connection pools:
 *   • writerPool  → primary (read-write) instance
 *   • readerPool  → read-replica instance (falls back to the writer host)
 *
 * The exported `query` helper automatically routes queries to the correct
 * pool based on the `useReplica` flag and records timing metrics via the
 * metrics module.
 */

const { Pool } = require('pg');
const metrics = require('./metrics');

// ---------------------------------------------------------------------------
// Connection Configuration
// ---------------------------------------------------------------------------
const DB_PORT = parseInt(process.env.DB_PORT, 10) || 5432;
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD;
const DB_NAME = process.env.DB_NAME;

const writerHost = process.env.DB_WRITER_HOST || process.env.DB_HOST || 'localhost';
const readerHost = process.env.DB_READER_HOST || process.env.DB_WRITER_HOST || process.env.DB_HOST || 'localhost';

// ---------------------------------------------------------------------------
// Pool Instances
// ---------------------------------------------------------------------------

/** Pool connected to the primary (writer) database instance. */
const writerPool = new Pool({
  host: writerHost,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  max: 20,                // maximum number of clients in the pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

/** Pool connected to the read-replica database instance. */
const readerPool = new Pool({
  host: readerHost,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// ---------------------------------------------------------------------------
// Connection Error Handlers
// ---------------------------------------------------------------------------
writerPool.on('error', (err) => {
  console.error('[db] Unexpected error on writer pool idle client:', err.message);
});

readerPool.on('error', (err) => {
  console.error('[db] Unexpected error on reader pool idle client:', err.message);
});

// Log pool creation for observability
console.log(`[db] Writer pool configured → ${writerHost}:${DB_PORT}/${DB_NAME}`);
console.log(`[db] Reader pool configured → ${readerHost}:${DB_PORT}/${DB_NAME}`);

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Return the writer (primary) pool instance.
 * @returns {Pool}
 */
function getWriterPool() {
  return writerPool;
}

/**
 * Return the reader (replica) pool instance.
 * @returns {Pool}
 */
function getReaderPool() {
  return readerPool;
}

/**
 * Execute a SQL query, automatically routing to the writer or reader pool.
 * Records query duration as a custom metric.
 *
 * @param {string}  text        - Parameterized SQL string.
 * @param {Array}   [params=[]] - Bind parameters.
 * @param {boolean} [useReplica=false] - When true the query runs against the reader pool.
 * @returns {Promise<import('pg').QueryResult>}
 */
async function query(text, params = [], useReplica = false) {
  const pool = useReplica ? readerPool : writerPool;
  const start = Date.now();

  try {
    const result = await pool.query(text, params);
    return result;
  } catch (err) {
    console.error('[db] Query error:', { text, error: err.message });
    throw err;
  } finally {
    const durationMs = Date.now() - start;
    metrics.recordQueryDuration(durationMs);
  }
}

/**
 * Gracefully close both connection pools.
 */
async function close() {
  console.log('[db] Closing database connections…');
  await Promise.all([writerPool.end(), readerPool.end()]);
  console.log('[db] All database connections closed.');
}

module.exports = {
  getWriterPool,
  getReaderPool,
  query,
  close,
};
