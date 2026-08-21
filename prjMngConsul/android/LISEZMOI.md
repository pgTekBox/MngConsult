# Répertoire de distribution Android (APK)

Déposez ici le paquet Android de l'application mobile **60sec-AI**.

## Fichier attendu

N'importe quel fichier `*.apk` déposé dans ce répertoire, par exemple :

```
android/ca.sixtysec.app.apk
```

Le nom n'a pas d'importance : le site sert le `*.apk` du répertoire, et le
plus récent s'il y en a plusieurs. Le visiteur télécharge le fichier **sous
son nom réel**, et c'est ce même nom qu'affiche le guide d'installation de la
page « Application mobile ».

Si le répertoire est vide, cette page affiche l'état « bientôt disponible » au
lieu du bouton de téléchargement (aucune erreur, aucun lien mort).

## Fichier de version (optionnel)

```
android/version.txt
```

Une seule ligne, par exemple :

```
1.0.3
```

Ce numéro est affiché sur la page de téléchargement. En son absence, la page
affiche seulement la taille du fichier et sa date de publication.

## Comment le fichier est servi

Le téléchargement passe par le handler `AppAndroid.ashx` (et non par IIS en
statique) :

- URL publique : `/AppAndroid.ashx`
- Content-Type : `application/vnd.android.package-archive`
- Le nom de fichier proposé au navigateur est celui du fichier déposé

Avantage : aucun type MIME `.apk` à configurer dans IIS, et le répertoire
peut rester en dehors du dépôt Git.

## Construire l'APK

Depuis `MAUI/60SecAI` :

```
dotnet publish -f net10.0-android -c Release
```

L'APK signé se trouve ensuite sous
`bin/Release/net10.0-android/publish/`. Copiez-le ici tel quel, sans le
renommer.

## Code QR

La page de téléchargement affiche un code QR **généré côté serveur** (SVG
inline, aucun service externe appelé) qui encode l'URL absolue de
`AppAndroid.ashx`. Il est produit par `App_Code/clsQrCode.vb`, qui s'appuie sur
le paquet NuGet **QRCoder** (MIT) pour l'encodage et dessine lui-même le SVG.

Rien à faire pour l'entretenir : l'URL est recalculée à chaque affichage à
partir du domaine servant la page, donc le même code fonctionne en
développement comme en production.

## Git

Les fichiers `*.apk` sont **exclus du dépôt** (voir `.gitignore` de ce
répertoire) : ce sont de gros binaires de build. Le fichier doit donc être
copié manuellement (ou par le script de déploiement) sur chaque serveur.
