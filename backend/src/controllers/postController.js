const postService = require('../services/postService');
const engagementService = require('../services/engagementService');
const documentService = require('../services/documentService');

class PostController {
  // --- POST OPERATIONS ---
  async createPost(req, res, next) {
    try {
      const userId = req.user.userId;
      const { categoryId, title, caption, content, constituency, hashtags } = req.body;
      
      let coverImg = null;
      if (req.files && req.files['cover_image'] && req.files['cover_image'].length > 0) {
        coverImg = req.files['cover_image'][0].filename;
      }

      const newPost = await postService.createPost({
        userId,
        categoryId,
        title,
        caption,
        content,
        coverImg,
        constituency,
        hashtags
      });

      return res.status(201).json({
        success: true,
        message: 'Story published successfully',
        data: newPost
      });
    } catch (err) {
      next(err);
    }
  }

  async getPostById(req, res, next) {
    try {
      const { postId } = req.params;
      const post = await postService.getPostById(postId);

      return res.status(200).json({
        success: true,
        message: 'Story fetched successfully',
        data: post
      });
    } catch (err) {
      next(err);
    }
  }

  async getPostsFeed(req, res, next) {
    try {
      const result = await postService.getPostsFeed(req.query);
      return res.status(200).json({
        success: true,
        message: 'Feed retrieved successfully',
        data: result.posts,
        pagination: {
          total: result.total,
          page: result.page,
          limit: result.limit,
          totalPages: result.totalPages
        }
      });
    } catch (err) {
      next(err);
    }
  }

  async getUserPosts(req, res, next) {
    try {
      const userId = req.params.userId || req.user.userId;
      const posts = await postService.getUserPosts(userId);

      return res.status(200).json({
        success: true,
        message: 'User stories fetched successfully',
        data: posts
      });
    } catch (err) {
      next(err);
    }
  }

  async deletePost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.userId;

      await postService.deletePost(postId, userId);

      return res.status(200).json({
        success: true,
        message: 'Story deleted successfully',
        data: null
      });
    } catch (err) {
      next(err);
    }
  }

  // --- SOCIAL ENGAGEMENTS ---
  async toggleSupport(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.userId;

      const status = await engagementService.toggleSupport(userId, postId);

      return res.status(200).json({
        success: true,
        message: status.supported ? 'Story supported successfully' : 'Support removed successfully',
        data: status
      });
    } catch (err) {
      next(err);
    }
  }

  async toggleSave(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.userId;

      const status = await engagementService.toggleSave(userId, postId);

      return res.status(200).json({
        success: true,
        message: status.saved ? 'Story bookmarked successfully' : 'Bookmark removed successfully',
        data: status
      });
    } catch (err) {
      next(err);
    }
  }

  async getSavedPosts(req, res, next) {
    try {
      const userId = req.params.userId || req.user.userId;
      const posts = await engagementService.getSavedPosts(userId);

      return res.status(200).json({
        success: true,
        message: 'Saved stories fetched successfully',
        data: posts
      });
    } catch (err) {
      next(err);
    }
  }

  // --- DOCUMENT AI ---
  async extractDocument(req, res, next) {
    try {
      const userId = req.user.userId;
      const result = await documentService.extractAndChunkDocument({
        userId,
        file: req.file
      });

      return res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async getDocumentChunk(req, res, next) {
    try {
      const { extractionId, chunkIndex } = req.params;
      const chunk = await documentService.getChunk(extractionId, chunkIndex);

      return res.status(200).json(chunk);
    } catch (err) {
      next(err);
    }
  }

  async getFullDocument(req, res, next) {
    try {
      const { extractionId } = req.params;
      const result = await documentService.getFullDocument(extractionId);
      return res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async getTrendingHashtags(req, res, next) {
    try {
      const hashtags = await postService.getTrendingHashtags();
      return res.status(200).json({
        success: true,
        message: 'Trending hashtags retrieved successfully',
        data: hashtags
      });
    } catch (err) {
      next(err);
    }
  }

  async incrementViews(req, res, next) {
    try {
      const { postId } = req.params;
      await postService.incrementViews(postId);
      return res.status(200).json({
        success: true,
        message: 'Views incremented successfully'
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new PostController();
