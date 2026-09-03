# Émettre nos propres fichiers CPA-005 — dossier d'approbation

> **Objectif** : que 60secPaiement produise elle-même ses fichiers AFT (norme 005 de Paiements
> Canada) et soit **autorisée** à les déposer dans le rail ACSS, plutôt que de passer par un
> agrégateur (VoPay, Zum Rails, Payment Source…).
>
> **Statut du dossier** : préparation du démarchage — aucune institution financière (IF) parraine
> engagée à ce jour. Document de travail, à valider avec conseil juridique et avec chaque IF
> approchée. Rédigé le 2026-09-03.

---

## 0. La réponse courte

Il n'existe **pas** d'« approbation pour produire des fichiers 005 » délivrée par Paiements Canada.
Le fichier 005 n'est qu'un format. Ce qui s'approuve, ce sont **trois portes distinctes**, dans cet
ordre, et chacune peut nous arrêter :

| # | Porte | Qui approuve | Sans elle |
|---|---|---|---|
| 1 | **Droit d'exercer** — inscription PSP (LAPD/RPAA), inscription ESM CANAFE, permis AMF, protection des fonds d'utilisateurs | Banque du Canada, CANAFE, AMF | Illégal d'opérer, peu importe le rail |
| 2 | **Accès au rail ACSS** — être membre-adhérent OU **parrainé** par un adhérent (*direct clearer*) | L'IF parraine (et ses comités crédit / conformité) | Le fichier n'a nulle part où aller |
| 3 | **Certification technique du fichier** — tests, validations, contrôles, mise en production | Le groupe *Cash Management / services aux entreprises* de l'IF parraine | Fichiers rejetés à l'intake |

