<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="LandingPage.aspx.vb" Inherits="MngConsul.LandingPage" %>
<!doctype html>
<html lang="fr-CA">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>60secondes</title>
<meta name="description" content="60secondes — quatorze fonctions intégrées pour l'administration financière des travailleurs autonomes et des petites sociétés du Québec et du Canada. Données hébergées et traitées au Québec et au Canada. Français, English, Español.">
<meta property="og:title" content="60secondes — votre administration financière 100 % automatisée">
<meta property="og:description" content="14 fonctions, 1 seul abonnement, dès 79,99 $/mois. Pour les travailleurs autonomes et les PME de 0 à 49 employés. Données au Québec et au Canada.">
<meta property="og:type" content="website">
<meta property="og:site_name" content="60secondes">
<meta property="og:url" content="https://60secondes.ca/">
<meta property="og:image" content="https://60secondes.ca/og-60secondes.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="60secondes — Unir pour grandir. Lancement le 1er janvier 2027.">
<meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="https://60secondes.ca/">
<link rel="alternate" hreflang="fr-CA" href="https://60secondes.ca/">
<link rel="alternate" hreflang="en-CA" href="https://60secondes.ca/en/">
<link rel="alternate" hreflang="es" href="https://60secondes.ca/es/">
<link rel="alternate" hreflang="x-default" href="https://60secondes.ca/">
<meta property="og:locale" content="fr_CA">
<meta property="og:locale:alternate" content="en_CA">
<meta property="og:locale:alternate" content="es_ES">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,650;12..96,800&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<link rel="stylesheet" href="css/landing2.css?v=%%V%%" />
</head>
<body>

<p id="lang-notice" role="status" hidden></p>
<div id="app">
<a class="skip" href="#contenu">Aller au contenu</a>
<header class="top">
  <div class="wrap">
    <a class="logo" href="#top" aria-label="60secondes, accueil">
      <span>60<b>secondes</b></span>
    </a>
    <nav class="main" aria-label="Sections">
      <a href="#economies">Concurrence</a>
      <a href="#profils">Profils et prix</a>
      <a href="#transfert">Transfert</a>
      <a href="#fonctions">Fonctions</a>
      <a href="#cortex">Cortex</a>
      <a href="#cabinets">Cabinets</a>
    </nav>
    <div class="actions">
      <div class="qcb">
        <button type="button" class="qc-badge" id="qc-btn" title="100 % Québec, Canada" aria-expanded="false" aria-controls="qc-pop"><span class="qc-f" aria-hidden="true"><svg class="flag" viewBox="0 0 30 20" width="32" height="21" aria-hidden="true"><rect width="30" height="20" fill="#0F4DA5"/><rect x="13" width="4" height="20" fill="#fff"/><rect y="8" width="30" height="4" fill="#fff"/><g fill="#fff"><circle cx="6.5" cy="4" r="1.6"/><circle cx="23.5" cy="4" r="1.6"/><circle cx="6.5" cy="16" r="1.6"/><circle cx="23.5" cy="16" r="1.6"/></g></svg><svg class="flag" viewBox="0 0 30 20" width="32" height="21" aria-hidden="true"><rect width="30" height="20" fill="#fff"/><rect width="7.5" height="20" fill="#D52B1E"/><rect x="22.5" width="7.5" height="20" fill="#D52B1E"/><path d="M15 4.5l1 2 1.2-.6-.4 2.8 1.8-1.7.5 1.1 1.8-.4-.7 2 .9.5-3 2.4.4 1.1-2.9-.4v2.6h-1.2v-2.6l-2.9.4.4-1.1-3-2.4.9-.5-.7-2 1.8.4.5-1.1 1.8 1.7-.4-2.8 1.2.6z" fill="#D52B1E"/></svg></span><span class="qc-t">100&nbsp;% Québec, Canada</span><span class="sr">Données hébergées et traitées au Québec et au Canada</span></button>
        <div class="qc-pop" id="qc-pop" role="dialog" aria-label="100 % Québec, Canada" hidden>
          <b>100&nbsp;% Québec, Canada</b>
          <p>Vos données sont hébergées et traitées au Québec et au Canada. Elles ne quittent jamais le Canada.<sup class="n"><a href="#note-5" aria-label="Note 5">5</a></sup></p>
          <ul><li>Hébergement</li><li>Traitement</li><li>Transit</li></ul>
          <p class="qc-own">Renseignements personnels protégés selon la Loi 25 (Québec) et la LPRPDE (Canada)<sup class="n"><a href="#note-13" aria-label="Note 13">13</a></sup>. Entreprise québécoise, siège social à Montréal.</p>
        </div>
      </div>
      <div class="langsw" role="group" aria-label="Langue · Language · Idioma">
        <button type="button" data-lang="fr" lang="fr" aria-pressed="true" title="Français">FR</button>
        <button type="button" data-lang="en" lang="en" aria-pressed="false" title="English">EN</button>
        <button type="button" data-lang="es" lang="es" aria-pressed="false" title="Español">ES</button>
      </div>
      <a class="btn btn-ghost" href="#connexion">Se connecter</a>
      <a class="btn btn-primary" href="#membres">Réserver<span class="hide-s"> ma place</span></a>
    </div>
  </div>
</header>

<main id="contenu" tabindex="-1">
<span id="top"></span>

<!-- HERO -->
<section class="hero" aria-labelledby="h-hero">
  <div class="wrap">
    <div>
      <p class="hero-launch"><span aria-hidden="true">●</span><b>Lancement le 1<sup>er</sup> janvier 2027</b></p>
      <p class="eyebrow">Travailleurs autonomes et PME de 0 à 49 employés</p>
      <h1 id="h-hero" style="margin-top:16px">Votre administration financière <em>100&nbsp;% automatisée</em>.<sup class="n"><a href="#note-6" aria-label="Note 6">6</a></sup></h1>
      <p class="punch">Vous pouvez maintenant vous concentrer sur vos clients&nbsp;!</p>
      <p class="lead">60secondes lit vos factures, reçus et relevés, tient vos livres et prépare vos taxes, votre paie et vos paiements.</p>
      <ul class="hchips"><li><b>14</b> fonctions</li><li><b>1</b> seul abonnement</li><li>dès <b>79,99&nbsp;$</b>/mois</li></ul>
      <div class="ctas">
        <a class="btn btn-primary" href="#membres">Réserver ma place</a>
        <a class="btn btn-ghost" href="#profils">Voir les prix</a>
      </div>
    </div>

    <div class="hero-r">
    <div class="phone" aria-label="Aperçu de l'application 60secondes sur cellulaire">
      <div class="phone-in">
        <div class="phone-bar" aria-hidden="true"><span>7:02</span><span class="phone-notch"></span><span class="phone-ic"><i></i><i></i><i></i></span></div>
    <div class="cxh pd" role="figure" aria-label="Exemple fictif : le tableau de bord 60secondes sur cellulaire">
      <div class="pd-top">
        <div><p class="pd-hi">Bonjour Marie</p><p class="pd-date">Mardi 15 septembre</p></div>
        <span class="cxh-st" id="cxh-st">1 décision</span>
      </div>
      <div class="pd-60">
        <span class="cxh-av" id="cxh-av"><span class="av-slot" data-av="action" data-size="44"></span></span>
        <p class="pd-bub">Tout roule ce matin : j'ai classé 36 pièces. Il me manque juste <b>une réponse</b> de votre part.</p>
      </div>
      <div class="pd-cash">
        <p class="pd-k">Encaisse prévue au 30 septembre</p>
        <p class="pd-big num">11&nbsp;930&nbsp;$</p>
        <svg class="pd-spark" viewBox="0 0 120 28" preserveAspectRatio="none" aria-hidden="true"><polyline points="0,20 15,18 30,21 45,14 60,16 75,10 90,12 105,7 120,9" fill="none" stroke="#7FE0C6" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>
        <p class="pd-ok">✓ Suffisante après la paie et les remises</p>
      </div>
      <div class="pd-tiles">
        <div><span>À recevoir</span><b class="num">8&nbsp;420&nbsp;$</b><small>3 factures</small></div>
        <div><span>À payer</span><b class="num">2&nbsp;214&nbsp;$</b><small>DAS · 15 oct.</small></div>
        <div><span>Taxes</span><b class="num">1&nbsp;842&nbsp;$</b><small>TPS/TVQ · 31 oct.</small></div>
      </div>
      <div class="q-box cxh-q">
        <p class="cxh-k">Votre décision</p>
        <p class="qhead"><span>Esso, 68,40&nbsp;$, le 14 septembre : déplacement pour un client ou usage personnel&nbsp;?</span></p>
        <div class="opts" role="group" aria-label="Répondre à Cortex">
          <button class="opt" type="button" data-ans="affaires">Affaires</button>
          <button class="opt" type="button" data-ans="personnel">Personnel</button>
          <button class="opt" type="button" data-ans="partage">Partagé 60&nbsp;/&nbsp;40</button>
        </div>
        <p class="learned" id="learned" aria-live="polite" hidden></p>
      </div>
      <div class="cxh-meter">
        <div class="cxh-bar"><span id="cxh-fill" style="width:97.3%"></span></div>
        <p><b class="num" id="cxh-n">36 sur 37</b> pièces traitées sans vous · <span id="cxh-pct">97&nbsp;%</span> <small class="cxh-fic">· fictif<sup class="n"><a href="#note-12" aria-label="Note 12">12</a></sup></small></p>
      </div>
      <nav class="pd-tab" aria-hidden="true">
        <span class="on"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg>Accueil</span>
        <span><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/></svg>Pièces</span>
        <span><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M17 11h4M19 9v4"/></svg>Paie</span>
        <span><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/></svg>Paiements</span>
      </nav>
    </div>
        <div class="phone-home" aria-hidden="true"></div>
      </div>
    </div>
    </div>
    <div class="hlinks">
      <div class="hm2" role="note" aria-label="Pourquoi 60secondes">
        <p class="hm2-t">Votre entreprise avance parce que ses gens se parlent. <span>Vos outils, eux, sont isolés&nbsp;: ils divisent pour régner.</span></p>
        <p class="hm2-r">60secondes réunit tout. <b>Unir pour grandir.</b></p>
      </div>
      <div class="htrust">
        <p class="hl-k"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg> Vos données en sécurité</p>
        <ul>
          <li>Données au Québec et au Canada</li>
          <li>Chiffrement en transit et au repos</li>
          <li>Double authentification</li>
          <li>Conforme Loi 25 et LPRPDE</li>
        </ul>
      </div>
      <div class="hcab">
      <button type="button" class="hl" data-cab-open="list">
        <span class="hl-i" aria-hidden="true"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 7h8M8 11h2M12 11h2M16 11v6M8 15h2M12 15h2"/></svg></span>
        <span class="hl-t"><b>Choisir mon cabinet comptable</b><span>Choisissez un cabinet certifié ou invitez le vôtre ; vous décidez ensemble de ce qu'il peut faire dans votre dossier.</span></span>
        <span class="hl-go" aria-hidden="true">Trouver ›</span>
      </button>
      </div>
    </div>
    <div class="pv-rdv pv1 pv2">
      <span class="pv2-i" aria-hidden="true"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4M9 15l2 2 4-4"/></svg></span>
      <div class="pv2-t">
        <p class="pv2-k">En prime · fonction 11, incluse</p>
        <p class="pv2-h">Vos clients réservent vos services en ligne, 24 h sur 24.</p>
        <p class="pv2-s">Massothérapie, coiffure, physiothérapie, plomberie… Le rendez-vous entre dans votre agenda et prépare la facture.</p>
      </div>
      <button type="button" class="btn pv2-b" data-an-find data-q="massothérapeute">Je suis un citoyen et je désire prendre RDV avec un spécialiste ›</button>
    </div>
  </div>
</section>

<!-- COMMENT ÇA MARCHE -->
<section class="s how3" id="comment" aria-labelledby="h-how3">
  <div class="wrap">
    <div class="s-head how3-head">
      <p class="eyebrow">Comment ça marche</p>
      <h2 id="h-how3">Trois étapes. Ensuite, Cortex s'occupe du reste.</h2>
    </div>
    <ol class="how3-steps">
      <li><span class="how3-n">1</span><h3>Réservez votre place</h3><p>Accès anticipé gratuit et sans engagement. Lancement le 1<sup>er</sup> janvier 2027.</p></li>
      <li><span class="how3-n">2</span><h3>On transfère vos données</h3><p>Gratuitement et en quelques minutes, depuis votre logiciel actuel : vous-même, votre comptable ou un cabinet certifié.</p></li>
      <li><span class="how3-n">3</span><h3>Cortex s'occupe du reste</h3><p>Il lit, classe, calcule et prépare. Vous répondez seulement aux questions qui méritent votre avis.</p></li>
    </ol>
    <div class="how3-cta"><a class="btn btn-primary" href="#membres">Réserver ma place</a></div>
  </div>
</section>

