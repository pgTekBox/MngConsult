# Liste maîtresse des documents — approbation du service de paiement EFT

> Consolidation, au 7 septembre 2026, du bordereau d'Yves (`Desktop\60sec level3\From Yves\00-bordereau-documents-FSP.pdf`),
> de `EFT_005_APPROBATION.md` (annexe A) et de `REVUE_DOSSIER_EFT.md`.
> Périmètre : la plateforme **InfraPaiement / 60secPaiement** telle que le code l'implémente
> (compte fiducie, encaissements PAD 430 et décaissements 230, fichiers CPA-005 produits par nous).

---

## 0. Avertissement — le dossier d'Yves ne décrit pas ce produit

Le dossier « From Yves » est complet et bien fait, mais il décrit **60S-AI**, un ERP qui
**ne détient aucun fonds** et dont les paiements sont exécutés par **Dream Payments**.
InfraPaiement fait l'inverse : `TRUST = Σ SUBBAL + Σ RESERVE + FEES` (`ARCHITECTURE.md` §4,
`07_grand_livre.sql`), fonds de tiers reçus par débit PAD, fichiers 005 émis sous notre propre
numéro d'émetteur.

Conséquence : la réponse **« Non » à la question 6.5 (détention de fonds) serait fausse** pour
InfraPaiement. Or c'est elle qui écarte **l'article 20 de la LAAPD** (fiducie / assurance /
garantie) et qui, dans la pièce 11, sert d'argument contre la qualification d'ESM. Avec le compte
fiducie, l'article 20 s'applique, l'inscription ESM à CANAFE devient très probable et le permis AMF
n'est plus hypothétique.

**Deux décisions bloquent la production de toute la liste ci-dessous :**

| # | Décision | Pourquoi elle bloque |
|---|---|---|
| D1 | **Quelle personne morale exploite InfraPaiement ?** 9567-0048 Québec inc. (60S-AI) ou une autre entité | Si c'est une autre entité : demande FSP distincte, organigramme distinct, et 60S-AI devient partenaire-revendeur (Modèle B de `Architecture-60secPaiement.docx` §5) — ce que le code implémente déjà (`PortailPartenaire`) |
| D2 | **Modèle A ou B** (`EFT_005_APPROBATION.md` §2.5) : 60secPaiement *payee-of-record* unique, ou un numéro d'émetteur par abonné | Conditionne le contrat abonné, l'entente de PAD du payeur, le nombre de LOU, et le discours à chaque banque |

---

## 1. Porte 1 — Inscription FSP auprès de la Banque du Canada (LAPD)

Dépôt via le portail Connexion FSP, **au moins 60 jours avant le début des activités**, droits
≈ 2 500 $. Un seul PDF par emplacement.

### 1.1 Les 12 pièces du bordereau