La porte 3 (la partie logicielle, celle qu'on maîtrise déjà à ~80 %) est **la plus facile**. Les
portes 1 et 2 sont le vrai chemin critique et se comptent en **mois**, pas en semaines.

Concrètement : **on ne « demande pas » à Paiements Canada — on se fait parrainer par une banque**,
qui nous attribue un **numéro de client émetteur (originator ID)**, un **centre de traitement
(data centre)**, des plafonds, et qui répond de nous devant le rail. Elle exige en retour une
**Lettre d'engagement du bénéficiaire** (*Payee Letter of Undertaking*, règle H1), une revue de
crédit, et le plus souvent une **réserve / garantie**.

---

## 1. Porte 1 — Droit d'exercer (réglementaire)

À monter avec conseil juridique spécialisé en paiements. Aucune IF n'ouvrira un dossier de
parrainage sans que ce volet soit au moins engagé.

### 1.1 Inscription PSP auprès de la Banque du Canada (LAPD / *RPAA*)

- Obligatoire **avant** d'exercer une activité de paiement de détail ; la demande doit être
  déposée **au moins 60 jours** avant le début des activités.
- Frais de demande : **≈ 2 500 $** (tarif publié en novembre 2024 — à revalider).
- Exigences continues : cadre de **gestion des risques opérationnels**, **déclaration d'incidents**,
  **protection des fonds des utilisateurs finaux**, et **rapport annuel** (portail *PSP Connect*,
  échéance du 31 mars, avec sursis au 28 avril pour les inscriptions de mars).
- **Protection des fonds** : les fonds des utilisateurs doivent être détenus dans un **compte en
  fiducie à vocation unique**, ou dans un compte ségrégué **assorti d'une assurance ou d'une
  garantie** d'un montant au moins égal aux fonds détenus.
  → Aligné avec notre modèle : compte fiducie mutualisé + grand livre partie double
  (`T100`-`T102`) qui en est le miroir.
- Un défaut de rapport ou une information trompeuse constitue une violation de la LAPD, passible de
  **sanctions administratives pécuniaires**, publiées par la Banque du Canada.

### 1.2 Inscription ESM (MSB) auprès de CANAFE

- Les anciennes positions d'exemption visant le **traitement de paiements et le service aux
  commerçants (PI-7670)** ont été **retirées le 27 avril 2022**. L'argument « nous ne sommes qu'une
  société techno » ne tient plus.
- Dès qu'une entité **reçoit, détient, transfère ou convertit des fonds pour le compte d'autrui**
  — ce que fait exactement 60secPaiement — les règles ESM s'appliquent : **inscription CANAFE**,
  **programme de conformité LRPCFAT** (politiques, agent de conformité désigné, formation,
  évaluation des risques, examen indépendant biennal), tenue de dossiers et déclarations
  (opérations douteuses, TEF internationaux ≥ 10 000 $, espèces).

### 1.3 Permis AMF (Québec)

- La *Loi sur les entreprises de services monétaires* exige un **permis de l'AMF** pour l'exploitation
  d'une entreprise de **transfert de fonds** au Québec, avec enquête de sécurité de la Sûreté du
  Québec sur les dirigeants et actionnaires.
- À confirmer avec le conseil juridique : la qualification exacte de notre activité (transfert de
  fonds vs. traitement pour le compte d'un adhérent) dépend du **modèle de flux de fonds** retenu
  à la section 2.5, et détermine si le permis est requis.

### 1.4 Gouvernance à démontrer (exigée aussi aux portes 2 et 3)

Programme AML/KYB écrit · agent de conformité nommé · KYB/KYC des abonnés (déjà : `T057KybCheck`,
`clsKyb`, statut KYB par abonné) · surveillance des transactions et seuils · plan de continuité ·
politique de sécurité de l'information · registre d'audit inaltérable (déjà : `T070AuditLog`) ·
politique de conservation et de purge (déjà : `s0079RunDailyMaintenance`).

---

## 2. Porte 2 — Accès au rail ACSS

### 2.1 Deux voies, une seule réaliste à court terme

**Voie A — devenir membre de Paiements Canada et adhérent (*direct clearer*).**
Depuis les modifications de 2025 à la *Loi canadienne sur les paiements*, l'admissibilité est
étendue aux **PSP inscrits sous la LAPD**, aux caisses locales membres d'une centrale et à certaines
chambres de compensation. L'exigence historique de **0,5 % du volume de l'ACSS** a été **abolie**
(règle D1 de l'ACSS, en vigueur le 5 août 2020). Quinze organisations ont adhéré en 2026.
**Mais** : l'adhésion ne donne **pas** l'accès aux systèmes. La participation directe exige un
**compte de règlement à la Banque du Canada** (ou une entente avec un agent de règlement) et le
passage d'exigences techniques, opérationnelles et de sécurité rigoureuses ; l'approbation passe par
le conseil de Paiements Canada, qui siège environ quatre fois l'an (mars, mai, septembre, décembre).
→ **Horizon : 18-36 mois, capital et opérations en continu. Pas notre point de départ.**

**Voie B — parrainage par un adhérent.** Nous restons **émetteur (*originator*) / bénéficiaire
(*payee*)** ; l'IF parraine dépose nos fichiers dans l'ACSS sous sa responsabilité et nous attribue
notre identité d'émetteur. C'est le chemin de **toutes** les fintechs de paiement au Canada, y
compris celles qui, comme nous, produisent elles-mêmes leurs 005.
→ **Horizon réaliste : 3 à 9 mois. C'est la voie retenue.**

### 2.2 Ce que l'IF parraine exige de nous

Le parrain porte le risque réglementaire et le risque de crédit à notre place ; sa diligence porte
sur les obligations de conformité, la répartition des responsabilités, les produits permis, les
**exigences de réserve**, l'exclusivité et les droits de résiliation.

Le **dossier** à déposer (check-list complète en annexe A) :

1. **Corporatif** : constitution, registre des actionnaires, organigramme, CV des dirigeants,
   états financiers (2-3 ans ou prévisionnels), preuves d'assurance (E&O, cyber, détournement).
2. **Réglementaire** : inscription LAPD, inscription CANAFE, permis AMF le cas échéant, politique
   AML complète, résultat du dernier examen indépendant.
3. **Modèle d'affaires** : description du service, types de flux (débits PAD entrants / crédits
   sortants), volumes et montants projetés (moyen, pointe, maximum unitaire), secteurs des abonnés,
   tarification, **liste des secteurs interdits**.
4. **Risque** : politique d'acceptation des abonnés (KYB), limites par abonné, traitement des
   retours/NSF, provisionnement des pertes, plan en cas d'insolvabilité d'un abonné.
5. **Technique** : architecture, sécurité, plan de reprise, **description du processus de génération
   et de transmission des fichiers 005** (c'est ici que notre documentation existante sert).
6. **Juridique** : projet de contrat abonné, modèle d'**entente de PAD du payeur**, et signature de
   la **Lettre d'engagement du bénéficiaire** exigée par la règle H1.

### 2.3 Ce que l'IF exigera en contrepartie

- **Réserve / garantie** : dépôt bloqué ou retenue d'un pourcentage du volume débit en cours de
  compensation, pour couvrir les retours.
- **Plafonds** : par transaction, par fichier, par jour, révisés à la hausse après historique.
- **Délai de disponibilité des fonds** sur les débits (rétention avant crédit à l'abonné).
- **Droit d'audit** sur nos processus et sur nos abonnés.
- **Comptes ouverts chez elle** : le compte de retour inscrit dans le fichier 005 doit être un
  compte qu'elle contrôle (champs `ReturnInstitution` / `ReturnTransit` / `ReturnAccount` de `T052`).

### 2.4 Règles applicables (à répercuter dans le contrat abonné)

- **Règle F1** — opérations AFT : identification de l'émetteur, délais d'échange, retours et
  contre-passations.
- **Règle H1** — PAD (débits préautorisés), version 2026 :
  - Toute ponction sur le compte d'un payeur exige une **entente de PAD du payeur** valide, obtenue
    par des **méthodes commercialement raisonnables** de vérification d'identité — et le bénéficiaire
    doit le **confirmer par écrit** dans sa Lettre d'engagement.
  - **Recours du payeur** : réclamation de remboursement jusqu'à **90 jours civils** (PAD personnel
    ou PAD de transfert de fonds) et **10 jours ouvrables** (PAD d'entreprise) après le débit.
    → Impact direct : notre politique de rétention et notre réserve doivent couvrir une fenêtre de
    **90 jours**, pas seulement les 2-3 jours du NSF classique. **À revoir dans notre modèle de risque.**
  - Préavis obligatoires en cas de changement de montant ou de date (PAD à montant variable).

### 2.5 Le point critique de notre modèle : émettre **pour le compte de tiers**

60secPaiement est multi-locataire : nos **abonnés** encaissent auprès de **leurs** clients. Devant
la règle H1, la question est : **qui est le bénéficiaire (*payee*) de l'entente de PAD ?**

| Modèle | Qui est *payee* | Ce que la banque exige | Impact sur notre code |
|---|---|---|---|
| **A — Plateforme *payee-of-record*** | 60secPaiement, agissant pour le compte de l'abonné | Une seule LOU (la nôtre), notre engagement de faire signer des ententes PAD conformes, KYB de chaque abonné, droit d'audit | Modèle **actuel** : `T052EftOriginator` est **unique et global** — un seul numéro d'émetteur, nos noms court/long. À enrichir : faire apparaître l'abonné dans le nom de contrepartie et la référence croisée pour que le payeur reconnaisse le prélèvement sur son relevé. |
| **B — Chaque abonné est *payee*** | L'abonné | Une LOU **par abonné** et souvent un **numéro d'émetteur par abonné** | Refonte : `T052` devient une table **par abonné** (`AbonneId`), un lot 005 par émetteur, numérotation FCN par émetteur. |

**Décision à prendre avant le démarchage** : elle conditionne le schéma et le discours à la banque.
Le modèle A est le standard des plateformes (et celui que notre code implémente déjà), mais
**certaines IF le refusent** ou le plafonnent — à poser comme **première question** à chaque IF
approchée (annexe B).

---

## 3. Porte 3 — Certification technique du fichier 005

### 3.1 Ce que la banque nous remet (et qui va dans `T052EftOriginator`)

| Élément reçu de l'IF | Champ `T052` | Aujourd'hui |
|---|---|---|
| Numéro de client émetteur (10) | `ClientNumber` | `0000000000` (bouchon) |
| Centre de traitement / *data centre* (5) | `DataCentre` | `00000` (bouchon) |
| Noms court (15) et long (30) de l'émetteur | `ShortName` / `LongName` | 60SECPAIEMENT |
| Compte de retour (institution / transit / compte) | `ReturnInstitution` / `ReturnTransit` / `ReturnAccount` | bouchons |
| Codes d'opération CPA autorisés | `CpaCodeDebit` / `CpaCodeCredit` | 430 / 230 |
| Plage et règle du numéro de création de fichier | `NextFileCreationNumber` | compteur séquentiel |
| Guide d'implantation (positions exactes), canal de transmission, **heures de tombée**, calendrier | — | **manquant** |

> ⚠️ Le guide d'implantation de l'IF **prime sur la norme générique** : chaque banque superpose ses
> propres validations de champs, sa règle de numéro d'émetteur, son canal de dépôt et ses heures de
> tombée. Notre `clsCpa005Builder` est documenté comme un **gabarit** — il ne sera conforme qu'après
> réception de ce guide.

### 3.2 Déroulement type de la certification

1. Signature de l'entente de services (AFT / dépôt direct + PAD) et de la LOU.
2. Réception du guide d'implantation et des identifiants (émetteur, centre, canal SFTP).
3. **Mapping** de nos champs sur le guide, puis reprise du générateur.
4. **Fichiers de test** déposés dans l'environnement de test de la banque, jusqu'à zéro rejet à
   l'intake (nos accusés et rejets sont déjà modélisés : `T055EftAck`, `clsEft005Ack`).
5. **Test réel de faible montant** (0,01-1,00 $ sur nos propres comptes), incluant **un retour NSF
   provoqué** pour valider la chaîne de contre-passation (`s0049`).
6. **Période de parallèle / surveillance** : volumes plafonnés, revue quotidienne par la banque.
7. **Mise en production** avec plafonds initiaux, puis relèvement graduel.

### 3.3 Les contrôles que la banque vérifiera — et où nous en sommes

| Contrôle attendu | État | Preuve / écart |
|---|---|---|
| Fichier à largeur fixe, enregistrements A/C/D/Z | ✅ gabarit | `clsCpa005Builder` (1464 oct., 6 segments/enr.) — **à réaligner sur le guide de l'IF** |
| Retours et rejets importés et rapprochés | ✅ | `clsEft005Returns` (E/F/NSF) + `s0049ProcessReturn` (contre-passation) |
| Accusé bancaire traité, lot passé Acknowledged/Rejected | ✅ | `clsEft005Ack`, `T055EftAck`, `s0094`-`s0096` |
| Numéro de création de fichier **séquentiel, unique, non réutilisé** | ⚠️ | compteur `T052.NextFileCreationNumber` correct, mais `Num()` **tronque** au-delà de 4 chiffres → collision au rebouclage 9999. **À corriger.** |
| Dates d'échéance et de création en **jour ouvrable** (calendrier de l'IF, heures de tombée) | ✅ | `clsBusinessCalendar` + `T059BankHoliday` (script 44) : date de dépôt en heure de l'Est, reportée après l'heure de tombée, échéances jamais un samedi/dimanche/férié |
| **Double contrôle (maker-checker)** avant soumission d'un lot | ✅ | statut `Approved` + `s0120ApproveEftBatch` (refuse l'approbateur = créateur) ; `s0064ListBatchesToSend` ne sort que les lots approuvés ; action auditée `EftBatchApprove` |
| Plafonds : montant unitaire, total du fichier, total quotidien | ✅ | `T052` (`MaxItemCents` / `MaxFileCents` / `MaxDailyCents`) + `T010Abonne.MaxDailyEftCents` ; vérifiés dans `s0044CreateEftBatch`, tout dépassement annule le lot |
| Rapprochement quotidien livre ↔ relevé bancaire | ✅ | `T061`, `clsBankRecon`, `wbfRapprochement` |
| Grand livre partie double immuable, invariant vérifié | ✅ | `T100`-`T102` |
| Piste d'audit inaltérable des actions sensibles | ✅ | `T070AuditLog` (déclencheurs d'immuabilité), `clsAudit` |
| Transmission sécurisée (SFTP, clés, journalisation) | ⚠️ | `clsBankExchange` / `T054` (transport local + WinSCP) — **testé en local seulement** |
| Chiffrement des coordonnées bancaires au repos | ✅ | AES-256 par clé symétrique + certificat (script 45) sur `T020` / `T021` / `T051` ; déchiffré seulement dans `s0012`/`s0036`/`s0046`, **masqué** dans l'export RGPD |
| Conservation et purge documentées | ✅ | `s0079RunDailyMaintenance` (rétentions 30 j → 7 ans) |
| Durcissement production | ✅ | `INFRA_PRODUCTION_HARDENING.md`, rôle `db_apiexec` |

**Lecture** : les quatre écarts qui auraient fait reculer une banque — double contrôle, plafonds,
calendrier des jours ouvrables, chiffrement — **sont corrigés** (scripts 44 et 45, `clsBusinessCalendar`,
`wbfEftBatches`, `wbfAbonne`). Restent la conformité fine du fichier au guide de l'IF et la sécurisation
réelle du canal de transmission, qui dépendent toutes deux du parrain.

---

## 4. Écarts — état

| # | Écart | Effort | État |
|---|---|---|---|
| 1 | Décider du modèle A ou B (section 2.4) | décision | **ouvert — à trancher avant le démarchage** |
| 2 | Double contrôle sur la génération/transmission d'un lot | 1-2 j | ✅ fait — script 44 (`s0120`), `wbfEftBatches` |
| 3 | Plafonds configurables (unitaire / fichier / jour / abonné) | 2-3 j | ✅ fait — script 44, `wbfEftBatches` + `wbfAbonne` |
| 4 | Calendrier de jours ouvrables, heure de tombée, heure de l'Est | 1-2 j | ✅ fait — script 44 (`T059`), `clsBusinessCalendar` |
| 5 | FCN : rebouclage sûr et contrôle d'unicité sur la période | 0,5 j | ouvert (le compteur reste correct jusqu'à 9999) |
| 6 | Chiffrement des coordonnées bancaires au repos | 2-3 j | ✅ fait — script 45 (AES-256, certificat) |
| 7 | Validateur 005 autonome (longueurs, totaux, séquences, cohérence Z) | 2-3 j | à la réception du guide |
| 8 | Réalignement complet du générateur sur le guide de l'IF | 3-5 j | à la réception du guide |
| 9 | Politique de réserve couvrant la fenêtre de **90 jours** des PAD personnels | modèle financier | avant contrat |

