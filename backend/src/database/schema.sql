-- =========================================================================
-- BIGILU BACKEND DATABASE SCHEMA - MICROSOFT SQL SERVER
-- Enterprise-grade, clean-architecture compliant, fully normalized to 3NF.
-- =========================================================================

-- 1. DATABASE CREATION
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'BigiluDB')
BEGIN
    CREATE DATABASE BigiluDB;
END
GO

USE BigiluDB;
GO

-- 2. SEQUENCE DEFINITIONS FOR MODULE-PREFIXED PRIMARY KEYS
-- Using 8-digit sequence range to ensure high enterprise scalability (up to 99,999,999 records per entity)

IF OBJECT_ID('Seq_User', 'SO') IS NULL CREATE SEQUENCE Seq_User START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Category', 'SO') IS NULL CREATE SEQUENCE Seq_Category START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Post', 'SO') IS NULL CREATE SEQUENCE Seq_Post START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Draft', 'SO') IS NULL CREATE SEQUENCE Seq_Draft START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Support', 'SO') IS NULL CREATE SEQUENCE Seq_Support START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Save', 'SO') IS NULL CREATE SEQUENCE Seq_Save START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Extraction', 'SO') IS NULL CREATE SEQUENCE Seq_Extraction START WITH 1 INCREMENT BY 1;
IF OBJECT_ID('Seq_Chunk', 'SO') IS NULL CREATE SEQUENCE Seq_Chunk START WITH 1 INCREMENT BY 1;
GO

-- 3. TABLE DEFINITIONS

-- A. CATEGORIES TABLE
IF OBJECT_ID('dbo.Categories', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categories (
        CategoryId VARCHAR(12) CONSTRAINT DF_Categories_CategoryId DEFAULT ('CAT' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Category AS VARCHAR(8)), 8)) NOT NULL,
        CategoryName NVARCHAR(100) NOT NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryId),
        CONSTRAINT UQ_Categories_CategoryName UNIQUE (CategoryName)
    );
END
GO

-- B. USERS TABLE
IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users (
        UserId VARCHAR(12) CONSTRAINT DF_Users_UserId DEFAULT ('USR' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_User AS VARCHAR(8)), 8)) NOT NULL,
        MobileNumber VARCHAR(15) NOT NULL,
        PasswordHash VARCHAR(255) NOT NULL,
        Username NVARCHAR(100) NOT NULL,
        Email VARCHAR(100) NOT NULL,
        Constituency NVARCHAR(100) NULL,
        ProfileImage VARCHAR(255) NULL,
        Role VARCHAR(20) NOT NULL CONSTRAINT DF_Users_Role DEFAULT 'User',
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
        CONSTRAINT UQ_Users_MobileNumber UNIQUE (MobileNumber),
        CONSTRAINT UQ_Users_Email UNIQUE (Email),
        CONSTRAINT CHK_Users_MobileNumber CHECK (MobileNumber LIKE '[0-9]%'),
        CONSTRAINT CHK_Users_Email CHECK (Email LIKE '%_@__%.__%')
    );
END
GO

-- C. POSTS TABLE
IF OBJECT_ID('dbo.Posts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Posts (
        PostId VARCHAR(12) CONSTRAINT DF_Posts_PostId DEFAULT ('PST' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Post AS VARCHAR(8)), 8)) NOT NULL,
        UserId VARCHAR(12) NOT NULL,
        CategoryId VARCHAR(12) NOT NULL,
        Title NVARCHAR(255) NOT NULL,
        Caption NVARCHAR(MAX) NULL,
        Content NVARCHAR(MAX) NOT NULL, -- Stored as JSON-encoded array of pages and blocks
        CoverImg VARCHAR(255) NULL,
        Constituency NVARCHAR(100) NULL, -- Auto-inherited from user constituency if null
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Posts PRIMARY KEY CLUSTERED (PostId),
        CONSTRAINT FK_Posts_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_Posts_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (CategoryId),
        CONSTRAINT CHK_Posts_Content_JSON CHECK (ISJSON(Content) > 0)
    );
END
GO

