<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="QuiFaitQuoi.aspx.vb" Inherits="MngConsul.QuiFaitQuoi" %>
<!doctype html>
<html lang="fr-CA">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Qui fait quoi — 60secondes</title>
<%-- Page « Qui fait quoi » (modèle 60secondes-qui-fait-quoi.html, inventaire v5.2), affichée dans
     l'onglet « Qui fait quoi » de la fenêtre Mon cabinet comptable (js/cabinet-60s.js, dans un cadre).
     Le contexte (entreprise, cabinet choisi) vient du serveur. Profil et métier : Paramètres › Entreprise (PROFIL, METIER). Chaque choix est un paramètre de
     compagnie QFQ:<id> (T326 ; POST vers cette page, administrateurs seulement). --%>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="css/qui-fait-quoi.css?v=2026102001">
<style>
/* Dans la fenêtre Mon cabinet comptable : la barre du haut et l'assistant de la page autonome
   doublent ceux de l'application ; ils restent dans la page (le script s'en sert) mais cachés. */
.top, .a60, .bulle { display: none !important; }
.resume { top: 8px; }
.bloc { scroll-margin-top: 150px; }
.page { padding-top: 12px; }
/* Tous les paramètres : bandeau d'explication et bascule « Toutes les actions » */
.qfq-bandeau { margin: 0 0 14px; padding: 14px 18px; border-radius: 18px; background: #E3EBF7; color: #143A73; font-weight: 700; font-size: 14px; line-height: 1.5; }
.qfq-bandeau a { color: #1B4F9C; font-weight: 800; }
.voir-tout { border: 0; background: none; padding: 0; font: inherit; font-weight: 800; color: #1B4F9C; text-decoration: underline; text-underline-offset: 3px; cursor: pointer; }
</style>
</head>
<body>

<header class="top">
  <a class="logo" href="#" aria-label="60secondes — accueil">
    <svg aria-hidden="true" width="42" height="42" viewBox="0 0 256 256"><circle cx="128" cy="128" r="112" fill="#FFFFFF" stroke="#D9A03C" stroke-width="16"/><circle cx="96" cy="120" r="16" fill="none" stroke="#0E1F3D" stroke-width="13"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#0E1F3D" stroke-width="13" stroke-linecap="round"/><ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#0E1F3D" stroke-width="13"/><path d="M99 166 q29 16 58 0" fill="none" stroke="#0E1F3D" stroke-width="11" stroke-linecap="round"/></svg>
    <span>secondes</span>
  </a>
  <span class="org"><b id="ctxEntreprise">—</b></span>
  <div class="ctx" aria-label="Votre entreprise">
    <span class="ctx-pill" id="ctxProfil">—</span>
    <span class="ctx-pill" id="ctxMetier">—</span>
  </div>
  <div class="grow"></div>
  <select class="pill-sel" id="lang" aria-label="Langue"><option value="FR">FR</option><option value="EN">EN</option><option value="ES">ES</option></select>
  <button class="round" id="btnAide" aria-label="Aide">
    <svg aria-hidden="true" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 0 1 4.8 1c0 1.7-2.3 2-2.3 3.5M12 17h.01"/></svg>
  </button>
</header>

<div class="page">
  <section class="entete" aria-labelledby="titre">
    <span class="eyebrow">Paramètres · convenus avec votre cabinet</span>
    <h1 id="titre">Qui fait quoi</h1>
    <p class="lede">60 propose déjà qui s'occupe de chaque action. Ouvrez un bloc et touchez « Moi », « Mon cabinet » ou les deux.</p>
    <div class="legende">
      <span><i class="mini-b on">Moi</i> vous</span>
      <span><i class="mini-b or">Cabinet</i> votre cabinet</span>
      <span><i class="mini-b on">Moi</i><i class="mini-b or">Cabinet</i> les deux : partagée</span>
      <span><i class="mini-b s60">60secondes</i> fait seul par 60</span>
    </div>
  </section>


  <section class="bloc resume" aria-label="Résumé">
    <div class="res">
      <span class="bloc-ico res-ico"><svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg></span>
      <span class="res-txt"><span class="bloc-t">Résumé</span><span class="bloc-d" id="resTot">—</span>
</span>
      <span class="stats" id="resStats"></span>
      <span class="res-cab"><span class="cab-nom" id="cabNom">—</span><span class="etat" id="cabEtat"></span></span>
      <button class="save" id="btnSave">Enregistrer</button>
    </div>
  </section>

  <div id="liste"></div>
</div>

<button class="a60" id="btn60" aria-label="Ouvrir 60, votre assistant" aria-expanded="false">
  <svg aria-hidden="true" width="50" height="50" viewBox="0 0 256 256"><circle cx="128" cy="128" r="112" fill="#FFFFFF" stroke="#D9A03C" stroke-width="16"/><circle cx="96" cy="120" r="16" fill="none" stroke="#0E1F3D" stroke-width="13"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#0E1F3D" stroke-width="13" stroke-linecap="round"/><ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#0E1F3D" stroke-width="13"/><path d="M99 166 q29 16 58 0" fill="none" stroke="#0E1F3D" stroke-width="11" stroke-linecap="round"/></svg>
  <span>60, votre assistant</span>
</button>
<div class="bulle" id="bulle" hidden>
  <b>60, votre assistant</b>
  <p>Je pars toujours de ma proposition. Touchez « Moi », « Mon cabinet » ou les deux : vert pour vous, orange pour votre cabinet ; les deux ensemble, c'est partagé. Le premier qui prend une action partagée la bloque pour l'autre, et tout est inscrit au journal.</p>
</div>
<div class="toast" id="toast" role="status" hidden></div>
<script>window.QFQ_CONTEXTE = <%= ContexteJson %>;</script>
<script src="js/qui-fait-quoi-data.js?v=2026102001"></script>
<%-- Les métiers viennent de la base (T330, gérés dans la console d'administration) ; ceux du fichier servent de secours. --%>
<script>(function (m) { if (m && m.length) DATA.M = m; })(<%= MetiersJson %>);</script>
<script src="js/qui-fait-quoi.js?v=2026102104"></script>
</body>
</html>