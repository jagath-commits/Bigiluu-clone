const { getPool } = require('../config/db');

async function run() {
  try {
    const pool = await getPool();
    console.log("Updating dbo.Supports...");
    const supportRes = await pool.request().query(`
      UPDATE dbo.Supports
      SET ModifiedBy = CreatedBy
      WHERE ModifiedBy IS NULL
    `);
    console.log(`Updated Supports. Rows affected: ${supportRes.rowsAffected[0]}`);

    console.log("Updating dbo.Saves...");
    const savesRes = await pool.request().query(`
      UPDATE dbo.Saves
      SET ModifiedBy = CreatedBy
      WHERE ModifiedBy IS NULL
    `);
    console.log(`Updated Saves. Rows affected: ${savesRes.rowsAffected[0]}`);

    console.log("Updating dbo.Posts...");
    const postsRes = await pool.request().query(`
      UPDATE dbo.Posts
      SET ModifiedBy = CreatedBy
      WHERE ModifiedBy IS NULL
    `);
    console.log(`Updated Posts. Rows affected: ${postsRes.rowsAffected[0]}`);

    console.log("Audit columns fix completed successfully!");
    process.exit(0);
  } catch (err) {
    console.error("Error updating audit columns:", err);
    process.exit(1);
  }
}

run();
