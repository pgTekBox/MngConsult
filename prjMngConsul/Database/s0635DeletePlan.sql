SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================
-- s0635DeletePlan
-- Suppression logique d'un forfait (IsDeleted = 1).
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.s0635DeletePlan
    @Id         INT,
    @ModifiedBy NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T021Plan
    SET IsDeleted  = 1,
        IsActive   = 0,
        ModifiedOn = GETDATE(),
        ModifiedBy = @ModifiedBy
    WHERE Id = @Id;
END
