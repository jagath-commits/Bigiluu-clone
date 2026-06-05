const { BadRequestError } = require('../utils/customErrors');
const constituencies = require('../constants/constituencies');

const validateProfileUpdate = (req, res, next) => {
  const { username, email, constituency } = req.body;

  if (email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return next(new BadRequestError('Email address must be valid'));
    }
  }

  if (username && username.trim().length < 3) {
    return next(new BadRequestError('Username must be at least 3 characters long'));
  }

  if (constituency && !constituencies.includes(constituency)) {
    return next(new BadRequestError('Assembly constituency must be a valid Tamil Nadu constituency'));
  }

  next();
};

module.exports = {
  validateProfileUpdate
};
