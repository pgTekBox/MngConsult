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
4. **Dispatch** selon `HandlerType`, puis **`s0740SaveExecutionResult`** et
   **`s0741LogExecution`**.

## Les handlers

| `HandlerType` | État | Ce qui se passe |
|---|---|---|
| `SP` | implémenté | Lance la procédure nommée par `HandlerName`. Les paramètres sont découverts par `DeriveParameters` : ceux du JSON `HandlerParams` sont passés, les autres sont ignorés, et `@CompanyGUID` est comblé par la compagnie de l'exécution. Jetons `@TODAY` et `@NOW` reconnus dans les valeurs. |
| `EMAIL` | implémenté | Un seul modèle pour l'instant : `RAPPEL_FACTURE` (reconnu par `Template`, `HandlerName` ou `JobCode`). Lit `s0746GetFacturesEnRetard` et dépose un courriel par facture dans `T400Mails` (base **MailService**) — c'est SrvAI qui l'envoie. |
| `CONNECTOR` | **non implémenté** | Échec explicite. Un connecteur parle à un système tiers (flux bancaire, export comptable) : c'est un projet à part. |
| `CUSTOM` | **non implémenté** | Échec explicite. `HandlerName` y désigne une classe .NET que ce service ne charge pas. |

Un type non implémenté **échoue** au lieu de marquer un succès qui n'a rien fait :
une tâche en erreur se voit, un faux succès non.

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
valeurs par défaut. Les deux chaînes de connexion y sont chiffrées (`clsEncDec`).
On l'édite par l'interface (**Paramètres...**), jamais à la main.

| Clé | Défaut | Rôle |
|---|---|---|
| `ConnectionString` | *(vide)* | Base **MngConsul** — les tâches et les données métier |
| `ConnectionStringMail` | *(vide)* | Base **MailService** — la file `T400Mails` |
| `IntervalSeconds` | 60 | Secondes entre deux passages |
| `BatchSize` | 5 | Tâches exécutées au maximum par passage |
| `LockSeconds` | 900 | Durée du verrou posé sur une exécution |
| `Actif` | 1 | 0 = le service tourne mais n'exécute rien |
| `MailSender` | noreply@60sec.ca | Expéditeur des courriels déposés |
| `RelanceJoursAvant` | 0 | Rappel préventif : jours **avant** l'échéance |
| `RelanceJoursApres` | 30 | Jusqu'à combien de jours **après** on relance |

Le `From` reste celui du service : SrvAI envoie en direct-to-MX depuis notre IP,
un `From` au domaine du client échouerait son SPF. C'est le `Reply-To` qui porte
l'adresse de la compagnie, et seulement si elle a été vérifiée.

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

`Resources\GenererIcones.ps1` régénère les quatre fichiers (toute la géométrie
est dans le script, rien n'est dessiné à la main) :

```powershell
powershell -ExecutionPolicy Bypass -File Resources\GenererIcones.ps1
```

## Ajouter un type de tâche

1. Créer la définition dans `T200JobDefinition` (`JobCode`, `HandlerType`,
   `HandlerName`, `HandlerParams` en JSON) et son calendrier dans
   `T201JobSchedule`.
2. Pour une **procédure SQL**, il n'y a rien à coder : `HandlerType = 'SP'` et
   `HandlerName` = le nom de la procédure suffisent.
3. Pour un **nouveau modèle de courriel**, ajouter la branche dans
   `clsTaskExecutor.HandlerEmail` et la procédure de lecture correspondante.