| # | Pièce | Section | État chez Yves | Pertinence InfraPaiement |
|---|---|---|---|---|
| 01 | Organigramme de propriété et de contrôle | Q5.1 / 15 | ✅ produit | **Oui si même entité** (D1). Ajouter les noms commerciaux « 60secPaiement » / « 60sec.ai » s'ils sont au Registraire |
| 02 | Description des services et processus de paiement | Q6.1 | ✅ produit | ❌ **À réécrire** — décrit l'ERP. Il faut : plateforme paiement multi-locataire, API + 3 portails, encaissements PAD **et** décaissements, compte fiducie, réserve, partenaires-revendeurs. Q6.5 = **Oui**, Q6.7.4 = **Oui**. Volumes à refaire (les ~10 200 TEF n'incluent aucun encaissement). Liste des tiers à refaire (aucun Stripe/Plaid/Square/Dream dans le code) |
| 03 | Exemples de contrats et d'ententes | Q6.2 | ✅ produit | ⚠️ **Partiel** — Doc A à réécrire pour un abonné qui détient un solde ; Doc B réutilisable ; Doc C à remplacer par une entente de partenaire-revendeur. **Manque l'entente de PAD du payeur** (règle H1) |
| 04 | Diagrammes des processus de paiement A-B-C-D | Q6.3 | ✅ produit | ❌ **À refaire** — chaque diagramme affirme « aucun fonds ne franchit cette ligne ». Refaire à partir de `diagrams/3-encaissement.png`, `4-cycle-paiement.png` et du séquencement de `ARCHITECTURE.md` §4-6 |
| 05 | Cadre de gestion des risques opérationnels | 11 | ✅ produit | ⚠️ **À adapter** — structure conforme aux art. 5-10 du Règlement. Remplacer les risques ERP par : retours NSF et **fenêtre de recours PAD de 90 jours**, insolvabilité d'un abonné, écart livre/banque, rejet à l'intake, compromission de clé API, panne SFTP. Ajouter la protection des fonds (art. 20) |
| 06 | Cadre de réponse aux incidents | 11 | ✅ produit | ⚠️ **À adapter** — bon squelette (48 h, avis, registre). Remplacer les 4 scénarios d'essai par : double envoi d'un lot 005, retour E/F non rapproché, fichier rejeté, fuite de coordonnées `T020/T021` |
| 07 | Politiques et procédures de cybersécurité | 11 | ✅ produit | ⚠️ **À adapter** — plusieurs affirmations ne sont pas vraies dans le code (voir §6) |
| 08 | **États financiers ou relevés bancaires** | 12 | ❌ **absent** | Requis. Premier exercice clos le 31 oct. 2026 → déposer des **relevés bancaires** + prévisionnels d'ici là |
| 09 | Projection de trésorerie | 12 | ✅ produit | ❌ **À refaire** — hypothèses ERP (forfaits 69,99 / 99,99 / 149,99 $). Il faut : revenus par transaction et par abonné, **coût de la réserve bancaire**, provision pour retours, assurance, frais de parrainage, frais ESM/AMF, et un **plan de capitalisation** |
| 10 | **Contrats avec les tiers fournisseurs** | 13 | ❌ **absent** | Requis. À refaire sur les vrais tiers d'InfraPaiement : parrain bancaire, partenaire Interac, fournisseur KYB, hébergeur |
| 11 | Programme de conformité LRPCFAT | 16 | ✅ produit | ⚠️ **À adapter** — bonne structure CANAFE (5 éléments). §1 (« ne détient aucun fonds ») à réécrire. Ajouter : TEF internationaux ≥ 10 000 $, politique KYB adossée à `clsKyb`/`T057KybCheck` |
| 12 | **Permis provincial (AMF)** | 17 | ❌ **absent** | Conditionnel à l'avis juridique — devient probable avec la détention de fonds |

**Bilan bordereau : 9 pièces sur 12 produites, mais 4 des 9 sont à réécrire (02, 04, 09 et la partie contrats de 03) et 4 autres à adapter (05, 06, 07, 11).**

### 1.2 Pièces additionnelles exigées par l'article 20 (détention de fonds), absentes du bordereau

| Document | Pourquoi |
|---|---|
| **Entente de compte en fiducie à vocation unique** avec l'institution dépositaire — ou preuve d'assurance/garantie couvrant le solde d'un compte ségrégué | Art. 20 LAAPD. Le bordereau ne le prévoit pas parce qu'il répond « Non » à la Q6.5 |
| **Schéma du flux de fonds + description du compte fiducie**, avec démonstration de l'invariant `TRUST = Σ SUBBAL + Σ RESERVE + FEES` | Art. 20 ; contredit aujourd'hui par la pièce 04. Source : `ARCHITECTURE.md` §4, `s0018GetPlatformSummary` |
| **Valeur moyenne et valeur de pointe des fonds détenus** (Q9.6 / Q9.7) | Déclaration obligatoire dès que Q6.5 = Oui |
| **Schéma de séquence d'initiation** (Q6.6.2) | Marqué « à produire » dans le dossier maître, jamais produit |
| **Procédure de suivi et de supervision des tiers fournisseurs** (section 13) | Marquée « à produire », jamais produite |
| **Résolution du CA nommant l'agent de conformité + mandat écrit** (Me Marc Lemieux) | Exigé aux trois portes |
| **Déclaration d'antécédents des administrateurs** (section 12) | Exigée |
| **Avis juridique externe** | Chemin critique — voir §5 |

