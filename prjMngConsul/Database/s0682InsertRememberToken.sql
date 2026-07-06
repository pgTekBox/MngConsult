SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0682InsertRememberToken
-- Enregistre un jeton « Se souvenir de moi » (hash du validator).
-- Purge au passage les jetons expirés (housekeeping).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0682InsertRememberToken
    @UserId        INT,
    @Selector      VARCHAR(64),
    @ValidatorHash VARCHAR(100),
    @ExpiresOn     DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.T016UserRememberToken WHERE ExpiresOn <= GETDATE();

    INSERT INTO dbo.T016UserRememberToken (UserId, Selector, ValidatorHash, ExpiresOn)
    VALUES (@UserId, @Selector, @ValidatorHash, @ExpiresOn);
END