<!-- CALCULATEUR -->
<section class="s alt calc" id="economies" aria-labelledby="h-calc">
  <div class="wrap">
    <div class="s-head">
      <p class="eyebrow">60secondes face à la concurrence</p>
      <h2 id="h-calc">Un système comptable complet. Quatorze fonctions. Comparez chacune.</h2>
      <p class="lead">Au centre, le système comptable. Autour, les treize autres fonctions du même abonnement. Touchez une fonction pour savoir à quoi elle sert et ce que son intégration au système comptable vous apporte ; « Voir la concurrence » montre ce qui existe ailleurs : éditeur, pays et prix.</p>
    </div>

    <div class="bk2-bar">
      <div class="bk2-seg" role="group" aria-label="Votre profil">
        <button type="button" data-kp="ta" aria-pressed="true">Travailleur autonome<small>79,99 $ / mois</small></button>
        <button type="button" data-kp="c0" aria-pressed="false">Société sans employé<small>99,99 $ / mois</small></button>
        <button type="button" data-kp="c4" aria-pressed="false">Société avec employés<small>149,99 $ / mois</small></button>
      </div>
      <div class="bk2-quick" hidden><button type="button" id="k-all">Panier type</button><button type="button" id="k-none">Vider le panier</button></div>
    </div>

    <div class="bk2-g">
<div class="k-left">
      <div class="k-orbit" id="k-orbit" aria-label="Les 14 fonctions de 60secondes autour du centre">
        <svg class="k-lines" id="k-lines" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"></svg>
        <div class="k-coin" id="k-coin">
          <div class="k-coin-in">
            <button type="button" class="k-face k-front" id="k-front"></button>
            <button type="button" class="k-face k-back" id="k-back" tabindex="-1" aria-hidden="true"><span id="k-back-av"></span><b>Système comptable complet</b><span class="yr" id="k-back-yr"></span><span>60secondes · les 14 fonctions</span></button>
          </div>
        </div>
        <button type="button" class="k-flip k-cmp0" id="k-flip" aria-label="Système comptable complet : voir la concurrence"><span id="k-flip-t">Voir la concurrence ›</span></button>
      </div>
      <p class="k-cap" id="k-cap" aria-live="polite"></p>
      <p class="k-cta"><a class="btn btn-gold" href="#membres" data-pick-calc>Réserver ma place</a></p>
      <details class="k-src"><summary>Sources et méthode des prix</summary><p class="bk2-fine">Prix publics consultés en septembre 2026, avant taxes, pour une société de 4 employés et un professionnel au calendrier ; couverture des fonctions selon ce que chaque éditeur offre dans le produit retenu ; gammes de prix : du forfait le moins cher au plus cher des grilles publiées, par année (Momenteo : 14,90 $ US convertis au taux du 16 septembre 2026 ; Nethris : 22,46 $ par période de paie aux deux semaines) ; Mailchimp + Twilio : forfait Mailchimp gratuit ou Standard (0 à 20 $ US par mois, 500 contacts) plus 200 textos par mois à 0,0083 $ US chacun, frais des opérateurs de 0,0047 à 0,0087 $ US et numéro à 1,15 $ US par mois, convertis au même taux ; seuls les produits dont le prix est publié sont retenus. Drapeau : pays de l'éditeur. Marques citées à titre de comparaison, sans affiliation (<a href="#note-1">note 1</a>, <a href="#note-2">note 2</a>).</p></details>
      <div class="k-scrim" id="k-scrim" hidden></div><div class="k-pick" id="k-pick" role="dialog" aria-modal="false" aria-label="Choix d'un produit" hidden></div>
      <h3 class="k-bag-h" hidden>Votre panier</h3>
      <ul class="k-bag" id="k-bag" aria-label="Produits dans votre panier" hidden></ul>
      <p class="bk2-mini" id="k-mini" aria-hidden="true" hidden></p>
      </div>

      <aside class="bk2-out" aria-labelledby="k-out-h" hidden>
        <h3 id="k-out-h" class="sr">Résultat de la comparaison</h3>
        <div class="bk2-say"><span id="k-face" aria-hidden="true"></span><p id="k-say" aria-live="polite"></p></div>
        <div class="bk2-chart" id="k-chart" role="img" aria-label=""></div>
        <p class="bk2-big"><span class="lbl" id="k-big-l">Vous économisez</span><b class="num" id="k-big">—</b><span class="per">par année</span></p>
        <ul class="bk2-count">
          <li><b id="k-v">0</b><span>fournisseurs<br><small>contre 1</small></span></li>
          <li><b id="k-f">0</b><span>factures par année<br><small>contre 12</small></span></li>
          <li><b id="k-l">0</b><span>ententes Loi 25 à évaluer<br><small>contre 1</small></span></li>
          <li><b id="k-x">0/14</b><span>fonctions accessibles sur les 14 nécessaires<br><small>contre 14 sur 14</small></span></li>
          <li class="kfl" id="k-fl"></li>
        </ul>
        <a class="btn btn-gold" href="#membres" data-pick-calc>Réserver ma place</a>
        <p class="bk2-fine">Prix publics consultés en septembre 2026, avant taxes, pour une société de 4 employés et un professionnel au calendrier ; couverture des fonctions selon ce que chaque éditeur offre dans le produit retenu ; gammes de prix : du forfait le moins cher au plus cher des grilles publiées, par année (Momenteo : 14,90 $ US convertis au taux du 16 septembre 2026 ; Nethris : 22,46 $ par période de paie aux deux semaines) ; Mailchimp + Twilio : forfait Mailchimp gratuit ou Standard (0 à 20 $ US par mois, 500 contacts) plus 200 textos par mois à 0,0083 $ US chacun, frais des opérateurs de 0,0047 à 0,0087 $ US et numéro à 1,15 $ US par mois, convertis au même taux ; seuls les produits dont le prix est publié sont retenus. Drapeau : pays de l'éditeur. Marques citées à titre de comparaison, sans affiliation (<a href="#note-1">note 1</a>, <a href="#note-2">note 2</a>).</p>
      </aside>
    </div>
  </div>
</section>

<!-- PROFILES -->
<section class="s profiles-sec" id="profils" aria-labelledby="h-prof">
  <div class="wrap">
    <div class="s-head">
      <p class="eyebrow">Pour qui</p>
      <h2 id="h-prof">Trois profils, trois forfaits. Lequel est le vôtre&nbsp;?</h2><span id="prix"></span>
      <p class="lead">60secondes est pensé pour les entreprises que les logiciels comptables servent mal : celles qui n'ont personne pour tenir les livres. Choisissez votre profil ; la page s'y ajuste.</p>
    </div>
    <div class="pcards">
      <article class="pcard" data-profile="ta">
        <div class="ptop"><span class="pnum">Profil 1</span><span class="pprice num">79,99&nbsp;$<small>/mois</small></span></div>
        <h3>Travailleur autonome</h3>
        <p class="pwho">Vous facturez à votre nom, sans société incorporée.</p>
        <p class="ppain">« 4 à 11 heures de paperasse par mois, et le rush du 30 avril. »</p>
        <ul class="pdo">
          <li>Sépare les dépenses d'affaires et personnelles</li>
          <li>Facture, relance et suit vos encaissements</li>
          <li>Calcule et prépare TPS/TVQ et acomptes</li>
        </ul>
        <p class="pinc">Inclus : les 14 fonctions, dont Cortex et le lien avec votre comptable.</p>
        <div class="pact">
          <a class="btn btn-primary" href="#membres" data-pick="ta">Réserver ma place</a>
          <a class="plink" href="#cortex" data-see="ta">Ce que Cortex fait pour moi →</a>
        </div>
      </article>
      <article class="pcard" data-profile="c0">
        <div class="ptop"><span class="pnum">Profil 2</span><span class="pprice num">99,99&nbsp;$<small>/mois</small></span></div>
        <h3>Société sans employé</h3>
        <p class="pwho">Vous êtes incorporé et seul à bord.</p>
        <p class="ppain">« La rigueur d'une société, sans personne pour la tenir. »</p>
        <ul class="pdo">
          <li>Tient le compte de l'actionnaire à jour</li>
          <li>Qualifie salaire, dividendes et remboursements</li>
          <li>Garde les livres prêts pour la fin d'exercice</li>
        </ul>
        <p class="pinc">Inclus : tout le profil 1, plus la comptabilité de société et la fin d'exercice.</p>
        <div class="pact">
          <a class="btn btn-primary" href="#membres" data-pick="c0">Réserver ma place</a>
          <a class="plink" href="#cortex" data-see="c0">Ce que Cortex fait pour moi →</a>
        </div>
      </article>
      <article class="pcard" data-profile="c4">
        <div class="ptop"><span class="pnum">Profil 3</span><span class="pprice num">149,99&nbsp;$<small>/mois</small></span></div>
        <h3>Société avec employés</h3>
        <p class="pwho">Vous avez une équipe, de 1 à 49 employés<sup class="n"><a href="#note-8" aria-label="Note 8">8</a></sup>.</p>
        <p class="ppain">« Paie, remises et horaires : tout grandit avec l'équipe. »</p>
        <ul class="pdo">
          <li>Transforme les heures poinçonnées en paie</li>
          <li>Prépare les DAS, relevés 1 et T4</li>
          <li>Donne à chaque employé son application</li>
        </ul>
        <p class="pinc">Inclus : tout le profil 2, plus paie, DAS, relevés et application employé. 4 employés inclus, puis 2&nbsp;$/mois par employé.</p>
        <div class="pact">
          <a class="btn btn-primary" href="#membres" data-pick="c4">Réserver ma place</a>
          <a class="plink" href="#cortex" data-see="c4">Ce que Cortex fait pour moi →</a>
        </div>
      </article>
    </div>
    <p class="pfine"><span>Les 14 fonctions dans chaque forfait</span><span>Prix en dollars canadiens, par mois, avant TPS et TVQ<sup class="n"><a href="#note-2" aria-label="Note 2">2</a></sup></span><span>Sans engagement : résiliable en tout temps</span><span>Aucun paiement pour réserver votre place</span></p>
    <a class="firm-strip" href="#cabinets">
      <span><strong>Vous êtes un cabinet comptable&nbsp;?</strong> Vos clients de ces trois profils vous invitent dans leur dossier ; vous y travaillez en direct.</span>
      <span class="go">Espace cabinets →</span>
    </a>
  </div>
</section>

<!-- MIGRATION -->
<section class="s mig" id="transfert" aria-labelledby="h-mig">
  <div class="wrap">
    <div class="mig-top">
      <p class="eyebrow">Votre année financière est en cours&nbsp;?</p>
      <h2 id="h-mig">Changez en cours d'année. On transfère tout, gratuitement<sup class="n"><a href="#note-14" aria-label="Note 14">14</a></sup>.</h2>
      <p class="lead">Ce qui retient la plupart des entrepreneurs, c'est le transfert de leurs données. Chez 60secondes, ce n'est plus un obstacle.</p>
    </div>

    <ul class="mig-big" aria-label="Le transfert en trois chiffres">
      <li><b class="num">0&nbsp;$</b><span>Le transfert est inclus.</span></li>
      <li><b>Minutes</b><span>Pas des semaines.</span></li>
      <li><b>Tout</b><span>Votre système comptable et vos autres logiciels, paie comprise.</span></li>
    </ul>

    <div class="mig-who">
      <p class="mig-who-h">Qui s'en occupe&nbsp;? Vous choisissez.</p>
      <div class="mig-who-b">
        <button type="button" class="btn btn-ghost" data-chat-go>Moi, guidé par l'agent</button>
        <button type="button" class="btn btn-ghost" data-cab-open="own">Mon comptable</button>
        <button type="button" class="btn btn-primary" data-cab-open="list">Un cabinet certifié</button>
      </div>
      <p class="mig-fine">Pour avoir l'esprit tranquille, passez par un cabinet : il vérifie tout et confirme vos soldes. Ses honoraires, s'il y en a, relèvent de lui.</p>
    </div>

    <div class="ctas mig-ctas">
      <a class="btn btn-gold" href="#membres">Réserver ma place</a>
    </div>
  </div>
</section>

