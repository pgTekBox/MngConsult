# Analyse fonctionnelle de Nubis (modèle pour 60secPaie)

Exploration en lecture seule du 2026-09-17. Seule la **structure** des écrans est notée ici
(aucune donnée réelle d'employé, NAS, salaire ou numéro d'entreprise).

## 1. Navigation générale

| Menu | Route Nubis | Contenu |
|---|---|---|
| Tableau de bord | `/dashboard` | 4 raccourcis (Faites vos paies, Paiement des retenues, Historique de paie, Historique des paiements de retenues) + « Activités récentes » (journal : paie générée par X, retenues payées par X) |
| Paie | `/payroll` | Calculer la paie (assistant 4 étapes), Historique de paie, Rapport de vacances, Rapport d'éléments de paie |
| Retenues | `/remittance` | Paiement des retenues, Historique des paiements, Feuillets T4 et Relevés 1, Déclaration des salaires CAT/CNESST |
| Employés | `/employees` | Liste, fiche employé, éléments de paie de l'employé, ajustement de cumulatifs |
| Configuration | `/configuration` | Ma compagnie, Éléments de paie, Positions, Unités de classification, Plan comptable du grand livre |

Autres : multi-compagnies (« Créer une nouvelle compagnie »), multi-utilisateurs, API, aide contextuelle « ? » par page, bilingue FR/EN.

## 2. Configuration

### 2.1 Ma compagnie (onglets)
- **Informations de base** : nom, adresse (2 lignes), ville, province, code postal, téléphone, fax, courriel du contact principal, site web.
- **Informations de paie** : période de paie par défaut, estimation de la masse salariale (sert au taux FSS), facteur de cotisation employeur à l'AE (1,4 par défaut), taux de vacances par défaut, date de référence pour les vacances (mois/jour), prochain numéro de chèque, format de chèque (3 formats), fréquence de paiement des retenues fédérales / provinciales, numéro d'entreprise fédéral (NE) / provincial (NEQ-RQ), organisme gouvernemental (o/n), NAS propriétaires #1/#2, numéro de transmetteur T4, numéro d'agrément RPA/RPDB.
- **Revenu Québec (transfert électronique)** : numéro de préparateur Relevé 1, numéro d'identification RQ, numéro de dossier RQ, premier numéro attribué par RQ (numérotation des relevés).
- **Taux CAT / CNESST** : un taux par province (QC = CNESST).
- **Feuille de temps** : activer les feuilles de temps ; règles de temps supplémentaire en 3 étapes (A, B, C) : heures min./semaine, heures min./jour, taux (régulier / temps et demi / temps double), option (Payé / Accumulé).
- **Dépôt direct de l'entreprise** : institution financière, numéro d'émetteur, transit, institution, compte, prochain numéro de dépôt direct.

Périodes de paie supportées : 1 (annuel), 12 (mensuel), 13 (4 semaines), 24 (bimensuel), 26, 27 (2 semaines), 52, 53 (hebdo), 240 (quotidien).
Fréquences de remise : annuel, trimestriel, mensuel, bimensuel, aux 2 semaines, hebdomadaire.

### 2.2 Éléments de paie
Liste groupée par statut (Actif / Inactif), colonnes Nom + Type. Création : Description, **Catégorie de paie**, Actif,
« Ne pas afficher sur le talon », et pour la catégorie *Accumulateur* : accumulateur lié + type (Heures / Monétaire).

**Idée clé à reprendre** : l'utilisateur ne configure jamais l'imposition. Chaque élément pointe vers une
*catégorie système* qui porte la matrice d'assujettissement et les cases T4 / R1. Voir §6.

### 2.3 Positions
Simple liste (Description).

### 2.4 Unités de classification (CNESST)
Description + numéro de l'unité ; assignée à l'employé.

### 2.5 Plan comptable du grand livre
Pour chaque ligne : compte débit, sous-compte débit, compte crédit, sous-compte crédit.
- Comptes à payer : banque, ajustement de cumulatif, vacances à payer, impôt fédéral, impôt du Québec, RPC, RRQ, AE, RQAP (employé), puis parts employeur RQAP / RPC / RRQ / AE / FSS / CNESST (et WCB des autres provinces).
- Comptes de dépense : vacances, parts employeur (mêmes rubriques), puis **un compte par élément de paie** défini par l'utilisateur.

## 3. Employés

Liste : Nom, Téléphone, Courriel, Date de naissance, Date d'embauche ; actions par employé : Modifier, Éléments de paie, Ajustement de cumulatifs ; suppression par sélection.

