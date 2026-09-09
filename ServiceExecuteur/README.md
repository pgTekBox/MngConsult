# ServiceExecuteur

Service Windows qui **exécute** les tâches planifiées de l'ERP.

Les écrans de tâches existaient déjà (console d'administration `prjSec60Admin`) et
le planificateur aussi (`sp_GenererPlanningJobs` remplit `T204JobPlanned`). Ce qui
manquait, c'était quelqu'un pour exécuter : `sp_LancerJobMaintenant` se contente
d'inscrire une exécution `EN_COURS` dans `T202JobExecution` et attend un worker —
d'où l'exécution restée en cours depuis le 28 avril. **ServiceExecuteur est ce
worker.**

Il reprend la structure du service SMTP (`ServiceWindowsSMTPMail`) et du service
de traitement des reçus : `tkbService` (service + installeur + contrôleur),
`modController` (icône dans la zone de notification), `Form1` (interface de
surveillance), `clsXmlConfig` (configuration chiffrée), `clsLog` (journaux
fichier), et un pipe nommé pour pousser l'état vers l'interface.

---

## Ce que fait la boucle

À chaque passage (intervalle configurable, 60 s par défaut) :

1. **`s0742MarquerAApprouver`** — les occurrences dont la définition porte
   `RequiertApprobation = 1` passent en `A_APPROUVER`. Elles n'iront pas plus
   loin sans l'utilisateur.
2. **`s0738PromouvoirPlanningEchu`** — les occurrences échues et approuvées (ou
   qui n'exigent pas d'approbation) deviennent des exécutions `T202JobExecution`.
   Une seule occurrence par définition et par passage : jamais deux exécutions
   simultanées de la même tâche.
3. **`s0739ClaimNextExecution`** — l'exécution la plus ancienne est réservée avec
   un verrou (`SvcLockedUntilUtc`), ce qui permet de faire tourner plusieurs
   exécuteurs sans qu'ils se marchent dessus.
4. **`JobRunner.ashx`** — l'exécution est confiée à la console
   d'administration, qui fait le travail et rend un compte rendu.
5. **`s0740SaveExecutionResult`** et **`s0741LogExecution`** enregistrent l'issue.

## Le partage des rôles

**Ce service ne sait rien d'aucune tâche.** Il ne connaît ni ce qu'une tâche
fait, ni à qui elle écrit, ni quelles procédures elle appelle. Il repère ce qui
est dû, le réserve, passe la main, et note le résultat.

**Tout ce qu'une tâche fait vraiment est écrit dans
`prjSec60Admin/App_Code/clsJobRunner.vb`.** Modifier une tâche, ou en ajouter
une, ne demande donc que de redéployer la console d'administration — ce service
Windows sur le serveur ne rebouge pas. C'était la raison d'être de ce découpage :
on déploie une application web tous les jours, pas un service Windows.

```
ServiceExecuteur                 60secadmin
────────────────                 ──────────
promotion, verrou   ── POST ──▶  JobRunner.ashx
                                 clsJobRunner.Dispatch
                                   ├─ TEST_COURRIEL
                                   ├─ RAPPEL_FACTURES
                                   └─ … (procédure stockée par défaut)
statut, journal     ◀── JSON ──  { success, message, rows, detail }
```

Le service garde le cycle de vie — verrou, statut, journal, durée, reprises —
parce qu'un seul endroit doit tenir l'état d'une exécution. La console ne fait
que le travail.

Une tâche pour laquelle la console n'a rien de défini **échoue** au lieu de
marquer un succès qui n'a rien fait : une tâche en erreur se voit dans le suivi,
un faux succès non.

## L'approbation — la boîte de messages

`T200JobDefinition.RequiertApprobation = 1` fait passer chaque occurrence de
cette tâche par une validation humaine. L'utilisateur la voit dans l'ERP
(**Tâches à approuver**, `wbfApprobations.aspx`), avec une pastille dans le menu
de gauche portant le nombre en attente.

- **Approuver** : l'occurrence repart dans le flux et s'exécute à l'heure prévue.
- **Refuser** : l'occurrence passe en `ANNULE`, avec le motif ; elle ne
  s'exécutera jamais.

Tout est cadré sur la compagnie : `s0743GetApprobations` et
`s0744DeciderApprobation` prennent le `CompanyGUID`, et `s0744` refuse (erreur
50202) une occurrence qui n'appartient pas à l'appelant.

Par défaut `RequiertApprobation` vaut 0 : les tâches existantes gardent leur
comportement. Pour activer l'approbation sur une tâche :

```sql
UPDATE dbo.T200JobDefinition SET RequiertApprobation = 1 WHERE JobCode = 'PURGE_LOGS';
```

---

## Base de données

`Database/T206_Approbation_et_executeur.sql` — ré-exécutable, à passer sur
**MngConsul**. Il ajoute les colonnes d'approbation et de verrou, puis les
procédures `s0738` à `s0749`.

| Procédure | Rôle |
|---|---|
| `s0738PromouvoirPlanningEchu` | Occurrences échues → exécutions |
| `s0739ClaimNextExecution` | Réserve la prochaine exécution |
| `s0740SaveExecutionResult` | Issue d'une exécution |
| `s0741LogExecution` | Une ligne de `T203JobLog` |
| `s0742MarquerAApprouver` | Met en attente de décision |
| `s0743GetApprobations` | La boîte de messages de l'ERP |
| `s0744DeciderApprobation` | L'utilisateur tranche |
| `s0745GetApprobationsCount` | Compteur du menu (par compagnie) |
| `s0746GetFacturesEnRetard` | Factures clients à relancer |
| `s0747GetExecutionsEnCours` | Ce qu'affiche l'interface du service |
| `s0748GetCompanyMailInfo` | Nom de compagnie + Reply-To vérifié |
| `s0749GetApprobationsCountGlobal` | Compteur du service (toutes compagnies) |
| `s0750GetJobExecutionContext` | Ce que la console relit pour exécuter (`T209`) |

Les autres scripts du dossier `Database/` : `T207` crée la tâche de test, `T208`
corrige `sp_SaveJobDefinition`, `T209` ajoute `s0750`.

Application (le `.sql` doit être ré-encodé en UTF-16 LE, sinon les accents sont
corrompus) :

```powershell
$src = 'Database\T206_Approbation_et_executeur.sql'
$tmp = "$env:TEMP\T206_u16.sql"
[IO.File]::WriteAllText($tmp, [IO.File]::ReadAllText($src, [Text.UTF8Encoding]::new($false)), [Text.UnicodeEncoding]::new($false, $true))
sqlcmd -S 192.168.0.203 -U MngConsul -P '***' -d MngConsul -i $tmp -b
```

---

## Configuration

`configExecuteur.xml`, à côté de l'exécutable, créé au premier démarrage avec des
valeurs par défaut. La chaîne de connexion et la clé partagée y sont chiffrées (`clsEncDec`).
On l'édite par l'interface (**Paramètres...**), jamais à la main.

| Clé | Défaut | Rôle |
|---|---|---|
| `ConnectionString` | *(vide)* | Base **MngConsul** — la file des tâches |
| `AdminBaseUrl` | *(vide)* | Adresse de la console, ex. `http://alfred/60secadmin` — c'est elle qui exécute |
| `AdminApiKey` | *(vide)* | Clé partagée avec `JobRunner.ashx` (chiffrée dans le fichier) |
| `IntervalSeconds` | 60 | Secondes entre deux passages |
| `BatchSize` | 5 | Tâches exécutées au maximum par passage |
| `LockSeconds` | 900 | Durée du verrou posé sur une exécution |
| `Actif` | 1 | 0 = le service tourne mais n'exécute rien |
| `PlanningRefreshMinutes` | 15 | Minutes entre deux appels à `sp_GenererPlanningJobs` (0 = jamais) |

Le regarnissage du planning n'est pas un luxe : `sp_GenererPlanningJobs` ne
génère que 500 occurrences d'avance par calendrier, soit **trois jours et demi**
pour un calendrier « toutes les 10 minutes ». Sans lui la tâche s'arrête d'
elle-même. Il tourne après la promotion, jamais avant : la procédure passe en
`EXPIRE` toute occurrence `PLANIFIE` dont l'heure est déjà passée, et l'inverse
effacerait le travail du tour.

La clé doit être identique des deux côtés : `AdminApiKey` ici, `JobRunnerKey`
dans le `Web.config` de 60secadmin. Ce `Web.config` n'est pas versionné, la clé
ne part donc pas dans le dépôt.

Côté console, deux réglages complètent le tableau : `JobRunnerKey` et
`JobMailSender` (expéditeur des courriels déposés par les tâches).

---

## Ligne de commande

| Argument | Effet |
|---|---|
| `-i` | Installe le service et démarre le contrôleur |
| `-u` | Désinstalle le service |
| `-e` | Démarre le contrôleur (icône dans la zone de notification) |
| `-x` | Ouvre l'interface seule |
| `-r` | Exécute la boucle en avant-plan (vérifier une configuration avant de l'installer) |
| `-h` | Aide |

Les mêmes commandes sont dans `ScriptBAT\`.

## Interface

- **Exécutions** : les exécutions, la plus récente en haut, colorées par statut
  (vert `SUCCES`, rouge `ECHEC`/`TIMEOUT`, jaune `EN_COURS`). Double-clic pour le
  détail complet.
- **Journal** : les fichiers `EventExecuteur.txt` et `ErrorExecuteur.txt`.
- En-tête : état du service (poussé par le pipe nommé), dernier passage, tâches à
  faire, tâches en attente d'approbation, succès et échecs depuis le démarrage.

## Les icônes

Un rouage traversé d'un glyphe : **lecture** pour l'application et pour le
service démarré (vert), **pause** en pause (ambre), **carré** à l'arrêt (gris).
Le glyphe seul distingue les trois états, la couleur ne fait que confirmer.

| Fichier | Où on la voit |
|---|---|
| `ServiceExecuteur.ico` | Explorateur, barre des tâches, gestionnaire de services |
| `Resources\Running.ico` | Zone de notification — service démarré |
| `Resources\Paused.ico` | Zone de notification — service en pause |
| `Resources\Stopped.ico` | Zone de notification — service arrêté |

En dessous de 40 px il ne reste pas assez de pixels pour les dents du rouage
**et** le glyphe : à ces tailles seul le glyphe est dessiné, en grand. C'est lui
qui porte l'information, la tuile colorée suffit à garder la famille.

**L'icône de la fenêtre ne doit pas être posée dans le concepteur.** Il la
recopie dans `Form1.resx` et elle se retrouve deux fois dans l'assembly — une
fois en ressource Win32, une fois en ressource .NET : `Form1.resx` était passé à
567 Ko pour ça. `Form1.AppliquerIcone()` la relit sur l'exécutable au démarrage
(`Icon.ExtractAssociatedIcon`), ce qui ne coûte pas un octet. Si vous ouvrez
`Form1` dans le concepteur, vérifiez qu'il n'a pas remis `Me.Icon` dans le
designer et regonflé le `.resx`.

`Resources\GenererIcones.ps1` régénère les quatre fichiers (toute la géométrie
est dans le script, rien n'est dessiné à la main) :

```powershell
powershell -ExecutionPolicy Bypass -File Resources\GenererIcones.ps1
```

## La tâche de test

`Database/T207_Tache_courriel_test.sql` crée `TEST_COURRIEL` : un courriel
toutes les 10 minutes portant le nom de la compagnie, envoyé à l'adresse des
paramètres. Elle sert à répondre à une seule question — « est-ce que l'exécuteur
tourne ? » — et le nom de la compagnie prouve au passage que le contexte a suivi
jusqu'au bout de la chaîne.

Elle se pilote ensuite dans la console d'administration comme n'importe quelle
tâche. **Pour arrêter les envois**, décocher `Actif` sur la définition ou sur le
calendrier, ou mettre le calendrier en pause :

```sql
UPDATE dbo.T200JobDefinition SET Actif = 0 WHERE JobCode = 'TEST_COURRIEL';
```

Le script passe par `sp_SaveJobDefinition` et `sp_SaveJobSchedule`, donc par le
même chemin que les écrans. Il exige `T208_sp_SaveJobDefinition_id.sql`, qui
corrige un défaut bloquant : `T200JobDefinition.Id` n'est pas une colonne
`IDENTITY`, mais la procédure lisait `SCOPE_IDENTITY()` après son `INSERT` —
aucune tâche n'était créable depuis la console.

## Ajouter une tâche

**Rien de tout cela ne touche à ce service.**

1. Créer la tâche et son calendrier dans la console d'administration
   (**Tâches planifiées**) : code, type, paramètres JSON, cadence.
2. Pour une **procédure SQL**, il n'y a rien à coder : `HandlerType = 'SP'` et
   `HandlerName` = le nom de la procédure suffisent. `clsJobRunner` la lance,
   en ne lui passant que les paramètres qu'elle accepte (`DeriveParameters`), et
   comble `@CompanyGUID` avec la compagnie de la tâche. Jetons `@TODAY` et
   `@NOW` reconnus dans les valeurs.
3. Pour **tout le reste**, ajouter le cas dans
   `prjSec60Admin/App_Code/clsJobRunner.vb` :

```vb
Select Case job.JobCode.Trim().ToUpperInvariant()
    Case "MON_NOUVEAU_JOB"
        Return MonNouveauJob(job)
```

   puis écrire la méthode. `JobContext` donne la compagnie, son nom, les
   paramètres (`Param`, `ParamInt`, `Destinataires`) et le `Reply-To` vérifié ;
   `clsJobData` donne l'accès aux deux bases. On rend un `JobResult.Ok` ou
   `JobResult.Ko` — le service s'occupe du reste.
4. Déployer la console. Le service, lui, ne bouge pas.
