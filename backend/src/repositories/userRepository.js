const { getPool, sql } = require('../config/db');

class UserRepository {
  async create({ mobileNumber, passwordHash, username, email, constituency, profileImage, role }) {
    const pool = await getPool();
    const result = await pool.request()
      .input('MobileNumber', sql.VarChar, mobileNumber)
      .input('PasswordHash', sql.VarChar, passwordHash)
      .input('Username', sql.NVarChar, username)
      .input('Email', sql.VarChar, email)
      .input('Constituency', sql.NVarChar, constituency || null)
      .input('ProfileImage', sql.VarChar, profileImage || null)
      .input('Role', sql.VarChar, role || 'User')
      .query(`
        INSERT INTO dbo.Users (MobileNumber, PasswordHash, Username, Email, Constituency, ProfileImage, Role, CreatedBy)
        OUTPUT INSERTED.UserId, INSERTED.MobileNumber, INSERTED.Username, INSERTED.Email, INSERTED.Constituency, INSERTED.ProfileImage, INSERTED.Role
        VALUES (@MobileNumber, @PasswordHash, @Username, @Email, @Constituency, @ProfileImage, @Role, 'SYSTEM')
      `);
    return result.recordset[0];
  }

  async findByMobile(mobileNumber) {
    const pool = await getPool();
    const result = await pool.request()
      .input('MobileNumber', sql.VarChar, mobileNumber)
      .query('SELECT * FROM dbo.Users WHERE MobileNumber = @MobileNumber AND IsDeleted = 0');
    return result.recordset[0];
  }

  async findByEmail(email) {
    const pool = await getPool();
    const result = await pool.request()
      .input('Email', sql.VarChar, email)
      .query('SELECT * FROM dbo.Users WHERE Email = @Email AND IsDeleted = 0');
    return result.recordset[0];
  }

  async findById(userId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .query(`
        SELECT UserId, MobileNumber, Username, Email, Constituency, ProfileImage, Role, CreatedDate, ModifiedDate 
        FROM dbo.Users 
        WHERE UserId = @UserId AND IsDeleted = 0 AND IsActive = 1
      `);
    return result.recordset[0];
  }

  async update(userId, { username, email, constituency, profileImage, modifiedBy }) {
    const pool = await getPool();
    
    // Dynamically build the update statement to allow partial updates
    let query = 'UPDATE dbo.Users SET ModifiedDate = GETDATE()';
    const request = pool.request();
    request.input('UserId', sql.VarChar, userId);
    request.input('ModifiedBy', sql.VarChar, modifiedBy || userId);

    if (username !== undefined) {
      query += ', Username = @Username';
      request.input('Username', sql.NVarChar, username);
    }
    if (email !== undefined) {
      query += ', Email = @Email';
      request.input('Email', sql.VarChar, email);
    }
    if (constituency !== undefined) {
      query += ', Constituency = @Constituency';
      request.input('Constituency', sql.NVarChar, constituency);
    }
    if (profileImage !== undefined) {
      query += ', ProfileImage = @ProfileImage';
      request.input('ProfileImage', sql.VarChar, profileImage);
    }

    query += ', ModifiedBy = @ModifiedBy WHERE UserId = @UserId AND IsDeleted = 0';

    await request.query(query);
    return await this.findById(userId);
  }

  async delete(userId, deletedBy) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .input('DeletedBy', sql.VarChar, deletedBy || 'SYSTEM')
      .query(`
        UPDATE dbo.Users 
        SET IsDeleted = 1, IsActive = 0, ModifiedBy = @DeletedBy, ModifiedDate = GETDATE() 
        WHERE UserId = @UserId AND IsDeleted = 0
      `);
    return result.rowsAffected[0] > 0;
  }

  async findAll({ page = 1, limit = 10, search = '', constituency = '', sorting = 'CreatedDate DESC' }) {
    const pool = await getPool();
    const offset = (page - 1) * limit;

    let baseQuery = 'FROM dbo.Users WHERE IsDeleted = 0 AND IsActive = 1';
    const request = pool.request();

    if (search) {
      baseQuery += ' AND (Username LIKE @Search OR Email LIKE @Search OR MobileNumber LIKE @Search)';
      request.input('Search', sql.NVarChar, `%${search}%`);
    }
    if (constituency) {
      baseQuery += ' AND Constituency = @Constituency';
      request.input('Constituency', sql.NVarChar, constituency);
    }

    // Count total matching items
    const countResult = await request.query(`SELECT COUNT(*) as Total ${baseQuery}`);
    const total = countResult.recordset[0].Total;

    // Validate sorting parameters to prevent SQL injection
    const allowedSortColumns = ['Username', 'Email', 'CreatedDate', 'ModifiedDate'];
    let orderClause = 'ORDER BY CreatedDate DESC';
    const parts = sorting.trim().split(' ');
    if (parts.length > 0 && allowedSortColumns.includes(parts[0])) {
      const dir = parts[1] && parts[1].toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
      orderClause = `ORDER BY ${parts[0]} ${dir}`;
    }

    // Fetch dynamic paginated rows using standard MSSQL OFFSET FETCH clauses
    request.input('Limit', sql.Int, limit);
    request.input('Offset', sql.Int, offset);

    const dataResult = await request.query(`
      SELECT UserId, MobileNumber, Username, Email, Constituency, ProfileImage, Role, CreatedDate
      ${baseQuery}
      ${orderClause}
      OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
    `);

    return {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      users: dataResult.recordset
    };
  }
}

module.exports = new UserRepository();
