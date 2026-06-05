require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 3000,
  JWT_SECRET: process.env.JWT_SECRET || 'bigilu_enterprise_super_secure_secret_key_2026',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  DB: {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'CODEREAD@123',
    server: process.env.DB_SERVER || 'localhost\\SQLEXPRESS',
    database: process.env.DB_DATABASE || 'BigiluDB',
    port: parseInt(process.env.DB_PORT, 10) || 1433,
    pool: {
      max: 20,
      min: 2,
      idleTimeoutMillis: 30000
    },
    options: {
      encrypt: false, // Set true if using Azure
      trustServerCertificate: true // Set true for local development
    }
  },
  MAX_FILE_SIZE_BYTES: 100 * 1024 * 1024 // 100MB as per Flutter WritePage
};
