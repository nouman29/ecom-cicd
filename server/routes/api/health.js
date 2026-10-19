const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const DB_STATES = ['disconnected', 'connected', 'connecting', 'disconnecting'];

// Liveness + DB connectivity check, used by the CD smoke test
router.get('/', (req, res) => {
  const dbConnected = mongoose.connection.readyState === 1;

  res.status(dbConnected ? 200 : 503).json({
    status: dbConnected ? 'ok' : 'error',
    database: DB_STATES[mongoose.connection.readyState] || 'unknown',
    version: process.env.APP_VERSION || 'dev',
    uptime: Math.round(process.uptime()),
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
