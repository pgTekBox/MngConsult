# 60secPaiement — Automatisation des tâches planifiées

Trois traitements récurrents font tourner la plateforme sans intervention :

| Tâche | Fréquence | Ce qu'elle fait | Mécanisme |
|---|---|---|---|
| **Dispatch des webhooks** | toutes les 1–5 min | POST signés vers les URL des abonnés, avec relances/backoff | `WebhookDispatcher.ashx` (POST sortant + HMAC) |
| **Règlement des échéances** | 1×/jour | Règle les transactions initiées échues (T+2), entrant + sortant (SIMULÉ) | T-SQL `dbo.s0056RunDailySettlement` |
| **Génération du lot EFT** | 1×/jour | Crée le lot CPA-005 depuis les transactions initiées non batchées | T-SQL `dbo.s0057AutoGenerateBatch` |

> Le **règlement** est le connecteur **simulé** : en production réelle, le règlement est confirmé par la banque (fichiers/relevés), pas par un timer — remplacer `s0056` par la logique pilotée par la banque (voir le connecteur EFT / retours).

## Option A — SQL Server Agent (recommandé si Agent disponible)

Script prêt : **`PortailMaster/Database/sqlagent_jobs.sql`** (à exécuter avec un compte **sysadmin**). Il crée les 3 jobs + horaires. **Avant** : remplacer `<HOST_PORTAIL>` (URL du PortailMaster) et `<DISPATCH_SECRET>` (= `Web.config` `Webhook.DispatchSecret`).

- Jobs T-SQL (règlement, génération) : étapes `TSQL` directes sur `60secPaiement`.
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
- `scheduler.ps1 -Mode Webhooks` → `HTTP 200 {"processed":N}` ; `-Mode Daily` → journalise `entrants/sortants` réglés + `created/batchId`.

## Supervision associée

Le tableau de bord **Supervision** (page `wbfSupervision`) montre en direct les paiements en souffrance (échéances non réglées), les webhooks en échec/abandonnés et les retours — de quoi vérifier que les tâches planifiées font bien leur travail.
