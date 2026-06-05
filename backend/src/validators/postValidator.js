const { BadRequestError } = require('../utils/customErrors');

const validatePostCreation = (req, res, next) => {
  const { categoryId, title, content } = req.body;

  if (!categoryId) {
    return next(new BadRequestError('Category ID is required'));
  }
  if (!title || title.trim().length === 0) {
    return next(new BadRequestError('Story title is required'));
  }
  if (!content) {
    return next(new BadRequestError('Story content blocks are required'));
  }

  // Content JSON validation
  try {
    JSON.parse(content);
  } catch (err) {
    return next(new BadRequestError('Content must be a valid JSON-encoded string'));
  }

  next();
};

const validateDraftSaving = (req, res, next) => {
  const { category_id, content } = req.body;

  if (!category_id) {
    return next(new BadRequestError('Category ID (category_id) is required to save drafts'));
  }
  if (!content) {
    return next(new BadRequestError('Content blocks are required to save drafts'));
  }

  try {
    JSON.parse(content);
  } catch (err) {
    return next(new BadRequestError('Content must be a valid JSON-encoded string'));
  }

  next();
};

module.exports = {
  validatePostCreation,
  validateDraftSaving
};