---

## 2. Porte 1b — Inscription ESM auprès de CANAFE

Les exemptions « traitement de paiements / service aux commerçants » (PI-7670) ont été **retirées le
27 avril 2022**. Dès qu'on reçoit, détient ou transfère des fonds pour autrui — ce que fait
InfraPaiement — les règles ESM s'appliquent.

- [ ] Formulaire d'inscription ESM (CANAFE)
- [ ] Programme de conformité LRPCFAT écrit (pièce 11 réécrite)
- [ ] Nomination de l'agent de conformité (résolution + mandat)
- [ ] Évaluation des risques documentée
- [ ] Plan de formation et registre de formation
- [ ] Politique de tenue de dossiers et de déclarations (opérations douteuses, TEF internationaux ≥ 10 000 $, espèces)
- [ ] Engagement d'examen indépendant biennal

## 3. Porte 1c — Permis AMF (Loi sur les ESM, Québec)

- [ ] Demande de permis d'entreprise de transfert de fonds — **ou** avis juridique motivant la non-application
- [ ] Enquête de sécurité de la Sûreté du Québec sur dirigeants et actionnaires
- [ ] CV et pièces d'identité des dirigeants

---

## 4. Porte 2 — Dossier pour l'institution financière parraine

C'est la porte la plus lourde et la seule qui donne accès au rail ACSS. Horizon réaliste : 3 à 9 mois.

### 4.1 Corporatif et financier

- [ ] Statuts constitutifs, registre des actionnaires, bénéficiaires ultimes
- [ ] Organigramme (pièce 01)
- [ ] CV et pièces d'identité des dirigeants ; enquêtes de sécurité
- [ ] États financiers (2-3 ans) ou prévisionnels **+ plan de capitalisation** — *manquant*
- [ ] **Preuves d'assurance** : responsabilité professionnelle (E&O), cyber, détournement — *manquant*

### 4.2 Réglementaire

- [ ] Attestation d'inscription LAPD — ou preuve de dépôt
- [ ] Attestation d'inscription ESM CANAFE — ou preuve de dépôt
- [ ] Permis AMF, ou avis juridique expliquant pourquoi il n'est pas requis
- [ ] Programme AML/LRPCFAT complet + nom de l'agent de conformité
- [ ] Résultat du dernier examen indépendant (sans objet au premier dépôt — le dire)

### 4.3 Modèle d'affaires et risque

- [ ] Description du service et des types de flux (débits PAD entrants 430 / crédits sortants 230)
- [ ] Volumes projetés : nombre, montant moyen, montant maximal unitaire, pointe mensuelle
- [ ] Tarification
- [ ] **Politique d'acceptation des abonnés (KYB)** et **liste des secteurs interdits** — *manquant* (esquissé dans la pièce 11 §6)
- [ ] **Politique de limites, de réserve et de traitement des retours**, couvrant les **90 jours** de recours du PAD personnel — *manquant, écart n° 9 ouvert*
- [ ] Plan en cas d'insolvabilité d'un abonné

### 4.4 Technique

