/**
 * Datadog Custom Metrics Module
 *
 * Sends custom application metrics to the Datadog Agent via DogStatsD.
 * All metric names are namespaced under the application prefix for clarity
 * in dashboards and monitors.
 */

const { StatsD } = require('hot-shots');

// ---------------------------------------------------------------------------
// StatsD Client
// ---------------------------------------------------------------------------
const statsd = new StatsD({
  host: process.env.DD_AGENT_HOST || 'localhost',
  port: parseInt(process.env.DD_DOGSTATSD_PORT, 10) || 8125,
  // Global tags applied to every metric emitted by this client
  globalTags: {
    service: process.env.DD_SERVICE || 'ecommerce-api',
    env: process.env.DD_ENV || 'development',
  },
  errorHandler: (err) => {
    // Log the error but never let a metrics failure crash the application
    console.error('[metrics] StatsD error:', err.message);
  },
});

// ---------------------------------------------------------------------------
// Exported Metric Helpers
// ---------------------------------------------------------------------------

/**
 * Increment the counter that tracks total product-related requests.
 */
function incrementProductRequests() {
  try {
    statsd.increment('products.requests.total');
  } catch (err) {
    console.error('[metrics] Failed to increment products.requests.total:', err.message);
  }
}

/**
 * Record how long a database query took.
 *
 * @param {number} durationMs - Query duration in milliseconds.
 */
function recordQueryDuration(durationMs) {
  try {
    statsd.timing('db.query.duration_ms', durationMs);
  } catch (err) {
    console.error('[metrics] Failed to record db.query.duration_ms:', err.message);
  }
}

module.exports = {
  statsd,
  incrementProductRequests,
  recordQueryDuration,
};
