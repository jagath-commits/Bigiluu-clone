const { getPool, sql } = require('../config/db');

class EngagementRepository {
  async toggleSupport(userId, postId) {
    const pool = await getPool();
    
    // Check if the record already exists (including soft-deleted records)
    const checkResult = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .input('PostId', sql.VarChar, postId)
      .query('SELECT SupportId, IsDeleted FROM dbo.Supports WHERE UserId = @UserId AND PostId = @PostId');

    if (checkResult.recordset.length > 0) {
      // Toggle IsDeleted status
      const existing = checkResult.recordset[0];
      const newIsDeleted = existing.IsDeleted ? 0 : 1;
      const newIsActive = existing.IsDeleted ? 1 : 0;

      await pool.request()
        .input('SupportId', sql.VarChar, existing.SupportId)
        .input('UserId', sql.VarChar, userId)
        .input('IsDeleted', sql.Bit, newIsDeleted)
        .input('IsActive', sql.Bit, newIsActive)
        .query(`
          UPDATE dbo.Supports 
          SET IsDeleted = @IsDeleted, IsActive = @IsActive, ModifiedBy = @UserId, ModifiedDate = GETDATE()
          WHERE SupportId = @SupportId
        `);
      return { supported: newIsDeleted === 0 };
    } else {
      // Insert new support record
      await pool.request()
        .input('UserId', sql.VarChar, userId)
        .input('PostId', sql.VarChar, postId)
        .query(`
          INSERT INTO dbo.Supports (UserId, PostId, CreatedBy, ModifiedBy)
          VALUES (@UserId, @PostId, @UserId, @UserId)
        `);
      return { supported: true };
    }
  }

  async toggleSave(userId, postId) {
    const pool = await getPool();
    
    // Check if the record already exists (including soft-deleted records)
    const checkResult = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .input('PostId', sql.VarChar, postId)
      .query('SELECT SaveId, IsDeleted FROM dbo.Saves WHERE UserId = @UserId AND PostId = @PostId');

    if (checkResult.recordset.length > 0) {
      // Toggle IsDeleted status
      const existing = checkResult.recordset[0];
      const newIsDeleted = existing.IsDeleted ? 0 : 1;
      const newIsActive = existing.IsDeleted ? 1 : 0;

      await pool.request()
        .input('SaveId', sql.VarChar, existing.SaveId)
        .input('UserId', sql.VarChar, userId)
        .input('IsDeleted', sql.Bit, newIsDeleted)
        .input('IsActive', sql.Bit, newIsActive)
        .query(`
          UPDATE dbo.Saves 
          SET IsDeleted = @IsDeleted, IsActive = @IsActive, ModifiedBy = @UserId, ModifiedDate = GETDATE()
          WHERE SaveId = @SaveId
        `);
      return { saved: newIsDeleted === 0 };
    } else {
      // Insert new save record
      await pool.request()
        .input('UserId', sql.VarChar, userId)
        .input('PostId', sql.VarChar, postId)
        .query(`
          INSERT INTO dbo.Saves (UserId, PostId, CreatedBy, ModifiedBy)
          VALUES (@UserId, @PostId, @UserId, @UserId)
        `);
      return { saved: true };
    }
  }

  async findSavedPostsByUserId(userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .query(`
        SELECT p.PostId as post_id, p.UserId as user_id, p.CategoryId as category_id, p.Title as title, p.Caption as caption,
               p.Content as content, p.CoverImg as cover_img, p.Constituency, p.Hashtags as hashtags, p.Views as views, p.CreatedDate,
               u.Username as username, u.ProfileImage as profile_image, u.Constituency as Constituency,
               c.CategoryName as category,
               (SELECT COUNT(*) FROM dbo.Supports s WHERE s.PostId = p.PostId AND s.IsDeleted = 0) as support_count
        FROM dbo.Saves sv
        INNER JOIN dbo.Posts p ON sv.PostId = p.PostId
        INNER JOIN dbo.Users u ON p.UserId = u.UserId
        INNER JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
        WHERE sv.UserId = @UserId AND sv.IsDeleted = 0 AND p.IsDeleted = 0 AND p.IsActive = 1
        ORDER BY sv.CreatedDate DESC
      `);
    return result.recordset;
  }
}

module.exports = new EngagementRepository();
