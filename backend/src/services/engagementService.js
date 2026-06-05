const engagementRepository = require('../repositories/engagementRepository');
const postRepository = require('../repositories/postRepository');
const { NotFoundError } = require('../utils/customErrors');

class EngagementService {
  async toggleSupport(userId, postId) {
    const post = await postRepository.findById(postId);
    if (!post) {
      throw new NotFoundError('Story not found');
    }
    return await engagementRepository.toggleSupport(userId, postId);
  }

  async toggleSave(userId, postId) {
    const post = await postRepository.findById(postId);
    if (!post) {
      throw new NotFoundError('Story not found');
    }
    return await engagementRepository.toggleSave(userId, postId);
  }

  async getSavedPosts(userId) {
    return await engagementRepository.findSavedPostsByUserId(userId);
  }
}

module.exports = new EngagementService();
