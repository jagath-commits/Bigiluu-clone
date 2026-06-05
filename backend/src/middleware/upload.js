const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const uploadDirs = [
  path.join(__dirname, '../../uploads/profile_images'),
  path.join(__dirname, '../../uploads/page_images'),
  path.join(__dirname, '../../uploads/temp_documents')
];

uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Configure custom storage engines for distinct upload types
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (file.fieldname === 'profile_image') {
      cb(null, path.join(__dirname, '../../uploads/profile_images'));
    } else if (file.fieldname === 'page_images' || file.fieldname === 'cover_image') {
      cb(null, path.join(__dirname, '../../uploads/page_images'));
    } else {
      cb(null, path.join(__dirname, '../../uploads/temp_documents'));
    }
  },
  filename: (req, file, cb) => {
    if (file.fieldname === 'page_images') {
      cb(null, file.originalname);
    } else {
      // Generate secure randomized filename retaining the original extension
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
  }
});

// Define safe file filters (Images and readable documents)
const fileFilter = (req, file, cb) => {
  const allowedImageTypes = ['.png', '.jpg', '.jpeg', '.gif'];
  const allowedDocTypes = ['.pdf', '.docx', '.txt'];
  const ext = path.extname(file.originalname).toLowerCase();

  if (file.fieldname === 'profile_image' || file.fieldname === 'page_images' || file.fieldname === 'cover_image') {
    if (allowedImageTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid image file type. Only JPG, JPEG, PNG, and GIF are allowed.'), false);
    }
  } else if (file.fieldname === 'document') {
    if (allowedDocTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid document file type. Only PDF, DOCX, and TXT are allowed.'), false);
    }
  } else {
    cb(null, true);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB max limit
  }
});

module.exports = upload;
