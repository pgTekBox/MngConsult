-- Adresse + courriel de FACTURATION (Billing, AddressTypeId=1) pour les 10 clients 654-663
-- Company D89EB638 / Pays Canada=1 / Province Quebec=2
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @Type int = 1, @Pays int = 1, @Prov int = 2;

EXEC s0015InsertPartyAddress @PartyId=654, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'145 rue Principale', @Address2=NULL, @Note=NULL, @City=N'Saint-Hyacinthe',
  @PostalCode=N'J2S 2R3', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@boulangerieducoin.ca';

EXEC s0015InsertPartyAddress @PartyId=655, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'2280 boulevard Saint-Laurent', @Address2=N'bureau 400', @Note=NULL, @City=N'Montréal',
  @PostalCode=N'H2X 2T3', @CountryId=@Pays, @StateId=@Prov, @Email=N'comptes@studiodesigncreatif.ca';

EXEC s0015InsertPartyAddress @PartyId=656, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'87 avenue des Pins', @Address2=NULL, @Note=NULL, @City=N'Laval',
  @PostalCode=N'H7N 3K5', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@epiceriefraicheur.ca';

EXEC s0015InsertPartyAddress @PartyId=657, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'500 rue Sherbrooke Ouest', @Address2=N'bureau 1200', @Note=NULL, @City=N'Montréal',
  @PostalCode=N'H3A 3C6', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@comptablelemieux.ca';

EXEC s0015InsertPartyAddress @PartyId=658, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'1340 boulevard Industriel', @Address2=NULL, @Note=NULL, @City=N'Longueuil',
  @PostalCode=N'J4G 1P6', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@mecanoexpress.ca';

EXEC s0015InsertPartyAddress @PartyId=659, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'32 rue Notre-Dame', @Address2=NULL, @Note=NULL, @City=N'Trois-Rivières',
  @PostalCode=N'G9A 4X5', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@fleuristebellesaison.ca';

EXEC s0015InsertPartyAddress @PartyId=660, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'744 rue Saint-Jean', @Address2=NULL, @Note=NULL, @City=N'Québec',
  @PostalCode=N'G1R 1P8', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@papieretencre.ca';

EXEC s0015InsertPartyAddress @PartyId=661, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'119 rue Wellington', @Address2=NULL, @Note=NULL, @City=N'Sherbrooke',
  @PostalCode=N'J1H 5C7', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@cafetorrefactionnord.ca';

EXEC s0015InsertPartyAddress @PartyId=662, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'908 boulevard des Érables', @Address2=NULL, @Note=NULL, @City=N'Gatineau',
  @PostalCode=N'J8T 6E4', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@cliniquedeserables.ca';

EXEC s0015InsertPartyAddress @PartyId=663, @AddressTypeId=@Type, @Name=N'Facturation',
  @Address1=N'56 chemin du Domaine', @Address2=NULL, @Note=NULL, @City=N'Saint-Jérôme',
  @PostalCode=N'J7Y 2R8', @CountryId=@Pays, @StateId=@Prov, @Email=N'facturation@paysagervertpre.ca';
GO

-- Vérification
SELECT a.PartyId, p.Name AS Client, a.AddressTypeId, a.Name AS AdrNom, a.Address1, a.City, a.PostalCode, a.Email
FROM T054PartyAddress a
JOIN T050Party p ON p.Id = a.PartyId
WHERE a.PartyId BETWEEN 654 AND 663
ORDER BY a.PartyId;
GO