- [ ] Architecture, sécurité, durcissement — **existe** : `ARCHITECTURE.md`, `Architecture-60secPaiement.docx`, `INFRA_PRODUCTION_HARDENING.md`, `AUTOMATION.md`, `webAPI/openapi.json`. **À extraire en PDF**
- [ ] **Description du processus de génération, d'approbation et de transmission des fichiers 005** (maker-checker, plafonds, calendrier, SFTP, accusés, retours) — *manquant*. Sources : `EFT_005_APPROBATION.md` §3, `clsCpa005Builder`, `s0120ApproveEftBatch`, `clsBankExchange`, `clsEft005Ack`, `clsEft005Returns`
- [ ] **Plan de continuité et de reprise** réellement en place (RTO 4 h / RPO 15 min) — *annoncé dans les pièces 05/07, rien dans le code*
- [ ] Attestation de test d'intrusion — *manquant, budgété janvier 2027*
- [ ] Fichier 005 d'échantillon (`AFT_1234567890_0001_20260903.005`) — **existe**, à corriger : code devise absent aux positions 56-58 de l'enregistrement A. *Ne pas le joindre à la demande FSP* : il montre les fonds transitant par 60SECPAIEMENT INC

### 4.5 Juridique

- [ ] **Contrat abonné** (API/portail) répercutant les règles F1 et H1, le solde, la réserve, les retours, les secteurs interdits — *manquant ; le contrat d'Yves est un contrat ERP*
- [ ] **Modèle d'entente de PAD du payeur** conforme H1 2026, avec méthode « commercialement raisonnable » de vérification d'identité — *manquant ; c'est la pièce que la banque exigera en premier*
- [ ] **Entente de partenaire-revendeur** (Modèle B : 60S-AI, Dentitek) — *manquant*
- [ ] **Lettre d'engagement du bénéficiaire (LOU, règle H1)** — fournie par l'IF, à signer

---

## 5. Porte 3 — Certification technique du fichier 005

Rien à déposer avant d'avoir un parrain. À recevoir de l'IF :

- [ ] Guide d'implantation 005 (positions exactes) — **prime sur la norme générique**
- [ ] Numéro de client émetteur, centre de traitement, compte de retour, codes CPA autorisés
- [ ] Canal SFTP, heures de tombée, calendrier
- [ ] Accès à l'environnement de test

Puis : mapping, fichiers de test jusqu'à zéro rejet, test réel à faible montant avec **retour NSF
provoqué**, période de parallèle, mise en production à plafonds réduits.

Écarts techniques encore ouverts : FCN qui tronque au-delà de 4 chiffres (collision au rebouclage
9999), validateur 005 autonome, réalignement du générateur, canal SFTP testé en local seulement.

---

## 6. Écarts entre les politiques d'Yves et le code d'InfraPaiement

Un examinateur compare la politique au système. Chaque ligne est un écart constaté au 7 septembre 2026 —
soit on implémente, soit on retire l'affirmation.

| Affirmation (pièces 05 / 07 / contrat) | Réalité dans le code |
|---|---|
| 2FA obligatoire pour l'administration et tout compte approuvant des paiements (07 §5.2, contrat 4.2) | Aucune trace de 2FA/TOTP/MFA dans les trois portails |
| Validation par un second canal de tout changement de coordonnées bancaires ; quarantaine du premier paiement (05 §7-8, 07 §7, contrat 5.8) | Aucune logique de ce type — c'est pourtant la mesure anti-fraude n° 1 citée dans les trois documents |
| Journalisation inaltérable des modifications de coordonnées bancaires (07 §10) | `T070AuditLog` ne couvre pas les écritures sur `T020Client` / `T021Fournisseur` |
| Secrets dans un magasin de secrets (07 §6) | Secrets en clair dans `Web.config` (`INFRA_PRODUCTION_HARDENING.md` §2) |
| La console d'administration ne peut pas initier un paiement au nom d'un abonné (02 §8, 05 §7, 07 §5.1) | **Faux** : `wbfPaiements`, `wbfDecaissements`, `wbfInterac` appellent `s0020` / `s0038` / `clsInterac` |
| Vérification d'identité complétée avant l'activation des paiements (11 §6.1, contrat 3.3) | `s0020InitiateClientPayment` et `s0038InitiatePayout` **ne vérifient pas le statut KYB** |
| Hébergement infonuagique au Canada sous entente écrite (07 §8) | Base sur `192.168.0.203` (réseau local), aucun hébergeur |
| Sauvegardes RPO 15 min / RTO 4 h, copie immuable, restauration testée (05 §3, 07 §11) | Rien de mis en place |
| Rotation annuelle des clés d'API (07 §5.4) | `T040ApiKey` n'a ni date d'expiration ni mécanisme de rotation |
| Chiffrement au repos de la base et des sauvegardes (07 §6) | AES-256 sur les **coordonnées bancaires** seulement ; pas de TDE |
| Analyse mensuelle des vulnérabilités, test d'intrusion (07 §9) | Aucun |
| Vérification de la provision par lecture bancaire Plaid (Q6.7.2) | Absent — répondre « Non » |

