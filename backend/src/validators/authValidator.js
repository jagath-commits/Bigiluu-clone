const { BadRequestError } = require('../utils/customErrors');

const validateSignup = (req, res, next) => {
  const { mobileNumber, password, username, email } = req.body;

  if (!mobileNumber || !password || !username || !email) {
    return next(new BadRequestError('All fields (mobileNumber, password, username, email) are required'));
  }

  // 1. Mobile Number (10 digits starting with +91 or raw 10 digits as per Flutter UI)
  const phoneRegex = /^[0-9]{10}$/;
  if (!phoneRegex.test(mobileNumber)) {
    return next(new BadRequestError('Mobile number must be a valid 10-digit number'));
  }

  // 2. Email Validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return next(new BadRequestError('Email address must be a valid structure'));
  }

  // 3. Username Validation
  if (username.trim().length < 3) {
    return next(new BadRequestError('Username must be at least 3 characters long'));
  }

  // 4. Password validation
  if (password.length < 6) {
    return next(new BadRequestError('Password must be at least 6 characters long'));
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { mobileNumber, password } = req.body;

  if (!mobileNumber || !password) {
    return next(new BadRequestError('Mobile number and password are required'));
  }

  const phoneRegex = /^[0-9]{10}$/;
  if (!phoneRegex.test(mobileNumber)) {
    return next(new BadRequestError('Mobile number must be a valid 10-digit number'));
  }

  next();
};

module.exports = {
  validateSignup,
  validateLogin
};
