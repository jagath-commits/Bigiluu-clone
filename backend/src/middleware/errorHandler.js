const { AppError } = require('../utils/customErrors');

module.exports = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Log detailed error for server administrators
  console.error(`[ERROR] [${req.method}] ${req.originalUrl}: ${err.message}`);
  if (err.stack) {
    console.error(err.stack);
  }

  // Format standard API response for failures
  return res.status(err.statusCode).json({
    success: false,
    message: err.isOperational ? err.message : 'Something went wrong on the server',
    data: null,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
};