**Ce qui est conforme et peut être cité en preuve** : accès BD par procédures stockées uniquement ;
grand livre immuable (`T101/T102`) ; journal d'audit append-only (`T070`) ; BCrypt + verrouillage ;
webhooks HMAC ; HSTS ; **double contrôle sur les lots 005** (`s0120`) ; **plafonds** unitaire /
fichier / jour / abonné ; **calendrier de jours ouvrables et heure de tombée** ; **chiffrement des
coordonnées bancaires** ; rétentions et purges (`s0079`) ; rôle SQL `db_apiexec`.

---

## 7. Récapitulatif — ce qui manque

**Manquant selon le bordereau d'Yves lui-même (3) :** pièce 08 (états financiers / relevés
bancaires), pièce 10 (contrats tiers fournisseurs), pièce 12 (permis AMF).

**Manquant en plus, du fait de la détention de fonds (8) :** entente de compte en fiducie ou preuve
d'assurance/garantie, schéma du flux de fonds et description du compte fiducie, valeurs moyenne et de
pointe des fonds détenus, schéma de séquence d'initiation, procédure de supervision des tiers,
résolution nommant l'agent de conformité, déclaration d'antécédents des administrateurs, avis
juridique externe.

**Manquant pour la banque parraine (10) :** plan de capitalisation, preuves d'assurance, politique
KYB + secteurs interdits, politique de limites/réserve/retours sur 90 jours, plan en cas
d'insolvabilité d'un abonné, description du processus 005, plan de continuité, attestation de test
d'intrusion, contrat abonné, modèle d'entente de PAD du payeur, entente de partenaire-revendeur.

**À réécrire plutôt qu'à produire (4) :** pièces 02, 04, 09 et la partie contrats de la pièce 03.
**À adapter (4) :** pièces 05, 06, 07, 11.

---

## 8. Ordre de travail

1. **Trancher D1** (entité juridique) — commande la réécriture ou la duplication du dossier.
2. **Trancher D2** (modèle A/B) — commande le contrat abonné, l'entente PAD et le discours bancaire.
3. Commander **un seul avis juridique** couvrant : détention de fonds et art. 20 avec compte fiducie,
   ESM CANAFE, permis AMF, qualification de la préparation des lots 005 (Q6.8), montage de parrainage.
4. Réécrire 02, 03, 04, 09, 11 ; adapter 05, 06, 07 ; produire les pièces du §1.2.
5. Corriger dans le code les écarts du §6 qui sont cités comme mesures de contrôle (2FA, second canal,
   audit des coordonnées, garde KYB, pouvoirs du staff) — ou retirer ces affirmations des politiques.
6. Seulement ensuite : démarchage de 4 à 6 IF avec le fichier 005 d'échantillon et la description du
   processus 005.

> Ce document décrit une démarche réglementaire et bancaire ; il ne constitue pas un avis juridique.
> Frais, délais et exigences sont à revalider auprès de chaque autorité et de chaque IF au moment du dépôt.
