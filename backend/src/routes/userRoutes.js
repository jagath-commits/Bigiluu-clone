const express = require('express');
const userController = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const { validateProfileUpdate } = require('../validators/profileValidator');
const upload = require('../middleware/upload');

const router = express.Router();

// Profile operations are private and require JWT authentication
router.get('/profile/:userId?', protect, userController.getProfile);
router.post('/update', protect, upload.single('profile_image'), validateProfileUpdate, userController.updateProfile);

module.exports = router;
