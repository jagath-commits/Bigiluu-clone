const { getPool, sql } = require('../config/db');

class PostRepository {
  async create({ userId, categoryId, title, caption, content, coverImg, constituency }) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .input('CategoryId', sql.VarChar, categoryId)
      .input('Title', sql.NVarChar, title)
      .input('Caption', sql.NVarChar, caption || null)
      .input('Content', sql.NVarChar, content) // JSON String
      .input('CoverImg', sql.VarChar, coverImg || null)
      .input('Constituency', sql.NVarChar, constituency || null)
      .query(`
        INSERT INTO dbo.Posts (UserId, CategoryId, Title, Caption, Content, CoverImg, Constituency, CreatedBy)
        OUTPUT INSERTED.PostId, INSERTED.UserId, INSERTED.CategoryId, INSERTED.Title, INSERTED.Caption, INSERTED.Content, INSERTED.CoverImg, INSERTED.Constituency
        VALUES (@UserId, @CategoryId, @Title, @Caption, @Content, @CoverImg, @Constituency, @UserId)
      `);
    return result.recordset[0];
  }

  async findById(postId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('PostId', sql.VarChar, postId)
      .query(`
        SELECT p.PostId, p.UserId, p.CategoryId, p.Title, p.Caption, p.Content, p.CoverImg, p.Constituency, p.CreatedDate,
               u.Username as username, u.ProfileImage as profile_image, u.Constituency as user_constituency,
               c.CategoryName as category,
               (SELECT COUNT(*) FROM dbo.Supports s WHERE s.PostId = p.PostId AND s.IsDeleted = 0) as support_count
        FROM dbo.Posts p
        INNER JOIN dbo.Users u ON p.UserId = u.UserId
        INNER JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
        WHERE p.PostId = @PostId AND p.IsDeleted = 0 AND p.IsActive = 1
      `);
    return result.recordset[0];
  }

  async update(postId, userId, { categoryId, title, caption, content, coverImg, constituency }) {
    const pool = await getPool();
    let query = 'UPDATE dbo.Posts SET ModifiedDate = GETDATE()';
    const request = pool.request();
    request.input('PostId', sql.VarChar, postId);
    request.input('ModifiedBy', sql.VarChar, userId);

    if (categoryId !== undefined) {
      query += ', CategoryId = @CategoryId';
      request.input('CategoryId', sql.VarChar, categoryId);
    }
    if (title !== undefined) {
      query += ', Title = @Title';
      request.input('Title', sql.NVarChar, title);
    }
    if (caption !== undefined) {
      query += ', Caption = @Caption';
      request.input('Caption', sql.NVarChar, caption);
    }
    if (content !== undefined) {
      query += ', Content = @Content';
      request.input('Content', sql.NVarChar, content);
    }
    if (coverImg !== undefined) {
      query += ', CoverImg = @CoverImg';
      request.input('CoverImg', sql.VarChar, coverImg);
    }
    if (constituency !== undefined) {
      query += ', Constituency = @Constituency';
      request.input('Constituency', sql.NVarChar, constituency);
    }

    query += ' WHERE PostId = @PostId AND UserId = @UserId AND IsDeleted = 0';
    request.input('UserId', sql.VarChar, userId);

    await request.query(query);
    return await this.findById(postId);
  }

  async delete(postId, userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('PostId', sql.VarChar, postId)
      .input('UserId', sql.VarChar, userId)
      .query(`
        UPDATE dbo.Posts 
        SET IsDeleted = 1, IsActive = 0, ModifiedBy = @UserId, ModifiedDate = GETDATE()
        WHERE PostId = @PostId AND UserId = @UserId AND IsDeleted = 0
      `);
    return result.rowsAffected[0] > 0;
  }

  async findAll({ page = 1, limit = 10, search = '', categoryId = '', constituency = '', sorting = 'CreatedDate DESC' }) {
    const pool = await getPool();
    const offset = (page - 1) * limit;

    let baseQuery = `
      FROM dbo.Posts p
      INNER JOIN dbo.Users u ON p.UserId = u.UserId
      INNER JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
      WHERE p.IsDeleted = 0 AND p.IsActive = 1
    `;
    const request = pool.request();

    if (search) {
      baseQuery += ' AND (p.Title LIKE @Search OR p.Caption LIKE @Search OR c.CategoryName LIKE @Search)';
      request.input('Search', sql.NVarChar, `%${search}%`);
    }
    if (categoryId && categoryId !== 'all') {
      baseQuery += ' AND p.CategoryId = @CategoryId';
      request.input('CategoryId', sql.VarChar, categoryId);
    }
    if (constituency) {
      baseQuery += ' AND p.Constituency = @Constituency';
      request.input('Constituency', sql.NVarChar, constituency);
    }

    // Get Total Count
    const countResult = await request.query(`SELECT COUNT(*) as Total ${baseQuery}`);
    const total = countResult.recordset[0].Total;

    // Sorting mapping to avoid SQL injection
    const allowedSortColumns = {
      'CreatedDate': 'p.CreatedDate',
      'Title': 'p.Title',
      'SupportCount': 'support_count'
    };
    let orderClause = 'ORDER BY p.CreatedDate DESC';
    const parts = sorting.trim().split(' ');
    if (parts.length > 0 && allowedSortColumns[parts[0]]) {
      const dir = parts[1] && parts[1].toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
      orderClause = `ORDER BY ${allowedSortColumns[parts[0]]} ${dir}`;
    }

    request.input('Limit', sql.Int, limit);
    request.input('Offset', sql.Int, offset);

    // Fetch details
    const dataResult = await request.query(`
      SELECT p.PostId as post_id, p.UserId as user_id, p.CategoryId as category_id, p.Title as title, p.Caption as caption,
             p.Content as content, p.CoverImg as cover_img, p.Constituency, p.CreatedDate,
             u.Username as username, u.ProfileImage as profile_image, u.Constituency as Constituency,
             c.CategoryName as category,
             (SELECT COUNT(*) FROM dbo.Supports s WHERE s.PostId = p.PostId AND s.IsDeleted = 0) as support_count
      ${baseQuery}
      ${orderClause}
      OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
    `);

    return {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      posts: dataResult.recordset
    };
  }

  async findByUserId(userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .query(`
        SELECT p.PostId as post_id, p.UserId as user_id, p.CategoryId as category_id, p.Title as title, p.Caption as caption,
               p.Content as content, p.CoverImg as cover_img, p.Constituency, p.CreatedDate,
               u.Username as username, u.ProfileImage as profile_image, u.Constituency as Constituency,
               c.CategoryName as category,
               (SELECT COUNT(*) FROM dbo.Supports s WHERE s.PostId = p.PostId AND s.IsDeleted = 0) as support_count
        FROM dbo.Posts p
        INNER JOIN dbo.Users u ON p.UserId = u.UserId
        INNER JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
        WHERE p.UserId = @UserId AND p.IsDeleted = 0 AND p.IsActive = 1
        ORDER BY p.CreatedDate DESC
      `);
    return result.recordset;
  }
}

module.exports = new PostRepository();
