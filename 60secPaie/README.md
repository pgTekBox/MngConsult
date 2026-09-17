# 60secPaie

Application Web de calcul de la paie pour des employeurs du **Québec**, **multi-compagnie** et en **trois langues** (français, anglais, espagnol).
Les utilisateurs, les compagnies et les employés sont ceux de **MngConsul** (même base de données).
ASP.NET Web Forms en **VB.NET** (.NET Framework 4.8), SQL Server, Visual Studio 2022/2026.
Le modèle fonctionnel est Nubis (voir [docs/analyse-nubis.md](docs/analyse-nubis.md)).

## Structure

| Dossier | Rôle |
|---|---|
| `src/60secPaie.Calcul` | Moteur de calcul, sans dépendance Web ni SQL : taux de l'année, catégories de paie, formules. |
| `src/60secPaie.Web` | Application Web Forms : pages, accès SQL (ADO.NET paramétré), sécurité, assistant de paie. |
| `src/60secPaie.Tests` | Tests MSTest : exemples chiffrés de Revenu Québec + cycle de paie complet sur LocalDB. |
| `Database` | Script du schéma SQL Server (relançable), déploiement sur le serveur, répliques des tables de MngConsul pour les tests. |
| `lib` | BCrypt.Net-Next 3.2.1 (vérification des mots de passe de MngConsul) ; le projet n'utilise pas NuGet. |
| `docs` | Analyse de Nubis, guide TP-1015.F 2026 de Revenu Québec. |

## Démarrer

