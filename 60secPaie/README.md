# 60secPaie

Application Web de calcul de la paie pour un employeur du **Québec**.
ASP.NET Web Forms en **VB.NET** (.NET Framework 4.8), SQL Server, Visual Studio 2022/2026.
Le modèle fonctionnel est Nubis (voir [docs/analyse-nubis.md](docs/analyse-nubis.md)).

## Structure

| Dossier | Rôle |
|---|---|
| `src/60secPaie.Calcul` | Moteur de calcul, sans dépendance Web ni SQL : taux de l'année, catégories de paie, formules. |
| `src/60secPaie.Web` | Application Web Forms : pages, accès SQL (ADO.NET paramétré), sécurité, assistant de paie. |
| `src/60secPaie.Tests` | Tests MSTest : exemples chiffrés de Revenu Québec + cycle de paie complet sur LocalDB. |
| `Database` | Script du schéma SQL Server (relançable). |
| `docs` | Analyse de Nubis, guide TP-1015.F 2026 de Revenu Québec. |

## Démarrer

1. Créer la base : `sqlcmd -S "(localdb)\MSSQLLocalDB" -f 65001 -i Database\01_schema.sql`
2. Ouvrir `60secPaie.sln`, définir **60secPaie.Web** comme projet de démarrage, F5 (IIS Express, port 50960).
3. À la première visite, créer le compte administrateur, puis configurer la compagnie, les employés, et lancer **Calculer la paie**.

La chaîne de connexion `Paie` est dans `Web.config` (LocalDB par défaut).

## Ce que fait la version 1

- **Configuration** : compagnie (fréquence de paie, taux de vacances, FSS selon la masse salariale et le secteur, facteur AE, taux CNESST, CNT), éléments de paie.
- **Éléments de paie par catégorie système** : l'utilisateur ne configure jamais l'imposition. La catégorie porte l'assujettissement
  (impôt fédéral/Québec, AE, RRQ, RQAP, FSS, CNESST, vacances) et les cases T4 / Relevé 1. Voir `CategoriePaie.vb`.
- **Employés** : fiche complète, TD1 / T1213, TP-1015.3 / TP-1016, exemptions, dépôt direct, gabarit de paie récurrent, cumulatifs de départ (conversion en cours d'année).
- **Assistant de paie en 4 étapes** : période → employés et lignes → révision (avec rapport de vérification des formules) → confirmation (numérotation des chèques).
- **Historique** par lot, détail en 3 colonnes (revenus, déductions, parts de l'employeur), talon de paie imprimable avec cumulatifs et solde de vacances, annulation de la dernière paie.
- **Calculs** : impôt fédéral (T4127, employé du Québec : abattement de 16,5 %, K2Q), impôt du Québec (TP-1015.F), RRQ et 2e cotisation supplémentaire,
  AE au taux du Québec, RQAP, FSS, CNESST, CNT, paiements forfaitaires (bonus, rétroactif), indemnité de vacances.

## Taux gouvernementaux

Les taux sont dans `src/60secPaie.Calcul/ParametresAnnee.vb`. **Seule l'année 2026 est définie.**
Chaque année (et lors d'une mise à jour de mi-année), ajouter un `Case` à partir de :

- ARC, guide **T4127** - Formules pour le calcul des retenues sur la paie ;
- Revenu Québec, guide **TP-1015.F** - Formules pour le calcul des retenues à la source et des cotisations.

Les tests `Annexe…` reproduisent les exemples chiffrés du TP-1015.F 2026 au cent près : les mettre à jour avec les exemples du nouveau guide.

### À valider avant d'utiliser en production

- **CNESST / CNT** : le salaire maximum assurable (103 000 $) et le taux de la CNT (0,06 %) de 2026 sont à confirmer auprès de la CNESST.
- **Impôt fédéral** : comparer quelques paies avec le calculateur en ligne de l'ARC (PDOC). L'impôt du Québec peut être comparé avec WebRAS.
- Faire une **paie en parallèle** avec Nubis pendant quelques périodes et comparer les talons.

### Simplifications connues

- Méthode des paiements réguliers (pas la méthode cumulative moyenne pour les commissions).
- Le crédit K2Q utilise les cotisations théoriques de la période annualisées (il ne chute pas lorsque le maximum annuel est atteint).
- Le montant de base fédéral n'est pas réduit pour les revenus supérieurs à 181 440 $ : inscrire le montant TD1 voulu dans la fiche.
- RRQ : pas de proratisation des maximums selon le nombre de mois (employé qui atteint 18 ans, retraité, décès).

## Sécurité

- Authentification par formulaire, mots de passe hachés PBKDF2-SHA256 (120 000 itérations), verrouillage après 5 échecs.
- NAS et numéro de compte **chiffrés en base** (`MachineKey.Protect`) et jamais renvoyés au navigateur (masqués).
  **En production, définir une `machineKey` fixe** dans la configuration du serveur, sinon ces données deviennent illisibles après un changement de serveur.
- Requêtes SQL paramétrées, sorties HTML encodées, ViewState chiffré et lié à l'utilisateur (anti-CSRF), en-têtes de sécurité.
- En production : HTTPS obligatoire (`Web.Release.config` active `requireSSL`), chaîne de connexion hors du dépôt.

### Utilisateurs et mots de passe

- **Mon compte** (clic sur son courriel, en haut à droite) : changer son nom et son mot de passe (le mot de passe actuel est exigé).
- **Configuration → Utilisateurs** (administrateurs seulement) : créer un utilisateur avec un mot de passe temporaire, le rendre administrateur,
  le désactiver, le déverrouiller, réinitialiser son mot de passe. Après une création ou une réinitialisation, la personne **doit choisir un nouveau
  mot de passe** à sa prochaine connexion. Il reste toujours au moins un administrateur actif ; on ne peut pas se désactiver soi-même.
- **Gardez deux administrateurs.** Si le seul administrateur perd son mot de passe, il faut passer par SQL Server : supprimer sa ligne dans
  `dbo.Utilisateur` s'il est le seul utilisateur (la page « Première utilisation » réapparaît), sinon demander à quelqu'un qui a accès à la base.

## Tests

```
msbuild 60secPaie.sln -restore
vstest.console src\60secPaie.Tests\bin\Debug\net48\60secPaie.Tests.dll
```

Les tests d'intégration recréent la base jetable `60secPaie_Test` sur LocalDB ; ils ne touchent jamais à la base `60secPaie`.

## Phase 2 (à venir)

Paiement des retenues (remises fédérales et provinciales) et historique, T4 / Relevés 1 et sommaires, déclaration des salaires CNESST,
rapport d'écritures comptables (GL), rapport de vacances, fichier de dépôt direct, envoi des talons par courriel, gestion des utilisateurs.