**Exploitation des correctifs** — trois points à retenir :

- **Deux comptes staff distincts sont désormais nécessaires** pour sortir un fichier : celui qui
  génère le lot ne peut pas l'approuver, et rien ne part sans approbation.
- Les **plafonds** se règlent dans « Configuration émetteur » (globaux) et sur la fiche de chaque
  abonné (quotidien par locataire). Vide = aucun plafond.
- Le **certificat de chiffrement doit être sauvegardé** hors de la base (voir la fin du script 45) :
  sans lui, une restauration sur un autre serveur rend les numéros de compte illisibles.
  Réglages facultatifs dans `Web.config` : `Eft.CutoffTime` (défaut 15:00), `Eft.HolidayScopes`
  (défaut `CA,QC`), `Eft.TimeZone` (défaut *Eastern Standard Time*).

---

## 5. Plan d'exécution

**Phase 0 — Préparation interne (semaines 1-4)**
Décision modèle A/B · écarts 2 à 5 · rédaction du dossier bancaire (annexe A) · sélection du conseil
juridique · démarrage des inscriptions LAPD et CANAFE.

**Phase 1 — Démarchage (semaines 3-12, en parallèle)**
Approcher **4 à 6 IF** simultanément (voir 5.1), une rencontre de cadrage chacune avec les questions
de l'annexe B. Ne pas s'exclusiver avant d'avoir deux offres.