1. Copier `src\60secPaie.Web\ConnectionStrings.exemple.config` sous le nom `ConnectionStrings.config` et y inscrire la connexion à la base
   MngConsul (ou lancer `Database\Deployer-Serveur.ps1 -Action Configurer`, qui la reprend de `prjMngConsul` sans l'afficher).
2. Ouvrir `60secPaie.sln`, définir **60secPaie.Web** comme projet de démarrage, F5 (IIS Express, port 50960).
3. Se connecter avec son **compte MngConsul**, enregistrer les paramètres de paie de la compagnie (Configuration), configurer la paie des
   employés (Employés → Configurer), puis lancer **Calculer la paie**.

La chaîne de connexion `Paie` est dans `ConnectionStrings.config`, **exclu de git** parce qu'il peut contenir le mot de passe du serveur SQL.

### Base de données : schéma « paie » dans la base MngConsul

Toutes les tables de 60secPaie sont dans le **schéma `paie`** de la base `MngConsul` (serveur `192.168.0.203`). Le script de schéma ne crée et
ne modifie rien hors de `paie`, et 60secPaie **n'écrit jamais dans les tables de MngConsul** : il les lit.

`Database\Deployer-Serveur.ps1` lit la chaîne de connexion dans le `Web.config` de `prjMngConsul` (clé `ConnectionString`) et ne l'affiche jamais.
Actions : `-Action Verifier` (lecture seule), `Schema` (exécute `01_schema.sql`, relançable), `Configurer` (écrit `ConnectionStrings.config`).

### Ce qui vient de MngConsul

| Donnée | Source (lecture seule) | Dans 60secPaie |
|---|---|---|
| Utilisateurs, mots de passe | `dbo.T015User` (BCrypt) | Connexion par courriel ; aucun mot de passe n'est stocké ni modifié ici. Mot de passe oublié : le réinitialiser dans MngConsul. |
| Compagnies accessibles | `dbo.s0210GetUserCompanies` | Un utilisateur voit sa compagnie ; un comptable, celles de ses clients. Sélecteur de compagnie dans l'en-tête. |
| Nom et coordonnées de la compagnie | `dbo.fCompanyName`, `dbo.fParamS` | Affichés en lecture seule ; `paie.Compagnie` ne garde que les paramètres de paie (liée par `CompanyGUID`). |
| Employés | `dbo.T300Employees` | Nom, adresse, poste, embauche, courriel : lecture seule. La paie (NAS, TD1, TP-1015.3, exemptions, taux, dépôt direct, langue) est dans `paie.EmployePaie`. |

La vue `paie.Employe` réunit `T300Employees` et `paie.EmployePaie`. Un employé n'est proposé dans l'assistant de paie qu'une fois sa paie
configurée. Chaque requête est filtrée par la compagnie courante, elle-même revalidée à chaque page contre les compagnies de l'utilisateur.

Non fait : vérification de l'abonnement (`T020Subscription`) à la connexion, connexion unique (SSO) avec MngConsul.

### Trois langues

Même convention que MngConsul : `?lang=fr|en|es`, puis la session, puis le français ; 60secPaie ajoute un témoin pour s'en souvenir.
Les pages sont écrites en français ; à la sortie, `I18n.TraduireHtml` remplace chaque texte par sa traduction, prise dans
**`src\60secPaie.Web\Langues\traductions.txt`** (relu automatiquement dès qu'il est enregistré, aucune recompilation) :

```
fr: Paie du {#0} confirmée.
en: Pay run of {#0} confirmed.
es: Nómina del {#0} confirmada.
```

`{0}` = un texte variable (traduit à son tour s'il est connu), `{#0}` = un nombre, un montant ou une date. Un texte absent du fichier reste en
français. `translate="no"` sur une balise protège son texte (nom du produit). Les montants et les nombres suivent la langue (1 234,50 $ / $1,234.50) ;
la saisie accepte les deux formats ; les dates restent en AAAA-MM-JJ. Le journal d'activités est enregistré en français et traduit à l'affichage.
Le **talon par courriel part dans la langue de l'employé** (fiche de l'employé), quelle que soit la langue de la personne qui fait la paie.
Les feuillets T4 / Relevé 1 affichent les libellés officiels traduits ; les sigles deviennent QPP, QPIP, EI, HSF, SIN en anglais.
Un test vérifie que chaque texte du fichier a ses deux traductions et les mêmes jetons.

**NAS et comptes bancaires** : ils sont chiffrés avec la clé machine d'ASP.NET du poste qui les a saisis. Tant que l'application tourne sur ce
poste (seule la base est sur le serveur), rien ne change. Le jour où l'application est installée sur un autre serveur IIS, définir la même
`machineKey` fixe des deux côtés avant, sinon il faudra ressaisir ces deux renseignements.

## Ce que fait la version 1

- **Configuration** : compagnie (fréquence de paie, taux de vacances, FSS selon la masse salariale et le secteur, facteur AE, taux CNESST, CNT), éléments de paie.
- **Éléments de paie par catégorie système** : l'utilisateur ne configure jamais l'imposition. La catégorie porte l'assujettissement
  (impôt fédéral/Québec, AE, RRQ, RQAP, FSS, CNESST, vacances) et les cases T4 / Relevé 1. Voir `CategoriePaie.vb`.
- **Employés** : fiche complète, TD1 / T1213, TP-1015.3 / TP-1016, exemptions, dépôt direct, gabarit de paie récurrent, cumulatifs de départ (conversion en cours d'année).
- **Assistant de paie en 4 étapes** : période → employés et lignes → révision (avec rapport de vérification des formules) → confirmation (numérotation des chèques).
- **Historique** par lot, détail en 3 colonnes (revenus, déductions, parts de l'employeur), talon de paie imprimable avec cumulatifs et solde de vacances, annulation de la dernière paie.
- **Calculs** : impôt fédéral (T4127, employé du Québec : abattement de 16,5 %, K2Q), impôt du Québec (TP-1015.F), RRQ et 2e cotisation supplémentaire,
  AE au taux du Québec, RQAP, FSS, CNESST, CNT, paiements forfaitaires (bonus, rétroactif), indemnité de vacances.

### Remises gouvernementales (menu Retenues)

- **Fédéral (Receveur général)** : impôt fédéral + assurance-emploi des employés et de l'employeur.
- **Revenu Québec** : impôt du Québec + RRQ et RQAP (employés et employeur) + FSS + versement périodique à la CNESST.
- La **CNT** se paie une fois l'an avec le sommaire 1 : elle est affichée à titre indicatif, hors remises.
- « Retenues accumulées au » : toutes les paies confirmées jusqu'à cette date dont les retenues ne sont pas encore payées à ce gouvernement.
  Le paiement enregistré fige les montants et rattache les paies ; **une paie dont les retenues sont payées ne peut plus être annulée**
  (annuler d'abord le paiement des retenues).
- Fréquence mensuelle ou trimestrielle (page Compagnie) : échéance le 15 suivant la période, avec alerte de retard au tableau de bord.
  Les fréquences accélérées (versements hebdomadaires ou bimensuels des grands employeurs) ne sont pas gérées.
- 60secPaie **ne transmet aucun paiement** : il calcule le montant, fournit les renseignements du formulaire de versement et tient l'historique.

### Rapports de fin d'année et de période (menu Rapports)

- **T4 et Relevés 1** : montants de chaque case par employé (paies confirmées + cumulatifs de départ), feuillet de travail imprimable,
  sommaire T4 / sommaire 1 avec conciliation des remises, export CSV (sans NAS). Le NAS complet ne s'affiche que sur demande, et c'est journalisé.
  **60secPaie ne transmet pas les feuillets** : les montants se saisissent dans Formulaires Web (ARC) et Mon dossier (Revenu Québec).
  La transmission XML n'est pas faite (Revenu Québec exige un logiciel certifié). Les cases B.A / B.B du Relevé 1 et 17A du T4
  (cotisations supplémentaires au RRQ) sont à vérifier avec les guides de l'année (RL-1.G, RC4120).
- **Déclaration des salaires CNESST** : salaire brut, excédent du maximum assurable, salaire assurable et cotisation par employé et par mois,
  conciliation avec les versements périodiques des remises.
- **Écritures comptables** : écriture équilibrée par paie ou par période (débit : dépenses ; crédit : retenues, cotisations à payer, paies nettes),
  export CSV. Les comptes se définissent dans Configuration → Plan comptable ; chaque élément de paie peut avoir son compte.
  Les vacances sont provisionnées (dépense à l'accumulation, réduction du passif au paiement). Les avantages non monétaires ne génèrent pas d'écriture.

### Dépôt direct et talons par courriel (détail d'une paie confirmée)

- **Fichier de dépôt direct** : norme 005 de Paiements Canada (enregistrements A, C, Z de 1 464 caractères, type de transaction 200 « paie »).
  Paramètres dans Configuration → Dépôt direct. **À valider avec un fichier d'essai auprès de l'institution financière** avant le premier
  dépôt réel ; certaines institutions (dont Desjardins pour certains services) exigent leur propre format.
  Le fichier contient des numéros de compte : il n'est pas conservé sur le serveur, seulement téléchargé.
- **Talons par courriel** : envoyés aux employés dont la fiche a la case « Envoyer le talon de paie par courriel » et un courriel.
  Un talon déjà envoyé n'est pas renvoyé sans le demander. En développement, la clé `Courriel:DossierTest` écrit les courriels en
  fichiers `.eml` dans `App_Data\courriels` ; en production, configurer `system.net/mailSettings` avec un serveur SMTP en TLS.
  Le talon voyage dans le corps du courriel : c'est un renseignement personnel, à n'activer qu'avec l'accord de l'employé.

## Taux gouvernementaux

Les taux sont dans `src/60secPaie.Calcul/ParametresAnnee.vb`. **Seule l'année 2026 est définie.**
Chaque année (et lors d'une mise à jour de mi-année), ajouter un `Case` à partir de :

- ARC, guide **T4127** - Formules pour le calcul des retenues sur la paie ;
- Revenu Québec, guide **TP-1015.F** - Formules pour le calcul des retenues à la source et des cotisations.

Les tests `Annexe…` reproduisent les exemples chiffrés du TP-1015.F 2026 au cent près : les mettre à jour avec les exemples du nouveau guide.

### À valider avant d'utiliser en production

- **CNESST / CNT** : le salaire maximum assurable (103 000 $) et le taux de la CNT (0,06 %) de 2026 sont à confirmer auprès de la CNESST.
- **Impôt fédéral** : comparer quelques paies avec le calculateur en ligne de l'ARC (PDOC). L'impôt du Québec peut être comparé avec WebRAS.
- Faire une **paie en parallèle** avec Nubis pendant quelques périodes et comparer les talons.

### Simplifications connues

- Méthode des paiements réguliers (pas la méthode cumulative moyenne pour les commissions).
- Le crédit K2Q utilise les cotisations théoriques de la période annualisées (il ne chute pas lorsque le maximum annuel est atteint).
- Le montant de base fédéral n'est pas réduit pour les revenus supérieurs à 181 440 $ : inscrire le montant TD1 voulu dans la fiche.
- RRQ : pas de proratisation des maximums selon le nombre de mois (employé qui atteint 18 ans, retraité, décès).

## Sécurité

- Authentification par formulaire avec les comptes de MngConsul (BCrypt, vérification seulement), verrouillage après 5 échecs (`paie.TentativeConnexion`).
- Cloisonnement par compagnie : toutes les requêtes portent la compagnie courante, revalidée à chaque page ; le journal d'activités aussi.
- NAS et numéro de compte **chiffrés en base** (`MachineKey.Protect`) et jamais renvoyés au navigateur (masqués).
  **En production, définir une `machineKey` fixe** dans la configuration du serveur, sinon ces données deviennent illisibles après un changement de serveur.
- Requêtes SQL paramétrées, sorties HTML encodées, ViewState chiffré et lié à l'utilisateur (anti-CSRF), en-têtes de sécurité.
- En production : HTTPS obligatoire (`Web.Release.config` active `requireSSL`), chaîne de connexion hors du dépôt.

## Tests

```
msbuild 60secPaie.sln -restore
vstest.console src\60secPaie.Tests\bin\Debug\net48\60secPaie.Tests.dll
```

Les tests d'intégration recréent la base jetable `60secPaie_Test` sur LocalDB, avec des répliques minimales des tables de MngConsul
(`Database	ests _stubs_mngconsul.sql`) ; ils ne touchent jamais au serveur.

## Phase 2 (à venir)

Fait : multi-compagnie et comptes MngConsul, trois langues, paiement des retenues, feuillets T4 / Relevés 1 (montants), déclaration CNESST, écritures comptables, dépôt direct, talons par courriel.
Reste : transmission XML des feuillets, rapport de vacances, portail employé sécurisé pour les talons, plusieurs unités de classification CNESST,
commissions (méthode cumulative), pourboires, relevé d'emploi (RE).
