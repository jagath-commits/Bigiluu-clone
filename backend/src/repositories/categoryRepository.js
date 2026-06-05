const { getPool, sql } = require('../config/db');

class CategoryRepository {
  async findAll() {
    const pool = await getPool();
    const result = await pool.request()
      .query('SELECT CategoryId, CategoryName, CreatedDate FROM dbo.Categories WHERE IsDeleted = 0 AND IsActive = 1 ORDER BY CategoryName ASC');
    return result.recordset;
  }

  async findById(categoryId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('CategoryId', sql.VarChar, categoryId)
      .query('SELECT CategoryId, CategoryName FROM dbo.Categories WHERE CategoryId = @CategoryId AND IsDeleted = 0 AND IsActive = 1');
    return result.recordset[0];
  }

  async create(categoryName, createdBy) {
    const pool = await getPool();
    const result = await pool.request()
      .input('CategoryName', sql.NVarChar, categoryName)
      .input('CreatedBy', sql.VarChar, createdBy || 'SYSTEM')
      .query(`
        INSERT INTO dbo.Categories (CategoryName, CreatedBy)
        OUTPUT INSERTED.CategoryId, INSERTED.CategoryName
        VALUES (@CategoryName, @CreatedBy)
      `);
    return result.recordset[0];
  }

  async update(categoryId, categoryName, modifiedBy) {
    const pool = await getPool();
    const result = await pool.request()
      .input('CategoryId', sql.VarChar, categoryId)
      .input('CategoryName', sql.NVarChar, categoryName)
      .input('ModifiedBy', sql.VarChar, modifiedBy || 'SYSTEM')
      .query(`
        UPDATE dbo.Categories 
        SET CategoryName = @CategoryName, ModifiedBy = @ModifiedBy, ModifiedDate = GETDATE()
        OUTPUT INSERTED.CategoryId, INSERTED.CategoryName
        WHERE CategoryId = @CategoryId AND IsDeleted = 0
      `);
    return result.recordset[0];
  }

  async delete(categoryId, deletedBy) {
    const pool = await getPool();
    const result = await pool.request()
      .input('CategoryId', sql.VarChar, categoryId)
      .input('DeletedBy', sql.VarChar, deletedBy || 'SYSTEM')
      .query(`
        UPDATE dbo.Categories 
        SET IsDeleted = 1, IsActive = 0, ModifiedBy = @DeletedBy, ModifiedDate = GETDATE()
        WHERE CategoryId = @CategoryId AND IsDeleted = 0
      `);
    return result.rowsAffected[0] > 0;
  }
}

module.exports = new CategoryRepository();
