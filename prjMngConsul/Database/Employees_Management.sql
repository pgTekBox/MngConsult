-- =============================================================================
-- Gestion des employés (= ressources de l'agenda, table dbo.T300Employees)
--   + boîte de courriel @60sec.ca par employé (MailService.dbo.SmtpLocalRecipient)
--   + réinitialisation du mot de passe de la boîte via un lien envoyé au
--     courriel EXTERNE de l'employé (colonne Email), page publique + jeton.
--
--   Colonnes ajoutées à T300Employees : Sec60Email, MailResetToken, MailResetExpires
--   Procs (plage libre MngConsul 0719+) :
--     s0719GetEmployees            liste (recherche) + état boîte/mot de passe
--     s0720GetEmployeeById         fiche complète
--     s0721SaveEmployee            upsert (@NewId OUTPUT)
--     s0722DeleteEmployee          supprime (détache les RDV + libère la boîte)
--     s0723AssignEmployeeMailbox   attribue/gènere l'adresse @60sec.ca (unicité)
--     s0724CreateEmployeeMailReset crée un jeton de réinit. (retourne infos courriel)
--     s0725GetEmployeeByMailResetToken  valide un jeton (non expiré)
--     s0726ClearEmployeeMailReset  efface le jeton après usage
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF COL_LENGTH('dbo.T300Employees', 'Sec60Email') IS NULL
    ALTER TABLE dbo.T300Employees ADD Sec60Email VARCHAR(150) NULL;
GO
IF COL_LENGTH('dbo.T300Employees', 'MailResetToken') IS NULL
    ALTER TABLE dbo.T300Employees ADD MailResetToken UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH('dbo.T300Employees', 'MailResetExpires') IS NULL
    ALTER TABLE dbo.T300Employees ADD MailResetExpires DATETIME NULL;
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0719GetEmployees
    @CompanyGUID UNIQUEIDENTIFIER,
    @Search      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        e.Id,
        e.EmployeeNumber,
        LTRIM(RTRIM(COALESCE(NULLIF(e.DisplayName, ''),
              LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, '')))))) AS FullName,
        e.JobTitle,
        e.Department,
        e.Email,
        e.Phone,
        e.Active,
        ISNULL(e.ColorHex, '#2563eb') AS ColorHex,
        e.Sec60Email,
        CAST(CASE WHEN e.Sec60Email IS NOT NULL AND e.Sec60Email <> '' THEN 1 ELSE 0 END AS BIT) AS HasMailbox,
        CAST(CASE WHEN r.PasswordHash IS NOT NULL AND r.PasswordHash <> '' THEN 1 ELSE 0 END AS BIT) AS HasPassword,
        CAST(CASE WHEN r.IsActive = 1 THEN 1 ELSE 0 END AS BIT) AS MailActive
    FROM dbo.T300Employees e
    LEFT JOIN MailService.dbo.SmtpLocalRecipient r ON r.Email = e.Sec60Email
    WHERE e.CompanyGUID = @CompanyGUID
      AND (@Search IS NULL OR @Search = ''
           OR e.DisplayName LIKE '%' + @Search + '%'
           OR e.FirstName   LIKE '%' + @Search + '%'
           OR e.LastName    LIKE '%' + @Search + '%'
           OR e.EmployeeNumber LIKE '%' + @Search + '%'
           OR e.Email       LIKE '%' + @Search + '%'
           OR e.Sec60Email  LIKE '%' + @Search + '%')
    ORDER BY FullName;
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0720GetEmployeeById
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        e.Id, e.EmployeeNumber, e.FirstName, e.LastName, e.DisplayName,
        e.JobTitle, e.Department, e.Email, e.Phone, e.Mobile, e.City,
        e.HireDate, e.EmploymentStatus, e.EmploymentType,
        ISNULL(e.Active, 1) AS Active,
        ISNULL(e.ColorHex, '#2563eb') AS ColorHex,
        e.Sec60Email
    FROM dbo.T300Employees e
    WHERE e.CompanyGUID = @CompanyGUID AND e.Id = @Id;
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0721SaveEmployee
    @Id               INT,
    @CompanyGUID      UNIQUEIDENTIFIER,
    @EmployeeNumber   VARCHAR(50)   = NULL,
    @FirstName        VARCHAR(150)  = NULL,
    @LastName         VARCHAR(150)  = NULL,
    @DisplayName      VARCHAR(300)  = NULL,
    @JobTitle         VARCHAR(150)  = NULL,
    @Department       VARCHAR(150)  = NULL,
    @Email            VARCHAR(200)  = NULL,
    @Phone            VARCHAR(50)   = NULL,
    @Mobile           VARCHAR(50)   = NULL,
    @City             VARCHAR(100)  = NULL,
    @HireDate         DATE          = NULL,
    @EmploymentStatus VARCHAR(50)   = NULL,
    @EmploymentType   VARCHAR(50)   = NULL,
    @Active           BIT           = 1,
    @ColorHex         VARCHAR(7)    = NULL,
    @UserId           INT           = NULL,
    @NewId            INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @disp VARCHAR(300) = NULLIF(LTRIM(RTRIM(ISNULL(@DisplayName, ''))), '');
    IF @disp IS NULL
        SET @disp = NULLIF(LTRIM(RTRIM(ISNULL(@FirstName, '') + ' ' + ISNULL(@LastName, ''))), '');

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO dbo.T300Employees
            (EmployeeGUID, CompanyGUID, EmployeeNumber, FirstName, LastName, DisplayName,
             JobTitle, Department, Email, Phone, Mobile, City, HireDate,
             EmploymentStatus, EmploymentType, Active, ColorHex, Created, CreatedBy)
        VALUES
            (NEWID(), @CompanyGUID, @EmployeeNumber, @FirstName, @LastName, @disp,
             @JobTitle, @Department, @Email, @Phone, @Mobile, @City, @HireDate,
             @EmploymentStatus, @EmploymentType, ISNULL(@Active, 1), @ColorHex, GETDATE(), @UserId);
        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.T300Employees
           SET EmployeeNumber = @EmployeeNumber, FirstName = @FirstName, LastName = @LastName,
               DisplayName = @disp, JobTitle = @JobTitle, Department = @Department,
               Email = @Email, Phone = @Phone, Mobile = @Mobile, City = @City, HireDate = @HireDate,
               EmploymentStatus = @EmploymentStatus, EmploymentType = @EmploymentType,
               Active = ISNULL(@Active, 1), ColorHex = @ColorHex, Modified = GETDATE(), ModifiedBy = @UserId
         WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
        SET @NewId = @Id;
    END
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0722DeleteEmployee
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mail VARCHAR(150) = (SELECT Sec60Email FROM dbo.T300Employees
                                  WHERE Id = @Id AND CompanyGUID = @CompanyGUID);
    BEGIN TRAN;
        -- détacher les rendez-vous (ne pas les supprimer)
        UPDATE dbo.Appointments SET EmployeeId = NULL
         WHERE EmployeeId = @Id AND CompanyGUID = @CompanyGUID;
        -- libérer la boîte locale
        IF @mail IS NOT NULL AND @mail <> ''
            DELETE FROM MailService.dbo.SmtpLocalRecipient WHERE Email = @mail;
        -- supprimer l'employé
        DELETE FROM dbo.T300Employees WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
    COMMIT;
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0723AssignEmployeeMailbox
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cur VARCHAR(150) = (SELECT Sec60Email FROM dbo.T300Employees
                                 WHERE Id = @Id AND CompanyGUID = @CompanyGUID);
    IF @cur IS NOT NULL AND @cur <> ''
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @cur)
            INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc)
            VALUES(@cur, 1, SYSUTCDATETIME());
        SELECT @cur AS Email;
        RETURN;
    END

    DECLARE @name NVARCHAR(300) =
        (SELECT LTRIM(RTRIM(COALESCE(NULLIF(DisplayName, ''),
                ISNULL(FirstName, '') + ' ' + ISNULL(LastName, ''))))
         FROM dbo.T300Employees WHERE Id = @Id AND CompanyGUID = @CompanyGUID);

    DECLARE @base VARCHAR(100) = dbo.fnSlugify(@name);
    IF @base IS NULL OR @base = '' SET @base = 'employe';

    DECLARE @cand VARCHAR(120) = @base, @email VARCHAR(150), @n INT = 1;
    WHILE 1 = 1
    BEGIN
        SET @email = @cand + '@60sec.ca';
        IF NOT EXISTS (SELECT 1 FROM dbo.T010Company   WHERE Sec60Email = @email)
           AND NOT EXISTS (SELECT 1 FROM dbo.T300Employees WHERE Sec60Email = @email AND Id <> @Id)
           AND NOT EXISTS (SELECT 1 FROM MailService.dbo.SmtpLocalRecipient WHERE LTRIM(RTRIM(Email)) = @email)
            BREAK;
        SET @n = @n + 1;
        SET @cand = @base + '-' + CAST(@n AS VARCHAR(10));
    END

    UPDATE dbo.T300Employees SET Sec60Email = @email WHERE Id = @Id AND CompanyGUID = @CompanyGUID;
    INSERT INTO MailService.dbo.SmtpLocalRecipient(Email, IsActive, CreatedAtUtc)
    VALUES(@email, 1, SYSUTCDATETIME());

    SELECT @email AS Email;
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0724CreateEmployeeMailReset
    @CompanyGUID UNIQUEIDENTIFIER,
    @Id          INT,
    @Hours       INT = 24
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @token UNIQUEIDENTIFIER = NEWID();

    UPDATE dbo.T300Employees
       SET MailResetToken = @token,
           MailResetExpires = DATEADD(HOUR, @Hours, GETDATE())
     WHERE Id = @Id AND CompanyGUID = @CompanyGUID
       AND Sec60Email IS NOT NULL AND Sec60Email <> ''
       AND Email IS NOT NULL AND Email <> '';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS Ok, CAST(NULL AS UNIQUEIDENTIFIER) AS Token,
               CAST(NULL AS VARCHAR(200)) AS ExternalEmail, CAST(NULL AS VARCHAR(150)) AS Sec60Email,
               CAST(NULL AS NVARCHAR(300)) AS FullName, CAST(NULL AS NVARCHAR(200)) AS CompanyName,
               N'La boîte @60sec.ca et le courriel externe doivent être renseignés.' AS Msg;
        RETURN;
    END

    SELECT CAST(1 AS BIT) AS Ok, @token AS Token,
           e.Email AS ExternalEmail, e.Sec60Email AS Sec60Email,
           LTRIM(RTRIM(COALESCE(NULLIF(e.DisplayName, ''), ISNULL(e.FirstName,'')+' '+ISNULL(e.LastName,'')))) AS FullName,
           COALESCE(dbo.fParamS(@CompanyGUID, 'TRADE_NAME'), dbo.fCompanyName(@CompanyGUID)) AS CompanyName,
           N'' AS Msg
    FROM dbo.T300Employees e
    WHERE e.Id = @Id AND e.CompanyGUID = @CompanyGUID;
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0725GetEmployeeByMailResetToken
    @Token UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.Sec60Email,
           LTRIM(RTRIM(COALESCE(NULLIF(e.DisplayName, ''), ISNULL(e.FirstName,'')+' '+ISNULL(e.LastName,'')))) AS FullName
    FROM dbo.T300Employees e
    WHERE e.MailResetToken = @Token
      AND e.MailResetExpires IS NOT NULL
      AND e.MailResetExpires > GETDATE()
      AND e.Sec60Email IS NOT NULL AND e.Sec60Email <> '';
END
GO

-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.s0726ClearEmployeeMailReset
    @Token UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.T300Employees
       SET MailResetToken = NULL, MailResetExpires = NULL
     WHERE MailResetToken = @Token;
END
GO