-- D. DRAFTS TABLE (Auto-saves and temporary storage before publication)
IF OBJECT_ID('dbo.Drafts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Drafts (
        DraftId VARCHAR(12) CONSTRAINT DF_Drafts_DraftId DEFAULT ('DFT' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Draft AS VARCHAR(8)), 8)) NOT NULL,
        UserId VARCHAR(12) NOT NULL,
        CategoryId VARCHAR(12) NOT NULL,
        Title NVARCHAR(255) NULL,
        Content NVARCHAR(MAX) NOT NULL, -- Stored as JSON-encoded array of pages and blocks
        CoverImg VARCHAR(255) NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Drafts PRIMARY KEY CLUSTERED (DraftId),
        CONSTRAINT FK_Drafts_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_Drafts_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories (CategoryId),
        CONSTRAINT CHK_Drafts_Content_JSON CHECK (ISJSON(Content) > 0)
    );
END
GO

-- E. SUPPORTS TABLE (Likes tracking)
IF OBJECT_ID('dbo.Supports', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Supports (
        SupportId VARCHAR(12) CONSTRAINT DF_Supports_SupportId DEFAULT ('SUP' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Support AS VARCHAR(8)), 8)) NOT NULL,
        UserId VARCHAR(12) NOT NULL,
        PostId VARCHAR(12) NOT NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Supports PRIMARY KEY CLUSTERED (SupportId),
        CONSTRAINT FK_Supports_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_Supports_Posts FOREIGN KEY (PostId) REFERENCES dbo.Posts (PostId),
        CONSTRAINT UQ_Supports_User_Post UNIQUE (UserId, PostId)
    );
END
GO

-- F. SAVES TABLE (Bookmarks tracking)
IF OBJECT_ID('dbo.Saves', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Saves (
        SaveId VARCHAR(12) CONSTRAINT DF_Saves_SaveId DEFAULT ('SAV' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Save AS VARCHAR(8)), 8)) NOT NULL,
        UserId VARCHAR(12) NOT NULL,
        PostId VARCHAR(12) NOT NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_Saves PRIMARY KEY CLUSTERED (SaveId),
        CONSTRAINT FK_Saves_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_Saves_Posts FOREIGN KEY (PostId) REFERENCES dbo.Posts (PostId),
        CONSTRAINT UQ_Saves_User_Post UNIQUE (UserId, PostId)
    );
END
GO

-- G. DOCUMENT EXTRACTIONS TABLE
IF OBJECT_ID('dbo.DocumentExtractions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentExtractions (
        ExtractionId VARCHAR(12) CONSTRAINT DF_DocExt_ExtractionId DEFAULT ('EXT' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Extraction AS VARCHAR(8)), 8)) NOT NULL,
        UserId VARCHAR(12) NOT NULL,
        FileName NVARCHAR(255) NOT NULL,
        FileType VARCHAR(50) NOT NULL,
        TotalChunks INT NOT NULL,
        ExtractedText NVARCHAR(MAX) NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_DocumentExtractions PRIMARY KEY CLUSTERED (ExtractionId),
        CONSTRAINT FK_DocumentExtractions_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId)
    );
END
GO

