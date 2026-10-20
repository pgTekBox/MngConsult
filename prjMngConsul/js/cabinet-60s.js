/* =====================================================================
   60secondes · Mon cabinet comptable (CabinetsCertifies.aspx) — couche de présentation v1 (2026-10-20)
   Côté navigateur seulement. Ne touche ni au filtrage d'origine (#cabRecherche), ni aux liens des cartes.
   Ajoute :
     1. Mon cabinet     — le cabinet choisi, la répartition en bref, l'accès aux données (clé COMPTABLE
                          lue en lecture seule dans wbfsetting.aspx) et les garde-fous.
     2. Qui fait quoi   — les 24 activités en 7 domaines qu'un cabinet peut faire au nom du client :
                          Vous · Mon cabinet · Ensemble (le cabinet prépare, vous approuvez),
                          plafond par paiement, séparation des tâches.
     3. Cabinets certifiés — les cartes d'origine, avec « Choisir ce cabinet ».
   Enregistrement : l'état est enregistré par compagnie sur le serveur (MonCabinet.ashx → T323MonCabinet),
   lu à l'ouverture et réécrit à chaque changement. Il reste publié par l'événement « s60:mon-cabinet »
   et l'objet window.S60MonCabinet { lire(), ecrire(etat) }.
   ===================================================================== */
