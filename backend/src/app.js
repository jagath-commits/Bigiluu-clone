const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const config = require('./config/config');
const { connectDB } = require('./config/db');
const errorHandler = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimit');

// Import Route Handlers
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const postRoutes = require('./routes/postRoutes');
const draftRoutes = require('./routes/draftRoutes');
const categoryRoutes = require('./routes/categoryRoutes');

const app = express();

// 1. Establish Database Connection Pool
connectDB()
  .then(() => {
    console.log('Database system initialized successfully.');
  })
  .catch((err) => {
    console.error('Fatal Database initialization error:', err.message);
    process.exit(1);
  });

// 2. Global Security Middlewares
app.use(helmet({
  crossOriginResourcePolicy: false // Allows client applications to load static image files
}));
app.use(cors());

// 3. Body Parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 4. Serve Static Upload Directories (Profile pictures, draft pages, cover images)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// 5. API Rate Limiting (Applied to all endpoints to prevent DOS/Abuse)
app.use('/api', apiLimiter);

// 6. Router Mapping
app.use('/api/auth', authRoutes);
app.use('/api/profile', userRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/draft', draftRoutes);
app.use('/api/categories', categoryRoutes);

// Fallback Route (404 Not Found)
app.use('*', (req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Resource not found on endpoint: ${req.originalUrl}`,
    data: null
  });
});

// 7. Register Global Error Handler (Intercepts all API processing failures)
app.use(errorHandler);

// 8. Server Bootstrapping
const PORT = config.PORT;
app.listen(PORT, () => {
  console.log(`================================================================`);
  console.log(`  BIGILU BACKEND SERVER ACTIVE - PORT: ${PORT}`);
  console.log(`  ENVIRONMENT: ${process.env.NODE_ENV || 'development'}`);
  console.log(`================================================================`);
});

module.exports = app;
