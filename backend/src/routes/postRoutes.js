const express = require('express');
const postController = require('../controllers/postController');
const draftController = require('../controllers/draftController');
const { protect } = require('../middleware/auth');
const { validatePostCreation } = require('../validators/postValidator');
const upload = require('../middleware/upload');

const router = express.Router();

// --- STORY / FEED ROUTINGS ---
router.post('/', protect, upload.single('cover_image'), validatePostCreation, postController.createPost);
router.get('/', postController.getPostsFeed);
router.get('/userposts/:userId?', protect, postController.getUserPosts);
router.get('/:postId', postController.getPostById);
router.delete('/:postId', protect, postController.deletePost);

// --- BACKWARD COMPATIBLE DRAFT ALIASES FOR MOBILE FEED ---
router.get('/draftposts/:userId?', protect, draftController.getUserDrafts);
router.get('/getdraftposts/:userId?', protect, draftController.getUserDrafts);

// --- SOCIAL / ENGAGEMENTS ---
router.post('/toggleSupport/:postId', protect, postController.toggleSupport);
router.post('/toggleSave/:postId', protect, postController.toggleSave);
router.get('/savedposts/:userId?', protect, postController.getSavedPosts);

// --- DOCUMENT AI TEXT EXTRACTION & CHUNKING ---
router.post('/extractDocument', protect, upload.single('document'), postController.extractDocument);
router.get('/documentChunk/:extractionId/:chunkIndex', postController.getDocumentChunk);

module.exports = router;
