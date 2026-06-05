const express = require('express');
const draftController = require('../controllers/draftController');
const { protect } = require('../middleware/auth');
const { validateDraftSaving } = require('../validators/postValidator');
const upload = require('../middleware/upload');

const router = express.Router();

// Draft operations require JWT protection
router.post('/saveDraft', protect, upload.fields([
  { name: 'cover_image', maxCount: 1 },
  { name: 'page_images', maxCount: 50 }
]), validateDraftSaving, draftController.saveDraft);
router.get('/userdrafts/:userId?', protect, draftController.getUserDrafts);
router.get('/:draftId', protect, draftController.getDraftById);
router.delete('/:draftId', protect, draftController.deleteDraft);

module.exports = router;
