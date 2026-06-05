const { getPool, sql } = require('../config/db');

class DocumentRepository {
  async createExtraction({ userId, fileName, fileType, totalChunks, extractedText }) {
    const pool = await getPool();
    const result = await pool.request()
      .input('UserId', sql.VarChar, userId)
      .input('FileName', sql.NVarChar, fileName)
      .input('FileType', sql.VarChar, fileType)
      .input('TotalChunks', sql.Int, totalChunks)
      .input('ExtractedText', sql.NVarChar, extractedText || null)
      .query(`
        INSERT INTO dbo.DocumentExtractions (UserId, FileName, FileType, TotalChunks, ExtractedText, CreatedBy)
        OUTPUT INSERTED.ExtractionId, INSERTED.UserId, INSERTED.FileName, INSERTED.FileType, INSERTED.TotalChunks
        VALUES (@UserId, @FileName, @FileType, @TotalChunks, @ExtractedText, @UserId)
      `);
    return result.recordset[0];
  }

  async findById(extractionId) {
    const pool = await getPool();
    const result = await pool.request()
      .input('ExtractionId', sql.VarChar, extractionId)
      .query('SELECT * FROM dbo.DocumentExtractions WHERE ExtractionId = @ExtractionId AND IsDeleted = 0');
    return result.recordset[0];
  }

  async createChunk({ extractionId, chunkIndex, chunkText }) {
    const pool = await getPool();
    const result = await pool.request()
      .input('ExtractionId', sql.VarChar, extractionId)
      .input('ChunkIndex', sql.Int, chunkIndex)
      .input('ChunkText', sql.NVarChar, chunkText)
      .query(`
        INSERT INTO dbo.DocumentChunks (ExtractionId, ChunkIndex, ChunkText, CreatedBy)
        OUTPUT INSERTED.ChunkId, INSERTED.ExtractionId, INSERTED.ChunkIndex
        VALUES (@ExtractionId, @ChunkIndex, @ChunkText, 'SYSTEM')
      `);
    return result.recordset[0];
  }

  async findChunkByIndex(extractionId, chunkIndex) {
    const pool = await getPool();
    const result = await pool.request()
      .input('ExtractionId', sql.VarChar, extractionId)
      .input('ChunkIndex', sql.Int, chunkIndex)
      .query(`
        SELECT ChunkText as chunk 
        FROM dbo.DocumentChunks 
        WHERE ExtractionId = @ExtractionId AND ChunkIndex = @ChunkIndex AND IsDeleted = 0 AND IsActive = 1
      `);
    return result.recordset[0];
  }
}

module.exports = new DocumentRepository();
