const postRepository = require('../repositories/postRepository');
const userRepository = require('../repositories/userRepository');
const categoryRepository = require('../repositories/categoryRepository');
const { NotFoundError, BadRequestError, ForbiddenError } = require('../utils/customErrors');

class PostService {
  async createPost({ userId, categoryId, title, caption, content, coverImg, constituency }) {
    // Validate Category
    const category = await categoryRepository.findById(categoryId);
    if (!category) {
      throw new BadRequestError('Invalid category ID');
    }

    // Verify content is valid JSON
    try {
      JSON.parse(content);
    } catch (e) {
      throw new BadRequestError('Content must be a valid JSON-encoded string representing pages and blocks');
    }

    // If constituency is missing, inherit from User profile
    let postConstituency = constituency;
    if (!postConstituency) {
      const user = await userRepository.findById(userId);
      if (user) {
        postConstituency = user.Constituency;
      }
    }

    return await postRepository.create({
      userId,
      categoryId,
      title,
      caption,
      content,
      coverImg,
      constituency: postConstituency
    });
  }

  async getPostById(postId) {
    const post = await postRepository.findById(postId);
    if (!post) {
      throw new NotFoundError('Story not found');
    }
    return post;
  }

  async getPostsFeed(params) {
    const page = parseInt(params.page, 10) || 1;
    const limit = parseInt(params.limit, 10) || 10;
    const search = params.search || '';
    const categoryId = params.categoryId || '';
    const constituency = params.constituency || '';
    const sorting = params.sorting || 'CreatedDate DESC';

    return await postRepository.findAll({
      page,
      limit,
      search,
      categoryId,
      constituency,
      sorting
    });
  }

  async getUserPosts(userId) {
    return await postRepository.findByUserId(userId);
  }

  async deletePost(postId, userId) {
    const post = await postRepository.findById(postId);
    if (!post) {
      throw new NotFoundError('Story not found');
    }

    // Authorization check
    if (post.UserId !== userId) {
      throw new ForbiddenError('You do not have permission to delete this story');
    }

    return await postRepository.delete(postId, userId);
  }
}

module.exports = new PostService();