### Fiche employé (onglets)
- **Base** : actif, code employé, prénom, second prénom, nom, adresse, ville, province (incl. Non-résident / hors province), code postal, pays, courriel, téléphone, date de naissance, langue (FR/EN).
- **Paie** : taux de vacances (défaut compagnie ou propre), position, NAS, province d'emploi, périodes de paie (défaut compagnie ou propre), date d'embauche, dernière date d'embauche, dernière date de terminaison, heures/semaine, taux horaire, salaire annuel ; règles de temps supplémentaire (défaut compagnie ou propres, étapes A/B/C).
- **Exemptions** (cases à cocher) : impôt fédéral, impôt provincial, RPC/RRQ, RQAP, AE, CAT/CNESST, FSS.
- **Imposition fédérale** : TD1 (code de demande 0-10 avec tranches de l'année, impôt additionnel à retenir, déduction zones visées, déductions annuelles T1213, autres crédits d'impôt) ; TD1X (rémunération totale + dépenses de commissions) ; AE (facteur employeur propre à l'employé).
- **Imposition provinciale** : TD1 provincial (hors QC) ; **TP-1015.3** (code de retenues A-N, X = exonéré ; impôt additionnel ; déductions ligne 19 ; exemption contribution santé) ; **TP-1016** (réduction accordée) ; unité de classification CNESST.
- **Notes** : texte libre.
- **Dépôt direct** : utilise le dépôt direct, envoyer le talon par courriel, transit, institution, compte.

### Éléments de paie de l'employé (gabarit de paie récurrent)
Grille : Catégorie de l'élément de paie | Heures travaillées | Taux horaire | Total. Sert de paie « par défaut » préremplie à chaque période.

### Ajustement de cumulatifs
Choix de l'année puis saisie des cumulatifs (soldes de départ lors d'une conversion en cours d'année).

## 4. Paie

### Assistant « Calculer la paie » (4 étapes)
1. **Période** : fréquence de paie, « Heures travaillées jusqu'au » (fin de période), « Payer le » (date de paie), prochain numéro de chèque.
2. Sélection des employés et saisie/ajustement des éléments (heures, taux, montants) — *non exploré (nécessite une soumission)*.
3. Révision des calculs — *non exploré*.
4. Confirmation / impression des chèques et talons — *non exploré*.

### Historique de paie
- Par lots (`/payroll/history/searchbatches`) ou par employé (`/payroll/history/searchemployees`).
- Détail d'un lot : par employé → période de paie, heures, paie brute, paie nette, vacances accumulées (taux) ; ventilation en 4 colonnes : **Revenus et avantages | Déductions | Parts de l'employeur | Cumulatifs annuels** ; grand total du lot.
- Actions : télécharger les chèques (lot ou individuel), rapport GL (écritures), rapport de paie ; annuler une paie tant que ses retenues ne sont pas payées.

### Rapports
Rapport de vacances (solde à une date), rapport d'éléments de paie (par employé et par dates).

## 5. Retenues (remises gouvernementales)
- **Paiement** : fréquence de paiement, retenues accumulées au (date), date du paiement, gouvernement (fédéral / provincial), province, paiement par chèque + numéro → « Calculer les retenues ».
- **Historique des paiements** (fédéral et provincial, par période).
- **T4 et Relevés 1** : par année, sélection d'employés → Générer le T4 / Générer le R1 (+ transmission électronique XML selon les numéros de transmetteur).
- **Déclaration des salaires CNESST** : année, mois, province.

## 6. Catégories de paie système (matrice d'assujettissement)

Colonnes : Impôt féd. | Impôt QC | AE | RRQ | RPC | RQAP | FSS | CNESST | Case T4 | Case R1 (O = assujetti, N = non).
**À valider contre les guides officiels (ARC T4001/T4130, Revenu Québec TP-1015.G) avant usage en production.**

### Revenus
| Catégorie | F | Q | AE | RRQ | RPC | RQAP | FSS | CNESST | T4 | R1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Salaire / Salaire fixe / Temps et demi / Temps double | O | O | O | O | O | O | O | O | 14 | A |
| Jours fériés / Congé de maladie / Paie de vacances / Vacances par paie / Paie de départ | O | O | O | O | O | O | O | O | 14 | A |
| Gratifications (bonus) / Avance de salaire / Autre revenu imposable / Régions éloignées | O | O | O | O | O | O | O | O | 14 | A |
| Commission (avec ou sans dépenses) | O | O | O | O | O | O | O | O | 14 & 42 | A & M |
| Pourboires contrôlés | O | O | O | O | O | O | O | O | 14 | A & S |
| Pourboires déclarés (attribués) | O | O | O | O | O | O | O | O | 14 | A & T |
| Pourboires directs | O | O | N | O | N | O | O | O | 14 | A & S |
| Autres allocations et avantages imposables | O | O | O | O | O | O | O | O | 14 & 40 | A & L |
| Indemnité compensatrice de préavis | O | O | O | N | O | O | N | N | 14 | O (RJ) |
| Allocation de retraite admissible | O | O | N | N | N | N | N | N | 66 | O (RJ) |
| Allocation de retraite non admissible | O | O | N | N | N | N | N | N | 67 | O (RJ) |
| Salaire rétroactif | N | N | N | N | N | N | O | O | 14 | A |
| Autre revenu non imposable | N | N | N | N | N | N | O | O | — | — |

### Avantages imposables
| Catégorie | F | Q | AE | RRQ | RPC | RQAP | FSS | CNESST | T4 | R1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Autre avantage monétaire | O | O | O | O | O | O | O | O | 14 & 40 | A & L |
| Autre avantage monétaire (fédéral seul.) | O | N | O | N | O | N | O | O | 14 & 40 | — |
| Autre avantage monétaire (Québec seul.) | N | O | N | O | N | O | O | O | — | A & L |
| Autre avantage non monétaire | O | O | N | O | O | N | O | O | 14 & 40 | A & L |
| Autre avantage non monétaire (fédéral seul.) | O | N | N | N | O | N | O | O | 14 & 40 | — |
| Autre avantage non monétaire (Québec seul.) | N | O | N | O | N | N | O | O | — | A & L |
| Nourriture et logement (monétaire) | O | O | O | O | O | O | O | O | 14 & 30 | A & V |
| Nourriture et logement (non monétaire) | O | O | N | O | O | N | O | O | 14 & 30 | A & V |
| Véhicule à moteur (monétaire) | O | O | O | O | O | O | O | O | 14 & 34 | A & W |
| Véhicule à moteur (non monétaire) | O | O | N | O | O | N | O | O | 14 & 34 | A & W |
| Régions éloignées (monétaire) | O | O | O | O | O | O | O | O | 14 & 40 | A & K |
| Régions éloignées (non monétaire) | O | O | N | O | O | N | O | O | 14 & 40 | A & K |
| Régime privé d'assurance maladie (monétaire) | N | O | N | O | N | O | O | O | 85 | A & J |
| Régime privé d'assurance maladie (non monétaire) | N | O | N | O | N | N | O | O | 85 | A & J |
| Régime d'assurance interentreprises (monétaire) | N | O | N | O | N | O | O | O | 85 | A & P |
| Régime d'assurance interentreprises (non monétaire) | N | O | N | O | N | N | O | O | 85 | A & P |
| Contribution employeur FondAction CSN / Fonds FTQ | O | O | N | N | N | N | N | N | 14 & 40 | A & L |
| Contribution employeur RVER | N | N | N | N | N | N | N | N | 14 & 40 | A & L |
| Régime de participation différée aux bénéfices | N | N | N | N | N | N | N | N | 20 | — |
| Avantage non imposable | N | N | N | N | N | N | N | N | — | — |

### Déductions (colonnes F/Q = « réduit le revenu imposable »)
| Catégorie | F | Q | T4 | R1 |
|---|---|---|---|---|
| REER | O | O | — | — |
| Régime de pension agréé (RPA) | N* | N* | 20 & 52 | D |
| Syndicat | O | N | 44 | F |
| Pension alimentaire | O | O | — | — |
| FondAction CSN / Fonds FTQ | O | O | — | — |
| Fonds de placement des travailleurs | O | N | — | — |
| Don de bienfaisance | N | N | 46 | N |
| Autre déduction | N | N | — | — |

\* tel qu'affiché par Nubis ; à vérifier (les cotisations RPA réduisent normalement le revenu imposable à la source).

### Gains ouvrant droit aux vacances (Québec)
Oui : salaire, salaire fixe, temps et demi, temps double, fériés, maladie, bonus, avance, commissions, pourboires (3 types), préavis, rétroactif, paie de vacances, autre revenu imposable.
Non : allocations de retraite, paie de départ, vacances par paie, allocations/avantages imposables, revenu non imposable, régions éloignées.
(Nubis maintient cette table pour les 13 provinces/territoires.)

## 7. Ce qui reste à voir (nécessite l'accord de l'utilisateur)
- Étapes 2 à 4 de l'assistant de paie (soumission de formulaire).
- Contenu des PDF : talon/chèque, rapport de paie, rapport GL, T4, R1 (téléchargements).
- Écran de calcul des retenues à payer, rapport de vacances, rapport d'éléments de paie, ajustement de cumulatifs (étape 2).
