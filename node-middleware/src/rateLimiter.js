const rateLimit = require('express-rate-limit');
const { RATE_LIMIT_WINDOW, RATE_LIMIT_MAX } = require('./config');

module.exports = rateLimit({
  windowMs: RATE_LIMIT_WINDOW,
  max:      RATE_LIMIT_MAX,
  standardHeaders: true,   // adds RateLimit-* headers
  legacyHeaders:   false,
  message: { error: 'Too many requests', message: 'Slow down and retry after the window resets.' },
  // Key by IP — in production, if behind nginx, trust the X-Forwarded-For header:
  // app.set('trust proxy', 1);
});