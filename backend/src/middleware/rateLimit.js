const rateLimit = require('express-rate-limit');

// Strict limiter for authentication endpoints (Login/Signup)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Limit each IP to 30 authentication requests per window
  message: {
    success: false,
    message: 'Too many authentication attempts from this IP, please try again after 15 minutes',
    data: null
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Standard limiter for general API endpoints
const apiLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 300, // Limit each IP to 300 general requests per window
  message: {
    success: false,
    message: 'Too many requests from this IP, please slow down',
    data: null
  },
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = {
  authLimiter,
  apiLimiter
};