<!-- FUNCTIONS -->
<section class="s" id="fonctions" aria-labelledby="h-fn">
  <div class="wrap">
    <div class="s-head">
      <p class="eyebrow">Quatorze fonctions intégrées</p>
      <h2 id="h-fn">Chaque fonction fait son travail. L'intégration fait le reste.</h2>
      <p class="lead">Dans 60secondes, tout est « connecté » : une seule base, avec le même plan comptable et la même pièce justificative. Une information entrée une fois sert partout — c'est là que disparaissent les heures.</p>
    </div>

    <article class="fn core">
      <span class="ic" aria-hidden="true"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M12 2v4M12 18v4M2 12h4M18 12h4M5 5l2.8 2.8M16.2 16.2 19 19M5 19l2.8-2.8M16.2 7.8 19 5"/></svg></span>
      <div>
        <span class="tag">01 · Le centre de décision</span>
        <h3 style="font-size:24px;margin-top:10px">Cortex</h3>
        <p class="what" style="margin-top:8px">Il lit la boîte de courriel de votre entreprise, extrait chaque transaction, la classe, fait les calculs et passe l'écriture. Seuls les cas non élucidés vous sont présentés par Le 60, son avatar, dont la couleur indique l'action à poser<sup class="n"><a href="#note-6" aria-label="Note 6">6</a></sup>.</p>
      </div>
      <p class="plus"><b>Plus-value de l'intégration</b>Cortex alimente les treize autres fonctions : un document qui arrive devient une écriture, une taxe, une ligne de paie, un mouvement de stock, un paiement à approuver ou une question. Aucun éditeur ne vend cette fonction seule — elle n'existe que parce que tout est dans le même système.</p>
    </article>

    <div class="fam">
      <div class="fam-h"><h3>Ventes et comptabilité</h3><p>De la soumission au rapprochement bancaire.</p></div>
      <div class="fam-g" style="--n:5">
        <article class="fn"><span class="fnum">02</span><h3>Soumissions</h3><p class="what">Devis professionnels, envoi et suivi des acceptations.</p><p class="plus"><b>Plus-value</b>Le devis accepté devient une facture, sans ressaisie.</p></article>
        <article class="fn"><span class="fnum">03</span><h3>Comptabilité et facturation</h3><p class="what">Grand livre, plan comptable, factures, TPS/TVQ, états financiers à jour.</p><p class="plus"><b>Plus-value</b>Une facture émise est déjà un revenu, une taxe portée et un compte à recevoir suivi.</p></article>
        <article class="fn"><span class="fnum">04</span><h3>Inventaire</h3><p class="what">Stocks, mouvements et coût des marchandises vendues.</p><p class="plus"><b>Plus-value</b>Chaque vente et chaque achat font bouger le stock et le coût des ventes aux livres.</p></article>
        <article class="fn"><span class="fnum">05</span><h3>Capture des reçus</h3><p class="what">Photo au téléphone ou courriel transféré : commerçant, montant, taxes et date lus.</p><p class="plus"><b>Plus-value</b>Le reçu devient une écriture et justifie la sortie d'argent vue à la banque.</p></article>
        <article class="fn"><span class="fnum">06</span><h3>Conciliation financière</h3><p class="what">Comptes bancaires et cartes appariés en continu ; doublons écartés.</p><p class="plus"><b>Plus-value</b>Aucun produit autonome ne la vend<sup class="n"><a href="#note-1" aria-label="Note 1">1</a></sup> : ici, factures, paiements et relevés partagent déjà la même base.</p></article>
      </div>
    </div>

    <div class="fam">
      <div class="fam-h"><h3>Votre équipe</h3><p>Des heures travaillées jusqu'aux feuillets de fin d'année.</p></div>
      <div class="fam-g">
        <article class="fn"><span class="fnum">07</span><h3>Paie</h3><p class="what">Retenues RRQ, RQAP, AE et impôt, DAS, talons, relevé 1 et T4.</p><p class="plus"><b>Plus-value</b>Les heures deviennent la paie ; la paie devient écriture et remise préparée.</p></article>
        <article class="fn"><span class="fnum">08</span><h3>Gestion des employés</h3><p class="what">Dossiers, documents, absences et banques de temps.</p><p class="plus"><b>Plus-value</b>Une absence approuvée ajuste l'horaire et la paie du même coup.</p></article>
        <article class="fn"><span class="fnum">09</span><h3>Horaires, poinçon, géolocalisation</h3><p class="what">Horaires d'équipe, entrées et sorties, présence confirmée sur le lieu de travail<sup class="n"><a href="#note-9" aria-label="Note 9">9</a></sup>.</p><p class="plus"><b>Plus-value</b>Une heure poinçonnée sert à la paie et, si elle est facturable, à la facture du client.</p></article>
        <article class="fn"><span class="fnum">10</span><h3>Application mobile employé</h3><p class="what">Poinçon, horaire, talons de paie et documents dans la main de l'employé.</p><p class="plus"><b>Plus-value</b>Même compte, même base : aucune application tierce à ajouter.</p></article>
      </div>
    </div>

    <div class="fam">
      <div class="fam-h"><h3>Clients, fournisseurs et comptable</h3><p>Tout ce qui entre et sort de l'entreprise.</p></div>
      <div class="fam-g" style="--n:5">
        <article class="fn"><span class="fnum">11</span><h3>Agenda et rendez-vous</h3><p class="what">Réservation en ligne et calendrier adaptés à votre métier.</p><p class="plus"><b>Plus-value</b>Un rendez-vous complété prépare la facture du client.</p></article>
        <article class="fn"><span class="fnum">12</span><h3>Courriel et messagerie texte</h3><p class="what">Confirmations, rappels, relances et avis, hébergés au Québec et au Canada.</p><p class="plus"><b>Plus-value</b>Jamais de relance pour une facture payée ce matin.</p></article>
        <article class="fn"><span class="fnum">13</span><h3>Préparation des paiements</h3><p class="what">Fournisseurs, remises et paie : montants, échéances et lots prêts à déclencher.</p><p class="plus"><b>Plus-value</b>Vous déclenchez un paiement déjà vérifié, ou vous autorisez votre cabinet à le faire. 60secondes prépare ; il ne paie jamais<sup class="n"><a href="#note-4" aria-label="Note 4">4</a></sup>.</p></article>
        <article class="fn"><span class="fnum">14</span><h3>Lien avec le bureau comptable</h3><p class="what">Votre cabinet, invité dans votre dossier, avec les permissions que vous choisissez.</p><p class="plus"><b>Plus-value</b>Il travaille dans vos vraies données, en direct — plus d'exports.</p></article>
        <article class="fn ext"><span class="tag">Hors forfait · à venir</span><h3>Exécution des paiements</h3><p class="what">Relèvera de 60sec-Paiement, société distincte, une fois ses autorisations obtenues. Ni offerte ni vendue aujourd'hui<sup class="n"><a href="#note-4" aria-label="Note 4">4</a></sup>.</p></article>
      </div>
    </div>

    <div class="compare">
      <div>
        <h3 style="font-size:18px;margin-bottom:10px">Des logiciels séparés, ailleurs</h3>
        <ul>
          <li>Deux systèmes, et une passerelle à payer puis à réparer</li>
          <li>Une copie de vos données de plus, chez un fournisseur de plus</li>
          <li>Quelqu'un transfère ce qui n'a pas suivi, chaque mois</li>
        </ul>
      </div>
      <div>
        <h3 style="font-size:18px;margin-bottom:10px">« Connecté », dans 60secondes</h3>
        <ul>
          <li>Une seule base, une seule version des chiffres</li>
          <li>Chaque information saisie une fois sert partout</li>
          <li>Un seul fournisseur, une seule évaluation Loi 25</li>
        </ul>
      </div>
    </div>
  </div>
</section>

<!-- CORTEX -->
<section class="s alt cx" id="cortex" aria-labelledby="h-cx">
  <div class="wrap">
    <div class="s-head">
      <p class="eyebrow">Cortex · le cœur de 60secondes</p>
      <h2 id="h-cx">Chaque jour, Cortex vous dit l'essentiel. Et rien de plus.</h2>
      <p class="lead">Cortex fait le travail en coulisse, puis vous parle par Le 60 : ce que vous avez à faire, ce qui s'en vient, ce qui est déjà réglé. Sa couleur vous dit tout, d'un coup d'œil. Essayez : répondez aux actions et regardez-le changer.</p>
    </div>

    <div class="cx-pick" role="group" aria-label="Voir la journée d'un profil">
      <span>La journée d'un :</span>
      <button type="button" data-cxp="ta" aria-pressed="true">Travailleur autonome</button>
      <button type="button" data-cxp="c0" aria-pressed="false">Société sans employé</button>
      <button type="button" data-cxp="c4" aria-pressed="false">Société avec employés</button>
    </div>

    <div class="cx-g">
      <ol class="cx-ladder" aria-label="Le code de couleur de Le 60, du plus urgent au plus calme">
        <li data-lv="probleme"><span class="av-slot" data-av="probleme" data-size="30"></span><b>Problème</b></li>
        <li data-lv="urgent"><span class="av-slot" data-av="urgent" data-size="30"></span><b>Urgent</b></li>
        <li data-lv="action"><span class="av-slot" data-av="action" data-size="30"></span><b>Action</b></li>
        <li data-lv="question"><span class="av-slot" data-av="question" data-size="30"></span><b>Votre décision</b></li>
        <li data-lv="info"><span class="av-slot" data-av="info" data-size="30"></span><b>Information</b></li>
        <li data-lv="regle"><span class="av-slot" data-av="regle" data-size="30"></span><b>Réglé</b></li>
        <li data-lv="travail"><span class="av-slot" data-av="travail" data-size="30"></span><b>Au travail</b></li>
        <li data-lv="pause"><span class="av-slot" data-av="pause" data-size="30"></span><b>En pause</b></li>
      </ol>

      <div class="cx-phone" aria-label="Démonstration : l'écran Cortex du jour (exemple fictif)">
        <div class="cx-screen">
          <div class="cx-top">
            <span class="cx-face" id="cx-face" aria-hidden="true"></span>
            <div>
              <p class="cx-hi" id="cx-hi"></p>
              <p class="cx-sum" id="cx-sum" aria-live="polite"></p>
            </div>
          </div>
          <h3 class="cx-lab">À faire</h3>
          <ul class="cx-todo" id="cx-todo"></ul>
          <h3 class="cx-lab">Les enjeux</h3>
          <ul class="cx-stakes" id="cx-stakes"></ul>
          <h3 class="cx-lab">Réglé par Cortex</h3>
          <ul class="cx-done" id="cx-done"></ul>
          <button type="button" class="cx-reset" id="cx-reset">↺ Recommencer la démonstration</button>
        </div>
      </div>

      <div class="cx-why">
        <div><span class="cx-n">1</span><div><h3>À faire</h3><p>Seulement ce qui vous revient, du plus urgent au plus calme. Une question, un bouton, c'est réglé — et votre réponse devient une règle.</p></div></div>
        <div><span class="cx-n">2</span><div><h3>Les enjeux</h3><p>Ce qui s'en vient et ce que ça pèse : taxes à remettre, paie, liquidités, seuils. Vous voyez venir, sans ouvrir un rapport.</p></div></div>
        <div><span class="cx-n">3</span><div><h3>Réglé par Cortex</h3><p>Tout ce qu'il a fait seul : pièces lues, classées, calculées, rapprochées. Vous ne le voyez que pour le savoir.</p></div></div>
        <p class="cx-rule"><b>Une couleur à la fois.</b> Le 60 montre toujours la situation la plus urgente ; quand tout est fait, il passe au vert. Ses expressions et ses pastilles disent la même chose que sa couleur, lisibles pour les personnes daltoniennes.</p>
        <p class="cx-flow" aria-label="Comment Cortex travaille"><span>Il reçoit</span>→<span>il lit</span>→<span>il classe</span>→<span>il calcule</span>→<span class="you">vous demande, si nécessaire</span>→<span>il apprend</span></p>
        <p class="fine" style="margin-top:0">Démonstration : entreprises, montants et personnes fictifs<sup class="n"><a href="#note-12" aria-label="Note 12">12</a></sup>. Cortex prépare les paiements ; vous les déclenchez, ou votre cabinet le fait si vous l'y autorisez<sup class="n"><a href="#note-4" aria-label="Note 4">4</a></sup>. <button type="button" class="voice-try" data-av-open>Une question ? Discuter avec Le 60 →</button></p>
      </div>
    </div>
  </div>
</section>

