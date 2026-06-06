const fs = require('fs');
const pdfParse = require('pdf-parse');
const documentRepository = require('../repositories/documentRepository');
const { BadRequestError, NotFoundError } = require('../utils/customErrors');

class DocumentService {
  async extractAndChunkDocument({ userId, file }) {
    if (!file) {
      throw new BadRequestError('No file provided for text extraction');
    }

    const filePath = file.path;
    const fileName = file.originalname;
    const fileType = file.mimetype;
    let extractedText = '';

    try {
      // 1. Read / parse based on MIME type
      if (fileType === 'application/pdf' || fileName.endsWith('.pdf')) {
        const fileBuffer = fs.readFileSync(filePath);
        const pdfData = await pdfParse(fileBuffer);
        extractedText = pdfData.text || '';
      } else if (fileType === 'text/plain' || fileName.endsWith('.txt')) {
        extractedText = fs.readFileSync(filePath, 'utf-8');
      } else {
        // Fallback for DOCX or others: try reading as plain buffer or text if compatible
        extractedText = fs.readFileSync(filePath, 'utf-8');
      }

      // Clean up local temp uploaded file asynchronously to avoid storage leakage
      fs.unlink(filePath, (err) => {
        if (err) console.error('Failed to delete temp document upload file:', err);
      });

      // 2. Normalize and check extracted text length
      extractedText = extractedText.trim();
      if (!extractedText) {
        throw new BadRequestError('Document is empty or could not be parsed');
      }

      // 3. Chunk text (standard 4000 characters per chunk)
      const chunkSize = 4000;
      const chunks = [];
      for (let i = 0; i < extractedText.length; i += chunkSize) {
        chunks.push(extractedText.substring(i, i + chunkSize));
      }

      const totalChunks = chunks.length;

      // 4. Save parent extraction log
      const extraction = await documentRepository.createExtraction({
        userId,
        fileName,
        fileType,
        totalChunks,
        extractedText: extractedText.length > 50000 ? extractedText.substring(0, 50000) + '... [TRUNCATED]' : extractedText
      });

      // 5. Bulk insert chunks sequentially
      for (let index = 0; index < totalChunks; index++) {
        await documentRepository.createChunk({
          extractionId: extraction.ExtractionId,
          chunkIndex: index,
          chunkText: chunks[index]
        });
      }

      return {
        success: true,
        extractionId: extraction.ExtractionId,
        totalChunks
      };
    } catch (err) {
      // Ensure temp file gets deleted on error
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      throw err;
    }
  }

  async getChunk(extractionId, chunkIndex) {
    const idx = parseInt(chunkIndex, 10);
    if (isNaN(idx) || idx < 0) {
      throw new BadRequestError('Invalid chunk index');
    }

    const extraction = await documentRepository.findById(extractionId);
    if (!extraction) {
      throw new NotFoundError('Extraction session not found');
    }

    if (idx >= extraction.TotalChunks) {
      throw new BadRequestError(`Chunk index out of bounds (Total: ${extraction.TotalChunks})`);
    }

    const chunk = await documentRepository.findChunkByIndex(extractionId, idx);
    if (!chunk) {
      throw new NotFoundError('Document chunk not found');
    }

    return chunk;
  }

  async getFullDocument(extractionId) {
    const extraction = await documentRepository.findById(extractionId);
    if (!extraction) {
      throw new NotFoundError('Extraction session not found');
    }

    const chunks = await documentRepository.findAllChunks(extractionId);
    const fullText = chunks.map(c => c.chunk).join('');

    return {
      success: true,
      text: fullText
    };
  }
}

module.exports = new DocumentService();
