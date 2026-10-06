# 60secPaie

Application Web de calcul de la paie pour des employeurs du **Québec** et de l'**Ontario**, **multi-compagnie** et en **trois langues** (français, anglais, espagnol).
Les utilisateurs, les compagnies et les employés sont ceux de **MngConsul** (même base de données).
ASP.NET Web Forms en **VB.NET** (.NET Framework 4.8), SQL Server, Visual Studio 2022/2026.
Le modèle fonctionnel est Nubis (voir [docs/analyse-nubis.md](docs/analyse-nubis.md)).

## Structure

| Dossier | Rôle |
|---|---|
| `src/60secPaie.Calcul` | Moteur de calcul, sans dépendance Web ni SQL : taux de l'année, catégories de paie, formules. |
| `src/60secPaie.Web` | Application Web Forms : pages, accès SQL (ADO.NET paramétré), sécurité, assistant de paie. |
| `src/60secPaie.Tests` | Tests MSTest : exemples chiffrés de Revenu Québec, cas de l'Ontario (T4127) + cycle de paie complet sur LocalDB. |
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
  Un talon déjà envoyé n'est pas renvoyé sans le demander.
- **Par où part le courriel** : par le **service d'envoi de la plateforme**, comme les factures de l'ERP. 60secPaie dépose le message
  dans la base `MailService` (connexion `Mail`, procédures `s0610InsertOutboundMail` et `s1579InsertAttachemnt_A`), et le service
  Windows **SrvAI** le remet lui-même aux serveurs de destination. 60secPaie ne parle donc à aucun serveur SMTP et ne détient aucun
  mot de passe de messagerie ; un seul domaine est à faire autoriser (SPF, DKIM) et un seul journal est à consulter quand un courriel
  n'arrive pas. `Deployer-Serveur.ps1 -Action Configurer` écrit la connexion `Mail` en même temps que `Paie`.
  En développement, la clé `Courriel:DossierTest` écrit plutôt les courriels en fichiers `.eml` dans `App_Data\courriels` :
  **rien ne part vers un employé tant qu'elle est là**. Pour envoyer réellement depuis un poste de développement, écrire
  `Courriel:Transport = service` — il faut le vouloir. Sans connexion `Mail` ni dossier d'essai, l'envoi retombe sur SMTP
  (`system.net/mailSettings`).
- **Ce que reçoit l'employé** : le talon dans le corps du message **et en pièce jointe PDF** (`Talon-de-paie-AAAA-MM-JJ.pdf`, nommé
  et rendu dans sa langue). C'est un renseignement personnel, à n'activer qu'avec son accord.
- **Expéditeur** : tout courriel part de **60sec.ca** (`Courriel:Expediteur`, `paie@60sec.ca` à défaut). Une adresse d'un autre domaine
  est refusée à l'envoi. Le nom affiché est celui de l'employeur et son adresse va en **Reply-To** : mise dans le `From`, elle ferait
  échouer SPF et DMARC de son domaine, et le talon n'arriverait pas — sans que personne ne s'en aperçoive.
- **Le PDF** est écrit par `Infrastructure\PdfSimple.vb`, un générateur maison d'environ 250 lignes (Helvetica, WinAnsi, pas de
  dépendance ni de partie native). Il lit le même `DonneesTalon` que le rendu HTML : les deux ne peuvent pas diverger.

## Paie de l'Ontario

La **province d'emploi** est celle de la compagnie : Configuration → Paramètres de paie → « Province d'emploi » (Québec, Ontario ou une autre province ou un territoire — voir la section suivante).
Une compagnie = une province ; un employeur présent dans les deux configure deux compagnies. La province est **figée sur chaque paie**
(`paie.Paie.Province`) : une compagnie qui change de province garde un historique juste.

