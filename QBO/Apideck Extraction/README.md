# Extraction QuickBooks Online par Apideck → CSV (MngConsul)

Application Windows (VB.NET, WinForms, .NET 8) qui lit les données comptables d'une société
QuickBooks Online **à travers l'API comptable unifiée d'Apideck** et écrit un fichier CSV par type de données.

Même principe que `QBO\POC Extraction` et `QBO\Codat Extraction`. Différence avec Codat : Apideck
ne synchronise rien d'avance, chaque extraction lit QuickBooks **en direct**.

## Prérequis

1. **Un compte Apideck** (app.apideck.com) avec l'API *Accounting* et le connecteur **QuickBooks** activés.
   Tableau de bord ▸ Configuration ▸ API Keys : notez la **clé d'API** et l'**Application ID**.
2. **Une application Intuit** (developer.intuit.com) : Apideck se connecte à QuickBooks avec vos
   propres clés.
   - Portée `com.intuit.quickbooks.accounting`.
   - URI de redirection : `https://unify.apideck.com/vault/callback`.
   - Collez le Client ID et le Client Secret dans Apideck ▸ Connecteur QuickBooks.
   - Les clés *Development* ne se connectent qu'à une société Sandbox d'Intuit ; les clés
     *Production* demandent l'approbation d'Intuit (questionnaire d'évaluation de l'application).

## Utilisation

1. Entrez la clé d'API, l'App ID, un **Consumer ID** de votre choix pour la société
   (par exemple `long-for-success`) et son nom. Connecteur : `quickbooks`.
2. **Relier QuickBooks (Vault)…** : Apideck ouvre sa page Vault ; choisissez QuickBooks et autorisez.
3. **Vérifier la connexion** : la connexion doit être à l'état `callable` ; le nom de la société s'affiche.
4. Réglez le dossier, les dates, le séparateur et la méthode comptable, puis un bouton par
   extraction, ou **Tout extraire**.

| Catégorie | Fichiers |
|---|---|
| Référentiels | Entreprise, PlanComptable, Clients, Fournisseurs, ProduitsServices, TauxTaxe, ModesPaiement, CategoriesSuivi, Emplacements, Departements, ComptesBancaires |
| Ventes | Factures, NotesCredit, RecusVente, Paiements, Remboursements, Soumissions — avec `_Lignes.csv` |
| Achats | FacturesFournisseurs, CreditsFournisseurs, PaiementsFournisseurs, Depenses, BonsCommande — avec `_Lignes.csv` |
| Banque et journal | EcrituresJournal et TransactionsGrandLivre (avec `_Lignes.csv`), Journaux |
| Rapports | BalanceAgeeClients et BalanceAgeeFournisseurs (détail par transaction), Bilan (à la bascule), EtatResultats (du début de l'exercice à la bascule) |

## Format des fichiers

- UTF-8 avec BOM ; en-têtes = chemins du modèle unifié d'Apideck (`customer.display_name`,
  `ledger_account.nominal_code`…).
- Montants avec point décimal, dates telles qu'Apideck les rend.
- `_Lignes.csv` : chaque ligne rappelle son document (`parent.id`, `parent.number`, `parent.date`)
  et son rang (`line_index`). Pour les paiements, les « lignes » sont les documents réglés (`allocations`).
- Adresses des tiers : facturation puis livraison (`addresses[billing].city`…) ; adresses des
  documents : `billing_address.*`, `shipping_address.*`.
- Valeurs multiples jointes par ` | ` ; paiements appliqués au format `id:montant@date`.

## Limites connues

- **Filtre de date** : Apideck ne l'offre que pour les factures fournisseurs (`billed_since`) et les
  écritures de journal (`start_date`) ; les autres ressources sont extraites en entier.
- **Pas de balance de vérification** dans l'API d'Apideck : le plan comptable donne les soldes
  **actuels** (`current_balance`). La balance à la bascule se tire de QuickBooks.
- **Couverture** : toutes les ressources ne sont pas offertes par chaque connecteur ; une
  ressource absente pour QuickBooks répond 404 ou « non supporté », et le journal le dit.
- Pagination par curseur, 200 enregistrements par page.

## Compiler

```
dotnet build -c Release
```
