# Revue du dossier d'Yves — pertinence pour InfraPaiement (60secPaiement)

> Revue faite le 2026-09-07 à partir des 15 fichiers de `Desktop\60sec level3\From Yves`
> et du code / de la documentation de `C:\MesSources\MngConsult\InfraPaiement`.
> Référence interne : `EFT_005_APPROBATION.md` (les trois « portes » et son annexe A).

---

## 1. Verdict

**Le dossier d'Yves est bien fait, mais il décrit un autre produit que celui d'InfraPaiement.**

| Sujet | Dossier d'Yves (60S-AI, ERP) | InfraPaiement (60secPaiement) |
|---|---|---|
| Détention de fonds | **Non** — « aucun compte fiducie, de passage ou de regroupement ; aucun solde d'utilisateur » (Q6.5, pièces 2, 3, 4, 11) | **Oui** — compte fiducie mutualisé `TRUST`, solde par abonné `SUBBAL`, réserve `RESERVE`, invariant `TRUST = Σ SUBBAL + Σ RESERVE + FEES` (`07_grand_livre.sql`, `ARCHITECTURE.md` §4, endpoint `/balance`) |
| Rail | Exécution par **Dream Payments** (FSP enregistré) puis parrainage Peoples Trust ; « niveau 3 » | Production **de nos propres fichiers CPA-005**, dépôt via parrain bancaire ; nous sommes l'émetteur (`T052EftOriginator`), le compte de retour est le nôtre |
| Sens des flux | Uniquement **sortant** : l'abonné paie ses fournisseurs, créanciers, remises, paie | **Entrant et sortant** : l'abonné **encaisse auprès de ses propres clients par débit PAD (code 430)** puis décaisse (code 230). Voir le fichier `AFT_1234567890_0001_20260903.005` : débit de « RESTAURANT LE COIN » vers 60SECPAIEMENT INC |
| Qui est *payee* du PAD | 60S-AI, pour son propre abonnement | 60secPaiement **pour le compte de tiers** (modèle A « payee-of-record », `EFT_005_APPROBATION.md` §2.5) — décision A/B toujours ouverte |
| Débiter/créditer le compte de l'utilisateur (Q6.7.4) | Non | Oui (crédit de `SUBBAL` à chaque encaissement) |
| Tiers | Dream Payments, Stripe, Plaid, Square, Anthropic, partenaire Interac, hébergeur cloud | Parrain bancaire (ACSS), partenaire Interac, fournisseur KYB (Trulioo/Onfido), WinSCP/SFTP, SQL Server sur `192.168.0.203` (réseau local) — aucun Stripe/Plaid/Square/Dream dans le code |

Conséquence directe : **si la demande FSP est déposée telle quelle pour la plateforme InfraPaiement, la réponse « Non » à la question 6.5 (détention de fonds) est fausse.** Or c'est cette réponse qui écarte l'article 20 de la LAAPD (fiducie / assurance / garantie) et les 26 sous-questions qui vont avec. Avec InfraPaiement, l'article 20 **s'applique** : compte en fiducie à vocation unique ou compte ségrégué avec assurance/garantie, valeur moyenne des fonds détenus à déclarer (Q9.6/Q9.7), etc. — exactement ce que `EFT_005_APPROBATION.md` §1.1 décrit.

Le même raisonnement fait tomber l'argument central de la pièce 11 (programme LRPCFAT §1 : « ne détient aucun fonds » contre la qualification d'ESM). Avec un compte fiducie qui reçoit les fonds des payeurs, l'inscription ESM à CANAFE et le permis AMF ne sont plus « à trancher » : ils sont très probablement requis (voir `EFT_005_APPROBATION.md` §1.2-1.3).

**Question préalable à régler avant tout le reste** : quelle personne morale exploite InfraPaiement ?
- Si c'est **9567-0048 Québec inc.** (60S-AI), alors « 60secPaiement » doit être déclaré comme nom commercial (Q2.2), et tout le dossier doit être réécrit sur le modèle « détention de fonds + rail propre ».
- Si c'est **une autre entité**, le dossier d'Yves ne couvre pas InfraPaiement du tout : il faut une demande FSP distincte, un organigramme distinct, et 60S-AI devient un **partenaire-revendeur** (Modèle B de `Architecture-60secPaiement.docx` §5) de 60secPaiement — ce qui est d'ailleurs le modèle que le code implémente (`PortailPartenaire`, clé `pk_`, `X-Abonne-Id`).

