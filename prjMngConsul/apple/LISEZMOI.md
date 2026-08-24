# Répertoire de distribution Apple (iPhone / iPad)

Déposez ici le paquet iOS de l'application mobile **60sec-AI**.

## Deux fichiers, pas un seul

Contrairement à Android, une installation « par le site » sur iPhone ou iPad
exige **deux** fichiers :

```
apple/60secai.ipa          <- l'application signée en Ad Hoc
apple/manifest.plist       <- le descripteur d'installation
```

Le nom du `.ipa` n'a pas d'importance : le site prend le `*.ipa` du
répertoire, et le plus récent s'il y en a plusieurs. Le `manifest.plist`,
lui, doit porter ce nom exact.

Sans le manifeste, iOS ne sait pas quoi installer et la page affiche
« bientôt disponible » : le bouton n'apparaît que lorsque les deux fichiers
sont présents.

## Produire ces deux fichiers

Depuis Xcode : **Product > Archive**, puis **Distribute App > Ad Hoc**, en
cochant **Include manifest for over-the-air installation**. Xcode demande
alors l'URL de téléchargement — peu importe ce que vous saisissez, le site
réécrit cette URL à la volée vers sa propre adresse. Copiez ensuite le `.ipa`
et le `manifest.plist` produits dans ce répertoire.

La compilation et la signature exigent un Mac et le programme développeur
Apple.

## Ad Hoc : la limite à connaître

Une distribution Ad Hoc n'installe l'application que sur les appareils dont
l'**UDID a été enregistré** dans le profil de provisionnement, avec un
maximum de 100 appareils par type et par an. Un visiteur dont l'appareil
n'est pas enregistré verra l'installation échouer.

C'est une solution de test. La distribution ouverte passera par l'App Store,
et il suffira alors de renseigner dans `Web.config` :

```xml
<add key="Apple.AppUrl" value="https://apps.apple.com/..." />
```

Cette clé est prioritaire : dès qu'elle est remplie, la page pointe vers
l'App Store et ignore le contenu de ce répertoire.

## HTTPS obligatoire

iOS refuse l'installation sans lien `https` valide et certificat reconnu.
**En développement sur `http://localhost`, le bouton ne fonctionnera pas** :
c'est une limite d'iOS, pas du site. Le test réel demande le site publié en
HTTPS.

## Fichier de version (optionnel)

```
apple/version.txt
```

Une seule ligne, par exemple `1.0.3`. Affiché sur la page de téléchargement.

## Comment les fichiers sont servis

- `/AppApple.ashx` renvoie le `.ipa` sous son propre nom
- `/AppApple.ashx?manifest=1` renvoie le manifeste, avec l'URL du `.ipa`
  réécrite vers l'adresse réelle du site
- Le bouton de la page utilise `itms-services://` pointant sur ce manifeste

## Git

Les `*.ipa`, `*.plist` et `*.mobileprovision` sont **exclus du dépôt**. Ils
doivent être copiés à la main (ou par le script de déploiement) sur chaque
serveur.