**Phase 2 — Diligence et contrat (mois 3-6)**
Revue de crédit et de conformité, négociation des réserves et plafonds, signature de l'entente AFT
et de la LOU, obtention des identifiants d'émetteur.

**Phase 3 — Certification technique (mois 5-8)**
Écarts 7-8 · fichiers de test · test à faible montant avec retour NSF provoqué · parallèle.

**Phase 4 — Production graduelle (mois 7-10)**
Plafonds initiaux, surveillance quotidienne, relèvement progressif.

### 5.1 Où frapper

- **Banques à service commercial** : Banque Nationale, Desjardins (services aux entreprises),
  BMO, Scotia, RBC — groupes *Cash Management / Gestion de trésorerie*. Leurs guides PAD et dépôt
  direct pour entreprises sont publics et donnent le vocabulaire exact à employer.
- **Institutions spécialisées dans le parrainage de PSP** : Peoples Trust / Peoples Group (premier
  nouvel adhérent direct à l'ACSS depuis 1984), VersaBank, Equitable/Concentra, centrales de caisses
  (Central 1, Fédération des caisses Desjardins).
- **Ne pas négliger** l'IF où sont déjà nos comptes d'exploitation : la relation existante raccourcit
  la diligence.

### 5.2 Plan parallèle assumé (et recommandé)

Rien n'oblige à choisir. **Lancer commercialement via un agrégateur** (VoPay, Zum Rails, Payment
Source, Rotessa) pendant que le parrainage direct chemine : l'agrégateur porte le parrainage, on
livre des volumes réels, et **ces volumes sont exactement l'argument** qui débloque une entente
directe — les IF veulent un historique de retours, pas un plan d'affaires.

