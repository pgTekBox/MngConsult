# ServiceTraitementRecu

Service Windows qui traite automatiquement les reçus arrivés dans `T0001Receipt`.
Il reprend, à intervalle régulier, le traitement qui se fait à la main dans
`wbfReceipt.aspx` de l'ERP.

Le projet est calqué sur `C:\MesSources\MailServer\ServiceWindowsSMTPMail` :
même structure (service + contrôleur en zone de notification + interface),
même mécanique de configuration XML chiffrée et de statut poussé sur un pipe
nommé.

---

## Ce que fait le service

Pour chaque reçu, dans l'ordre d'arrivée (le plus ancien d'abord) :

| Étape | Ce qui se passe | Procédure | `ProcessingStatus` |
|---|---|---|---|
| 1 | Photo convertie en **noir et blanc** et allégée (`clsReceiptImageOptimizer`) | `s0004SaveoptimizedImage` | 2 |
| 2 | Document **lu par ChatGPT** (`OpenAiReceiptReader`), JSON enregistré | `s0006SaveAIReturn` | 3 |
| 3 | **Process JSON** : création du marchand et du document | `s0008`/`s0009` (fournisseur) ou `s0033`/`s0034` (client) | 4 |

L'étape 1 ne concerne que les `image/jpeg`. Les `application/pdf` et
`text/plain` passent directement à l'étape 2, avec la méthode correspondante
du lecteur OpenAI — exactement comme le fait la page web.

Un reçu déjà avancé reprend là où il en était : un reçu à l'état 3 ne
redemande pas le JSON à ChatGPT, il n'exécute que le « Process JSON ».

### Garde-fous

- **Verrou par reçu** (`SvcLockedUntilUtc`) : deux instances du service ne
  peuvent pas traiter le même reçu, donc pas de double appel facturé à OpenAI.
- **Compteur de tentatives** (`SvcAttemptCount`) : au-delà de `MaxAttempts`,
  le reçu n'est plus repris automatiquement ; il reste visible en erreur dans
  l'interface, où on peut le relancer à la main.
- **Validation du JSON avant écriture** : `s0006SaveAIReturn` refuse
  silencieusement ce qui n'est pas du JSON (`ISJSON = 0`). Le service valide
  donc lui-même, et retire au passage l'emballage <code>```json</code> que le
  modèle ajoute parfois — sans quoi le reçu resterait bloqué sans explication.
  La validation s'arrête à « est-ce un objet JSON », qui est exactement ce dont
  SQL a besoin : lier le contrôle au DTO bloquait des reçus traitables dès que
  le modèle écrivait `167.8L` dans un champ de montant, alors que `JSON_VALUE`
  s'en accommode.

---

## L'interface

Lancée par le menu du contrôleur (« Reçus... ») ou par `Interface.bat`.

- **Reçus à faire** — la file d'attente : état, prochaine étape, nombre de
  tentatives, dernière erreur. Les lignes en erreur sont sur fond rose, les
  lignes terminées sur fond vert. Boutons « Tout refaire (IA incluse) »,
  « Refaire le Process JSON » et « Voir le JSON ».
- **Résultat (JSON)** — le journal de traitement (`T0002ReceiptProcessLog`) :
  une ligne par étape, avec durée, jetons consommés, coût estimé, et le JSON
  produit affiché en dessous (double-clic pour l'ouvrir en grand).
- **Journal** — les fichiers texte écrits par le service, à côté de l'exécutable.

Le bouton **Traiter maintenant** lance un lot depuis l'interface. Le service
peut tourner en même temps : la réservation se fait en base, le même reçu ne
peut pas être pris deux fois.

---

## Installation

1. Compiler la solution `ServiceTraitementRecu.sln` (VB.NET, .NET Framework 4.7.2).
2. Exécuter `Database\T0002_ReceiptQueue.sql` sur `MngConsul` (ré-exécutable).
3. Copier le contenu de `bin\Debug` sur le serveur (voir
   `ScriptBAT\Transfert vers Alfred.bat`).
4. `ServiceInstaller.bat` — installe le service et démarre le contrôleur.
5. Ouvrir l'interface, **Paramètres...**, renseigner la chaîne de connexion,
   puis **Tester la connexion** : le test vérifie aussi que la clé OpenAI est
   présente en base.
6. Démarrer le service depuis le contrôleur (clic droit sur l'icône).

### Lignes de commande

| Argument | Effet |
|---|---|
| *(aucun)* | démarrage par le gestionnaire de services Windows |
| `-i` | installe le service |
| `-u` | désinstalle le service |
| `-e` | démarre le contrôleur (icône dans la zone de notification) |
| `-x` | ouvre l'interface seule |
| `-h` | aide |

---

## Configuration

`configTraitementRecu.xml`, à côté de l'exécutable. La chaîne de connexion y
est chiffrée (`clsEncDec`).

| Clé | Défaut | Rôle |
|---|---|---|
| `ConnectionString` | — | base `MngConsul` (chiffrée) |
| `IntervalSeconds` | 60 | attente entre deux passages |
| `BatchSize` | 5 | reçus traités par passage |
| `MaxAttempts` | 3 | tentatives avant abandon |
| `LockSeconds` | 300 | durée du verrou posé sur un reçu |
| `Actif` | 1 | 0 = le service tourne sans rien traiter |
| `ImageMaxWidth` | 1024 | largeur max. de l'image envoyée à l'IA |
| `ImageJpegQuality` | 55 | qualité JPEG de l'image optimisée |

La **clé OpenAI** et le **prompt** ne sont pas dans ce fichier : le service les
lit en base (`s0000GetParameter 'CHATGPT'` et `s0032GetPromptOpenAPI
'PROMPT_RECEIPT'`), comme le fait l'application web. Un seul endroit à changer.

---

## Base de données

`Database\T0002_ReceiptQueue.sql` ajoute :

- sur `T0001Receipt` : `SvcAttemptCount`, `SvcLastAttemptUtc`, `SvcLastError`,
  `SvcLockedUntilUtc`, `SvcProcessedUtc` (colonnes utilisées par le seul service) ;
- la table `T0002ReceiptProcessLog` (journal par étape) ;
- les procédures `s0729` à `s0736`.

L'état `ProcessingStatus = 4` (« JSON traité ») est nouveau ; les états 0 à 3
gardent leur signification d'origine, l'application web n'est pas affectée.

### Dépendance : s0009SaveDocument

Le « Process JSON » passe par `s0009SaveDocument`, qui liait chaque ligne de
document à un rapport de taxe dont l'Id était écrit en dur (`= 1`). Ce rapport
n'existe plus dans `T070RapportTaxe`, donc l'insertion violait la clé étrangère
`FK_T071_T061DocumentLine_T070RapportTaxe_T070RapportTaxe` — pour le service
comme pour `wbfReceipt.aspx`. Corrigé dans
`prjMngConsul\Database\s0009SaveDocument.sql` : le rapport est résolu par
compagnie et par période, et le lien est omis quand aucune période ne couvre la
date du document.

---

## Divergence assumée avec le service SMTP

`clsEncDec.Decrypt` est repris du service SMTP, avec une correction : un seul
`CryptoStream.Read` ne rend pas forcément tout le tampon, ce qui tronquait les
chaînes longues à 128 caractères — une chaîne de connexion complète devenait
inutilisable. La boucle de lecture corrige cela. **Le même défaut existe dans
`ServiceWindowsSMTPMail\clsEncDec.vb`** et mériterait la même correction.
