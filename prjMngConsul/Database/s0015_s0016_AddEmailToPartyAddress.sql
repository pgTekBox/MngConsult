-- s0015_s0016_AddEmailToPartyAddress.sql
-- Ajoute le champ @Email (optionnel, retrocompatible) a l'insert et l'update d'une adresse.
-- La colonne T054PartyAddress.Email existe deja ; s0013GetPastyAddress la retourne deja.
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[s0015InsertPartyAddress]
    @PartyId int, @AddressTypeId int, @Name varchar(200), @Address1 varchar(500),
    @Address2 varchar(500), @Note varchar(max), @City varchar(50), @PostalCode varchar(20),
    @CountryId int, @StateId int, @Email varchar(200) = NULL
AS
INSERT INTO [dbo].[T054PartyAddress]
    ([PartyId],[AddressTypeId],[Name],Note,[Address1],[Address2],[City],[PostalCode],[CountryId],[StateId],[Email])
VALUES
    (@PartyId,@AddressTypeId,@Name,@Note,@Address1,@Address2,@City,@PostalCode,@CountryId,@StateId,@Email);
GO

CREATE OR ALTER PROCEDURE [dbo].[s0016UpdatePartyAddress]
    @Id int, @AddressTypeId int, @Name varchar(200), @Address1 varchar(500),
    @Address2 varchar(500), @City varchar(50), @Note varchar(max), @PostalCode varchar(20),
    @CountryId int, @StateId int, @Email varchar(200) = NULL
AS
UPDATE [dbo].[T054PartyAddress]
   SET [AddressTypeId] = @AddressTypeId,
       [Name]        = @Name,
       Note          = @Note,
       [Address1]    = @Address1,
       [Address2]    = @Address2,
       City          = @City,
       [StateId]     = @StateId,
       [CountryId]   = @CountryId,
       [PostalCode]  = @PostalCode,
       [Email]       = @Email
 WHERE Id = @Id;
GO