Notre architecture le permet sans dette : la génération et le transport sont déjà isolés derrière
`clsCpa005Builder` et `clsBankExchange` (interface `IBankTransport`). Un connecteur agrégateur
s'ajoute à côté, sans toucher au grand livre ni aux portails. **Passer en direct plus tard = changer
de connecteur, pas de plateforme.**

---

## Annexe A — Check-list du dossier bancaire

- [ ] Statuts constitutifs, registre des actionnaires, structure de propriété (bénéficiaires ultimes)
- [ ] CV et pièces d'identité des dirigeants ; enquêtes de sécurité
- [ ] États financiers (2-3 ans) ou prévisionnels et plan de capitalisation
- [ ] Attestation d'inscription LAPD (Banque du Canada) — ou preuve de dépôt de la demande
- [ ] Attestation d'inscription ESM (CANAFE) — ou preuve de dépôt
- [ ] Permis AMF si requis — ou avis juridique expliquant pourquoi il ne l'est pas
- [ ] Programme AML/LRPCFAT écrit et nom de l'agent de conformité
- [ ] Politique KYB d'acceptation des abonnés (référence : `clsKyb`, `T057KybCheck`)
- [ ] Politique de limites, de réserve et de traitement des retours
- [ ] Volumes projetés : nombre de transactions, montant moyen, montant maximal, pointe mensuelle
- [ ] Liste des secteurs servis et des secteurs interdits
- [ ] Schéma du flux de fonds et description du compte fiducie
- [ ] Architecture technique, sécurité et plan de reprise (extraits de `ARCHITECTURE.md` et
      `INFRA_PRODUCTION_HARDENING.md`)
