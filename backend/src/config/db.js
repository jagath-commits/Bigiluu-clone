const sql = require('mssql');
const config = require('./config');

const dbConfig = config.DB;
let pool = null;

async function connectDB() {
  try {
    if (pool) return pool;

    pool = await new sql.ConnectionPool(dbConfig).connect();
    console.log('Successfully established connection pool to Microsoft SQL Server.');
    
    pool.on('error', (err) => {
      console.error('Database connection pool error:', err);
      pool = null; // Reset pool on fatal errors so it can reconnect on next request
    });

    return pool;
  } catch (err) {
    console.error('Failed to connect to MSSQL Server:', err.message);
    pool = null;
    throw err;
  }
}

async function getPool() {
  if (!pool) {
    return await connectDB();
  }
  return pool;
}

module.exports = {
  sql,
  connectDB,
  getPool
};
