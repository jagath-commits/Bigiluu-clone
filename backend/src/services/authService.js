const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const userRepository = require('../repositories/userRepository');
const config = require('../config/config');
const { BadRequestError, UnauthorizedError, ConflictError } = require('../utils/customErrors');

class AuthService {
  async register({ mobileNumber, password, username, email, constituency, profileImage }) {
    // 1. Validation check
    if (!mobileNumber || !password || !username || !email) {
      throw new BadRequestError('Required parameters are missing');
    }

    // 2. Check if mobile number already exists
    const existingMobile = await userRepository.findByMobile(mobileNumber);
    if (existingMobile) {
      throw new ConflictError('Mobile number is already registered');
    }

    // 3. Check if email already exists
    const existingEmail = await userRepository.findByEmail(email);
    if (existingEmail) {
      throw new ConflictError('Email is already registered');
    }

    // 4. Hash the password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 5. Create the user
    const newUser = await userRepository.create({
      mobileNumber,
      passwordHash,
      username,
      email,
      constituency,
      profileImage,
      role: 'User'
    });

    // 6. Generate JWT token
    const token = this.generateToken(newUser);

    return {
      token,
      user_id: newUser.UserId,
      user_mobile: newUser.MobileNumber,
      username: newUser.Username,
      email: newUser.Email,
      constituency: newUser.Constituency,
      profile_image: newUser.ProfileImage
    };
  }

  async login(mobileNumber, password) {
    if (!mobileNumber || !password) {
      throw new BadRequestError('Mobile number and password are required');
    }

    // Find user
    const user = await userRepository.findByMobile(mobileNumber);
    if (!user) {
      throw new UnauthorizedError('Invalid mobile number or password');
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, user.PasswordHash);
    if (!isMatch) {
      throw new UnauthorizedError('Invalid mobile number or password');
    }

    // Generate JWT token
    const token = this.generateToken(user);

    return {
      token,
      user_id: user.UserId,
      user_mobile: user.MobileNumber,
      username: user.Username,
      email: user.Email,
      constituency: user.Constituency,
      profile_image: user.ProfileImage
    };
  }

  generateToken(user) {
    return jwt.sign(
      {
        userId: user.UserId,
        mobileNumber: user.MobileNumber,
        role: user.Role
      },
      config.JWT_SECRET,
      { expiresIn: config.JWT_EXPIRES_IN }
    );
  }
}

module.exports = new AuthService();