---

## 2. Revue fichier par fichier

| # | Fichier | Rôle dans le dossier | Pertinent pour InfraPaiement ? | Problèmes relevés |
|---|---|---|---|---|
| 01 | `piece-01-organigramme-propriete-controle.pdf` | Q5.1 et section 15 | **Oui** si l'entité est la même | À refaire si l'exploitant d'InfraPaiement est une autre société. Ajouter les noms commerciaux « 60secPaiement » / « 60sec.ai » s'ils sont inscrits au Registraire. |
| 02 | `piece-02-description-services-paiement.pdf` | Q6.1 | **Non, à réécrire** | Décrit l'ERP (facturation, paie, IA, catégories A-B-C-D). Pour InfraPaiement : plateforme « paiement-as-a-service » multi-locataire, API + 3 portails, encaissements PAD et décaissements, compte fiducie, réserve, partenaires-revendeurs. Q6.5 = Oui, Q6.7.4 = Oui. Volumes à refaire (les ~10 200 TEF n'incluent aucun encaissement). La liste des tiers ne correspond pas au code. |
| 03 | `piece-03-exemples-contrats-ententes.pdf` | Q6.2 | **Partiellement** | Doc A (conditions d'utilisation) : à réécrire pour un abonné API/portail qui détient un solde. Doc B (PAD d'entreprise pour la facturation de 60S-AI) : réutilisable pour facturer nos abonnés. **Il manque l'entente de PAD du payeur** (le client de l'abonné, règle H1) — c'est la pièce que la banque parraine exigera en premier. Doc C (bureau comptable) : remplacer par une **entente de partenaire-revendeur** (Modèle B). |
| 04 | `piece-04-diagrammes-flux-ABCD.pdf` | Q6.3 | **Non, à refaire** | Chaque diagramme affirme « aucun fonds ne franchit cette ligne ». Pour InfraPaiement, les fonds passent par le compte fiducie. Refaire à partir de `diagrams/3-encaissement.png`, `4-cycle-paiement.png` et du séquencement ledger de `ARCHITECTURE.md` §4-6 (initiation → lot 005 → règlement → retour/NSF). |
| 05 | `piece-05-cadre-risques-operationnels.pdf` | Section 11 | **Oui, à adapter** | Structure conforme aux art. 5-10 du Règlement, réutilisable. Remplacer les risques ERP (classement IA, séance consolidée, échéances fiscales) par les risques réels d'InfraPaiement : retours NSF et fenêtre de recours PAD de 90 jours, insolvabilité d'un abonné, écart livre/banque (`clsBankRecon`), rejet à l'intake du fichier 005, compromission d'une clé API, panne SFTP. Ajouter la protection des fonds (art. 20). |
| 06 | `piece-06-cadre-reponse-incidents.pdf` | Section 11 | **Oui, à adapter** | Bon squelette (48 h, contenu des avis, registre). Remplacer les 4 scénarios d'essai par : double envoi d'un lot 005, retour E/F non rapproché, fichier rejeté par la banque, fuite de coordonnées bancaires `T020/T021`. |
| 07 | `piece-07-politiques-cybersecurite.pdf` | Section 11 | **Oui, mais plusieurs affirmations ne sont pas vraies dans le code** | Voir §4 ci-dessous (2FA, second canal, magasin de secrets, hébergement cloud, sauvegardes, rotation des clés). Un examinateur qui compare la politique au système constatera l'écart. |
| 09 | `piece-09-projection-tresorerie.pdf` | Section 12 | **À refaire** | Les hypothèses sont celles de l'ERP (abonnements 69,99-149,99 $). Pour InfraPaiement : revenus par transaction / par abonné, **coût de la réserve exigée par la banque**, provision pour retours, assurance, frais de parrainage, frais d'inscription ESM/AMF. Ajouter un **plan de capitalisation** (demandé par la banque parraine). |
| 11 | `piece-11-programme-conformite-LRPCFAT.pdf` | Section 16 | **Oui, à adapter** | Bonne structure CANAFE (5 éléments). §1 (« ne détient aucun fonds ») à réécrire. Ajouter : déclaration de TEF internationaux ≥ 10 000 $ (probablement N/A, à dire), politique KYB des abonnés adossée à `clsKyb` / `T057KybCheck`, et le fait que le **statut KYB ne bloque pas encore la création de paiements** (voir §4). |
| — | `60sai-demande-enregistrement-FSP-BdC.docx` | Dossier maître (v2.8) | **Oui, comme gabarit** | Excellent guide de saisie. Toutes les réponses des sections 6, 9, 13, 16, 17 changent avec InfraPaiement. Ses annexes A (12 pièces) et B (4 décisions) restent la bonne check-list de forme. |
| — | `60sai-contrat-client.docx` | Version longue du Doc A | **Non** | Même remarque que la pièce 03. L'article 4.2 impose au client d'activer l'authentification à deux facteurs : la fonction n'existe pas dans InfraPaiement. |
| — | `AFT_1234567890_0001_20260903.005` | Fichier 005 produit par `clsCpa005Builder` | **Oui, pour la porte 3 (banque)** | Bon échantillon pour la certification technique. **Ne pas le joindre à la demande FSP** : il montre justement des fonds qui transitent par 60SECPAIEMENT INC. Bouchons (émetteur 1234567890, centre 00400). Code devise absent dans l'enregistrement A (positions 56-58) — à aligner sur le guide de l'IF. |
| — | `60sai-deck-modulaire.pptx` | Marketing / investisseurs | **Non (pas une pièce)** | Ne pas déposer. Attention : les diapos 7-8 annoncent « Niveau 3 opérationnel au lancement » et « prélèvements automatiques via Stripe » ; le site et les decks ne doivent rien présenter comme offert avant l'inscription au registre (note Q4.1.13 du dossier d'Yves). |
| — | `60sai-positionnement-concurrentiel.pptx` | Marketing | **Non** | Sans lien avec l'approbation. |
| — | `60sai-annexes-economiques.pptx` | Marketing | **Non** | Sans lien avec l'approbation. |