<!-- FIRMS -->
<section class="s band" id="cabinets" aria-labelledby="h-firm">
  <div class="wrap">
    <div class="s-head cab-head">
      <p class="eyebrow">Cabinets comptables certifiés</p>
      <h2 id="h-firm" style="font-size:clamp(30px,4vw,46px)">Votre comptable, connecté à votre dossier. Selon vos règles.</h2>
      <p class="lead">Vous choisissez qui voit vos chiffres et ce qu'il peut y faire. Choisissez un cabinet certifié 60secondes, ou invitez le vôtre : il pourra lui aussi être certifié. Dans les deux cas, vous décidez ensemble des fonctions précises où il voit vos informations et agit en votre nom. Tout est paramétrable, et vous retirez l'accès en tout temps.</p>
    </div>

    <div class="cab-flow">
      <div class="cab-paths">
        <article class="cab-path">
          <span class="k">Chemin A</span>
          <h3>Vous avez déjà un comptable</h3>
          <ol>
            <li>Vous l'invitez par courriel, depuis votre dossier.</li>
            <li>Il accède à votre dossier selon les permissions convenues ensemble.</li>
            <li>S'il le souhaite, il devient cabinet certifié : formation en ligne et entente de confidentialité conforme à la Loi 25, sans frais.</li>
          </ol>
          <button type="button" class="btn btn-ghost-dark cab-find" data-cab-open="own">Inviter mon comptable</button>
        </article>
        <article class="cab-path">
          <span class="k">Chemin B</span>
          <h3>Vous en cherchez un</h3>
          <ol>
            <li>Vous choisissez un cabinet certifié dans la liste : ville, langue, spécialité.</li>
            <li>Au besoin, vous réservez une rencontre découverte en ligne.</li>
            <li>Vous l'invitez comme votre cabinet ; il est connecté selon les paramètres convenus.</li>
          </ol>
          <button type="button" class="btn btn-gold cab-find" data-cab-open="list">Choisir un cabinet certifié</button>
        </article>
      </div>

      <div class="cab-arrow" aria-hidden="true"><span>→</span></div>

      <aside class="cab-set" aria-labelledby="cab-set-h">
        <div class="cab-set-top">
          <span class="an-av" aria-hidden="true">LC</span>
          <div><h3 id="cab-set-h">Vos paramètres</h3><p>Lachance CPA inc. · <span class="cab-cert">✓ certifié 60secondes</span></p></div>
        </div>
        <p class="cab-set-sub">Cochez ce que votre cabinet peut faire. Essayez : c'est vous qui décidez.</p>
        <ul class="cab-perm" id="cab-perm">
          <li><label><input type="checkbox" checked> <span>Consulter livres, pièces et rapports en direct</span></label></li>
          <li><label><input type="checkbox" checked> <span>Passer et corriger des écritures</span></label></li>
          <li><label><input type="checkbox" checked> <span>Répondre aux questions de Cortex à votre place</span></label></li>
          <li><label><input type="checkbox" checked> <span>Préparer la fin d'exercice et les déclarations</span></label></li>
          <li><label><input type="checkbox"> <span>Préparer les lots de paiements pour votre approbation</span></label></li>
          <li><label><input type="checkbox"> <span>Déclencher les paiements en votre nom <small>— seulement si vous l'autorisez</small></span></label></li>
        </ul>
        <p class="cab-live" id="cab-live" aria-live="polite"></p>
        <p class="cab-set-fine">Chaque geste du cabinet est journalisé et visible dans votre dossier. Vous retirez l'accès d'un clic.</p>
      </aside>
    </div>

    <p class="cab-more">Vous êtes un cabinet comptable ? <button type="button" class="cab-more-b" data-fc-go="pour-cabinets">Découvrez ce que 60secondes change pour vous ›</button></p>
  </div>
</section>

<!-- POUR LES CABINETS COMPTABLES -->
<section class="s fc-intro" id="pour-cabinets" aria-labelledby="h-fc">
  <div class="wrap fc-hero">
    <div>
      <p class="eyebrow">Pour les cabinets comptables</p>
      <h2 id="h-fc" class="fc-h">La tenue de livres change. Les cabinets qui mènent prennent l'avance maintenant.</h2>
      <p class="lead">Avec 60secondes, Cortex fait la saisie, le classement, les rapprochements et les calculs. Votre équipe révise, conseille et signe. Vous servez plus de clients, mieux, avec les mêmes personnes.</p>
      <div class="fc-ctas">
        <button type="button" class="btn btn-gold" data-cab-open="firm">Devenir cabinet certifié</button>
        <button type="button" class="btn btn-ghost" data-fc-open="fc-b-mk">Tout savoir pour les cabinets ›</button>
      </div>
      <p class="fc-fine">Certification sans frais. Aucune commission. Vos honoraires restent les vôtres.</p>
    </div>
    <figure class="fc-ts" aria-labelledby="fc-ts-h">
      <div class="fc-ts-h"><b id="fc-ts-h">Fiche de temps d'un dossier</b><span>mois type</span></div>
      <div class="fc-ts-seg" role="group" aria-label="Type de dossier">
        <button type="button" data-fcp="ta" aria-pressed="true">Travailleur autonome</button>
        <button type="button" data-fcp="c0" aria-pressed="false">Société sans employé</button>
        <button type="button" data-fcp="c4" aria-pressed="false">Société, 1 à 4 employés</button>
      </div>
      <div class="fc-ts-rows">
        <div class="fc-ts-row"><span class="fc-l">En manuel</span><span class="fc-tr"><span class="fc-fl" style="width:100%"></span></span><span class="fc-v num" id="fc-mv">10 h</span></div>
        <div class="fc-ts-row fc-a"><span class="fc-l">Avec 60secondes</span><span class="fc-tr"><span class="fc-fl" id="fc-a" style="width:5%"></span></span><span class="fc-v num" id="fc-av">30 min</span></div>
      </div>
      <div class="fc-ts-foot">
        <div><b class="num" id="fc-x">× 20</b>dossiers suivis dans le même temps</div>
      </div>
      <p class="fc-ts-note">Modèle 60secondes, heures d'équipe par mois<sup class="n"><a href="#note-7" aria-label="Note 7">7</a></sup>.</p>
    </figure>
  </div>

  <div class="wrap fc-sum">
    <button type="button" data-fc-open="fc-b-mk"><b>Le marché change</b><span>Consolidation partout au Canada : seuls les leaders resteront.</span><i>Lire ›</i></button>
    <button type="button" data-fc-open="fc-dossier"><b>Le temps récupéré</b><span>Personnel rare, salaires en hausse : gardez vos gens pour le travail qui compte.</span><i>Lire ›</i></button>
    <button type="button" data-fc-open="fc-b-how"><b>Comment ça fonctionne</b><span>Certification sans frais, liste des cabinets, portail de vos dossiers.</span><i>Lire ›</i></button>
    <button type="button" data-fc-open="fc-b-faq"><b>Questions des associés</b><span>Heures facturables, QuickBooks, impôts, paiements, recommandations.</span><i>Lire ›</i></button>
  </div>
  <dialog class="an-dlg fc-dlg" id="fc-dlg" aria-labelledby="fc-dlg-h">
    <div class="dh"><div><h3 id="fc-dlg-h">Pour les cabinets comptables</h3><p class="an-fsub">Tout ce que 60secondes change pour votre cabinet.</p></div><button type="button" class="an-x" id="fc-dlg-x" aria-label="Fermer">×</button></div>
    <div class="db">
  <div class="wrap fc-block" id="fc-b-mk">
    <div class="s-head">
      <p class="eyebrow">Ce qui se passe dans le marché</p>
      <h3 class="fc-h3">Partout au Canada, le marché se consolide et s'automatise. La tenue de livres manuelle ne tiendra pas.</h3>
      <p class="lead">D'Halifax à Vancouver, les clients PME veulent des chiffres à jour, tout le temps, à un prix qu'ils comprennent. Les cabinets qui s'équipent maintenant gardent ces clients ; les autres les verront partir vers les logiciels ou vers les grands réseaux.</p>
    </div>
    <div class="fc-mk">
      <article><div class="fc-big num">22 789</div><h4>cabinets et bureaux employeurs au Canada</h4><p>Trois sur quatre comptent de 1 à 4 employés, et 39 313 praticiens travaillent seuls. Ce sont eux qui servent la grande majorité des travailleurs autonomes et des petites sociétés du pays.</p><div class="fc-qc"><span class="fc-qc-k">Au Québec</span><p><b>4 174</b> cabinets et bureaux employeurs, dont 2 835 de 1 à 4 employés (68 %), et 8 090 praticiens qui travaillent seuls.</p></div><span class="fc-src">Statistique Canada et ISDE, SCIAN 5412, 2025</span></article>
      <article><div class="fc-big num">6</div><h4>provinces touchées par les achats de deux réseaux, en cinq mois</h4><p>De septembre 2025 à janvier 2026, Doane Grant Thornton et MNP ont acquis des cabinets en Ontario, au Québec, en Saskatchewan, en Alberta, en Colombie-Britannique et au Nouveau-Brunswick. Aux États-Unis, les fonds privés financent déjà Grant Thornton et Crowe.</p><div class="fc-qc"><span class="fc-qc-k">Au Québec</span><p><b>9</b> cabinets acquis par MNP depuis janvier 2025, dont MLSG à Montréal et Boisvert &amp; Chartrand à Joliette ; Raymond Chabot Grant Thornton a aussi acquis PSB Boisjoli et Lemieux Cantin.</p></div><span class="fc-src">Communiqués des cabinets, 2025-2026</span></article>
    </div>
    <div class="fc-verdict"><b>Seuls les leaders resteront.</b><p>Le cabinet qui automatise la tenue garde ses clients, libère son équipe pour le conseil et croît sans courir après le personnel. Celui qui attend devient plus cher, plus lent, et remplaçable.</p></div>
  </div>

  <div class="wrap fc-block" id="fc-b-col">
    <div class="s-head">
      <p class="eyebrow">Une approche collaborative</p>
      <h3 class="fc-h3">La plateforme s'occupe des tâches de commodité. Votre cabinet, de la valeur ajoutée.</h3>
    </div>
    <div class="fc-split">
      <div class="fc-col">
        <span class="fc-k">60secondes s'en charge</span>
        <h4>Ce qui coûte des heures</h4>
        <ul><li>Lecture, saisie et classement des factures et reçus</li><li>Rapprochements bancaires et des cartes</li><li>Calcul de la TPS/TVQ, de la paie, des DAS et des relevés</li><li>Relances de comptes clients</li><li>Préparation des lots de paiements</li><li>Extraction des données de fin d'exercice pour vos déclarations de revenus</li><li>Questions simples au client, par Cortex</li></ul>
      </div>
      <div class="fc-mid" aria-hidden="true"><span>→</span></div>
      <div class="fc-col fc-you">
        <span class="fc-k">Votre cabinet s'y consacre</span>
        <h4>Ce que vos clients paient vraiment</h4>
        <ul><li>Révision et contrôle de la qualité</li><li>Conseil et planification fiscale</li><li>Fin d'exercice, états financiers et déclarations</li><li>Rémunération du propriétaire : salaire ou dividendes</li><li>Accompagnement de la croissance et du financement</li><li>La signature, et la relation</li></ul>
      </div>
    </div>
  </div>

  <div class="wrap fc-block" id="fc-dossier">
    <div class="s-head">
      <p class="eyebrow">Le temps récupéré</p>
      <h3 class="fc-h3">Vos gens sont rares et coûtent plus cher chaque année. Gardez-les pour le travail qui compte.</h3>
      <p class="lead">Recruter un technicien comptable prend des mois, et le garder coûte de plus en plus cher. 60secondes ne vous demande pas d'embaucher : il rend à votre équipe les heures que la saisie lui prend.</p>
    </div>
    <div class="fc-lab">
      <article><h4>Un personnel difficile à trouver</h4><p><b>53 %</b> des gestionnaires en finance et en comptabilité au Canada trouvent plus difficile d'embaucher qu'il y a un an. Et d'ici 2033, les trois quarts des postes de techniciens comptables à pourvoir viendront de départs, surtout à la retraite.</p><p class="fc-lab-qc"><b>Au Québec :</b> les travailleurs « continuent de se faire rares dans plusieurs secteurs d'activité » (Ordre des CRHA).</p><span class="fc-src">Robert Half Canada, 2026 · EDSC, Système de projection des professions au Canada 2024-2033 · Ordre des CRHA, septembre 2026</span></article>
      <article><h4>Des salaires toujours plus élevés</h4><p>Au Canada, les budgets d'augmentation salariale sont projetés à <b>3,1 %</b> pour 2027, et près de la moitié des employeurs prévoient une enveloppe de plus pour retenir leurs talents clés.</p><p class="fc-lab-qc"><b>Au Québec :</b> cinquième année de suite de hausses moyennes supérieures à 3 % ; 3,1 % prévus pour 2027.</p><span class="fc-src">Normandin Beaudry, 1<sup>er</sup> septembre 2026 · Ordre des CRHA, septembre 2026</span></article>
      <article><h4>La réponse : moins d'heures par dossier</h4><p>Quand la saisie, le classement et les calculs sont faits par la plateforme, la même équipe suit beaucoup plus de dossiers, sans heures supplémentaires.</p><span class="fc-src">Modèle 60secondes</span></article>
    </div>
    <p class="fc-eco-fine">Modèle 60secondes : heures d'équipe par dossier et par mois, hypothèses à confirmer en projet pilote. Ordres de grandeur, non une garantie de résultat<sup class="n"><a href="#note-7" aria-label="Note 7">7</a></sup>.</p>
  </div>

  <div class="wrap fc-block" id="fc-b-how">
    <div class="s-head">
      <p class="eyebrow">Comment ça fonctionne</p>
      <h3 class="fc-h3">Quatre étapes, et vos clients vous suivent sur la plateforme.</h3>
    </div>
    <ol class="fc-how">
      <li><h4>Demandez la certification</h4><p>Votre cabinet et vos professionnels, avec leur titre. Sans frais.</p></li>
      <li><h4>Formez votre équipe</h4><p>Formation en ligne à la plateforme et entente de confidentialité conforme à la Loi 25.</p></li>
      <li><h4>Apparaissez dans la liste</h4><p>Votre fiche de cabinet certifié : spécialités, langues, ville, plages de rencontre.</p></li>
      <li><h4>Travaillez dans les dossiers</h4><p>Chaque client vous donne accès aux fonctions convenues avec vous, dans un seul portail.</p></li>
    </ol>
    <div class="fc-twoway">
      <div><b>Vos clients viennent à vous</b><p>Un entrepreneur qui cherche un comptable choisit un cabinet certifié dans la liste, réserve une rencontre et vous invite dans son dossier.</p></div>
      <div><b>Vous amenez vos clients</b><p>Invitez vos clients actuels à rejoindre 60secondes. Ils s'abonnent à leur nom, puis vous donnent accès selon les paramètres que vous fixez ensemble.</p></div>
    </div>
  </div>

  <div class="wrap fc-block" id="fc-b-pt">
    <div class="fc-pt">
      <div>
        <p class="eyebrow">Le portail du cabinet</p>
        <h3 class="fc-h3" style="margin-top:12px">Tous vos dossiers, dans un seul tableau. Chacun selon les règles du client.</h3>
        <p class="lead" style="margin-top:14px">Le client décide, avec vous, des fonctions où vous voyez ses informations et agissez en son nom. Tout est paramétrable, tout est journalisé.</p>
        <div class="fc-deal">
          <div><b>0 $</b><span>Certification</span><p>Formation et entente de confidentialité, sans frais.</p></div>
          <div><b>0 %</b><span>Commission</span><p>Vos honoraires sont les vôtres ; vous en fixez le niveau.</p></div>
          <div><b>Le client</b><span>Abonnement</span><p>Au nom du client et payé par lui, de 79,99 $ à 149,99 $ par mois.</p></div>
          <div><b>Québec</b><span>Hébergement</span><p>Dossiers et portail hébergés au Québec et au Canada.</p></div>
        </div>
      </div>
      <figure class="fc-portal" aria-labelledby="fc-pt-h">
        <div class="fc-portal-h"><b id="fc-pt-h">Mes dossiers</b><span>exemple fictif</span></div>
        <div class="fc-tbl"><table>
          <thead><tr><th>Client</th><th>Accès</th><th>État</th></tr></thead>
          <tbody>
            <tr><td>Atelier Gagnon inc.<small>Société · 3 employés</small></td><td>6 fonctions</td><td><span class="fc-chip fc-ask">2 questions</span></td></tr>
            <tr><td>Sophie Roy, designer<small>Travailleuse autonome</small></td><td>4 fonctions</td><td><span class="fc-chip fc-ok">à jour</span></td></tr>
            <tr><td>Clinique des Monts<small>Société · 1 employé</small></td><td>5 fonctions</td><td><span class="fc-chip fc-gold">DAS à préparer</span></td></tr>
            <tr><td>Lavoie Services inc.<small>Société sans employé</small></td><td>3 fonctions</td><td><span class="fc-chip fc-ok">à jour</span></td></tr>
            <tr><td>Construction Dubé<small>Société · 4 employés</small></td><td>6 fonctions</td><td><span class="fc-chip fc-gold">fin d'exercice</span></td></tr>
          </tbody>
        </table></div>
        <p class="fc-foot">Portail hébergé au Québec et au Canada. Données fictives pour la démonstration.</p>
      </figure>
    </div>
  </div>

  <div class="wrap fc-block" id="fc-b-faq">
    <div class="fc-fin">
      <div>
        <div class="s-head" style="margin-bottom:22px">
          <p class="eyebrow">Questions de cabinets</p>
          <h3 class="fc-h3">Ce que les associés nous demandent.</h3>
        </div>
        <div class="fc-faq">
          <details><summary>Pourquoi mon cabinet adopterait-il 60secondes ?</summary><p>Pour servir plus de clients sans embaucher. La plateforme fait la saisie, le classement, les rapprochements et les calculs ; votre équipe passe de la tenue de livres à la révision et au conseil. Vous recevez des dossiers à jour et complets plutôt qu'un assemblage d'outils à réconcilier. Vous gardez le client et vos honoraires, sans commission. La liste des cabinets certifiés vous amène de nouveaux clients, et vous pouvez offrir des services de plus, comme la gestion des paiements que vos clients vous autorisent à déclencher.</p></details>
          <details><summary>La plateforme ne réduit-elle pas mes heures facturables ?</summary><p>Elle réduit les heures de saisie, celles que vous avez de plus en plus de mal à pourvoir et qui rapportent le moins. Le temps libéré va au travail que vos clients paient vraiment : conseil, fiscalité, fin d'exercice. Pour un cabinet à pleine capacité ou au forfait, chaque heure récupérée est un dossier de plus, pas un revenu de moins.</p></details>
          <details><summary>Mes clients sont déjà sur QuickBooks, Sage, Acomba ou Xero. Pourquoi changer ?</summary><p>Parce que leur logiciel comptable n'est qu'une pièce : la paie, les reçus, l'agenda et les paiements sont ailleurs, et c'est vous qui recollez les morceaux. Avec 60secondes, les quatorze fonctions sont dans un seul dossier. Le transfert des données est gratuit, même en cours d'année, et vous validez les soldes d'ouverture. Vous suivez ensuite tous vos dossiers dans un seul portail.</p></details>
          <details><summary>Pourquoi recommanderais-je 60secondes à mes clients ?</summary><p>Vous ne recommandez que ce que vous avez éprouvé. C'est pourquoi la certification commence par un projet pilote sur 5 à 10 de vos propres dossiers, mesurés sur vos chiffres. Si les heures baissent et que la qualité monte, vous le constatez avant d'en parler à un client. Et le client qui vous suit reste le vôtre : il vous invite dans son dossier et vous décidez ensemble de ce que vous y faites.</p></details>
          <details><summary>60secondes veut-il remplacer les comptables ?</summary><p>Non. La plateforme fait la tenue et les calculs ; le jugement, le conseil, la révision et la signature restent au cabinet. C'est précisément ce que le client paie.</p></details>
          <details><summary>Qui est propriétaire du dossier et des données ?</summary><p>Le client. Il ouvre son compte à son nom et vous invite. Il peut modifier ou retirer votre accès en tout temps, et chaque geste est journalisé.</p></details>
          <details><summary>Puis-je déclencher des paiements pour mon client ?</summary><p>Oui, si votre client vous y autorise. Le client déclenche lui-même ses paiements — fournisseurs, remises, paie — ou donne à votre cabinet l'autorisation de le faire en son nom. Cette autorisation fait partie des permissions qu'il fixe avec vous : il la donne de façon expresse et peut la retirer en tout temps. Chaque déclenchement est journalisé et visible par le client. L'accès de votre cabinet aux renseignements personnels se limite à ce qui est nécessaire, conformément à la Loi 25.</p></details>
          <details><summary>Comment récupérer les données pour préparer les déclarations de revenus ?</summary><p>60secondes vous permettra d'extraire, en quelques clics, les données nécessaires à la préparation des déclarations de revenus de vos clients : balance de vérification codée selon l'IGRF (GIFI), grand livre, conciliations, registre des immobilisations et feuillets de paie. Ces données seront exportées dans un format que vos logiciels d'impôt et de fin d'exercice peuvent importer : aucune ressaisie. Et comme elles sont tenues à jour toute l'année, le dossier est prêt quand la saison commence.</p></details>
          <details><summary>Quand puis-je commencer ?</summary><p>Lancement le 1<sup>er</sup> janvier 2027. Les cabinets inscrits d'ici là participent au projet pilote, avec 5 à 10 dossiers mesurés sur leurs propres chiffres.</p></details>
        </div>
      </div>
      <aside class="fc-cta">
        <p class="eyebrow">Passez devant</p>
        <h3 class="fc-h3">Devenez cabinet certifié 60secondes.</h3>
        <ol>
          <li><b>Demande</b> : votre cabinet et vos professionnels.</li>
          <li><b>Certification</b> : formation en ligne et entente de confidentialité.</li>
          <li><b>Projet pilote</b> : 5 à 10 de vos dossiers, mesurés sur vos chiffres.</li>
        </ol>
        <button type="button" class="btn btn-gold" data-cab-open="firm">Demander la certification</button>
        <button type="button" class="btn btn-ghost" data-cab-open="firm">Inviter mes clients</button>
        <p class="fc-fine">Sans frais, sans engagement. Cabinets : certifies@60secondes.ca</p>
      </aside>
    </div>
  </div>
    </div>
  </dialog>
