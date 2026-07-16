-- Logo d'entreprise stocké dans T010Company + procs get/save.
-- Colonnes : Logo (octets), LogoContentType (MIME), LogoUpdatedOn.
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.T010Company', 'Logo') IS NULL
    ALTER TABLE [dbo].[T010Company] ADD [Logo] varbinary(max) NULL;
GO
IF COL_LENGTH('dbo.T010Company', 'LogoContentType') IS NULL
    ALTER TABLE [dbo].[T010Company] ADD [LogoContentType] varchar(100) NULL;
GO
IF COL_LENGTH('dbo.T010Company', 'LogoUpdatedOn') IS NULL
    ALTER TABLE [dbo].[T010Company] ADD [LogoUpdatedOn] datetime NULL;
GO

-- Enregistre (ou retire si @Logo IS NULL) le logo de la compagnie.
CREATE OR ALTER PROCEDURE [dbo].[s0689SaveCompanyLogo]
    @CompanyGUID uniqueidentifier,
    @Logo varbinary(max) = NULL,
    @ContentType varchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [dbo].[T010Company]
       SET [Logo] = @Logo,
           [LogoContentType] = @ContentType,
           [LogoUpdatedOn] = GETDATE()
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO

-- Retourne le logo (octets + MIME) de la compagnie.
CREATE OR ALTER PROCEDURE [dbo].[s0690GetCompanyLogo]
    @CompanyGUID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Logo], [LogoContentType], [LogoUpdatedOn]
      FROM [dbo].[T010Company]
     WHERE [CompanyGUID] = @CompanyGUID;
END
GO
