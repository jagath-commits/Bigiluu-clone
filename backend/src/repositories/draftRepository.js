const { getPool, sql } = require('../config/db');

class DraftRepository {
  async upsert({ draftId, userId, categoryId, title, content, coverImg }) {
    const pool = await getPool();
    const result = await pool.request()
      .input('DraftId', sql.VarChar, draftId || null)
      .input('UserId', sql.VarChar, userId)
      .input('CategoryId', sql.VarChar, categoryId)
      .input('Title', sql.NVarChar, title || null)
      .input('Content', sql.NVarChar, content) // JSON string
      .input('CoverImg', sql.VarChar, coverImg || null)
      .output('ResultDraftId', sql.VarChar(12))
      .execute('dbo.sp_UpsertDraft');
      
    const savedDraftId = result.output.ResultDraftId;
    return await this.findById(savedDraftId);
  }

  async findById(draftId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('DraftId', sql.VarChar, draftId)
      .query(`
        SELECT d.DraftId as draft_id, d.UserId as user_id, d.CategoryId as category_id, d.Title as title, 
               d.Content as content, d.CoverImg as cover_img, d.CreatedDate, d.ModifiedDate,
               c.CategoryName as category
        FROM dbo.Drafts d
        INNER JOIN dbo.Categories c ON d.CategoryId = c.CategoryId
        WHERE d.DraftId = @DraftId AND d.IsDeleted = 0 AND d.IsActive = 1
      `);
    return result.recordset[0];
  }

  async findByUserId(userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .query(`
        SELECT d.DraftId as draft_id, d.UserId as user_id, d.CategoryId as category_id, d.Title as title, 
               d.Content as content, d.CoverImg as cover_img, d.ModifiedDate as updated_at, d.CreatedDate as created_at,
               c.CategoryName as category
        FROM dbo.Drafts d
        INNER JOIN dbo.Categories c ON d.CategoryId = c.CategoryId
        WHERE d.UserId = @UserId AND d.IsDeleted = 0 AND d.IsActive = 1
        ORDER BY d.ModifiedDate DESC
      `);
    return result.recordset;
  }

  async delete(draftId, userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('DraftId', sql.VarChar, draftId)
      .input('UserId', sql.VarChar, userId)
      .query(`
        UPDATE dbo.Drafts
        SET IsDeleted = 1, IsActive = 0, ModifiedBy = @UserId, ModifiedDate = GETDATE()
        WHERE DraftId = @DraftId AND UserId = @UserId AND IsDeleted = 0
      `);
    return result.rowsAffected[0] > 0;
  }
}

module.exports = new DraftRepository();
