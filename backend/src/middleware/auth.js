const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { UnauthorizedError, ForbiddenError } = require('../utils/customErrors');
const userRepository = require('../repositories/userRepository');

const protect = async (req, res, next) => {
  try {
    let token = null;

    // 1. Extract from Authorization Header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }
    // 2. Fallback to query parameter (often used in webviews/links)
    else if (req.query.token) {
      token = req.query.token;
    }

    if (!token) {
      return next(new UnauthorizedError('Please log in to access this resource'));
    }

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, config.JWT_SECRET);
    } catch (err) {
      return next(new UnauthorizedError('Session has expired or token is invalid'));
    }

    // Verify user still exists and is active
    const currentUser = await userRepository.findById(decoded.userId);
    if (!currentUser) {
      return next(new UnauthorizedError('The user belonging to this token no longer exists'));
    }

    // Bind verified user context to request
    req.user = {
      userId: currentUser.UserId,
      mobileNumber: currentUser.MobileNumber,
      role: currentUser.Role
    };

    next();
  } catch (err) {
    next(err);
  }
};

const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(new ForbiddenError('You do not have permission to perform this action'));
    }
    next();
  };
};

module.exports = {
  protect,
  restrictTo
};