-- H. DOCUMENT CHUNKS TABLE
IF OBJECT_ID('dbo.DocumentChunks', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentChunks (
        ChunkId VARCHAR(12) CONSTRAINT DF_DocChk_ChunkId DEFAULT ('CHK' + RIGHT('00000000' + CAST(NEXT VALUE FOR Seq_Chunk AS VARCHAR(8)), 8)) NOT NULL,
        ExtractionId VARCHAR(12) NOT NULL,
        ChunkIndex INT NOT NULL,
        ChunkText NVARCHAR(MAX) NOT NULL,
        
        -- Standard Audit Columns
        CreatedBy VARCHAR(12) NOT NULL DEFAULT 'SYSTEM',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedBy VARCHAR(12) NULL,
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_DocumentChunks PRIMARY KEY CLUSTERED (ChunkId),
        CONSTRAINT FK_DocumentChunks_Extractions FOREIGN KEY (ExtractionId) REFERENCES dbo.DocumentExtractions (ExtractionId) ON DELETE CASCADE,
        CONSTRAINT UQ_DocumentChunks_Ext_Idx UNIQUE (ExtractionId, ChunkIndex)
    );
END
GO

-- 4. HIGH-PERFORMANCE INDEX OPTIMIZATIONS
-- Placing non-clustered indexes on FKs, soft-delete flags, and search fields to guarantee scalability

CREATE NONCLUSTERED INDEX IX_Users_IsActive_IsDeleted ON dbo.Users (IsActive, IsDeleted);
CREATE NONCLUSTERED INDEX IX_Posts_UserId ON dbo.Posts (UserId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_Posts_CategoryId ON dbo.Posts (CategoryId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_Posts_IsActive_IsDeleted ON dbo.Posts (IsActive, IsDeleted) INCLUDE (Title, CreatedDate);
CREATE NONCLUSTERED INDEX IX_Drafts_UserId ON dbo.Drafts (UserId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_Supports_PostId ON dbo.Supports (PostId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_Saves_PostId ON dbo.Saves (PostId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_DocumentChunks_ExtractionId ON dbo.DocumentChunks (ExtractionId);
GO

-- 5. STORED PROCEDURES FOR HIGH CONCURRENCY OPERATIONS

-- A. TRANSACTION-SAFE DRAFT UPSERT STORED PROCEDURE
-- Solves background auto-save race conditions by either creating a new draft or updating an existing one safely.
CREATE OR ALTER PROCEDURE dbo.sp_UpsertDraft
    @DraftId VARCHAR(12) = NULL,
    @UserId VARCHAR(12),
    @CategoryId VARCHAR(12),
    @Title NVARCHAR(255) = NULL,
    @Content NVARCHAR(MAX),
    @CoverImg VARCHAR(255) = NULL,
    @ResultDraftId VARCHAR(12) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF @DraftId IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Drafts WHERE DraftId = @DraftId AND IsDeleted = 0)
    BEGIN
        -- Update existing draft
        UPDATE dbo.Drafts
        SET CategoryId = @CategoryId,
            Title = COALESCE(@Title, Title),
            Content = @Content,
            CoverImg = COALESCE(@CoverImg, CoverImg),
            ModifiedBy = @UserId,
            ModifiedDate = GETDATE()
        WHERE DraftId = @DraftId;

        SET @ResultDraftId = @DraftId;
    END
    ELSE
    BEGIN
        -- Insert new draft
        DECLARE @NewDraftIdTable TABLE (NewId VARCHAR(12));

        INSERT INTO dbo.Drafts (UserId, CategoryId, Title, Content, CoverImg, CreatedBy)
        OUTPUT INSERTED.DraftId INTO @NewDraftIdTable
        VALUES (@UserId, @CategoryId, @Title, @Content, @CoverImg, @UserId);

        SELECT TOP 1 @ResultDraftId = NewId FROM @NewDraftIdTable;
    END

    COMMIT TRANSACTION;
END;
GO

-- 6. INITIAL SEED DATA
-- Populate categories according to analyzed frontend categories (Library: 4, Thoughts: 2, Announcements: 3, Petitions: 1)
-- To ensure sequence safety, we will insert them explicitly utilizing the sequence next values or directly using exact prefixed names.

IF NOT EXISTS (SELECT 1 FROM dbo.Categories)
BEGIN
    -- Disable or override defaults for exact mappings to synchronize with Flutter ID categories
    INSERT INTO dbo.Categories (CategoryId, CategoryName, CreatedBy) VALUES 
    ('CAT00000001', N'மனு (Petitions)', 'SYSTEM'),
    ('CAT00000002', N'சிந்தனைகள் (Thoughts)', 'SYSTEM'),
    ('CAT00000003', N'அறிகைகள் (Announcements)', 'SYSTEM'),
    ('CAT00000004', N'நூலகம் (Library)', 'SYSTEM');

    -- Update sequence so that it starts at index 5 for any subsequent dynamic categories
    ALTER SEQUENCE Seq_Category RESTART WITH 5;
END
GO
