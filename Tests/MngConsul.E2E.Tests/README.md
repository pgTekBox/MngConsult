# MngConsul.E2E.Tests — Smoke test

Vérifie que **chaque écran du menu** se charge sans erreur (HTTP < 400, pas de
redirection vers le login, pas de page d'erreur ASP.NET). Un test par écran (36).

## Prérequis
- Le site **prjMngConsul doit tourner** (Visual Studio / IIS Express).
  URL par défaut attendue : `http://localhost:53024`.
- Navigateur Playwright déjà installé (Chromium).
  Réinstaller au besoin : `pwsh bin/Debug/net9.0/playwright.ps1 install chromium`.

## Configuration (variables d'environnement)
| Variable | Rôle | Défaut |
|----------|------|--------|
| `MNG_BASEURL`  | URL du site                | `http://localhost:53024` |
| `MNG_EMAIL`    | Courriel d'un compte test  | *(obligatoire)* |
| `MNG_PASSWORD` | Mot de passe du compte     | *(obligatoire)* |

> Le compte doit être **actif**, avec abonnement + profil complétés
> (sinon le login redirige vers paiement / nouvel utilisateur et le test est ignoré).
> Utiliser de préférence une **compagnie de test** dédiée.

## Lancer
```powershell
$env:MNG_BASEURL  = "http://localhost:53024"
$env:MNG_EMAIL    = "test@exemple.com"
$env:MNG_PASSWORD = "********"
dotnet test
```

Sans `MNG_EMAIL` / `MNG_PASSWORD`, les tests sont **ignorés** (pas en échec) avec
un message explicatif.

## Comment ça marche
1. `LoginFixture` se connecte **une seule fois** via `wbfLogin.aspx` et sauvegarde
   la session (cookies) dans un fichier temporaire.
2. Chaque test recharge cette session, ouvre un écran et vérifie qu'il s'affiche
   sans erreur serveur.

## Étendre
- Ajouter un écran : une ligne dans le tableau `Screens` de `SmokeTests.cs`.
- Niveau suivant (Phase 2/3 de la stratégie) : tests des procédures `sNNNN`
  et parcours E2E (création de facture, encaissement, journal équilibré…).
