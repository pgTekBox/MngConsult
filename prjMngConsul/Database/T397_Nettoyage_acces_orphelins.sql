-- =====================================================================
-- T397 — Les réglages d'accès par dossier (T336DossierAction) d'un
-- employé sont effacés quand il perd l'accès au dossier.
--
-- s1019PurgerActionsOrphelines : efface, dans un cabinet, les réglages
-- d'un employé ACTIF pour un dossier qu'il ne peut plus ouvrir
-- (absent de fCabinetDossiers). Filtres facultatifs : un dossier, un
-- employé. Les employés inactifs ne sont jamais touchés : désactiver
-- quelqu'un ne doit pas lui rendre l'accès complet à sa réactivation.
--
-- Appelée par :
--   s0930AssignDossier  — dossier réaffecté : réglages devenus inutiles
--                         pour ce dossier (ancien employé, son superviseur) ;
--   s0998SetSuperviseur — superviseur changé : réglages de l'ancien
--                         superviseur sur les dossiers qu'il ne voit plus.
-- =====================================================================
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.s1019PurgerActionsOrphelines
    @CabinetId   int,
    @CompanyGUID uniqueidentifier = NULL,
    @UserGUID    uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DELETE a
    FROM dbo.T336DossierAction a
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = a.UserGUID AND m.CabinetId = a.CabinetId AND m.IsActive = 1
    WHERE a.CabinetId = @CabinetId
      AND (@CompanyGUID IS NULL OR a.CompanyGUID = @CompanyGUID)
      AND (@UserGUID IS NULL OR a.UserGUID = @UserGUID)
      AND NOT EXISTS (SELECT 1 FROM dbo.fCabinetDossiers(a.UserGUID) f WHERE f.CompanyGUID = a.CompanyGUID);
END
GO

-- ---------------------------------------------------------------------------
-- s0930AssignDossier : affecte un dossier (compagnie) a un membre / une equipe.
-- Valide que la compagnie appartient bien au cabinet de l'appelant.
-- ErrorCode : 0=OK, 2=non autorise, 6=compagnie hors cabinet.
-- T397 : efface ensuite les reglages d'acces devenus orphelins pour ce dossier.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0930AssignDossier
    @UserId           varchar(200),
    @CompanyGUID      uniqueidentifier,
    @AssignedUserGUID uniqueidentifier = NULL,
    @EquipeId         int = NULL,
    @ErrorCode        int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;

    DECLARE @cabId int, @callerRole nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @callerRole = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @callerRole NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END

    -- la compagnie doit etre un dossier du cabinet (ComptableGUID d'un membre)
    IF NOT EXISTS (
        SELECT 1 FROM dbo.T010Company c
        WHERE c.CompanyGUID = @CompanyGUID
          AND c.ComptableGUID IN (SELECT UserGUID FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1)
    )
    BEGIN SET @ErrorCode = 6; RETURN; END

    IF EXISTS (SELECT 1 FROM dbo.T334CabinetDossier WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID)
        UPDATE dbo.T334CabinetDossier
        SET AssignedUserGUID = @AssignedUserGUID, EquipeId = @EquipeId
        WHERE CabinetId = @cabId AND CompanyGUID = @CompanyGUID;
    ELSE
        INSERT INTO dbo.T334CabinetDossier (CabinetId, CompanyGUID, AssignedUserGUID, EquipeId)
        VALUES (@cabId, @CompanyGUID, @AssignedUserGUID, @EquipeId);

    -- T397 : les reglages des employes qui ne voient plus ce dossier
    EXEC dbo.s1019PurgerActionsOrphelines @CabinetId = @cabId, @CompanyGUID = @CompanyGUID;
END
GO

-- ---------------------------------------------------------------------------
-- s0998SetSuperviseur (T392) — T397 : efface ensuite les reglages de
-- l'ancien superviseur sur les dossiers qu'il ne voit plus.
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0998SetSuperviseur
    @UserId varchar(200),
    @MembreId int,
    @SuperviseurUserGUID uniqueidentifier = NULL,
    @ErrorCode int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorCode = 0;
    DECLARE @cabId int, @role nvarchar(20);
    SELECT TOP 1 @cabId = m.CabinetId, @role = m.Role
    FROM dbo.T015User u
    JOIN dbo.T332CabinetMembre m ON m.UserGUID = u.UserGUID AND m.IsActive = 1
    WHERE u.email = @UserId AND u.IsDeleted = 0
    ORDER BY m.Id;

    IF @cabId IS NULL OR @role NOT IN ('admin', 'solo') BEGIN SET @ErrorCode = 2; RETURN; END
    DECLARE @cible uniqueidentifier = (SELECT UserGUID FROM dbo.T332CabinetMembre
                                       WHERE Id = @MembreId AND CabinetId = @cabId AND IsActive = 1 AND Role = 'technicien');
    IF @cible IS NULL BEGIN SET @ErrorCode = 3; RETURN; END
    -- T392 : tout membre actif du cabinet peut superviser, sauf l'employe lui-meme
    IF @SuperviseurUserGUID IS NOT NULL AND (@SuperviseurUserGUID = @cible OR NOT EXISTS (
        SELECT 1 FROM dbo.T332CabinetMembre WHERE CabinetId = @cabId AND IsActive = 1
          AND UserGUID = @SuperviseurUserGUID))
    BEGIN SET @ErrorCode = 4; RETURN; END

    DECLARE @ancien uniqueidentifier = (SELECT SuperviseurUserGUID FROM dbo.T332CabinetMembre
                                        WHERE Id = @MembreId AND CabinetId = @cabId);

    UPDATE dbo.T332CabinetMembre SET SuperviseurUserGUID = @SuperviseurUserGUID
    WHERE Id = @MembreId AND CabinetId = @cabId;

    -- T397 : l'ancien superviseur perd les dossiers de cet employe
    IF @ancien IS NOT NULL AND (@SuperviseurUserGUID IS NULL OR @ancien <> @SuperviseurUserGUID)
        EXEC dbo.s1019PurgerActionsOrphelines @CabinetId = @cabId, @UserGUID = @ancien;
END
GO