</section>


<!-- ANNUAIRE -->
<!-- ANNUAIRE : fenêtres (ouvertes depuis la première page) -->
<div id="specialistes" class="dlg-host">
    <dialog class="an-dlg an-fdlg" id="an-find" aria-labelledby="an-find-h">
    <div class="dh"><div class="an-av" aria-hidden="true" id="an-find-av"></div><div><h3 id="an-find-h">Prendre rendez-vous</h3><p class="an-fsub">Cherchez un professionnel, choisissez une plage, c'est réservé.</p></div><button type="button" class="btn btn-ghost an-mng" id="an-manage">Mes rendez-vous<span class="an-badge" id="an-count" hidden></span></button><button type="button" class="an-x" id="an-find-x" aria-label="Fermer">×</button></div>
    <div class="db" id="an-full">
    <form class="an-search" id="an-form" role="search" aria-label="Rechercher un spécialiste">
      <div class="field"><label for="an-q">Quoi ou qui&nbsp;?</label><input id="an-q" type="search" autocomplete="off" placeholder="ex. : physiothérapeute, électricienne, Roy"></div>
      <div class="field"><label for="an-city">Ville</label><select id="an-city"><option value="">Toutes les villes</option></select></div>
      <div class="field"><label for="an-cp">Code postal</label><input id="an-cp" autocomplete="off" inputmode="text" maxlength="7" placeholder="H2X 1Y4" aria-describedby="an-cp-msg"></div>
      <div class="field"><label for="an-rad">Rayon</label><select id="an-rad"><option value="10">10 km</option><option value="25" selected>25 km</option><option value="50">50 km</option><option value="0">Sans limite</option></select></div>
      <div class="an-chips" role="group" aria-label="Industrie" id="an-ind"></div>
      <p class="an-cpmsg" id="an-cp-msg" aria-live="polite"></p>
    </form>

    <div class="an-bar">
      <p id="an-status" aria-live="polite"></p>
      <div class="an-opts">
        <label><input type="checkbox" id="an-soon"> Disponible d'ici 7&nbsp;jours</label>
        <label for="an-sort">Trier par <select id="an-sort"><option value="next">Prochaine disponibilité</option><option value="dist">Distance</option><option value="nom">Nom</option></select></label>
      </div>
    </div>
    <div class="an-grid" id="an-results"></div>
    </div>
    <div class="db an-bookv" id="an-dlg" hidden>
      <div class="an-bh">
        <button type="button" class="an-back" id="an-x"><span aria-hidden="true">‹</span> <span id="an-x-t">Retour aux résultats</span></button>
        <div class="an-bh-who"><div class="an-av" id="an-dlg-av" aria-hidden="true"></div><div style="min-width:0"><h3 id="an-dlg-h"></h3><p class="sp" id="an-dlg-sub"></p></div></div>
      </div>
      <div id="an-body"></div>
    </div>
    </dialog>
  <dialog class="an-dlg cb-dlg" id="cb-dlg" aria-labelledby="cb-h">
    <div class="dh"><div class="cb-ic" aria-hidden="true"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 7h8M8 11h2M12 11h2M16 11v6M8 15h2M12 15h2"/></svg></div><div><h3 id="cb-h">Mon cabinet comptable</h3><p class="an-fsub">Choisissez, invitez, puis décidez ensemble de ce qu'il peut faire.</p></div><button type="button" class="an-x" id="cb-x" aria-label="Fermer">×</button></div>
    <div class="cb-tabs" role="tablist" aria-label="Options">
      <button type="button" role="tab" id="cb-t1" aria-selected="true" data-cbt="list">Choisir un cabinet certifié</button>
      <button type="button" role="tab" id="cb-t2" aria-selected="false" data-cbt="own">Inviter mon comptable</button>
      <button type="button" role="tab" id="cb-t3" aria-selected="false" data-cbt="firm">Je suis un cabinet</button>
    </div>
    <div class="db">
      <!-- 1. liste des partenaires -->
      <div class="cb-pane" data-cbp="list">
        <div class="cb-filt">
          <label>Ville <select id="cb-city"><option value="">Toutes</option></select></label>
          <label>Spécialité <select id="cb-spec"><option value="">Toutes</option><option value="ta">Travailleurs autonomes</option><option value="soc">Sociétés sans employé</option><option value="paie">Paie et employés</option><option value="constr">Construction</option><option value="sante">Santé et services</option></select></label>
          <label>Langue <select id="cb-lang"><option value="">Toutes</option><option>FR</option><option>EN</option><option>ES</option></select></label>
        </div>
        <p class="cb-count" id="cb-count" aria-live="polite"></p>
        <ul class="cb-list" id="cb-list"></ul>
        <p class="cb-fine">Cabinets fictifs, pour la démonstration<sup class="n"><a href="#note-12" aria-label="Note 12">12</a></sup>. Aucune commission n'est versée entre 60secondes et les cabinets.</p>
      </div>
      <!-- 2. inviter son propre comptable -->
      <form class="cb-pane" data-cbp="own" id="cb-own" hidden novalidate>
        <p class="cb-intro">Votre comptable n'est pas encore sur 60secondes ? Invitez-le : il accède à votre dossier selon vos paramètres et peut, s'il le souhaite, devenir cabinet certifié. La certification est sans frais pour lui.</p>
        <div class="row2">
          <div class="field"><label for="cb-o-n">Nom du cabinet ou du comptable</label><input id="cb-o-n" autocomplete="organization" required></div>
          <div class="field"><label for="cb-o-e">Courriel</label><input id="cb-o-e" type="email" autocomplete="email" required></div>
        </div>
        <label class="consent"><input type="checkbox" id="cb-o-p" checked> <span>Lui proposer aussi la certification 60secondes (formation en ligne et entente de confidentialité conforme à la Loi 25).</span></label>
        <p class="an-warn" id="cb-o-err" hidden></p>
        <button type="submit" class="btn btn-primary">Continuer : ses permissions</button>
      </form>
      <!-- 3. cabinet qui devient partenaire -->
      <form class="cb-pane" data-cbp="firm" id="cb-firm" hidden novalidate>
        <p class="cb-intro">Faites certifier votre cabinet : vos clients vous trouvent dans cette liste et vous invitent dans leur dossier. Vous pouvez aussi inviter vos clients actuels à rejoindre 60secondes ; ils vous donneront ensuite accès, selon les paramètres convenus avec vous.</p>
        <div class="row2">
          <div class="field"><label for="cb-f-n">Nom du cabinet</label><input id="cb-f-n" autocomplete="organization" required></div>
          <div class="field"><label for="cb-f-e">Courriel professionnel</label><input id="cb-f-e" type="email" autocomplete="email" required></div>
        </div>
        <div class="row2">
          <div class="field"><label for="cb-f-v">Ville</label><input id="cb-f-v" autocomplete="address-level2"></div>
          <div class="field"><label for="cb-f-t">Titre professionnel</label><select id="cb-f-t"><option>CPA</option><option>Technicien ou technicienne comptable</option><option>Autre</option></select></div>
        </div>
        <div class="field"><label for="cb-f-c">Inviter des clients à rejoindre 60secondes (facultatif)</label><textarea id="cb-f-c" placeholder="Un courriel par ligne"></textarea></div>
        <p class="an-warn" id="cb-f-err" hidden></p>
        <button type="submit" class="btn btn-gold">Demander la certification</button>
      </form>
      <!-- 4. permissions -->
      <div class="cb-pane" data-cbp="perm" hidden>
        <p class="cb-who" id="cb-who"></p>
        <h4>Ce que votre cabinet pourra faire</h4>
        <p class="cb-intro">Choisissez-le ensemble. Chaque fonction s'ouvre ou se ferme séparément ; vous pourrez tout modifier plus tard.</p>
        <ul class="cab-perm cb-perm" id="cb-perm"></ul>
        <div class="field cb-dur"><label for="cb-dur">Durée de l'accès</label><select id="cb-dur"><option value="rev">Jusqu'à ce que je le retire</option><option value="fx">Jusqu'à la fin de l'exercice en cours</option><option value="3m">Trois mois</option></select></div>
        <p class="cab-live" id="cb-live" aria-live="polite"></p>
        <div class="an-actions"><button type="button" class="btn btn-ghost" id="cb-back">‹ Retour</button><button type="button" class="btn btn-primary" id="cb-send">Envoyer l'invitation</button></div>
      </div>
      <!-- 5. confirmation -->
      <div class="cb-pane" data-cbp="done" hidden>
        <div class="an-ok" id="cb-ok"></div>
        <ol class="cb-next">
          <li><b>Le cabinet reçoit votre invitation</b> avec les permissions proposées.</li>
          <li><b>Il accepte, ou vous propose un ajustement</b> ; rien ne s'applique sans votre accord.</li>
          <li><b>Il est connecté à votre dossier</b>, seulement sur les fonctions choisies. Chaque geste est journalisé ; vous retirez l'accès d'un clic.</li>
        </ol>
        <p class="cb-fine">Démonstration : aucune invitation n'est réellement envoyée ; ce choix reste sur votre appareil<sup class="n"><a href="#note-15" aria-label="Note 15">15</a></sup>.</p>
        <div class="an-actions"><button type="button" class="btn btn-ghost" id="cb-again">Choisir un autre cabinet</button><button type="button" class="btn btn-primary" id="cb-close2">Terminer</button></div>
      </div>
    </div>
  </dialog>
