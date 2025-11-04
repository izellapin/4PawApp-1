-- Add Payment Columns to Appointments Table
-- Run this manually if migration hasn't applied

USE 4PawDB;
GO

-- Check if columns exist before adding them
IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID(N'Appointments') AND name = 'IsPaid')
BEGIN
    ALTER TABLE Appointments ADD IsPaid BIT NOT NULL DEFAULT 0;
    PRINT 'IsPaid column added successfully';
END
ELSE
BEGIN
    PRINT 'IsPaid column already exists';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID(N'Appointments') AND name = 'PaymentDate')
BEGIN
    ALTER TABLE Appointments ADD PaymentDate DATETIME2 NULL;
    PRINT 'PaymentDate column added successfully';
END
ELSE
BEGIN
    PRINT 'PaymentDate column already exists';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID(N'Appointments') AND name = 'PaymentMethod')
BEGIN
    ALTER TABLE Appointments ADD PaymentMethod NVARCHAR(100) NULL;
    PRINT 'PaymentMethod column added successfully';
END
ELSE
BEGIN
    PRINT 'PaymentMethod column already exists';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID(N'Appointments') AND name = 'PaymentTransactionId')
BEGIN
    ALTER TABLE Appointments ADD PaymentTransactionId NVARCHAR(100) NULL;
    PRINT 'PaymentTransactionId column added successfully';
END
ELSE
BEGIN
    PRINT 'PaymentTransactionId column already exists';
END
GO

-- Verify columns were added
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Appointments'
  AND COLUMN_NAME IN ('IsPaid', 'PaymentDate', 'PaymentMethod', 'PaymentTransactionId')
ORDER BY COLUMN_NAME;






