const userRepository = require('../repositories/userRepository');
const constituencies = require('../constants/constituencies');
const { NotFoundError, BadRequestError } = require('../utils/customErrors');

class UserService {
  async getProfile(userId) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new NotFoundError('User profile not found');
    }
    return user;
  }

  async updateProfile(userId, { username, email, constituency, profileImage }) {
    // Validate constituency if provided
    if (constituency && !constituencies.includes(constituency)) {
      throw new BadRequestError('Invalid assembly constituency provided');
    }

    const updatedUser = await userRepository.update(userId, {
      username,
      email,
      constituency,
      profileImage
    });

    if (!updatedUser) {
      throw new NotFoundError('User profile not found or could not be updated');
    }

    return updatedUser;
  }
}

module.exports = new UserService();
