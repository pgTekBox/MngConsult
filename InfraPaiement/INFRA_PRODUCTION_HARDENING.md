# 60secPaiement — Durcissement production

Checklist avant mise en production de **PortailMaster** (portail staff) et **webAPI** (API abonnés). Les points marqués ✅ sont déjà en place dans le code ; les ⚠️ sont à faire côté serveur/exploitation.

## 1. Configuration applicative (fait au publish Release)

✅ **`Web.Release.config`** (les 2 projets) applique automatiquement au *publish Release* :
- `compilation` **sans `debug`** ;
- **`customErrors mode="On"`** (PortailMaster → `Error.aspx`) — jamais de stack trace au client ;
- **`httpErrors errorMode="Custom"`** — pas d'erreur IIS détaillée ;
- **`httpCookies requireSSL="true"`** (PortailMaster) — cookies session/remember-me en HTTPS seulement ;
- **`enableVersionHeader="false"`** + suppression de **`X-Powered-By`** ;
- **HSTS** (`Strict-Transport-Security`, 1 an) ;
- **redirection HTTP→HTTPS** (règle URL Rewrite, localhost exclu).

⚠️ **Publier en configuration `Release`** (pas Debug) pour que ces transformations s'appliquent.
⚠️ Installer le **module IIS “URL Rewrite”** sur le serveur (requis par la règle HTTPS).
⚠️ **En-têtes de sécurité supplémentaires** déjà présents : `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`. Une **CSP** n'est pas ajoutée automatiquement (les pages WebForms et `docs.html` utilisent du style/JS inline) — à définir manuellement si souhaité.

## 2. Secrets (⚠️ à faire)

Aujourd'hui les secrets sont en clair dans `Web.config` (chaîne de connexion + mot de passe SQL, `Webhook.DispatchSecret`, clés de rate-limit). En production :

- **Chiffrer les sections sensibles** avec Protected Configuration :
  ```
  aspnet_regiis -pef "appSettings" "C:\chemin\vers\l'app"
  ```
  (DPAPI par machine, ou RSA pour une ferme). À refaire par serveur.
- **Ou** externaliser via un fichier hors dépôt : `<appSettings file="secrets.config">` / `configSource`, `secrets.config` ignoré par git et déployé séparément.
- **Rotations obligatoires** :
  - mot de passe de l'admin de départ (`admin@60secpaiement.ca` → `Portail2026`) ;
  - **révoquer la clé d'API de test** (`sk_test_e6702fd4…`) et n'émettre que des clés `live` ;
  - `Webhook.DispatchSecret` (Web.config PortailMaster) → chaîne aléatoire forte ;
  - mot de passe du login SQL applicatif.

## 3. Base de données — moindre privilège (⚠️ à finaliser)

✅ Script **`Database/15_least_privilege.sql`** PARTIE A appliqué : rôle **`db_apiexec`** (EXECUTE sur `dbo`) créé, `MngConsul` ajouté. Tout l'accès BD passe par des procédures stockées → EXECUTE suffit.

⚠️ **PARTIE B (manuelle)** après validation : retirer `MngConsul` de `db_owner`
```sql
USE [60secPaiement];
ALTER ROLE db_owner DROP MEMBER [MngConsul];
```
⚠️ Idéalement, **login SQL dédié** aux apps de paiement (`SixtySecApp`, EXECUTE-seul) au lieu de réutiliser `MngConsul` (voir le script). Pointer les `ConnectionString` dessus.

## 4. Réseau / TLS (⚠️)

- Certificat TLS valide, binding **443**, HTTP→HTTPS (via la règle du §1).
- Restreindre l'accès **PortailMaster** (interne/staff) : IP/VPN, pas d'exposition publique inutile.
- **webAPI** exposé publiquement : ne servir que HTTPS ; envisager un WAF / reverse-proxy.

## 5. API — points spécifiques

✅ Auth par clé (hash SHA-256), isolation locataire, idempotence, pagination, **rate-limiting**, versionnage `/api/v1`, webhooks signés HMAC, **WebDAV retiré** (PUT/DELETE).
- ⚠️ **Rate-limiting en mémoire** (par instance) : pour du **multi-instances**, remplacer `RateLimiter` par un store partagé (Redis/SQL).
- ⚠️ Le **fallback non versionné `/api/...`** est déprécié (en-tête `X-Api-Deprecation`) : prévoir de le **retirer** une fois les abonnés migrés vers `/api/v1`.
- ⚠️ Ajuster `RateLimit.PerMinute` selon la charge réelle.

## 6. Données de démonstration (⚠️ à nettoyer)

Créées pendant les tests sur l'abonné 1 : client « API Test Client », fournisseur « Hydro-Fournisseur », paiements/décaissements de test, endpoint webhook de test (désactivé). Les **écritures de grand livre sont immuables** (contre-passation seulement). À repartir sur une base propre pour la prod, ou nettoyer les objets non-immuables.

## 7. Exploitation (⚠️)

- **Sauvegardes** SQL + plan de restauration.
- **Journalisation/supervision** (erreurs, taux 4xx/5xx, latence, échecs de webhooks/livraisons `Abandoned`).
- **Tâche planifiée** appelant `WebhookDispatcher.ashx` (SQL Agent) pour vider la file de webhooks avec relances.
- Revue de conformité (le projet reste soumis aux exigences réglementaires : FINTRAC/AMF/RPAA, partenaire bancaire) avant tout traitement de fonds réels.
