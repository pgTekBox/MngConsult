# 60secPaiement — Automatisation des tâches planifiées

Quatre traitements récurrents font tourner la plateforme sans intervention :

| Tâche | Fréquence | Ce qu'elle fait | Mécanisme |
|---|---|---|---|
| **Dispatch des webhooks** | toutes les 1–5 min | POST signés vers les URL des abonnés, avec relances/backoff | `WebhookDispatcher.ashx` (POST sortant + HMAC) |
| **Règlement des échéances** | 1×/jour | Règle les transactions initiées échues (T+2), entrant + sortant (SIMULÉ) | T-SQL `dbo.s0056RunDailySettlement` |
| **Génération du lot EFT** | 1×/jour | Crée le lot CPA-005 depuis les transactions initiées non batchées | T-SQL `dbo.s0057AutoGenerateBatch` |
| **Maintenance / hygiène** | 1×/jour (03:00) | Purge : jetons « Se souvenir de moi » expirés (`s0077`) ; livraisons de webhooks livrées > 30 j (`s0078`, `Delivered`) et **abandonnées** > 90 j (`s0084`, `Abandoned`) ; lignes de relevé **rapprochées** > 365 j (`s0080`, `Matched` hors horizon) ; **lots EFT réglés** > 365 j (`s0081`, `Settled` + lignes `T051` ; paiements détachés mais conservés) ; **journaux d'échange bancaire** > 180 j (`s0082`, `T054`, tous statuts) ; **retours EFT traités** > 365 j (`s0083`, `T053` `Processed` — statuts problématiques conservés) ; **paiements retournés** > 7 ans (`s0085`, `T030` `Retourne` non référencés — voir ⚠️ ci-dessous) ; **utilisateurs abonnés désactivés** > 365 j (`s0086`, `T011` `IsActive=0` ; jetons remember-me par cascade — minimisation RGPD) | T-SQL `dbo.s0079RunDailyMaintenance` (orchestrateur) |

> ⚠️ **Paiements retournés (`s0085`) — enregistrement financier, pas un log.** Rétention par défaut **2555 j (≈ 7 ans)** pour respecter les obligations de conservation des registres de paiement (FINTRAC/PCMLTFA, fiscalité) — **à ajuster selon votre politique / conseil juridique** avant de raccourcir. Le **grand livre immuable (T101/T102)** conserve de toute façon l'écriture réelle et l'invariant (aucune FK vers `T030`) : la piste d'audit comptable survit à la purge. Seuls les paiements `Retourne` qui ne sont **plus référencés** (livraisons webhook / lignes de lot déjà purgées) sont supprimés — aucune cascade.

> Le **règlement** est le connecteur **simulé** : en production réelle, le règlement est confirmé par la banque (fichiers/relevés), pas par un timer — remplacer `s0056` par la logique pilotée par la banque (voir le connecteur EFT / retours).

## Option A — SQL Server Agent (recommandé si Agent disponible)

Script prêt : **`PortailMaster/Database/sqlagent_jobs.sql`** (à exécuter avec un compte **sysadmin**). Il crée les 4 jobs + horaires. **Avant** : remplacer `<HOST_PORTAIL>` (URL du PortailMaster) et `<DISPATCH_SECRET>` (= `Web.config` `Webhook.DispatchSecret`).

- Jobs T-SQL (règlement 22:00, génération 06:00, maintenance/purge jetons 03:00) : étapes `TSQL` directes sur `60secPaiement`.
- Job webhooks : étape **PowerShell** faisant l'`Invoke-WebRequest` vers le handler.
- Prérequis : service SQL Agent démarré ; sous-système PowerShell actif ; l'hôte SQL doit pouvoir joindre l'URL du portail en HTTPS.

## Option B — Planificateur de tâches Windows (sans SQL Agent)

Script prêt : **`InfraPaiement/scheduler.ps1`** avec un paramètre `-Mode` :

