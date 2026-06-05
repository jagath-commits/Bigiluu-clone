const userService = require('../services/userService');

class UserController {
  async getProfile(req, res, next) {
    try {
      const userId = req.params.userId || req.user.userId;
      const profile = await userService.getProfile(userId);

      return res.status(200).json({
        success: true,
        message: 'Profile retrieved successfully',
        data: profile
      });
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const userId = req.user.userId;
      const { username, email, constituency } = req.body;
      const profileImage = req.file ? req.file.filename : undefined;

      const updated = await userService.updateProfile(userId, {
        username,
        email,
        constituency,
        profileImage
      });

      return res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: updated
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new UserController();