</div>

<!-- CLIENTS-FONDATEURS -->
<section class="s fclub-sec" id="fondateur" aria-labelledby="h-fclub">
  <div class="wrap">
    <div class="fclub">
      <div class="fclub-l">
        <span class="av-slot" data-av="bonjour" data-size="56"></span>
        <p class="eyebrow">Avant le lancement du 1<sup>er</sup> janvier 2027</p>
        <h2 id="h-fclub">Devenez client&#8209;fondateur</h2>
        <p>Avant le lancement, un petit groupe d'entreprises utilise 60secondes avec ses vraies données pour éprouver la plateforme. En échange de vos commentaires :</p>
      </div>
      <ul class="fclub-list">
        <li>Vous utilisez 60secondes <b>avant tout le monde</b>.</li>
        <li>Vous êtes <b>accompagné directement</b> par l'équipe fondatrice.</li>
        <li>Vos besoins <b>orientent les priorités</b> du produit.</li>
        <li>Vos données sont protégées par une <b>lettre de confidentialité signée</b> : elles servent aux seuls tests, jamais à la vente, au marketing ni à une étude de cas sans votre accord écrit.</li>
      </ul>
      <div class="fclub-cta">
        <a class="btn btn-gold" href="#membres" data-founder>Réserver ma place de client-fondateur</a>
        <p class="fine">Participation sur invitation, après votre inscription ; aucune obligation d'achat<sup class="n"><a href="#note-17" aria-label="Note 17">17</a></sup>.</p>
      </div>
    </div>
  </div>
</section>

<!-- MEMBERS -->
<section class="s" id="membres" aria-labelledby="h-mem">
  <div class="wrap">
    <div class="s-head">
      <p class="eyebrow">Inscription et connexion</p>
      <h2 id="h-mem">Votre espace, selon votre profil.</h2>
      <p class="lead">Réservez votre accès anticipé ; nous ouvrons les dossiers par vagues à compter du lancement<sup class="n"><a href="#note-3" aria-label="Note 3">3</a></sup>. Déjà inscrit ? La connexion s'ouvrira au même moment.</p>
    </div>

    <div class="members">
      <form class="form" id="signup" novalidate aria-labelledby="h-signup" aria-describedby="signup-notice">
        <h3 id="h-signup" style="font-size:21px">Créer mon compte</h3>
        <fieldset class="pick">
          <legend>Je suis</legend>
          <div class="pick-g">
            <label class="pk"><input type="radio" name="prof" value="ta" checked><span><b>Travailleur autonome</b><small>79,99 $/mois</small></span></label>
            <label class="pk"><input type="radio" name="prof" value="c0"><span><b>Société sans employé</b><small>99,99 $/mois</small></span></label>
            <label class="pk"><input type="radio" name="prof" value="c4"><span><b>Société avec employés</b><small>dès 149,99 $/mois</small></span></label>
            <label class="pk pk-firm"><input type="radio" name="prof" value="cab"><span><b>Cabinet comptable</b><small>certification 60secondes</small></span></label>
          </div>
        </fieldset>

        <div class="row2">
          <div class="field"><label for="s-name">Nom et prénom</label><input id="s-name" autocomplete="name" placeholder="Marie Tremblay"></div>
          <div class="field"><label for="s-mail">Courriel <span aria-hidden="true">*</span></label><input id="s-mail" type="email" autocomplete="email" required aria-required="true" placeholder="marie@exemple.ca"></div>
        </div>

        <div class="act" id="s-act-wrap">
          <div class="row2">
            <div class="field"><label for="s-act">Secteur d'activité</label><select id="s-act"><option value="">Choisissez…</option><option value="0">Construction et rénovation</option><option value="1">Santé et bien-être</option><option value="2">Beauté et soins personnels</option><option value="3">Services professionnels</option><option value="4">Technologies de l'information</option><option value="5">Arts, médias et création</option><option value="6">Commerce de détail</option><option value="7">Restauration et alimentation</option><option value="8">Transport et logistique</option><option value="9">Automobile</option><option value="10">Éducation, formation et sport</option><option value="11">Immobilier</option><option value="12">Agriculture, forêt et pêche</option><option value="13">Services à la personne et à la maison</option><option value="14">Tourisme et hébergement</option><option value="autre">Autre secteur</option></select></div>
            <div class="field"><label for="s-sub">Sous-catégorie</label><select id="s-sub" disabled><option value="">Choisissez d'abord un secteur</option></select></div>
          </div>
          <div class="field" id="s-act-other-wrap" hidden><label for="s-act-other">Précisez votre activité</label><input id="s-act-other" maxlength="80" placeholder="ex. : fabrication de savons artisanaux"></div>
          <p class="act-hint">Cortex s'en sert pour préparer votre plan comptable, vos catégories de dépenses et votre agenda selon votre métier.</p>
        </div>
        <div class="cond" data-for="ta">
          <div class="field"><label for="s-ta-tax">Inscrit à la TPS/TVQ ?</label><select id="s-ta-tax"><option>Oui</option><option>Non</option><option>Je ne sais pas</option></select></div>
        </div>
        <div class="cond" data-for="c0" hidden>
          <div class="row2">
            <div class="field"><label for="s-c0-name">Nom de la société</label><input id="s-c0-name" autocomplete="organization" placeholder="Lavoie Services inc."></div>
            <div class="field"><label for="s-c0-fy">Fin d'exercice</label><select id="s-c0-fy"><option>Décembre</option><option>Janvier</option><option>Février</option><option>Mars</option><option>Avril</option><option>Mai</option><option>Juin</option><option>Juillet</option><option>Août</option><option>Septembre</option><option>Octobre</option><option>Novembre</option><option>Je ne sais pas</option></select></div>
          </div>
        </div>
        <div class="cond" data-for="c4" hidden>
          <div class="row2">
            <div class="field"><label for="s-c4-name">Nom de la société</label><input id="s-c4-name" autocomplete="organization" placeholder="Atelier Gagnon inc."></div>
            <div class="field"><label for="s-c4-n">Nombre d'employés</label><input id="s-c4-n" type="number" inputmode="numeric" min="1" max="49" value="4"></div>
          </div>
          <div class="field"><label for="s-c4-freq">Fréquence de paie</label><select id="s-c4-freq"><option>Aux deux semaines</option><option>Hebdomadaire</option><option>Deux fois par mois</option><option>Mensuelle</option></select></div>
        </div>
        <div class="cond" data-for="cab" hidden>
          <div class="row2">
            <div class="field"><label for="s-cab-name">Nom du cabinet</label><input id="s-cab-name" autocomplete="organization" placeholder="Cabinet Roy CPA"></div>
            <div class="field"><label for="s-cab-n">Dossiers de tenue de livres</label><select id="s-cab-n"><option>1 à 25</option><option>26 à 100</option><option>101 à 300</option><option>Plus de 300</option></select></div>
          </div>
          <div class="row2">
            <div class="field"><label for="s-cab-sw">Logiciel actuel</label><select id="s-cab-sw"><option>QuickBooks</option><option>Sage</option><option>Acomba</option><option>Xero</option><option>Autre</option></select></div>
            <div class="field"><label for="s-cab-pilot">Projet pilote</label><select id="s-cab-pilot"><option>Oui, 5 à 10 dossiers</option><option>Pas pour l'instant</option></select></div>
          </div>
        </div>

        <div class="row2">
          <div class="field"><label for="s-lang">Langue de travail</label><select id="s-lang"><option>Français</option><option lang="en">English</option><option lang="es">Español</option></select></div>
          <div class="field est"><span class="lbl">Forfait estimé<sup class="n"><a href="#note-2" aria-label="Note 2">2</a></sup></span><output id="s-est" class="num" for="s-c4-n">79,99 $ / mois</output></div>
        </div>

        <label class="consent" for="s-fd"><input id="s-fd" type="checkbox"><span><b>Je souhaite devenir client-fondateur</b> : tester 60secondes avant le lancement avec mes vraies données, sous lettre de confidentialité<sup class="n"><a href="#note-17" aria-label="Note 17">17</a></sup>.</span></label>
        <label class="consent" for="s-c1"><input id="s-c1" type="checkbox" required aria-required="true"><span id="s-c1-t">J'accepte que 60secondes utilise ces renseignements pour traiter ma demande d'accès anticipé et me joindre à ce sujet. <span aria-hidden="true">*</span></span></label>
        <label class="consent" for="s-c2"><input id="s-c2" type="checkbox"><span>J'accepte de recevoir par courriel les nouvelles et avis de lancement de 9567-0048 Québec inc. (60secondes). Je peux retirer ce consentement en tout temps<sup class="n"><a href="#note-11" aria-label="Note 11">11</a></sup>. <em>Facultatif.</em></span></label>
        <button class="btn btn-gold" type="submit" id="s-submit">Réserver ma place</button>
        <p class="msg" id="signup-msg" role="status" hidden></p>
        <p class="notice" id="signup-notice"><strong>Avis de collecte.</strong> Responsable : 9567-0048 Québec inc. Fins : traiter votre demande et, si vous l'acceptez, vous informer du lancement. Seuls le courriel et le premier consentement sont obligatoires. Ces renseignements sont conservés au Québec, ne sont ni vendus ni communiqués à des tiers, et sont détruits au plus tard 24 mois après le lancement ou dès le retrait de votre consentement. Accès, correction ou retrait : vieprivee@60secondes.ca. <a href="#doc-confidentialite">Politique de confidentialité</a>.</p>
        <p class="fine" style="margin-top:8px">* Champ obligatoire. Aucune réservation ne crée de contrat ni ne fixe de prix ; aucun paiement n'est demandé<sup class="n"><a href="#note-3" aria-label="Note 3">3</a></sup>.</p>
      </form>

      <aside class="portal" id="connexion" aria-labelledby="h-login">
        <div class="ph">
          <h3 id="h-login">Se connecter</h3>
          <span class="chip gold">Au lancement</span>
        </div>
        <div class="seg roles" role="group" aria-label="Type d'accès">
          <button type="button" data-role="ent" aria-pressed="true">Entreprise</button>
          <button type="button" data-role="cab" aria-pressed="false">Cabinet</button>
          <button type="button" data-role="emp" aria-pressed="false">Employé</button>
        </div>
        <p class="sub" id="role-desc">Travailleurs autonomes et sociétés : votre dossier, vos questions Cortex et vos paiements à approuver.</p>
        <form id="login">
          <fieldset class="locked" disabled>
            <legend class="fine" style="margin:0">Connexion — disponible au lancement</legend>
            <div class="field"><label for="f-email">Courriel</label><input id="f-email" type="email" autocomplete="off" placeholder="vous@exemple.ca"></div>
            <div class="field"><label for="f-pass">Mot de passe</label><input id="f-pass" type="password" autocomplete="off" placeholder="••••••••"></div>
            <button class="btn btn-primary" type="submit">Se connecter</button>
          </fieldset>
        </form>
        <p class="soon" role="note">La connexion n'est pas encore active : aucun identifiant n'est demandé ni recueilli ici. À l'ouverture, chaque personne inscrite reçoit par courriel son lien d'activation et active la double authentification.</p>
        <ul class="roles-list">
          <li><b>Entreprise</b> — le titulaire du compte : il invite son comptable et ses employés, déclenche ses paiements ou autorise son cabinet à le faire<sup class="n"><a href="#note-4" aria-label="Note 4">4</a></sup>.</li>
          <li><b>Cabinet</b> — accède aux dossiers des clients qui l'ont invité, dans les limites des permissions accordées.</li>
          <li><b>Employé</b> — ne s'inscrit pas lui-même : il reçoit une invitation de son employeur pour l'application mobile.</li>
        </ul>
      </aside>
    </div>

    <div class="faq" style="margin-top:40px">
      <details><summary>Est-ce que 60secondes remplace mon comptable ?</summary><p>Non. 60secondes fait la tenue et les calculs ; votre comptable garde la révision, le conseil et les déclarations, et y gagne du temps<sup class="n"><a href="#note-10" aria-label="Note 10">10</a></sup>.</p></details>
      <details><summary>Est-ce que 60secondes paie mes fournisseurs ?</summary><p>Non. 60secondes calcule et prépare vos paiements. Vous déclenchez chaque paiement, ou vous autorisez votre cabinet comptable à le faire en votre nom. L'exécution relèvera de 60sec-Paiement, société distincte, une fois ses autorisations obtenues<sup class="n"><a href="#note-4" aria-label="Note 4">4</a></sup>.</p></details>
      <details><summary>Puis-je partir quand je veux ?</summary><p>Oui. L'abonnement est sans engagement : il se renouvelle de mois en mois et se résilie en tout temps, avec effet à la fin du mois en cours. Vos données restent les vôtres et peuvent être exportées.</p></details>
      <details><summary>Je change de profil en cours de route ?</summary><p>Votre forfait suit votre entreprise : incorporation, premier employé ou croissance de l'équipe, le dossier et son historique restent les mêmes.</p></details>
      <details><summary>Que se passe-t-il si Cortex n'est pas sûr ?</summary><p>Il vous pose la question. Rien d'ambigu n'est passé sans votre décision, et vous pouvez faire réviser par une personne toute décision automatisée<sup class="n"><a href="#note-6" aria-label="Note 6">6</a></sup>.</p></details>
      <details><summary>Et les entreprises de 50 employés et plus ?</summary><p>Elles ne sont pas desservies : leurs besoins (contrôleur interne, ERP, service comptable) dépassent ce que la plateforme vise<sup class="n"><a href="#note-8" aria-label="Note 8">8</a></sup>.</p></details>
    </div>
  </div>