---

## 3. Ce qui manque

### 3.1 Pièces manquantes dans le dossier d'Yves, selon sa propre annexe A

| # | Pièce | État |
|---|---|---|
| 8 | États financiers ou relevés bancaires (section 12) | **Absent** — premier exercice clos le 31 octobre 2026 |
| 10 | Contrats avec les tiers fournisseurs (section 13) | **Absent** — les 4 documents Dream Payments existent mais ne sont pas dans le répertoire ; 3 écarts à corriger avant dépôt (PAD signé par une personne physique, transit 00001 vs 06071, nom commercial « 60sec AI ») |
| 12 | Permis AMF (section 17) | **Absent** — conditionnel à l'avis juridique |
| — | Avis juridique externe (annexe B, décisions 1 à 3) | **Absent** — non commandé |
| — | Schéma de séquence d'initiation (Q6.6.2, « à produire ») | **Absent** |
| — | Procédure de suivi et supervision des tiers (section 13, « à produire ») | **Absent** |
| — | Résolution du CA nommant l'agent de conformité + mandat écrit (Marc Lemieux) | **Absent** |
| — | Déclaration d'antécédents des administrateurs (section 12) | **Absent** |

### 3.2 Pièces exigées par InfraPaiement et absentes des deux côtés

Croisement avec `EFT_005_APPROBATION.md`, annexe A (dossier bancaire) et §1 (portes réglementaires).

