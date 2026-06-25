SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0649DeleteAdmin
-- Suppression logique d'un administrateur (IsDeleted = 1).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0649DeleteAdmin
    @Id         INT,
    @ModifiedBy NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T900AdminUser
    SET IsDeleted  = 1,
        IsActive   = 0,
        ModifiedOn = GETDATE(),
        ModifiedBy = @ModifiedBy
    WHERE Id = @Id;
END