- [ ] Description du processus de génération, d'approbation et de transmission des fichiers 005
- [ ] Modèle de contrat abonné et modèle d'entente de PAD du payeur (conforme H1)
- [ ] Preuves d'assurance : responsabilité professionnelle, cyber, détournement
- [ ] Attestation de test d'intrusion, si disponible

## Annexe B — Questions à poser à chaque IF dès le premier appel

1. Acceptez-vous un émetteur qui **initie pour le compte de tiers** (plateforme multi-locataire) ?
   Si oui, en **payee-of-record unique** ou avec un **numéro d'émetteur par sous-marchand** ?
2. Quels **codes d'opération CPA** nous autorisez-vous (débits PAD, crédits, transferts de fonds) ?
3. **Réserve** exigée : forme, pourcentage, durée ? Couvre-t-elle les 90 jours du recours PAD personnel ?
4. **Plafonds** initiaux (unitaire, fichier, journalier) et conditions de relèvement ?
5. **Canal de dépôt** : SFTP, portail, API ? Fréquence, heures de tombée, calendrier ?
6. Fournissez-vous un **environnement de test**, et quel est le délai de certification typique ?
7. Quels **fichiers de retour** recevons-nous (accusé, rejets à l'intake, retours/NSF), dans quel
   format et à quelle fréquence ?
8. Durée de la **revue de crédit et de conformité** ? Qui décide ?
9. Tarification : par fichier, par transaction, mensuelle, par retour/NSF ?
10. Conditions de **résiliation** et préavis (risque de *de-risking*) ?

## Annexe C — Sources

- Paiements Canada — [Norme 005 (échange de données financières sur les fichiers AFT)](https://www.payments.ca/sites/default/files/standard005eng.pdf)
- Paiements Canada — [Règle F1 (opérations AFT)](https://www.payments.ca/sites/default/files/f1eng.pdf)
- Paiements Canada — [Règle H1 (débits préautorisés), version 2026](https://www.payments.ca/sites/default/files/h1eng.pdf)
- Paiements Canada — [Participation des fournisseurs de services de paiement](https://www.payments.ca/connect/membership/payment-service-provider-participation)
- Paiements Canada — [Système de paiement de détail par lots (ACSS)](https://www.payments.ca/systems-services/payment-systems/retail-batch-payment-system)
- Paiements Canada — [Peoples Trust devient adhérent à l'ACSS](https://www.payments.ca/peoples-trust-company-become-new-direct-clearer-payments-canadas-acss)
- Gazette du Canada — [Règlement modifiant certains règlements administratifs (règle D1, retrait du seuil de 0,5 %)](https://gazette.gc.ca/rp-pr/p2/2020/2020-08-05/html/sor-dors167-eng.html)
- Banque du Canada — [Critères d'inscription des fournisseurs de services de paiement](https://www.bankofcanada.ca/2026/06/criteria-for-registering-payment-service-providers/)
- Banque du Canada — [Supervision des paiements de détail](https://www.bankofcanada.ca/regulatory-oversight/retail-payments/)
- Blakes — [Rapport annuel exigé des PSP inscrits sous la LAPD](https://www.blakes.com/insights/bank-of-canada-outlines-annual-reporting-requirements-for-registered-psps-under-the-retail-payment-a/)
- Osler — [CANAFE retire les exemptions de traitement de paiements (PI-7670)](https://www.osler.com/en/insights/updates/fintrac-retracts-merchant-servicing-and-payment-processing-exemptions/)
- CANAFE — [Entreprises de services monétaires](https://fintrac-canafe.canada.ca/msb-esm/msb-eng)
- McMillan — [Mise à jour du cadre des PAD (règle H1)](https://mcmillan.ca/insights/payments-canada-hits-refresh-on-pre-authorized-debit-framework-with-updates-to-rule-h1/)
- Banque Nationale — [Guide d'utilisation des prélèvements préautorisés](https://welcome.nbc.ca/content/dam/bnc/outils-apps/entreprises/guides/preauthorized-debits-user-guide.pdf)

---

*Ce document décrit une démarche réglementaire et bancaire ; il ne constitue pas un avis juridique.
Frais, délais et exigences doivent être revalidés auprès de chaque autorité et de chaque IF au
moment du dépôt.*
