const draftService = require('../services/draftService');

class DraftController {
  async saveDraft(req, res, next) {
    try {
      const userId = req.user.userId;
      const { draft_id, category_id, title, content } = req.body;
      const coverImg = req.file ? req.file.filename : undefined;

      const savedDraft = await draftService.saveDraft({
        draftId: draft_id,
        userId,
        categoryId: category_id,
        title,
        content,
        coverImg
      });

      return res.status(200).json({
        success: true,
        message: 'Draft auto-saved successfully',
        draft_id: savedDraft.draft_id,
        content: savedDraft.content,
        data: savedDraft
      });
    } catch (err) {
      next(err);
    }
  }

  async getDraftById(req, res, next) {
    try {
      const { draftId } = req.params;
      const userId = req.user.userId;

      const draft = await draftService.getDraftById(draftId, userId);

      return res.status(200).json({
        success: true,
        message: 'Draft retrieved successfully',
        data: draft
      });
    } catch (err) {
      next(err);
    }
  }

  async getUserDrafts(req, res, next) {
    try {
      const userId = req.params.userId || req.user.userId;
      const drafts = await draftService.getUserDrafts(userId);

      return res.status(200).json({
        success: true,
        message: 'User drafts retrieved successfully',
        data: drafts
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteDraft(req, res, next) {
    try {
      const { draftId } = req.params;
      const userId = req.user.userId;

      await draftService.deleteDraft(draftId, userId);

      return res.status(200).json({
        success: true,
        message: 'Draft deleted successfully',
        data: null
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DraftController();