</section>
</main>

<footer>
  <div class="wrap cols">
    <div>
      <a class="logo" href="#top" aria-label="60secondes, haut de page">
        <span>60<b>secondes</b></span>
      </a>
      <p class="f-prev">Traduction de courtoisie : en cas de divergence, la version française prévaut.</p>
      <p style="margin-top:12px">Administration financière des travailleurs autonomes et des petites sociétés, au Québec et partout au Canada. Un service de 9567-0048 Québec inc.</p>
      <div class="contact">
        <span>Renseignements : info@60secondes.ca</span>
        <span>Cabinets certifiés : certifies@60secondes.ca</span>
        <span>Vie privée : vieprivee@60secondes.ca</span>
      </div>
      <p class="f-rdv">Vous cherchez un professionnel membre de 60secondes ? <button type="button" data-an-find>Réserver un rendez-vous ›</button></p>
      <nav class="flinks" aria-label="Documents juridiques">
        <a href="#doc-notes">Notes et réserves</a>
        <a href="#doc-mentions">Mentions légales</a>
        <a href="#doc-confidentialite">Confidentialité</a>
        <a href="#doc-temoins">Témoins</a>
        <a href="#doc-conditions">Conditions d'utilisation</a>
        <a href="#doc-accessibilite">Accessibilité</a>
      </nav>
    </div>

  </div>

  <div class="wrap legal" aria-labelledby="h-legal">
    <h2 id="h-legal">Documents juridiques</h2>
    <p class="sub">En vigueur le 23 septembre 2026. Rédigés en français ; toute traduction est fournie à titre de courtoisie.</p>

    <details id="doc-notes">
      <summary>Notes et réserves</summary>
      <div class="doc">
        <ol id="notes" style="margin:0;padding-left:20px;display:grid;gap:8px">
        <li id="note-1"><strong>Comparaison.</strong> Panier de dix produits pour une société de quatre employés et un professionnel au calendrier ; à chaque fonction, l'option la moins chère offrant une interface française, sinon la moins chère. Prix publics consultés le 8 septembre 2026 (fonctions 1 à 9) et le 17 septembre 2026 (fonctions 10 à 14), avant taxes, bas et haut des fourchettes publiées ; conversion USD au taux de la Banque du Canada du 16 septembre 2026. Modèle type, pas une facture réelle ; les prix de tiers peuvent avoir changé. Hébergement des tiers selon ce que les éditeurs documentent eux-mêmes ; « non documenté » est traité comme « non ». Cortex et la conciliation financière : aucun produit autonome repéré à ces dates. Les marques citées appartiennent à leurs titulaires ; aucune affiliation.</li>
        <li id="note-2"><strong>Prix.</strong> CAD, par mois et par dossier, avant TPS et TVQ. Grille en vigueur au 9 septembre 2026, applicable au lancement ; elle peut être modifiée d'ici la mise en service, avec avis aux personnes inscrites avant toute facturation. Abonnement sans engagement, renouvelé de mois en mois et résiliable en tout temps, avec effet à la fin du mois en cours. La section « 60secondes face à la concurrence » présente, fonction par fonction, les produits du relevé de la note 1 et leurs gammes de prix publiées ; il s'agit d'une information comparative qui ne constitue ni une offre ni une garantie de résultat, et qui porte sur les seuls abonnements, sans le temps de travail.</li>
        <li id="note-3"><strong>Disponibilité.</strong> Le lancement du 1<sup>er</sup> janvier 2027 est la date prévue et non un engagement. Les demandes d'accès anticipé ne créent aucun contrat, ne réservent aucun prix et n'entraînent aucune facturation. Le portail des cabinets ouvre à la même échéance.</li>
        <li id="note-4"><strong>Paiements.</strong> 60secondes n'exécute aucun paiement, ne détient aucuns fonds et n'accède à aucun système de paiement : il calcule, prépare et présente le paiement ; le client le déclenche, ou autorise expressément son cabinet comptable certifié à le déclencher en son nom, autorisation qu'il peut retirer en tout temps. L'exécution est prévue par 60sec-Paiement, société affiliée distincte, assujettie à l'enregistrement de fournisseur de services de paiement auprès de la Banque du Canada (Loi sur les activités associées aux paiements de détail), aux obligations de la Loi sur le recyclage des produits de la criminalité et le financement des activités terroristes (CANAFE) et au régime des entreprises de services monétaires de l'Autorité des marchés financiers. Ce service n'est ni offert, ni vendu, ni commercialisé avant l'obtention de ces autorisations, et rien sur cette page ne constitue une offre de services de paiement.</li>
        <li id="note-5"><strong>Hébergement et sécurité.</strong> Serveurs applicatifs, bases de données, boîtes de courriel dédiées, portail des cabinets et copies de sauvegarde hébergés et exploités au Québec et au Canada. Le traitement des pièces et la circulation des données se font sur des infrastructures situées au Québec et au Canada ; aucune donnée ne sort du Canada. Chiffrement en transit (TLS 1.2 ou plus) et au repos, authentification à deux facteurs, journalisation des accès.</li>
        <li id="note-6"><strong>Intelligence artificielle.</strong> Cortex s'appuie sur un modèle de langage fourni par un tiers. Son exploitation sur des infrastructures situées au Canada est soumise aux engagements contractuels de ce fournisseur et à la disponibilité de ses services au Canada ; toute exception serait annoncée au préalable et documentée. Seuls des extraits minimisés lui sont transmis ; ils ne sortent pas du Canada, ne sont pas conservés par ce fournisseur, ne servent pas à entraîner ses modèles et ne comprennent aucune coordonnée bancaire. Une évaluation des facteurs relatifs à la vie privée documente cette communication et est fournie sur demande. Sous un seuil de confiance, la transaction est soumise à votre décision ; le modèle ne déclenche aucun paiement. Conformément à l'article 12.1 de la Loi sur la protection des renseignements personnels dans le secteur privé, vous êtes informé des traitements automatisés, pouvez connaître les principaux facteurs d'un classement et en demander la révision par une personne. Le classement automatisé n'est pas garanti exact : vous demeurez tenu de le vérifier.</li>
        <li id="note-7"><strong>Heures du canal comptable.</strong> Modélisation interne des heures d'équipe d'un cabinet : 10 h, 15 h et 35 h par dossier et par mois en manuel ; 30 min, 45 min et 2 h avec la plateforme, hypothèses à confirmer en projet pilote. Heures libérées = différence multipliée par 12 ; semaines calculées sur 35 heures ; capacité théorique à pleine charge. Contexte du marché du travail : Ordre des conseillers en ressources humaines agréés, communiqués et enquêtes salariales de septembre 2026. Ordres de grandeur, non des projections certifiées ; aucune garantie de résultat. Le niveau des honoraires relève entièrement du cabinet.</li>
        <li id="note-8"><strong>Admissibilité.</strong> Services offerts exclusivement aux entreprises et travailleurs autonomes établis au Canada, dans le cadre de leurs activités commerciales, et non aux consommateurs, à l'exception de l'annuaire des spécialistes et de la réservation en ligne, offerts gratuitement au public (note 15). Forfait « Société avec employés » : quatre employés inclus, 2 $ par mois par employé additionnel, jusqu'à 49 employés ; les entreprises de 50 employés et plus ne sont pas desservies.</li>
        <li id="note-9"><strong>Géolocalisation.</strong> Fonction désactivée par défaut ; elle n'est activée qu'au moment du poinçon, après que l'employé a été informé de son usage, de ses fins et de la façon de la désactiver (Loi sur la protection des renseignements personnels dans le secteur privé, art. 8.1). Aucun suivi continu.</li>
        <li id="note-10"><strong>Portée du service.</strong> 60secondes est un outil d'administration financière. Il ne constitue pas un avis comptable, fiscal, juridique ou financier et ne remplace pas un comptable professionnel agréé. L'exactitude des déclarations, remises et feuillets et le respect des échéances demeurent la responsabilité du contribuable ou de son mandataire.</li>
        <li id="note-11"><strong>Communications électroniques.</strong> Loi canadienne anti-pourriel : aucun message commercial sans votre consentement exprès. Expéditeur : 9567-0048 Québec inc. (60secondes), info@60secondes.ca. Chaque envoi comporte un lien de désabonnement, traité dans les dix jours ouvrables.</li>
        <li id="note-12"><strong>Exemples.</strong> Les démonstrations, noms d'entreprises, personnes, montants et tableaux de dossiers de cette page sont fictifs et servent d'illustration ; toute ressemblance est fortuite.</li>
        <li id="note-13"><strong>Renseignements personnels.</strong> Traités selon la Loi sur la protection des renseignements personnels dans le secteur privé (Québec), telle que modifiée par la Loi 25, et la Loi sur la protection des renseignements personnels et les documents électroniques (Canada). Détails dans la <a href="#doc-confidentialite">politique de confidentialité</a>.</li>
        <li id="note-14"><strong>Transfert des données.</strong> Transfert offert sans frais depuis tout système comptable et ses produits satellites (paie, poinçon, reçus, inventaire, agenda), dont QuickBooks, Sage, Acomba, Xero, Wave et Odoo, à partir d'exports complets et lisibles ; ces marques appartiennent à leurs titulaires, sans affiliation. « Quelques minutes » désigne une durée indicative pour une petite entreprise ; elle varie selon le volume, la source et la qualité des fichiers, et certaines données peuvent exiger une vérification. Les soldes d'ouverture et les cumulatifs de paie sont soumis à la validation du client ou de son comptable avant la première déclaration ou remise. Les honoraires d'un bureau ou d'un cabinet comptable qui effectue le transfert pour le client relèvent de ce bureau ou de ce cabinet. Le système d'origine n'est pas modifié ; la conservation des registres qu'il contient demeure la responsabilité de l'entreprise.</li>
        <li id="note-15"><strong>Annuaire et réservation en ligne.</strong> Offerts gratuitement au public, sans compte. N'y figurent que les professionnels abonnés à 60secondes qui choisissent d'y apparaître ; ils fixent eux-mêmes leurs services, prix, heures et politique de changement ou d'annulation, et le contrat de service se forme entre vous et eux. 60secondes n'est pas partie à ce contrat, ne recommande aucun professionnel et ne traite aucun paiement pour ces rendez-vous. Titres et ordres professionnels déclarés par le professionnel : vérifiez-les au besoin auprès de l'ordre concerné. Les renseignements saisis (nom, courriel, téléphone facultatif, précisions facultatives) servent uniquement à gérer le rendez-vous et ne sont communiqués qu'au professionnel choisi ; aucun motif de consultation n'est demandé pour les services de santé. Le code postal sert à calculer les distances dans votre navigateur ; il n'est ni transmis ni conservé. Dans cet aperçu, les fiches, prix et disponibilités sont fictifs, les distances approximatives, et les réservations d'essai sont gardées dans le stockage local de votre appareil seulement.</li>
        <li id="note-16"><strong>Assistant Le 60.</strong> Assistant automatisé qui répond à des questions générales sur 60secondes à partir d'une base de réponses préparée ; il ne donne aucun avis comptable, fiscal, juridique ou financier et peut se tromper : la page et les documents contractuels prévalent. Dans cet aperçu, la conversation reste dans votre navigateur ; elle n'est ni transmise, ni conservée, ni utilisée pour entraîner un modèle. N'y inscrivez aucun renseignement personnel. Pour parler à une personne : info@60secondes.ca.</li>
        <li id="note-17"><strong>Clients-fondateurs.</strong> Participation sur invitation, sans frais ni obligation d'achat, avant le lancement. Les données financières confiées pour les tests sont encadrées par une lettre de confidentialité signée : elles servent uniquement à vérifier l'exactitude, la fiabilité et la sécurité de la plateforme, ne sont ni vendues, ni communiquées, ni utilisées à des fins de marketing, et ne sont jamais citées sans accord écrit. Aucun avantage tarifaire n'est promis par cette page.</li>
      </ol>
      </div>
    </details>

    <details id="doc-mentions">
      <summary>Mentions légales</summary>
      <div class="doc">
        <dl>
          <dt>Éditeur</dt><dd>9567-0048 Québec inc., société par actions constituée le 6 mai 2026 en vertu de la Loi sur les sociétés par actions (Québec)</dd>
          <dt>NEQ</dt><dd>1182124850 — état de renseignements consultable au Registraire des entreprises du Québec</dd>
          <dt>Siège</dt><dd>Montréal (Québec), Canada</dd>
          <dt>Noms employés</dt><dd>60secondes · 60S-AI / 60S-IA (acronyme enregistré) · 60sec-Paiement désigne une société affiliée distincte</dd>
          <dt>Responsable de la publication</dt><dd>Le président de la société</dd>
          <dt>Nous joindre</dt><dd>info@60secondes.ca</dd>
          <dt>Site</dt><dd>60secondes.ca — hébergé au Québec et au Canada</dd>
        </dl>
        <p>60secondes, 60S-AI et 60sec-Paiement sont des noms et marques employés au Canada par leurs sociétés respectives. Les autres marques mentionnées appartiennent à leurs titulaires.</p>
      </div>
    </details>

    <details id="doc-confidentialite">
      <summary>Politique de confidentialité</summary>
      <div class="doc">
        <p>Cette politique explique, en termes simples, comment 9567-0048 Québec inc. (« 60secondes », « nous ») traite les renseignements personnels recueillis par ce site. L'utilisation de la plateforme elle-même est régie par le contrat d'abonnement.</p>
        <h4>Responsable de la protection des renseignements personnels</h4>
        <p>Le président de 9567-0048 Québec inc. — vieprivee@60secondes.ca. Il veille au respect de cette politique et répond à vos demandes.</p>
        <h4>Ce que nous recueillons, et pourquoi</h4>
        <ul>
          <li><strong>Formulaire d'accès anticipé :</strong> nom (facultatif), courriel, profil et secteur d'activité de l'entreprise, langue de travail — pour traiter votre demande, vous écrire à l'ouverture et, si vous y consentez séparément, vous envoyer nos avis de lancement.</li>
          <li><strong>Réservation auprès d'un professionnel de l'annuaire :</strong> nom, courriel, téléphone et précisions facultatifs — communiqués au seul professionnel choisi, pour confirmer, rappeler, changer ou annuler le rendez-vous. Aucun renseignement de santé n'est demandé. Conservés au plus 12 mois après la date du rendez-vous (<a href="#note-15">note 16</a>).</li>
          <li><strong>Assistant Le 60 :</strong> vos questions restent dans votre navigateur le temps de la visite ; aucune n'est transmise ni conservée (<a href="#note-16">note 17</a>).</li>
          <li><strong>Aucune autre donnée :</strong> ce site ne recueille pas d'adresse IP à des fins de profilage, n'utilise aucun outil de mesure d'audience tiers et ne dépose aucun témoin publicitaire.</li>
        </ul>
        <h4>Consentement</h4>
        <p>Chaque finalité fait l'objet d'un consentement distinct, manifeste et libre ; aucune case n'est cochée d'avance. Vous pouvez retirer votre consentement en tout temps.</p>
        <h4>Communication et lieu de conservation</h4>
        <p>Vos renseignements ne sont ni vendus, ni loués, ni communiqués à des tiers à des fins commerciales. Ils sont conservés au Québec. Aucun renseignement recueilli par ce site n'est communiqué hors du Québec ; si cela devait changer, une évaluation des facteurs relatifs à la vie privée serait réalisée au préalable et cette politique mise à jour.</p>
        <h4>Conservation</h4>
        <p>Au plus 24 mois après le lancement de la plateforme, ou jusqu'au retrait de votre consentement, puis destruction sécuritaire.</p>
        <h4>Vos droits</h4>
        <p>Accès, rectification, retrait du consentement, portabilité, désindexation et cessation de diffusion, ainsi que le droit d'être informé des traitements automatisés et d'en demander la révision. Écrivez à vieprivee@60secondes.ca ; nous répondons dans un délai de 30 jours. Vous pouvez porter plainte auprès de la Commission d'accès à l'information du Québec ou du Commissariat à la protection de la vie privée du Canada.</p>
        <h4>Sécurité et incidents</h4>
        <p>Mesures de sécurité raisonnables au regard de la sensibilité des renseignements. Tout incident de confidentialité présentant un risque de préjudice sérieux est déclaré à la Commission d'accès à l'information et aux personnes concernées, et consigné au registre des incidents.</p>
        <h4>Mineurs</h4>
        <p>Ce site s'adresse aux entreprises et, pour l'annuaire, au public adulte ; il ne vise pas les personnes de moins de 14 ans et ne recueille sciemment aucun renseignement à leur sujet.</p>
        <h4>Modifications</h4>
        <p>Toute modification est publiée ici avec sa date d'entrée en vigueur.</p>
      </div>
    </details>

    <details id="doc-temoins">
      <summary>Témoins et stockage local</summary>
      <div class="doc">
        <p>Ce site n'utilise aucun témoin (cookie) publicitaire ou analytique et aucun traceur tiers. Il ne comporte aucune fonction d'identification, de localisation ou de profilage.</p>
        <p>Seules des préférences techniques sont conservées dans le stockage local de votre navigateur, sur votre appareil seulement : le dernier profil consulté dans la section Cortex et, dans cet aperçu, les réservations d'essai faites dans l'annuaire. Rien n'est transmis. Vous pouvez l'effacer en tout temps depuis les réglages de votre navigateur ; le site fonctionne normalement sans elle.</p>
        <p>Les polices de caractères sont chargées depuis Google Fonts, qui reçoit l'adresse IP technique de votre appareil pour les servir.</p>
      </div>
    </details>

    <details id="doc-conditions">
      <summary>Conditions d'utilisation du site</summary>
      <div class="doc">
        <p>Ce site présente la plateforme 60secondes à titre informatif. Son contenu ne constitue ni une offre de contracter, ni un avis professionnel. Les services sont fournis uniquement en vertu d'un contrat d'abonnement écrit, qui prévaut sur toute information de cette page.</p>
        <p>Les textes, visuels, marques et éléments graphiques sont la propriété de 9567-0048 Québec inc. ou de leurs titulaires et ne peuvent être reproduits sans autorisation. Les liens vers des sites tiers sont fournis pour commodité ; nous ne répondons pas de leur contenu.</p>
        <p>Nous visons l'exactitude de l'information, sans garantir qu'elle soit complète ou à jour en tout temps. Ces conditions sont régies par les lois applicables au Québec et au Canada.</p>
      </div>
    </details>

    <details id="doc-accessibilite">
      <summary>Accessibilité</summary>
      <div class="doc">
        <p>Ce site vise la conformité au niveau AA des Règles pour l'accessibilité des contenus Web (WCAG) 2.1, norme internationale ISO/IEC 40500 : navigation complète au clavier, lien d'évitement, contrastes suffisants, textes alternatifs, respect du réglage « réduire les animations », thèmes clair et sombre.</p>
        <p>Un obstacle vous empêche d'accéder à une information ? Écrivez à info@60secondes.ca : nous vous la fournirons sous une autre forme et corrigerons la page.</p>
      </div>
    </details>
  </div>

  <div class="wrap meta">
    <span>© 2026 9567-0048 Québec inc. Tous droits réservés.</span>
    <span>Contenu à jour au 26 septembre 2026 · Français · English · Español</span>
  </div>
