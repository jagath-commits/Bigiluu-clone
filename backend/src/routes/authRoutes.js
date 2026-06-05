const express = require('express');
const authController = require('../controllers/authController');
const { validateSignup, validateLogin } = require('../validators/authValidator');
const { authLimiter } = require('../middleware/rateLimit');
const upload = require('../middleware/upload');

const router = express.Router();

// Apply authLimiter specifically to prevent credentials brute-forcing
router.post('/register', authLimiter, upload.single('profile_image'), validateSignup, authController.register);
router.post('/login', authLimiter, validateLogin, authController.login);

module.exports = router;
