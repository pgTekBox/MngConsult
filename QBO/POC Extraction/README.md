# Extraction QuickBooks Online → CSV (MngConsul)

Application Windows (VB.NET, WinForms, .NET 8) qui lit une société QuickBooks Online par l'API
comptable d'Intuit et écrit un fichier CSV par type de données, pour la reprise dans MngConsul.

## 1. Créer l'application chez Intuit (une fois)

1. <https://developer.intuit.com> ▸ **Dashboard** ▸ **Create an app** ▸ *QuickBooks Online and Payments*.
2. Portée : **com.intuit.quickbooks.accounting**.
3. **Keys & credentials** : copiez le **Client ID** et le **Client Secret**
   (*Development* pour une société Sandbox, *Production* pour une vraie société).
4. **Redirect URIs** : ajoutez exactement `http://localhost:8765/callback`
   (la même valeur que dans l'application).
   Intuit n'accepte `http://localhost` qu'avec les clés *Development* ; pour une vraie société,
   voir la section 4.

## 2. Se connecter

1. Lancez `QboExtraction.exe`, entrez le Client ID, le Client Secret et l'environnement.
2. **Se connecter à QuickBooks…** : le navigateur s'ouvre, choisissez la société et autorisez.
   L'application reçoit elle-même la réponse, remplit le **Realm ID** et le **Refresh token**,
   puis vérifie la connexion.

Le jeton d'accès se renouvelle seul. Le jeton de renouvellement dure 100 jours et Intuit en donne
un nouveau à chaque usage : l'application le garde aussitôt.

Le secret et le jeton sont chiffrés pour l'utilisateur Windows (DPAPI) dans
`%APPDATA%\60sec\QboExtraction\parametres.json`.

## 3. Extraire

- **Dossier de sortie**, **Début de l'exercice**, **Date de bascule**, séparateur (`;` par défaut) et
  méthode comptable.
- Un bouton par extraction, ou **Tout extraire**. Le journal indique chaque fichier et son nombre de lignes.

| Catégorie | Fichiers |
|---|---|
| Référentiels | Entreprise, PlanComptable, Clients, Fournisseurs, ProduitsServices, Employes, CodesTaxe, TauxTaxe, Modalites, ModesPaiement, Classes, Emplacements |
| Ventes | Factures, NotesCredit, RecusVente, PaiementsClients, Remboursements, Soumissions — chacun avec son `_Lignes.csv` |
| Achats | FacturesFournisseurs, CreditsFournisseurs, PaiementsFournisseurs, Depenses, BonsCommande — avec `_Lignes.csv` |
| Banque et journal | EcrituresJournal et Depots (avec `_Lignes.csv`), Virements |
| Rapports (à la date de bascule) | BalanceVerification, BalanceAgeeClients, BalanceAgeeFournisseurs, Bilan, EtatResultats, GrandLivre — `_AAAA-MM-JJ.csv` |

**Format des fichiers**
- UTF-8 avec BOM, en-têtes = chemins de l'API QuickBooks (`CustomerRef.name`, `BillAddr.City`…).
- Montants et dates tels que les donne l'API : point décimal, dates `AAAA-MM-JJ`.
- Fichiers `_Lignes.csv` : chaque ligne rappelle sa transaction (`Parent.Id`, `Parent.DocNumber`,
  `Parent.TxnDate`) ; les composants d'un groupe de produits portent l'Id de la ligne de groupe dans
  `GroupLine.Id`.
- Valeurs multiples (transactions liées, taxes par taux) jointes par ` | `.
- Rapports : une ligne par ligne du rapport, avec sa `Section` et son `Type de ligne`
  (Entête, Donnée, Total), et les identifiants QuickBooks dans les colonnes `(Id)`.
- Les numéros d'assurance sociale des employés ne sont pas extraits.

## 4. Vraie société (Production)

Intuit exige, pour les clés *Production*, une URI de redirection en **https** et une application
« publiée » (questionnaire de conformité). Deux possibilités :

- Obtenir un **Refresh token** et le **Realm ID** dans l'**OAuth 2.0 Playground** d'Intuit
  (developer.intuit.com ▸ *Playground*), avec les clés Production, puis les coller dans
  l'application et cliquer **Tester la connexion**.
- Ou compléter les exigences Production d'Intuit pour utiliser **Se connecter**.

## Compiler

```
dotnet build -c Release
```