</footer>

</div>

<!-- LE 60 : assistant de discussion (hors #app, garde la conversation au changement de langue) -->
<div class="chat-launch early">
  <div class="chat-tease" id="chat-tease" role="note"><b>Une question ?</b>Je réponds en quelques secondes.<button type="button" id="chat-tease-x" aria-label="Masquer ce message">×</button></div>
  <button type="button" class="chat-fab" id="chat-fab" aria-expanded="false" aria-controls="chat" aria-label="Discuter avec Le 60"></button>
</div>
<section class="chat" id="chat" role="dialog" aria-modal="false" aria-labelledby="chat-t" hidden>
  <div class="chat-h">
    <span id="chat-face" aria-hidden="true"></span>
    <div class="t"><b id="chat-t">Le 60</b><span>Le visage de Cortex · questions générales</span></div>
    <button type="button" class="x" id="chat-x" aria-label="Fermer la discussion">×</button>
  </div>
  <p class="chat-disc">Assistant automatisé : réponses générales sur la plateforme, sans avis comptable, fiscal ou juridique. N'inscrivez aucun renseignement personnel ou financier<sup class="n"><a href="#note-16" aria-label="Note 16">16</a></sup>.</p>
  <div class="chat-log" id="chat-log" role="log" aria-live="polite" aria-label="Conversation"></div>
  <form class="chat-f" id="chat-f" autocomplete="off">
    <label for="chat-in" class="sr">Votre question</label>
    <input id="chat-in" maxlength="200" placeholder="Posez votre question…">
    <button type="submit" aria-label="Envoyer"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg></button>
  </form>
</section>

<script src="js/landing2-1.js?v=%%V%%"></script>

<script src="js/landing2-2.js?v=%%V%%"></script>

<!-- Gabarits de traduction : coller ici la page traduite (mêmes id). Vides = repli sur le français. -->
<script src="js/landing2-3.js?v=%%V%%"></script>
<template id="tpl-en"></template>
<template id="tpl-es"></template>
<script src="js/landing2-4.js?v=%%V%%"></script>
<script src="js/landing2-5.js?v=%%V%%"></script>
</body>
</html>
