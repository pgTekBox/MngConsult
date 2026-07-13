SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================================================
-- s0230GetUserAndCompanyInfo
-- Infos utilisateur + compagnie. CompanyName / CompanyLegalName proviennent du
-- paramètre LEGAL_NAME (T101) via dbo.fCompanyName (repli T010Company.Name).
-- Champs fiscaux sourcés depuis T101 (source unique) : BusinessNumber(FED_BN),
-- SIN, TpsNumber(GST_NO), TpsRegDate(TPS_REG_DATE), NEQ, TvqNumber(QST_NO),
-- TvqRegDate(TVQ_REG_DATE), CAE, FiscalYearEnd(FISCAL_YEAR_END), PaymentRegime.
-- TpsFrequency et TvqFrequency proviennent du paramètre unique TAX_FREQ.
-- Tous les champs entreprise viennent désormais de T101 ; T010Company ne sert
-- plus que pour Id/CompanyCode (identité de l'enregistrement).
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[s0230GetUserAndCompanyInfo]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- ===== Utilisateur (T015User) =====
        u.Id                  AS UserId,
        u.CompanyGUID,
        u.Email,
        u.FirstName,
        u.LastName,
        u.Address1            AS UserAddress1,
        u.City                AS UserCity,
        u.Province            AS UserProvince,
        u.PostalCode          AS UserPostalCode,
        u.Phone               AS UserPhone,
        u.IsAdmin,
        u.IsAccountant,
        u.IsActive,
        u.IsEmailVerified,
        u.ActivatedOn,
        u.CreatedOn           AS UserCreatedOn,
        u.ModifiedOn          AS UserModifiedOn,

        -- ===== Compagnie (T010Company) =====
        c.Id                  AS CompanyId,
        c.CompanyCode,
        dbo.fCompanyName(u.CompanyGUID) AS CompanyName,
        dbo.fCompanyName(u.CompanyGUID) AS CompanyLegalName,


        -- Identification fiscale fédérale (T101 : source unique)
        dbo.fParamS(u.CompanyGUID, 'FED_BN')       AS BusinessNumber,
        dbo.fParamS(u.CompanyGUID, 'SIN')          AS SIN,
        dbo.fParamS(u.CompanyGUID, 'GST_NO')       AS TpsNumber,
        dbo.fParamD(u.CompanyGUID, 'TPS_REG_DATE') AS TpsRegDate,

        -- Identification fiscale provinciale (Québec)
        dbo.fParamS(u.CompanyGUID, 'NEQ')          AS NEQ,
        dbo.fParamS(u.CompanyGUID, 'QST_NO')       AS TvqNumber,
        dbo.fParamD(u.CompanyGUID, 'TVQ_REG_DATE') AS TvqRegDate,
        dbo.fParamS(u.CompanyGUID, 'CAE')          AS CAE,

        T020.[PlanCode] Abonnement,


        -- Périodicité des déclarations
        dbo.fParamS(u.CompanyGUID, 'TAX_FREQ') AS TpsFrequency,
        dbo.fParamS(u.CompanyGUID, 'TAX_FREQ') AS TvqFrequency,
        dbo.fParamD(u.CompanyGUID, 'FISCAL_YEAR_END') AS FiscalYearEnd,
        dbo.fParamS(u.CompanyGUID, 'PAYMENT_REGIME') AS PaymentRegime,

        c.ModifiedOn          AS CompanyModifiedOn

    FROM dbo.T015User u
    INNER JOIN dbo.T010Company c  ON c.CompanyGUID = u.CompanyGUID
    left join [dbo].[T020Subscription] T020 on T020.[CompanyGUID] = u.CompanyGUID
    WHERE u.Id = @UserId
      AND u.IsDeleted = 0;
END
GO