| | Québec | Ontario |
|---|---|---|
| Impôt provincial | Impôt du Québec (TP-1015.F) | Impôt de l'Ontario (T4127) : barème, surtaxe (V1), contribution-santé (V2), réduction d'impôt (S) |
| Impôt fédéral | Abattement de 16,5 %, crédit K2Q | Sans abattement, crédit K2 |
| Régime de pension | RRQ + 2e cotisation supplémentaire | RPC + 2e cotisation supplémentaire (du mois suivant les 18 ans au mois des 70 ans) |
| Assurance-emploi | Taux réduit du Québec | Taux ordinaire |
| Congés parentaux | RQAP | — (compris dans l'AE) |
| Cotisation santé de l'employeur | FSS | Impôt-santé des employeurs (ISE) |
| Accidents du travail | CNESST, unités de classification | WSIB (CSPAAT), mêmes « unités » appelées classes |
| Normes du travail | CNT | — |
| Formulaires de l'employé | TD1 + TP-1015.3 / TP-1016 | TD1 + TD1ON (montant de la demande, personnes à charge, autres crédits) |
| Remises | Receveur général + Revenu Québec | Receveur général seulement (impôt fédéral, impôt de l'Ontario, RPC, AE) |
| Feuillets | T4 (cases 17, 17A, 55, 56) + Relevé 1 | T4 seulement (cases 16, 16A ; la case 22 réunit les deux impôts) |
| Indemnité de vacances | Sur le salaire brut, paie de vacances comprise | Sur le salaire brut, sans la paie de vacances |

**Aucune colonne de montant n'a été ajoutée.** Les colonnes gardent leur nom québécois et leur contenu suit la province de la paie :
`ImpotQuebec` = impôt provincial, `RRQ` / `RRQ2` / `GainsRRQ` = régime de pension (RPC en Ontario), `EmployeurFSS` = FSS ou ISE,
`EmployeurCNESST` = CNESST ou WSIB ; `RQAP` et `EmployeurCNT` valent 0 en Ontario. Les exemptions de la fiche suivent la même règle.
`LibellesProvince` (projet Calcul) donne le nom à afficher ; `Contexte.Province` et `Contexte.Libelles`, la province de la compagnie courante.
Le tableau complet est en tête de `Database\05_ontario.sql`.

- **ISE** : le taux se lit dans le barème selon la masse salariale ontarienne estimée ; l'employeur admissible retranche l'exemption
  (1 000 000 $). Le logiciel applique à chaque paie le **taux effectif** — taux × (masse – exemption) ÷ masse — pour répartir la charge
  de l'année ; l'écart avec le réel se règle dans la déclaration annuelle (15 mars). Sous l'exemption, l'ISE est nul.
- **WSIB** : taux de prime de la compagnie ou de la classe de l'employé, jusqu'au plafond des gains assurables de l'année.
- L'ISE et la WSIB **ne font partie d'aucune remise** : ils se paient au ministère des Finances de l'Ontario et à la WSIB. Le logiciel
  les calcule, les inscrit aux écritures comptables et en affiche le cumul (Retenues, Rapports).
- **Gratification** quand la rémunération de l'année ne dépasse pas 5 000 $ : 15 % en tout (T4127), répartis 10 % au fédéral et 5 % à l'Ontario.

### Simplifications et limites propres à l'Ontario

- Une seule province par compagnie. Un employé payé dans les deux provinces la même année apparaît sur un seul feuillet, avec un avertissement :
  l'ARC veut un T4 par province, la répartition est à faire à la main.
- **Changement de province en cours d'année** : possible, mais à vérifier. Les paies confirmées et les cumulatifs de départ gardent leur province
  (`paie.Paie.Province`, `paie.CumulatifDepart.Province`) ; le RRQ et le RPC cumulent leurs maximums, la CNESST et la WSIB ont chacune leur plafond
  et leur rapport. Le taux et les unités de classification restent ceux saisis : ils sont à remplacer par ceux de la nouvelle province.
  Les libellés des écritures comptables d'une période suivent la province actuelle de la compagnie.
- Un élément de paie dont la catégorie n'est imposable qu'au Québec est refusé dans une paie de l'Ontario et n'y est pas recopié du gabarit de l'employé.
- Crédit d'impôt de l'Ontario pour fonds de travailleurs (LCP) : non calculé. Le crédit fédéral (LCF) l'est.
- RPC : pas de proratisation des maximums selon le nombre de mois ; l'employé qui choisit de cesser de cotiser (CPT30) se marque « Ne pas cotiser au RPC ».
- Fréquences de remise accélérées de l'ARC : non gérées, comme au Québec.

## Paie des autres provinces et territoires

Le moteur calcule les **treize** provinces et territoires : après le Québec et l'Ontario, l'Alberta, la Colombie-Britannique,
l'Île-du-Prince-Édouard, le Manitoba, le Nouveau-Brunswick, la Nouvelle-Écosse, le Nunavut, la Saskatchewan, Terre-Neuve-et-Labrador,
les Territoires du Nord-Ouest et le Yukon. La liste « Province d'emploi » les offre tous (`Provinces.Gerees`).

Tout ce qui est dit de l'Ontario vaut **hors Québec** : RPC, AE au taux ordinaire, impôt fédéral sans abattement, impôt de la province
(T4127), tout remis au Receveur général, T4 seulement (case 10 = code de la province, cases 16 et 16A, case 22 = fédéral + provincial).
Dans la couche web, `Contexte.HorsQuebec` / `PageBase.HorsQuebec` décide de ce comportement commun ; `EnOntario` ne sert plus qu'à ce qui
est propre à l'Ontario (barème de l'ISE, personnes à charge du TD1ON). Les libellés viennent de `LibellesProvince` (`Contexte.Libelles`,
`PageBase.Noms`) : « Impôt de l'Alberta », TD1AB, WCB, WorkSafeBC, WorkplaceNL…

Mêmes colonnes que pour l'Ontario (tableau en tête de `Database\06_provinces.sql`), avec deux ajouts :

- **Impôt sur la paie des Territoires du Nord-Ouest et du Nunavut** (2 %, retenu à l'employé) : il occupe `RQAP` et `GainsRQAP`, vides
  hors Québec. `LibellesProvince.ARetenueTerritoriale` est vrai et `RetenueProvinciale` vaut « Impôt sur la paie » : partout où le RQAP
  s'affiche (talon, tableau du lot, sommaire, écritures, cumulatifs de départ), la colonne paraît sous ce nom. Il se remet **au territoire** :
  il n'entre dans aucune remise (ni `SqlDuFederal`, ni `SqlDuQuebec`), ni dans la case 22 du T4, ni dans les cases 55 et 56. La case
  d'exemption du RQAP de la fiche (`ExemptRQAP`) devient « Ne pas retenir l'impôt sur la paie du territoire ».
- **Cotisation santé de l'employeur** (`EmployeurFSS`) : elle n'existe qu'en Ontario, en Colombie-Britannique, au Manitoba et à
  Terre-Neuve-et-Labrador (`LibellesProvince.ASante`). L'ISE de l'Ontario se calcule par barème ; pour les trois autres, l'employeur saisit
  son **taux effectif** en % dans Paramètres de paie (`paie.Compagnie.TauxSanteEmployeur`, ajoutée par `06_provinces.sql`).
  `ServicePaie.TauxSanteEmployeur` choisit : FSS, ISE, taux saisi, ou 0 là où il n'y a pas de telle cotisation.

Ce que la page Retenues appelle « montants hors remises » (une carte par province, `ServiceRemise.HorsRemiseProvinces`) réunit ce qui
se paie ailleurs qu'à l'ARC : prime de la commission des accidents du travail, cotisation santé de l'employeur, impôt sur la paie d'un territoire.
Dans une remise fédérale, l'impôt provincial a une ligne par province (`IMPOT_ON`, `IMPOT_AB`…).

Particularités calculées (T4127) : crédit supplémentaire K5P de l'Alberta ; réduction d'impôt pour bas revenus de la Colombie-Britannique ;
montant personnel de base du Manitoba réduit entre 200 000 $ et 400 000 $ ; crédit canadien pour emploi du Yukon (K4P) ; changements
du 1er juillet 2026 en Colombie-Britannique, à Terre-Neuve-et-Labrador et à l'Île-du-Prince-Édouard, appliqués selon la date de la paie.

Les taux vivent dans `paie.ParametresProvince` (une ligne par province et par date d'entrée en vigueur) et, en secours, dans
`ParametresProvince.Annee2026()`. Sources : guide **T4127**, 122e édition (1er janvier 2026) et 123e édition (1er juillet 2026).
Ils se tiennent à jour dans Sec60Admin.

### Ce qui n'est pas calculé

- Crédits d'impôt provinciaux pour fonds de travailleurs (Manitoba, Nouveau-Brunswick, Nouvelle-Écosse, Saskatchewan).
- Le taux de la cotisation santé de l'employeur en Colombie-Britannique, au Manitoba et à Terre-Neuve-et-Labrador : il est saisi.
- Les règles provinciales de vacances et de jours fériés au-delà du taux de vacances saisi.
- La remise de l'impôt sur la paie des territoires : 60secPaie en donne le cumul, sans enregistrer le paiement.
- Les colonnes `TD1ONMontantDemande`, `TD1ONAutresCredits` et `TD1ONPersonnesACharge` de `paie.EmployePaie` gardent leur nom et servent au
  formulaire de toute province hors Québec : après un changement de province, le montant de la demande est à revoir employé par employé.

## Taux gouvernementaux

Les taux sont dans `src/60secPaie.Calcul/ParametresAnnee.vb`. **Seule l'année 2026 est définie.**
Pour ajouter une année : écrire une fonction `Annee20XX()` sur le modèle de `Annee2026()`, puis ajouter **un seul `Case`** dans `Construire()`.
Tout le reste — `Pour`, `EstDisponible`, `DerniereAnneeConnue` — en découle, et le test `AnneesDisponibles_EstDisponibleEtPourSaccordent` vérifie qu'aucune des deux réponses ne diverge.
Tout ce qui change d'une année à l'autre vit dans cette seule fonction, **y compris la formule du FSS** (taux du secteur public, plancher et plafond de masse salariale, constantes et coefficients). Sources :

- ARC, guide **T4127** - Formules pour le calcul des retenues sur la paie (fédéral, RPC, AE **et impôt de l'Ontario**) ;
- Revenu Québec, guide **TP-1015.F** - Formules pour le calcul des retenues à la source et des cotisations.

Les taux hors Québec et ceux de l'Ontario sont dans la même fonction (`RPC…`, `AE…HorsQuebec`, `On…`, `ISE…`, `WSIBMaxAssurable`) et dans
des colonnes NULLables de `paie.ParametresAnnee` (script `05_ontario.sql`). Une année dont les taux de l'Ontario manquent reste valide
pour le Québec ; le moteur **refuse** de calculer une paie de l'Ontario plutôt que d'y appliquer d'autres taux.
**La console Sec60Admin ne saisit pas encore ces colonnes** : `spParametresAnnee_Save` les accepte en paramètres facultatifs et les laisse
intactes quand ils sont absents ; `spParametresAnnee_Copier` les recopie. En attendant, les taux de l'Ontario d'une nouvelle année
se mettent à jour par SQL ou dans `ParametresAnnee.vb`.

Les tests `Annexe…` reproduisent les exemples chiffrés du TP-1015.F 2026 au cent près : les mettre à jour avec les exemples du nouveau guide.

### À valider avant d'utiliser en production

- **CNESST / CNT** : le salaire maximum assurable (103 000 $) et le taux de la CNT (0,06 %) de 2026 sont à confirmer auprès de la CNESST.
- **Ontario** : comparer quelques paies avec le calculateur en ligne de l'ARC (PDOC), province « Ontario » — les tests reproduisent les
  formules du T4127, pas des résultats du PDOC. Confirmer le barème, l'exemption et le seuil de l'**ISE** (ministère des Finances de l'Ontario)
  et le plafond des gains assurables de la **WSIB** (121 700 $ en 2026).
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

`OntarioTests` couvre le moteur pour l'Ontario : barèmes, surtaxe, contribution-santé, réduction d'impôt, RPC et ses maximums, gratifications, ISE, WSIB.
Les tests d'intégration recréent la base jetable `60secPaie_Test` sur LocalDB, avec des répliques minimales des tables de MngConsul
(`Database\tests\00_stubs_mngconsul.sql`) ; ils ne touchent jamais au serveur.

## Phase 2 (à venir)

Fait : multi-compagnie et comptes MngConsul, trois langues, paie de l'Ontario, paiement des retenues, feuillets T4 / Relevés 1 (montants), déclaration CNESST, écritures comptables, dépôt direct, talons par courriel.
Reste : saisie des taux de l'Ontario dans Sec60Admin, province d'emploi par employé (plutôt que par compagnie), transmission XML des feuillets, rapport de vacances, portail employé sécurisé pour les talons, plusieurs unités de classification CNESST,
commissions (méthode cumulative), pourboires, relevé d'emploi (RE).
