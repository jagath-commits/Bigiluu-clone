const authService = require('../services/authService');

class AuthController {
  async register(req, res, next) {
    try {
      const { mobileNumber, password, username, email, constituency } = req.body;
      const profileImage = req.file ? req.file.filename : null;

      const result = await authService.register({
        mobileNumber,
        password,
        username,
        email,
        constituency,
        profileImage
      });

      return res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: result
      });
    } catch (err) {
      next(err);
    }
  }

  async login(req, res, next) {
    try {
      const { mobileNumber, password } = req.body;

      const result = await authService.login(mobileNumber, password);

      return res.status(200).json({
        success: true,
        message: 'Login successful',
        data: result
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