```powershell
# Webhooks (toutes les 2 min)
schtasks /Create /TN "60sec\Webhooks" /SC MINUTE /MO 2 /RU SYSTEM ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\MesSources\MngConsul\InfraPaiement\scheduler.ps1 -Mode Webhooks"

# Quotidien (règlement + génération de lot), 22:00
schtasks /Create /TN "60sec\Daily" /SC DAILY /ST 22:00 /RU SYSTEM ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\MesSources\MngConsul\InfraPaiement\scheduler.ps1 -Mode Daily"
```

Adapter en tête de `scheduler.ps1` (ou via paramètres) : `-PortailUrl`, `-DispatchSecret`, `-SqlServer`/`-SqlUser`/`-SqlPassword`/`-Database`.
⚠️ Ne pas laisser les identifiants en clair dans le script en production : utiliser un compte de service / coffre / config protégée.

## Vérifications déjà faites

- `s0056` / `s0057` testés (rollback) : les échéances entrantes **et** sortantes sont réglées, la transaction non échue est ignorée ; la génération crée un lot puis ne fait rien s'il n'y a plus rien (`Created=0`, sans erreur).
- `s0077PurgeExpiredRememberTokens` testé : supprime les jetons expirés et renvoie `Purged=N` (idempotent, `0` s'il n'y a rien à purger).
- `s0078PurgeDeliveredWebhooks` / `s0079RunDailyMaintenance` testés : seules les livraisons `Delivered` au-delà de la rétention sont supprimées (les `Pending`/`Abandoned` restent) ; l'orchestrateur renvoie `PurgedTokens` + `PurgedWebhooks` + `PurgedBankLines`.
- `s0080PurgeReconciledBankLines` testé : seules les lignes `Matched` dont le mouvement est hors horizon sont supprimées ; s0060/s0062 bornées à l'horizon → aucun mouvement rapproché ne réapparaît comme non rapproché.
- `s0081PurgeSettledEftBatches` testé : seuls les lots `Settled` au-delà de la rétention sont supprimés (avec leurs lignes `T051`) ; les paiements `T030` sont détachés (`BatchId=NULL`) mais **conservés** ; les lots en cours (Open/Generated/Submitted) restent.
- `s0082PurgeExchangeLog` testé : supprime les entrées `T054` au-delà de la rétention (par `Utc`), toutes récentes conservées ; renvoie `Purged=N`.
- `s0083PurgeProcessedEftReturns` testé : seuls les retours `Processed` anciens sont supprimés ; `Unmatched`/`AmountMismatch`/`Error`/`AlreadyReturned` conservés.
- `s0084PurgeAbandonedWebhooks` testé : seules les livraisons `Abandoned` au-delà de 90 j sont supprimées ; les `Abandoned` récentes (encore visibles dans la Supervision), `Pending` et `Delivered` restent.
- `s0085PurgeReturnedPayments` testé : seuls les paiements `Retourne` anciens **et non référencés** sont supprimés ; un retourné encore référencé (livraison webhook / ligne de lot) ou dans la rétention est conservé ; le grand livre reste intact.
- `s0086PurgeDeactivatedAbonneUsers` testé : seuls les comptes `IsActive=0` désactivés au-delà de la rétention sont supprimés (jetons remember-me par cascade) ; les comptes actifs et désactivés récents restent.
- `scheduler.ps1 -Mode Webhooks` → `HTTP 200 {"processed":N}` ; `-Mode Daily` → journalise `entrants/sortants` réglés + `created/batchId` + `Maintenance: jetons=… webhooks=… webhooksAband=… releve=… lotsEFT=… journaux=… retours=… paiementsRet=… usagersDesact=…`.

## Supervision associée

Le tableau de bord **Supervision** (page `wbfSupervision`) montre en direct les paiements en souffrance (échéances non réglées), les webhooks en échec/abandonnés et les retours — de quoi vérifier que les tâches planifiées font bien leur travail.