(function () {
  'use strict';
  var page = document.querySelector('#divMain .cab-page');
  if (!page || page.getAttribute('data-s60c')) return;
  page.setAttribute('data-s60c', '1');

  /* Clé du navigateur : l'onglet ouvert (session) et l'ancien état local, repris une fois sur le serveur. */
  var CLE = 's60-mon-cabinet-v1' + (page.getAttribute('data-cie') ? '-' + page.getAttribute('data-cie') : '');
  function $(s, r) { return (r || document).querySelector(s); }
  function $$(s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function ic(n) { return '<i class="ic ic-' + n + '" aria-hidden="true"></i>'; }
  function argent(n) { return Math.round(n).toLocaleString('fr-CA') + ' $'; }

  /* ---------- Catalogue : ce qu'un cabinet peut faire au nom du client ---------- */
  var DOMAINES = [
    ['livres', 'Tenue de livres', 'book'],
    ['factu', 'Facturation et encaissements', 'receipt'],
    ['paiement', 'Paiements au nom de l\'entreprise', 'banknote'],
    ['paie', 'Paie et employés', 'users'],
    ['taxes', 'Taxes et gouvernements', 'scale'],
    ['fin', 'Fin d\'exercice', 'calculator'],
    ['relation', 'Suivi et conseil', 'message']
  ];
  /* id, domaine, nom, ce que ça couvre, suggestion, « Ensemble » veut dire…, options ('3' = Vous/Cabinet/Ensemble, 'oui' = Cabinet/Non), paiement */
  var ACT = [
    ['classer', 'livres', 'Classer les dépôts et les transactions', 'Valider ou corriger le classement proposé par Le 60.', 'partage', 'Vous classez au quotidien ; le cabinet révise chaque mois.'],
    ['rappro', 'livres', 'Rapprocher les comptes bancaires', 'Confirmer que les relevés concordent avec les livres.', 'cabinet', 'Vous rapprochez ; le cabinet vérifie à la fin du mois.'],
    ['saisie', 'livres', 'Saisir les factures fournisseurs', 'Enregistrer les factures reçues.', 'partage', 'Vous déposez les factures ; le cabinet les saisit.'],
    ['corriger', 'livres', 'Corriger une écriture', 'Modifier ou annuler une écriture, avec une note au dossier.', 'cabinet', 'Le cabinet propose la correction ; vous l\'approuvez.'],
    ['facturer', 'factu', 'Émettre les factures', 'Préparer et envoyer les factures à vos clients.', 'client', 'Le cabinet prépare ; vous approuvez avant l\'envoi.'],
    ['relance', 'factu', 'Relancer les comptes clients en retard', 'Envoyer les rappels de paiement à vos clients.', 'client', 'Le cabinet prépare les rappels ; vous les approuvez.'],
    ['encaisser', 'factu', 'Enregistrer les encaissements', 'Associer chaque paiement reçu à la bonne facture.', 'client', 'Vous enregistrez ; le cabinet règle les paiements non reconnus.'],
    ['payer_fourn', 'paiement', 'Payer les factures fournisseurs', 'Déclencher le paiement d\'une facture approuvée.', 'partage', 'Le cabinet prépare le paiement ; vous l\'approuvez.', 1],
    ['remise', 'paiement', 'Payer les remises DAS', 'Verser les retenues à la source à l\'ARC et à Revenu Québec.', 'cabinet', 'Le cabinet calcule ; vous approuvez le prélèvement.', 1],
    ['payer_taxes', 'paiement', 'Payer la TPS/TVQ due', 'Verser le solde de taxes aux gouvernements.', 'partage', 'Le cabinet calcule ; vous approuvez le prélèvement.', 1],
    ['rembourser', 'paiement', 'Rembourser les dépenses d\'employés', 'Verser les remboursements approuvés.', 'client', 'Le cabinet prépare ; vous approuvez le versement.', 1],
    ['paie_prep', 'paie', 'Préparer la paie', 'Saisir les heures et vérifier les retenues.', 'cabinet', 'Vous saisissez les heures ; le cabinet vérifie les retenues.'],
    ['paie_appr', 'paie', 'Approuver la paie', 'Autoriser le départ de la paie à la date prévue.', 'client', 'Approbation à deux : le cabinet, puis vous.'],
    ['feuillets', 'paie', 'Produire les T4 et les Relevés 1', 'Préparer et transmettre les feuillets de fin d\'année.', 'cabinet', 'Le cabinet prépare ; vous approuvez avant la transmission.'],
    ['embauche', 'paie', 'Inscrire un nouvel employé', 'Créer la fiche et recueillir les formulaires de retenues.', 'partage', 'Vous créez la fiche ; le cabinet vérifie les formulaires.'],
    ['tps_prep', 'taxes', 'Préparer la déclaration TPS/TVQ', 'Calculer la déclaration de la période.', 'cabinet', 'Le cabinet calcule ; vous révisez.'],
    ['tps_trans', 'taxes', 'Transmettre la déclaration TPS/TVQ', 'Envoyer la déclaration aux gouvernements.', 'partage', 'Le cabinet transmet après votre approbation.'],
    ['avis_gouv', 'taxes', 'Répondre aux avis de l\'ARC et de Revenu Québec', 'Préparer et envoyer la réponse avec les pièces.', 'cabinet', 'Le cabinet prépare la réponse ; vous l\'approuvez.'],
    ['etats', 'fin', 'Préparer les états financiers', 'Produire les états de fin d\'exercice.', 'cabinet', 'Le cabinet prépare ; vous approuvez.'],
    ['ajust', 'fin', 'Passer les ajustements de fin d\'exercice', 'Amortissement, charges à payer, inventaire.', 'cabinet', 'Le cabinet propose ; vous approuvez.'],
    ['repondre', 'relation', 'Répondre à vos questions', 'Avec les chiffres de votre dossier.', 'cabinet', '', 0, 'oui'],
    ['treso', 'relation', 'Vous prévenir d\'un manque de liquidités', 'Vous avertir et proposer une solution.', 'cabinet', '', 0, 'oui'],
    ['conseil', 'relation', 'Vous proposer un rendez-vous de conseil', 'Quand Le 60 repère une occasion ou un risque.', 'cabinet', '', 0, 'oui'],
    ['signer', 'relation', 'Vous envoyer des documents à signer', 'Signature électronique dans votre dossier.', 'cabinet', '', 0, 'oui']
  ].map(function (a) { return { id: a[0], dom: a[1], nom: a[2], desc: a[3], sugg: a[4], ens: a[5], pay: !!a[6], mode: a[7] || '3' }; });
  var PAR_ID = {}; ACT.forEach(function (a) { PAR_ID[a.id] = a; });
  /* Séparation des tâches : une même personne du cabinet ne fait jamais les deux */
  var PAIRES = [['saisie', 'payer_fourn'], ['paie_prep', 'paie_appr'], ['facturer', 'encaisser'], ['corriger', 'rappro']];
  var PLAFOND_DEF = 5000;
  var QUI = { client: 'Vous', cabinet: 'Mon cabinet', partage: 'Ensemble', aucun: 'Non merci' };

  /* ---------- État ---------- */
  function vierge() { return { cabinet: null, rep: {}, plafonds: {}, envoye: '', maj: '' }; }
  function normal(v) { v = v && typeof v === 'object' ? v : vierge(); if (!v.rep || typeof v.rep !== 'object') v.rep = {}; if (!v.plafonds || typeof v.plafonds !== 'object') v.plafonds = {}; if (v.cabinet === undefined) v.cabinet = null; return v; }
  var S = vierge();
  var URL_ETAT = 'MonCabinet.ashx', tEnvoi = null;
  function envoyer() {
    tEnvoi = null;
    fetch(URL_ETAT, { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(S) })
      .then(function (r) { if (!r.ok) throw new Error(r.status); })
      .catch(function () { avis('Enregistrement impossible pour l\'instant. Réessayez.'); });
  }
  function sauver() {
    S.maj = new Date().toISOString();
    clearTimeout(tEnvoi); tEnvoi = setTimeout(envoyer, 400);
    try { document.dispatchEvent(new CustomEvent('s60:mon-cabinet', { detail: JSON.parse(JSON.stringify(S)) })); } catch (e) {}
  }
  /* Lecture à l'ouverture. Un ancien état gardé dans ce navigateur est repris une seule fois, si le serveur n'a encore rien. */
  function charger() {
    fetch(URL_ETAT, { credentials: 'same-origin', cache: 'no-store' }).then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); }).then(function (d) {
      var local = null; try { local = JSON.parse(localStorage.getItem(CLE) || 'null'); } catch (e) {}
      if (d && d.etat) S = normal(d.etat);
      else if (local && typeof local === 'object' && (local.cabinet || (local.rep && Object.keys(local.rep).length))) { S = normal(local); sauver(); }
      try { localStorage.removeItem(CLE); } catch (e) {}
      page.removeAttribute('aria-busy'); toutRendre();
    }).catch(function () { page.removeAttribute('aria-busy'); avis('Lecture impossible pour l\'instant. Rechargez la fenêtre.'); });
  }
  window.S60MonCabinet = { lire: function () { return JSON.parse(JSON.stringify(S)); }, ecrire: function (e) { S = normal(e); sauver(); toutRendre(); } };
  function qui(a) { return S.rep[a.id] || a.sugg; }
  function plafond(a) { var v = S.plafonds[a.id]; return v == null || isNaN(v) ? PLAFOND_DEF : +v; }
  function implique(v) { return v === 'cabinet' || v === 'partage'; }
  function conflits() {
    return PAIRES.filter(function (p) { return implique(qui(PAR_ID[p[0]])) && implique(qui(PAR_ID[p[1]])); });
  }
  function compte() {
    var c = { client: 0, cabinet: 0, partage: 0, aucun: 0 };
    ACT.forEach(function (a) { c[qui(a)]++; }); return c;
  }

  /* ---------- Avis ---------- */
  var avisEl = document.createElement('div'); avisEl.className = 's60c-avis'; avisEl.setAttribute('role', 'status'); avisEl.hidden = true; document.body.appendChild(avisEl);
  var tAvis; function avis(t) { avisEl.textContent = t; avisEl.hidden = false; clearTimeout(tAvis); tAvis = setTimeout(function () { avisEl.hidden = true; }, 3000); }

  /* ---------- Structure : en-tête + onglets ---------- */
  var tete = $('.boite', page), h1 = $('.cab-head h1', page), sous = $('.cab-head .sub', page);
  var lede = $('.cab-lede', page), outils = $('.cab-outils', page), liste = $('#cabListe', page), videListe = $('#cabVide', page);
  if (h1) h1.textContent = 'Mon cabinet comptable';
  if (sous) sous.textContent = 'Votre cabinet, ce qu\'il fait au nom de votre entreprise et ce que vous gardez.';

  var nbCab = liste ? $$('.cab-carte', liste).length : 0;
  var nav = document.createElement('div'); nav.className = 's60c-onglets'; nav.setAttribute('role', 'tablist');
  nav.innerHTML = '<button type="button" role="tab" data-v="moncab" id="s60c-t-moncab" aria-controls="s60c-v-moncab">' + ic('handshake') + 'Mon cabinet</button>' +
    '<button type="button" role="tab" data-v="qfq" id="s60c-t-qfq" aria-controls="s60c-v-qfq">' + ic('users') + 'Qui fait quoi <span class="n" id="s60c-n-qfq"></span></button>' +
    '<button type="button" role="tab" data-v="annuaire" id="s60c-t-annuaire" aria-controls="s60c-v-annuaire">' + ic('search') + 'Cabinets certifiés <span class="n">' + nbCab + '</span></button>';
  tete.appendChild(nav);

  function vue(id) { var d = document.createElement('div'); d.className = 's60c-vue'; d.id = 's60c-v-' + id; d.setAttribute('role', 'tabpanel'); d.setAttribute('aria-labelledby', 's60c-t-' + id); return d; }
  var vMon = vue('moncab'), vQfq = vue('qfq'), vAnn = vue('annuaire');
  tete.parentNode.insertBefore(vMon, tete.nextSibling);
  vMon.parentNode.insertBefore(vQfq, vMon.nextSibling);
  vQfq.parentNode.insertBefore(vAnn, vQfq.nextSibling);
  /* L'annuaire d'origine (texte, recherche, cartes, message vide) passe dans son onglet ; les écouteurs suivent. */
  var boiteAnn = document.createElement('div'); boiteAnn.className = 's60c-boite';
  boiteAnn.innerHTML = '<div class="s60c-etiq">Annuaire</div><h2 style="margin:2px 0 10px">Cabinets certifiés 60secondes</h2>';
  if (lede) boiteAnn.appendChild(lede);
  if (outils) boiteAnn.appendChild(outils);
  vAnn.appendChild(boiteAnn);
  if (liste) vAnn.appendChild(liste);
  if (videListe) vAnn.appendChild(videListe);
  var inviter = document.createElement('div'); inviter.className = 's60c-inviter';
  inviter.innerHTML = '<div class="t"><b>Votre comptable n\'est pas dans la liste ?</b>Invitez-le : il pourra travailler dans votre dossier et devenir certifié.</div>' +
    '<a class="s60c-btn" data-s60c="inviter" href="#">' + ic('mail') + 'Inviter mon comptable</a>';
  vAnn.appendChild(inviter);

  var courante = '';
  function montrer(id, focus) {
    courante = id;
    $$('button[role=tab]', nav).forEach(function (b) { var on = b.getAttribute('data-v') === id; b.setAttribute('aria-selected', on ? 'true' : 'false'); b.tabIndex = on ? 0 : -1; if (on && focus) b.focus(); if (on && b.scrollIntoView && nav.scrollWidth > nav.clientWidth) nav.scrollLeft = b.offsetLeft - 16; });
    [vMon, vQfq, vAnn].forEach(function (v) { v.hidden = v.id !== 's60c-v-' + id; });
    try { sessionStorage.setItem(CLE + '-onglet', id); } catch (e) {}
  }
  nav.addEventListener('click', function (e) { var b = e.target.closest('button[role=tab]'); if (b) montrer(b.getAttribute('data-v')); });
  nav.addEventListener('keydown', function (e) {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
    var ids = ['moncab', 'qfq', 'annuaire'], i = ids.indexOf(courante);
    montrer(ids[(i + (e.key === 'ArrowRight' ? 1 : 2)) % 3], true); e.preventDefault();
  });

  /* ---------- Cartes de l'annuaire : lire les données et ajouter « Choisir » ---------- */
  function lireCarte(c) {
    var mail = $('.cab-actions a[href^="mailto:"]', c), site = $('.cab-actions a.sec', c), tel = $('.cab-actions .tel', c);
    return {
      nom: ($('h2', c) || {}).textContent || '', resp: ($('.cab-resp', c) || {}).textContent || '',
      init: ($('.cab-av', c) || {}).textContent || '', cert: (($('.cab-cert', c) || {}).textContent || '').trim(),
      lieu: (($('.cab-badges .lieu', c) || {}).textContent || '').trim(), langues: (($('.cab-badges .lang', c) || {}).textContent || '').trim(),
      courriel: mail ? mail.getAttribute('href').replace(/^mailto:/, '') : '', site: site ? site.getAttribute('href') : '',
      tel: tel ? tel.textContent.replace(/^T[ée]l\.?\s*/, '').trim() : ''
    };
  }
  var CARTES = liste ? $$('.cab-carte', liste) : [];
  CARTES.forEach(function (c) {
    var b = document.createElement('button'); b.type = 'button'; b.className = 's60c-choisir';
    b.addEventListener('click', function () {
      var d = lireCarte(c); if (S.cabinet && S.cabinet.nom === d.nom) return;
      var avant = S.cabinet; S.cabinet = d; S.envoye = ''; sauver(); toutRendre(); montrer('moncab');
      avis(avant ? 'Cabinet changé. Votre répartition est conservée.' : d.nom + ' est maintenant votre cabinet.');
    });
    var act = $('.cab-actions', c); if (act) act.appendChild(b);
  });
  function rendreCartes() {
    CARTES.forEach(function (c) {
      var on = !!(S.cabinet && S.cabinet.nom === ($('h2', c) || {}).textContent);
      c.classList.toggle('s60c-choisi', on);
      var b = $('.s60c-choisir', c); b.classList.toggle('on', on);
      b.innerHTML = on ? ic('check-circle') + 'Votre cabinet' : ic('plus') + 'Choisir ce cabinet';
      b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
  }

  /* ---------- Clé comptable (Paramètres › Comptable), lecture seule ---------- */
  var cle = { etat: 'lecture', val: '' };
  function lireCle() {
    if (window.__s60CleApercu != null) { cle = { etat: 'ok', val: window.__s60CleApercu }; rendreMon(); return; }
    fetch('wbfSetting', { credentials: 'same-origin' }).then(function (r) { return r.text(); }).then(function (h) {
      var d = new DOMParser().parseFromString(h, 'text/html');
      var cache = Array.prototype.filter.call(d.querySelectorAll('input[type=hidden]'), function (i) { return i.value === 'COMPTABLE' && /hidShortName/.test(i.name); })[0];
      var champ = cache && cache.closest('.field') && cache.closest('.field').querySelector('input.riTextBox, input[type=text]');
      cle = champ ? { etat: 'ok', val: champ.value || '' } : { etat: 'inconnu', val: '' };
      rendreMon();
    }).catch(function () { cle = { etat: 'inconnu', val: '' }; rendreMon(); });
  }

  /* ---------- Vue 1 : Mon cabinet ---------- */
  var retraitArme = false;
  function rendreMon() {
    var c = compte(), conf = conflits(), cab = S.cabinet, h = '';
    if (!cab) {
      h += '<section class="s60c-boite"><div class="s60c-vide"><div class="ill">' + ic('handshake') + '</div><div class="t">' +
        '<h2>Vous n\'avez pas encore de cabinet comptable</h2><p class="aide">Choisissez un cabinet certifié ou invitez votre propre comptable. Vous décidez ensuite, activité par activité, ce qu\'il fait au nom de votre entreprise.</p></div>' +
        '<div class="s60c-actions"><button type="button" class="s60c-btn p" data-s60c="voir-ann">' + ic('search') + 'Voir les cabinets certifiés</button>' +
        '<a class="s60c-btn" data-s60c="inviter" href="#">' + ic('mail') + 'Inviter mon comptable</a></div></div></section>';
    } else {
      var envoye = S.envoye ? '<span class="s60c-puce ok">' + ic('check-circle') + 'Répartition proposée le ' + new Date(S.envoye).toLocaleDateString('fr-CA', { day: 'numeric', month: 'long' }) + '</span>' : '<span class="s60c-puce att">' + ic('alert') + 'Répartition à envoyer au cabinet</span>';
      h += '<section class="s60c-boite"><div class="s60c-moncab"><div class="av" aria-hidden="true">' + esc(cab.init) + '</div><div class="t">' +
        '<div class="s60c-etiq">Votre cabinet</div><h2>' + esc(cab.nom) + '</h2><div class="resp">' + esc(cab.resp) + (cab.lieu ? ' · ' + esc(cab.lieu) : '') + (cab.tel ? ' · Tél. ' + esc(cab.tel) : '') + '</div>' +
        '<div class="s60c-puces">' + (cab.cert ? '<span class="s60c-puce ok">' + ic('check-circle') + esc(cab.cert) + '</span>' : '') + envoye + (cab.langues ? '<span class="s60c-puce">' + esc(cab.langues) + '</span>' : '') + '</div></div>' +
        '<div class="s60c-actions">' + (cab.courriel ? '<a class="s60c-btn p" href="mailto:' + esc(cab.courriel) + '">' + ic('mail') + 'Écrire</a>' : '') +
        (cab.site ? '<a class="s60c-btn" href="' + esc(cab.site) + '" target="_blank" rel="noopener">' + ic('globe') + 'Site web</a>' : '') + '</div></div>' +
        '<hr class="s60c-sep"><div style="display:flex;justify-content:space-between;align-items:baseline;gap:10px;flex-wrap:wrap"><h2>Qui fait quoi, en bref</h2><button type="button" class="s60c-btn lien" data-s60c="voir-qfq">Modifier la répartition</button></div>' +
        '<div class="s60c-trois">' + tuile('client', 'Vous', c.client, 'activités que vous gardez') + tuile('cabinet', 'Mon cabinet', c.cabinet, 'faites en votre nom') + tuile('partage', 'Ensemble', c.partage, 'le cabinet prépare, vous approuvez') + '</div>' +
        '<div class="s60c-barre-rep" aria-hidden="true">' + ['client', 'cabinet', 'partage'].map(function (k) { return c[k] ? '<i style="flex:' + c[k] + ';background:var(--q-' + (k === 'client' ? 'client' : k === 'cabinet' ? 'cab' : 'ens') + ')"></i>' : ''; }).join('') + '</div>' +
        '<div class="s60c-actions" style="margin-top:16px"><button type="button" class="s60c-btn" data-s60c="voir-ann">' + ic('refresh') + 'Changer de cabinet</button>' +
        '<button type="button" class="s60c-btn lien" data-s60c="retirer">' + (retraitArme ? 'Confirmer : retirer ' + esc(cab.nom) : 'Retirer ce cabinet') + '</button></div></section>';
    }
    /* Accès et garde-fous */
    var payCab = ACT.filter(function (a) { return a.pay && qui(a) === 'cabinet'; });
    var cleTxt = cle.etat === 'lecture' ? 'Vérification…' : cle.etat === 'inconnu' ? 'Impossible de lire vos paramètres pour l\'instant.' : cle.val ? 'Clé créée (••••' + esc(cle.val.slice(-4)) + '). Le cabinet consulte vos données sans être un utilisateur de votre compte.' : 'Aucune clé pour l\'instant. Créez-la dans Paramètres › Comptable, puis donnez-la à votre cabinet.';
    h += '<section class="s60c-boite"><h2>Accès et garde-fous</h2><p class="aide">Ce qui protège votre entreprise quand le cabinet agit en son nom.</p><div class="s60c-garde">' +
      '<div class="' + (cle.val ? 'ok' : cle.etat === 'ok' ? 'warn' : '') + '">' + ic('key') + '<div><b>Clé comptable</b><span>' + cleTxt + '</span>' + (cle.etat === 'ok' ? '<a class="s60c-btn lien" href="wbfSetting" target="_top">Ouvrir Paramètres › Comptable</a>' : '') + '</div></div>' +
      '<div>' + ic('coins') + '<div><b>Plafond par paiement</b><span>' + (payCab.length ? payCab.map(function (a) { return esc(a.nom) + ' : ' + argent(plafond(a)); }).join(' · ') + '. Au-delà, votre approbation est demandée.' : 'Le cabinet ne paie rien seul : chaque paiement passe par votre approbation.') + '</span></div></div>' +
      '<div class="' + (conf.length ? 'warn' : 'ok') + '">' + ic('shield') + '<div><b>Séparation des tâches</b><span>' + (conf.length ? conf.length + ' paire' + (conf.length > 1 ? 's' : '') + ' de tâches confiée' + (conf.length > 1 ? 's' : '') + ' au cabinet : deux personnes différentes du cabinet devront s\'en charger.' : 'Aucune paire de tâches incompatibles n\'est confiée à une seule partie.') + '</span><button type="button" class="s60c-btn lien" data-s60c="voir-qfq">Voir le détail</button></div></div>' +
      '<div>' + ic('lock') + '<div><b>Vous gardez le contrôle</b><span>Vous pouvez changer la répartition ou retirer votre cabinet en tout temps. Les honoraires, s\'il y en a, relèvent du cabinet.</span></div></div>' +
      '</div></section>';
    vMon.innerHTML = h;
  }
  function tuile(k, lab, n, s) {
    var col = k === 'client' ? 'client' : k === 'cabinet' ? 'cab' : 'ens';
    return '<button type="button" class="s60c-tuile" data-s60c="voir-qfq"><span class="lab"><i style="background:var(--q-' + col + ')"></i>' + lab + '</span><b>' + n + '</b><small>' + s + '</small></button>';
  }

  /* ---------- Vue 2 : Qui fait quoi ---------- */
  var filtre = '';
  function rendreQfq() {
    var conf = conflits(), dansConf = {}; conf.forEach(function (p) { dansConf[p[1]] = p[0]; });
    var h = '<section class="s60c-boite"><div class="s60c-etiq">Répartition des responsabilités</div><h2>Qui fait quoi dans votre dossier</h2>' +
      '<p class="aide">Pour chaque activité, choisissez qui s\'en occupe. Ce que vous faites vous-même, le cabinet ne le fait pas en double.</p>' +
      '<div class="s60c-legende"><div class="c"><b>Vous</b>Vous vous en occupez dans 60secondes.</div><div class="k"><b>Mon cabinet</b>Le cabinet le fait au nom de votre entreprise.</div><div class="e"><b>Ensemble</b>Le cabinet prépare ; vous approuvez.</div></div>' +
      '<div class="s60c-filtres" role="group" aria-label="Filtrer par domaine"><button type="button" data-f="" aria-pressed="' + (!filtre) + '">Tout (' + ACT.length + ')</button>' +
      DOMAINES.map(function (d) { return '<button type="button" data-f="' + d[0] + '" aria-pressed="' + (filtre === d[0]) + '">' + esc(d[1]) + '</button>'; }).join('') +
      '<span class="esp"></span><button type="button" data-s60c="suggere">' + ic('refresh') + ' Répartition suggérée</button></div>';
    DOMAINES.forEach(function (d) {
      if (filtre && filtre !== d[0]) return;
      var acts = ACT.filter(function (a) { return a.dom === d[0]; });
      var nCab = acts.filter(function (a) { return implique(qui(a)); }).length;
      h += '<div class="s60c-dom"><div class="s60c-dom-t">' + ic(d[2]) + '<h3>' + esc(d[1]) + '</h3><span class="cpt">' + nCab + ' sur ' + acts.length + ' avec le cabinet</span></div>';
      acts.forEach(function (a) {
        var v = qui(a), opts = a.mode === 'oui' ? ['cabinet', 'aucun'] : ['client', 'cabinet', 'partage'];
        h += '<div class="s60c-act" data-a="' + a.id + '"><div><div class="nom" id="s60c-l-' + a.id + '">' + esc(a.nom) + '</div><div class="desc">' + esc(a.desc) + '</div></div>' +
          '<div class="s60c-seg" role="radiogroup" aria-labelledby="s60c-l-' + a.id + '">' + opts.map(function (o) {
            return '<label class="' + o + (v === o ? ' on' : '') + '"><input type="radio" name="s60c-' + a.id + '" value="' + o + '"' + (v === o ? ' checked' : '') + '>' + QUI[o] + '</label>';
          }).join('') + '</div><div class="effet">' + effet(a, v) + '</div>';
        if (dansConf[a.id]) {
          h += '<div class="alerte" role="note">' + ic('shield') + '<span>Séparation des tâches : « ' + esc(PAR_ID[dansConf[a.id]].nom) + ' » et « ' + esc(a.nom) + ' » sont tous deux confiés au cabinet. Deux personnes différentes du cabinet devront s\'en charger, ou gardez l\'une des deux.</span></div>';
        }
        h += '</div>';
      });
      h += '</div>';
    });
    var c = compte(), cab = S.cabinet;
    h += '<div class="s60c-pied"><div class="r"><b>' + c.client + '</b> pour vous · <b>' + c.cabinet + '</b> pour le cabinet · <b>' + c.partage + '</b> ensemble' + (conf.length ? ' · <b>' + conf.length + '</b> à séparer' : '') + '</div>' +
      '<button type="button" class="s60c-btn" data-s60c="copier">' + ic('clipboard') + 'Copier</button>' +
      '<button type="button" class="s60c-btn" data-s60c="imprimer">' + ic('printer') + 'Imprimer</button>' +
      (cab && cab.courriel ? '<a class="s60c-btn p" data-s60c="envoyer" href="' + esc(mailto()) + '">' + ic('mail') + 'Envoyer à ' + esc(cab.nom) + '</a>' : '<button type="button" class="s60c-btn p" data-s60c="voir-ann">' + ic('search') + 'Choisir un cabinet</button>') + '</div></section>';
    vQfq.innerHTML = h;
    var n = $('#s60c-n-qfq'); n.textContent = conf.length ? conf.length : c.cabinet + c.partage; n.classList.toggle('warn', !!conf.length);
    n.title = conf.length ? 'Paires de tâches à séparer' : 'Activités avec le cabinet';
  }
  function effet(a, v) {
    if (a.mode === 'oui') return v === 'cabinet' ? '' : '<span style="color:var(--p-muted)">Le cabinet ne le fera pas.</span>';
    if (v === 'partage') return '<span style="color:var(--q-ens);font-weight:800">' + esc(a.ens) + '</span>';
    if (v === 'cabinet' && a.pay) return '<span>Le cabinet paie à votre place jusqu\'à</span><label class="s60c-plafond"><span class="sr" style="position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0)">Plafond pour ' + esc(a.nom) + '</span><input type="text" inputmode="numeric" data-plafond="' + a.id + '" value="' + plafond(a).toLocaleString('fr-CA') + '"> $</label><span>par paiement ; au-delà, vous approuvez.</span>';
    return '';
  }
  function texteRep() {
    var cab = S.cabinet, L = [];
    L.push('Répartition des responsabilités — ' + (cab ? cab.nom : 'mon cabinet comptable'));
    L.push('Légende : Vous = je m\'en occupe · Cabinet = au nom de mon entreprise · Ensemble = le cabinet prépare, j\'approuve');
    DOMAINES.forEach(function (d) {
      L.push(''); L.push(d[1].toUpperCase());
      ACT.filter(function (a) { return a.dom === d[0]; }).forEach(function (a) {
        var v = qui(a); L.push('- ' + a.nom + ' : ' + (a.mode === 'oui' ? (v === 'cabinet' ? 'Oui' : 'Non') : QUI[v] === 'Mon cabinet' ? 'Cabinet' : QUI[v]) + (v === 'cabinet' && a.pay ? ' (plafond ' + argent(plafond(a)) + ' par paiement)' : ''));
      });
    });
    var conf = conflits();
    if (conf.length) { L.push(''); L.push('Séparation des tâches à respecter : ' + conf.map(function (p) { return PAR_ID[p[0]].nom + ' / ' + PAR_ID[p[1]].nom; }).join(' ; ')); }
    return L.join('\n');
  }
  function mailto() {
    var cab = S.cabinet || {};
    return 'mailto:' + (cab.courriel || '') + '?subject=' + encodeURIComponent('60secondes — ce que je vous confie dans mon dossier') +
      '&body=' + encodeURIComponent('Bonjour,\n\nVoici la répartition des tâches que je propose pour mon dossier 60secondes. Pouvez-vous me confirmer qu\'elle vous convient ?\n\n' + texteRep() + '\n\nMerci !');
  }
  function mailInvitation() {
    return 'mailto:?subject=' + encodeURIComponent('Invitation : travailler dans mon dossier 60secondes') +
      '&body=' + encodeURIComponent('Bonjour,\n\nJ\'utilise 60secondes pour la comptabilité de mon entreprise. J\'aimerais que vous puissiez y travailler directement (tenue de livres, taxes, paie, fin d\'exercice) et, si vous le souhaitez, devenir cabinet certifié.\n\nVous pouvez commencer ici : https://www.60sec.ca\n\nMerci !');
  }

  /* ---------- Événements ---------- */
  page.addEventListener('change', function (e) {
    var r = e.target; if (!r.matches || !r.matches('.s60c-seg input')) return;
    var id = r.name.replace('s60c-', ''); S.rep[id] = r.value; sauver();
    var y = window.scrollY; rendreQfq(); rendreMon(); window.scrollTo(0, y);
    var ri = $('input[name="s60c-' + id + '"][value="' + r.value + '"]', vQfq); if (ri) ri.focus();
  });
  page.addEventListener('change', function (e) {
    var p = e.target; if (!p.matches || !p.matches('input[data-plafond]')) return;
    var n = parseInt(String(p.value).replace(/[^\d]/g, ''), 10); if (isNaN(n) || n < 0) n = PLAFOND_DEF;
    S.plafonds[p.getAttribute('data-plafond')] = n; p.value = n.toLocaleString('fr-CA'); sauver(); rendreMon(); avis('Plafond enregistré : ' + argent(n) + '.');
  });
  page.addEventListener('click', function (e) {
    var f = e.target.closest('.s60c-filtres button[data-f]');
    if (f) { filtre = f.getAttribute('data-f'); rendreQfq(); return; }
    var b = e.target.closest('[data-s60c]'); if (!b) return;
    var k = b.getAttribute('data-s60c');
    if (k === 'voir-ann') { montrer('annuaire'); var champ = $('#cabRecherche'); if (champ) champ.focus(); }
    else if (k === 'voir-qfq') montrer('qfq');
    else if (k === 'inviter') { b.setAttribute('href', mailInvitation()); }
    else if (k === 'suggere') { S.rep = {}; S.plafonds = {}; sauver(); rendreQfq(); rendreMon(); avis('Répartition suggérée appliquée.'); }
    else if (k === 'imprimer') { montrer('qfq'); window.print(); }
    else if (k === 'copier') {
      var t = texteRep();
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(t).then(function () { avis('Répartition copiée.'); }, function () { avis('Copie impossible dans cette fenêtre.'); });
      else avis('Copie impossible dans cette fenêtre.');
    }
    else if (k === 'envoyer') { b.setAttribute('href', mailto()); S.envoye = new Date().toISOString(); sauver(); setTimeout(function () { rendreMon(); }, 50); }
    else if (k === 'retirer') {
      if (!retraitArme) { retraitArme = true; rendreMon(); var bt = $('[data-s60c="retirer"]', vMon); if (bt) bt.focus(); setTimeout(function () { if (retraitArme) { retraitArme = false; rendreMon(); } }, 6000); return; }
      retraitArme = false; var nom = S.cabinet && S.cabinet.nom; S.cabinet = null; S.envoye = ''; sauver(); toutRendre(); avis(nom + ' n\'est plus votre cabinet.');
    }
  });

  function toutRendre() { rendreMon(); rendreQfq(); rendreCartes(); }
  page.setAttribute('aria-busy', 'true'); toutRendre(); lireCle(); charger();
  var dep = ''; try { dep = sessionStorage.getItem(CLE + '-onglet') || ''; } catch (e) {}
  montrer(dep || (S.cabinet ? 'moncab' : 'moncab'));
})();