| Document | Pour qui | État | Source pour le produire |
|---|---|---|---|
| **Description du processus de génération, d'approbation et de transmission des fichiers 005** (maker-checker, plafonds, calendrier, SFTP, accusés, retours) | IF parraine | Absent | `EFT_005_APPROBATION.md` §3, `clsCpa005Builder`, `s0120ApproveEftBatch`, `clsBankExchange`, `clsEft005Ack`, `clsEft005Returns` |
| **Schéma du flux de fonds et description du compte fiducie** + démonstration de l'invariant | Banque du Canada (art. 20) et IF | Absent (contredit par la pièce 04) | `ARCHITECTURE.md` §4, `s0018GetPlatformSummary` |
| **Modèle d'entente de PAD du payeur** (client de l'abonné), conforme H1 2026, avec méthode « commercialement raisonnable » de vérification d'identité | IF parraine, abonnés | Absent | Règle H1 ; guide PAD de la Banque Nationale cité dans `EFT_005_APPROBATION.md` |
| **Contrat abonné** (API / portail) répercutant les règles F1 et H1, le solde, la réserve, les retours, les secteurs interdits | IF parraine | Absent (le contrat d'Yves est un contrat ERP) | `EFT_005_APPROBATION.md` §2.4 |
| **Entente de partenaire-revendeur** (Modèle B : 60S-AI, Dentitek) | IF parraine | Absent | `Architecture-60secPaiement.docx` §5 |
| **Politique de limites, de réserve et de traitement des retours**, couvrant la fenêtre de 90 jours des PAD personnels | IF parraine | Absent (écart n° 9 ouvert) | `EFT_005_APPROBATION.md` §2.3-2.4, `T052.Max*Cents`, `T010.MaxDailyEftCents` |
| **Politique d'acceptation des abonnés (KYB)** et liste des **secteurs interdits** | IF parraine, CANAFE | Absent (esquissé dans la pièce 11 §6) | `clsKyb`, `T057KybCheck` |
| **Décision modèle A / B** (payee-of-record unique ou numéro d'émetteur par abonné) | Interne, avant démarchage | Ouverte | `EFT_005_APPROBATION.md` §2.5 |
| **Preuves d'assurance** (E&O, cyber, détournement) | IF parraine ; Banque du Canada si l'option assurance/garantie de l'art. 20 est retenue | Absent | — |
| **Plan de continuité et de reprise** (sauvegardes, RTO 4 h / RPO 15 min réellement mis en place) | Banque du Canada, IF | Absent (annoncé dans les pièces 05/07, rien dans le code) | `INFRA_PRODUCTION_HARDENING.md` §7 |
| **Attestation de test d'intrusion** | IF parraine | Absent (budgété janv. 2027) | — |
| **CV et pièces d'identité des dirigeants** ; enquête de sécurité (AMF) | IF parraine, AMF | Absent | — |
| **Attestation d'inscription LAPD, ESM CANAFE, permis AMF** (ou preuves de dépôt) | IF parraine | Absent | Porte 1 |
| **Lettre d'engagement du bénéficiaire (LOU, règle H1)** | Fournie par l'IF, à signer | À venir | — |
| **Guide d'implantation 005 de l'IF**, identifiants d'émetteur, centre de traitement, canal SFTP | Reçus de l'IF | À venir | `EFT_005_APPROBATION.md` §3.1 |
| **Documentation technique** (architecture, sécurité, durcissement) | IF parraine, Banque du Canada | **Existe** : `ARCHITECTURE.md`, `Architecture-60secPaiement.docx`, `INFRA_PRODUCTION_HARDENING.md`, `AUTOMATION.md`, `webAPI/openapi.json` | À extraire en PDF |

---

## 4. Affirmations des politiques d'Yves non vérifiées dans le code d'InfraPaiement

Un examinateur (Banque du Canada ou banque parraine) compare la politique au système. Chaque ligne ci-dessous est un écart constaté dans le code au 2026-09-07.

| Affirmation (pièces 05 / 07 / contrat) | Réalité dans InfraPaiement | À faire |
|---|---|---|
| Authentification à deux facteurs obligatoire pour l'administration et tout compte approuvant des paiements (07 §5.2 ; contrat 4.2) | Aucune trace de 2FA/TOTP/MFA dans `PortailMaster`, `PortailABN`, `PortailPartenaire` | Implémenter, ou retirer l'affirmation |
| Validation par un second canal de tout changement de coordonnées bancaires d'un bénéficiaire ; quarantaine du premier paiement (05 §7-8, 07 §7, contrat 5.8) | Aucune logique de ce type dans `wbfClient`, `wbfFournisseur`, `s0012`/`s0036` | Implémenter (c'est la mesure anti-fraude n° 1 citée dans les 3 documents) |
| Journalisation inaltérable de la modification des coordonnées bancaires d'un bénéficiaire (07 §10) | `T070AuditLog` couvre login, clés API, KYB, exports, offboarding, approbation de lot, partenaires. **Aucune écriture d'audit sur les modifications de `T020Client` / `T021Fournisseur`** | Ajouter `clsAudit.Write` sur ces écrans et sur l'API |
| Secrets conservés dans un magasin de secrets, jamais dans les fichiers de configuration (07 §6) | `INFRA_PRODUCTION_HARDENING.md` §2 : secrets en clair dans `Web.config`, chiffrement « à faire » | Appliquer `aspnet_regiis` ou `secrets.config` |
| Console d'administration : aucune capacité d'initier un paiement au nom d'un abonné (02 §8, 05 §7, 07 §5.1) | **Faux** : `PortailMaster/wbfPaiements`, `wbfDecaissements`, `wbfInterac` appellent `s0020` / `s0038` / `clsInterac` | Soit retirer cette capacité du staff, soit l'encadrer (double contrôle + audit) et corriger la politique |
| Vérification d'identité complétée avant l'activation de la fonction de paiement (11 §6.1, contrat 3.3) | `StatutKYB` est piloté par `s0103`, mais **`s0020InitiateClientPayment` et `s0038InitiatePayout` ne vérifient pas le statut KYB** : un abonné `NonDebute` peut initier des paiements | Ajouter la garde dans les procs (et dans `ApiHandler`) |
| Hébergement infonuagique au Canada sous entente écrite (07 §8, section 13 « [À CONFIRMER] ») | Base sur `192.168.0.203` (réseau local), aucun hébergeur | Décider l'hébergement cible et le contractualiser |
| Sauvegardes conformes RPO 15 min / RTO 4 h, copie immuable, restauration testée deux fois l'an (05 §3, 07 §11) | Rien de mis en place (`INFRA_PRODUCTION_HARDENING.md` §7 ⚠️) | Mettre en place et documenter |
| Rotation annuelle des clés d'API (07 §5.4) | `T040ApiKey` n'a pas de date d'expiration ; pas de mécanisme de rotation | Ajouter `ExpiresUtc` + rappel, ou reformuler |
| Sessions expirant, réauthentification pour les opérations sensibles (07 §5.2) | Aucun `Web.config` dans le dépôt, aucune réauthentification dans le code | À vérifier au déploiement et documenter |
| Chiffrement au repos de la base et des sauvegardes (07 §6) | Chiffrement AES-256 des **coordonnées bancaires** seulement (script 45) ; pas de TDE ni de chiffrement des sauvegardes documenté | Préciser le périmètre réel ou activer TDE |
| Analyse mensuelle des vulnérabilités, test d'intrusion avant lancement (07 §9) | Aucun (admis dans 07 §15) | Planifier |
| Vérification de la provision par lecture bancaire Plaid (Q6.7.2) | Absent d'InfraPaiement | Répondre « Non » pour InfraPaiement |

Points qui **sont** conformes et que les documents peuvent citer en preuve : accès BD par procédures stockées uniquement ; grand livre immuable (`T101/T102`) ; journal d'audit append-only (`T070`) ; BCrypt + verrouillage ; webhooks HMAC ; HSTS et en-têtes durcis ; double contrôle sur les lots 005 (`s0120`) ; plafonds unitaire/fichier/jour/abonné ; calendrier de jours ouvrables et heure de tombée (`clsBusinessCalendar`, `T059`) ; chiffrement des coordonnées bancaires ; rétentions et purges documentées (`s0079`) ; rôle SQL `db_apiexec`.

---

## 5. Ordre de travail proposé

1. **Trancher l'entité juridique** qui exploite InfraPaiement et, en conséquence, si le dossier d'Yves est à réécrire ou à dupliquer.
2. **Trancher le modèle A / B** (`EFT_005_APPROBATION.md` §2.5) : il conditionne le contrat abonné, l'entente PAD du payeur et le discours à la banque.
3. Commander **un seul avis juridique** couvrant : détention de fonds (art. 20) avec compte fiducie, ESM CANAFE, permis AMF, qualification de la préparation des lots 005 (Q6.8), et le montage de parrainage.
4. Réécrire les pièces **02, 03, 04, 09, 11** et adapter **05, 06, 07** sur le modèle réel ; ajouter les pièces du §3.2.
5. Corriger dans le code les écarts du §4 qui sont cités comme mesures de contrôle (2FA, second canal, audit des coordonnées, garde KYB, staff), ou retirer ces affirmations des politiques.
6. Seulement ensuite : démarchage des IF (annexe B de `EFT_005_APPROBATION.md`) avec le fichier 005 d'échantillon et la description du processus 005.
