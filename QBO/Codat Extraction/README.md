# Extraction QuickBooks Online par Codat → CSV (MngConsul)

Application Windows (VB.NET, WinForms, .NET 8) qui lit les données comptables d'une société
QuickBooks Online **à travers Codat** et écrit un fichier CSV par type de données.

Même principe que `QBO\POC Extraction`, mais l'application ne gère pas l'OAuth : la société relie
son QuickBooks à Codat par un lien, Codat synchronise ses données, et l'application les lit chez
Codat avec une clé d'API.

**Un compte développeur Intuit reste nécessaire** : Codat se connecte à QuickBooks Online avec
votre propre application Intuit (Client ID / Secret fournis dans le portail Codat).

## Prérequis

- Un compte Codat avec l'**Accounting API** et l'intégration **QuickBooks Online Sandbox** (essais)
  ou **QuickBooks Online** (vraies sociétés) activée : portail Codat ▸ Settings ▸ Integrations ▸ Accounting.
- Une application Intuit (developer.intuit.com) dont les clés sont données à Codat, avec l'URI de
  redirection https://quickbooksonlinesandbox.codat.io/oauth2/callback (Sandbox) ou
  https://quickbooksonline.codat.io/oauth2/callback (Production, après approbation d'Intuit).
  Codat indique que la référence de l'Accounting API vise ses clients existants : un nouveau compte
  passe par un contact commercial chez Codat.
- Les types de données voulus activés et synchronisés (portail ▸ Settings ▸ Data types).
- Une **clé d'API** : portail ▸ Settings ▸ Developers ▸ API keys. La clé brute ou l'en-tête
  « Basic … » que le portail propose conviennent.

## Utilisation

1. Entrez la clé d'API et le nom de la société, puis **Créer la société et relier QuickBooks…** :
   Codat crée la société et ouvre son lien ; choisissez QuickBooks Online et autorisez l'accès.
   Pour une société déjà créée dans le portail, collez simplement son **Company ID**.
2. **Vérifier la connexion** : l'application retrouve la connexion QuickBooks reliée et remplit le
   **Connection ID** (nécessaire aux comptes bancaires, virements, transactions, dépenses et revenus directs).
3. **Synchroniser**, puis **État des données** jusqu'à ce que les types voulus soient à jour :
   les extractions lisent la **dernière synchronisation** de Codat, pas QuickBooks en direct.
   Le journal rappelle, pour chaque fichier, la date de synchronisation lue.
4. Réglez le dossier, les dates et le séparateur, puis un bouton par extraction, ou **Tout extraire**.

| Catégorie | Fichiers |
|---|---|
| Référentiels | Entreprise, PlanComptable, Clients, Fournisseurs, ProduitsServices, TauxTaxe, ModesPaiement, CategoriesSuivi, Journaux, ComptesBancaires |
| Ventes | Factures, NotesCredit, PaiementsClients, CommandesClients, RevenusDirects — avec `_Lignes.csv` |
| Achats | FacturesFournisseurs, CreditsFournisseurs, PaiementsFournisseurs, BonsCommande, DepensesDirectes — avec `_Lignes.csv` |
| Banque et journal | EcrituresJournal et TransactionsComptes (avec `_Lignes.csv`), Virements |
| Rapports | BalanceAgeeClients, BalanceAgeeFournisseurs (à la date de bascule), Bilan et EtatResultats (mois par mois, du début de l'exercice à la bascule) |

## Format des fichiers

- UTF-8 avec BOM ; en-têtes = chemins du modèle de données Codat (`customerRef.companyName`,
  `lineItems` → `accountRef.name`…), identiques quel que soit le logiciel comptable relié.
- Montants avec point décimal, dates ISO telles que Codat les rend (`2026-03-17T00:00:00`).
- `_Lignes.csv` : chaque ligne rappelle son document (`parent.id`, `parent.number`, `parent.date`)
  et son rang (`lineIndex`).
- Adresses : facturation puis livraison, champ par champ (`addresses[Billing].city`…).
- Valeurs multiples jointes par ` | ` ; paiements appliqués au format `paiement:montant@date`.
- Rapports financiers : une ligne par nœud de l'arbre (`section`, `level`, `path`), totaux compris.

## Différences avec l'extraction directe QuickBooks

- **Pas de balance de vérification** : Codat n'en fournit pas. Le plan comptable donne les soldes
  **actuels** (`currentBalance`), pas ceux de la date de bascule ; la balance à la bascule se tire
  toujours de QuickBooks (rapport ou `POC Extraction`).
- **Modèle normalisé** : certains champs propres à QuickBooks (classes, emplacements, termes de
  paiement, champs personnalisés) n'ont pas d'équivalent ou passent par les catégories de suivi.
- **Bilan et résultats** : paramètres `periodLength=1`, `periodsToCompare` = nombre de mois,
  `startMonth` = mois de la bascule. À vérifier sur une vraie société que les mois rendus sont bien
  ceux de l'exercice ; Codat synchronise par défaut 24 mois d'historique.

## Compiler

```
dotnet build -c Release
```
