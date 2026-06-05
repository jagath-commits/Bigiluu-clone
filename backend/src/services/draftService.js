const draftRepository = require('../repositories/draftRepository');
const categoryRepository = require('../repositories/categoryRepository');
const { NotFoundError, BadRequestError, ForbiddenError } = require('../utils/customErrors');

class DraftService {
  async saveDraft({ draftId, userId, categoryId, title, content, coverImg }) {
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

    // Authorization check if draft exists
    if (draftId) {
      const existing = await draftRepository.findById(draftId);
      if (existing && existing.user_id !== userId) {
        throw new ForbiddenError('You do not have permission to modify this draft');
      }
    }

    return await draftRepository.upsert({
      draftId,
      userId,
      categoryId,
      title,
      content,
      coverImg
    });
  }

  async getDraftById(draftId, userId) {
    const draft = await draftRepository.findById(draftId);
    if (!draft) {
      throw new NotFoundError('Draft not found');
    }

    if (draft.user_id !== userId) {
      throw new ForbiddenError('You do not have permission to view this draft');
    }

    return draft;
  }

  async getUserDrafts(userId) {
    return await draftRepository.findByUserId(userId);
  }

  async deleteDraft(draftId, userId) {
    const draft = await draftRepository.findById(draftId);
    if (!draft) {
      throw new NotFoundError('Draft not found');
    }

    if (draft.user_id !== userId) {
      throw new ForbiddenError('You do not have permission to delete this draft');
    }

    return await draftRepository.delete(draftId, userId);
  }
}

module.exports = new DraftService();
