/* =====================================================================
   60secondes · Mon cabinet comptable (CabinetsCertifies.aspx) — couche de présentation v1 (2026-10-20)
   Côté navigateur seulement. Ne touche ni au filtrage d'origine (#cabRecherche), ni aux liens des cartes.
   Ajoute :
     1. Mon cabinet     — le cabinet choisi, l'accès aux données (clé COMPTABLE lue en lecture seule
                          dans wbfsetting.aspx) et les garde-fous.
     2. Qui fait quoi   — la page QuiFaitQuoi.aspx (répartition action par action) dans un cadre.
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

  /* ---------- État ---------- */
  function vierge() { return { cabinet: null, rep: {}, plafonds: {}, envoye: '', maj: '' }; }
  function normal(v) { v = v && typeof v === 'object' ? v : vierge(); if (!v.rep || typeof v.rep !== 'object') v.rep = {}; if (!v.plafonds || typeof v.plafonds !== 'object') v.plafonds = {}; if (v.cabinet === undefined) v.cabinet = null; return v; }
  var S = vierge();
  /* Seuls les administrateurs modifient (le serveur refuse les autres) ; faux tant que le serveur n'a pas répondu. */
  var modifiable = false, charge = false;
  function lectureSeule() { if (modifiable) return false; avis('Seul un administrateur peut choisir ou retirer le cabinet.'); return true; }
  var URL_ETAT = 'MonCabinet.ashx', tEnvoi = null;
  function envoyer() {
    tEnvoi = null;
    fetch(URL_ETAT, { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(S) })
      .then(function (r) { if (!r.ok) throw new Error(r.status); actualiserQfq(); })
      .catch(function () { avis('Enregistrement impossible pour l\'instant. Réessayez.'); });
  }
  function sauver() {
    if (!modifiable) return;
    S.maj = new Date().toISOString();
    clearTimeout(tEnvoi); tEnvoi = setTimeout(envoyer, 400);
    try { document.dispatchEvent(new CustomEvent('s60:mon-cabinet', { detail: JSON.parse(JSON.stringify(S)) })); } catch (e) {}
  }
  /* Lecture à l'ouverture. Un ancien état gardé dans ce navigateur est repris une seule fois, si le serveur n'a encore rien. */
  function charger() {
    fetch(URL_ETAT, { credentials: 'same-origin', cache: 'no-store' }).then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); }).then(function (d) {
      var local = null; try { local = JSON.parse(localStorage.getItem(CLE) || 'null'); } catch (e) {}
      modifiable = !!(d && d.modifiable); charge = true;
      if (d && d.etat) S = normal(d.etat);
      else if (local && typeof local === 'object' && (local.cabinet || (local.rep && Object.keys(local.rep).length)) && modifiable) { S = normal(local); sauver(); }
      if (modifiable) { try { localStorage.removeItem(CLE); } catch (e) {} }
      page.removeAttribute('aria-busy'); toutRendre();
    }).catch(function () { page.removeAttribute('aria-busy'); avis('Lecture impossible pour l\'instant. Rechargez la page.'); });
  }
  window.S60MonCabinet = { lire: function () { return JSON.parse(JSON.stringify(S)); }, ecrire: function (e) { S = normal(e); sauver(); toutRendre(); } };

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
    '<button type="button" role="tab" data-v="qfq" id="s60c-t-qfq" aria-controls="s60c-v-qfq">' + ic('users') + 'Qui fait quoi</button>' +
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
    if (id === 'qfq') chargerQfq();
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
      if (lectureSeule()) return;
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
    var cab = S.cabinet, h = '';
    if (charge && !modifiable) h += '<p class="s60c-lecture">' + ic('lock') + 'Consultation seulement : seul un administrateur de votre compagnie peut choisir ou retirer le cabinet.</p>';
    if (!cab) {
      h += '<section class="s60c-boite"><div class="s60c-vide"><div class="ill">' + ic('handshake') + '</div><div class="t">' +
        '<h2>Vous n\'avez pas encore de cabinet comptable</h2><p class="aide">Choisissez un cabinet certifié ou invitez votre propre comptable. Vous décidez ensuite, activité par activité, ce qu\'il fait au nom de votre entreprise.</p></div>' +
        '<div class="s60c-actions"><button type="button" class="s60c-btn p" data-s60c="voir-ann">' + ic('search') + 'Voir les cabinets certifiés</button>' +
        '<a class="s60c-btn" data-s60c="inviter" href="#">' + ic('mail') + 'Inviter mon comptable</a></div></div></section>';
    } else {
      h += '<section class="s60c-boite"><div class="s60c-moncab"><div class="av" aria-hidden="true">' + esc(cab.init) + '</div><div class="t">' +
        '<div class="s60c-etiq">Votre cabinet</div><h2>' + esc(cab.nom) + '</h2><div class="resp">' + esc(cab.resp) + (cab.lieu ? ' · ' + esc(cab.lieu) : '') + (cab.tel ? ' · Tél. ' + esc(cab.tel) : '') + '</div>' +
        '<div class="s60c-puces">' + (cab.cert ? '<span class="s60c-puce ok">' + ic('check-circle') + esc(cab.cert) + '</span>' : '') + (cab.langues ? '<span class="s60c-puce">' + esc(cab.langues) + '</span>' : '') + '</div></div>' +
        '<div class="s60c-actions">' + (cab.courriel ? '<a class="s60c-btn p" href="mailto:' + esc(cab.courriel) + '">' + ic('mail') + 'Écrire</a>' : '') +
        (cab.site ? '<a class="s60c-btn" href="' + esc(cab.site) + '" target="_blank" rel="noopener">' + ic('globe') + 'Site web</a>' : '') + '</div></div>' +
        '<hr class="s60c-sep"><div style="display:flex;justify-content:space-between;align-items:baseline;gap:10px;flex-wrap:wrap"><h2>Qui fait quoi</h2><button type="button" class="s60c-btn lien" data-s60c="voir-qfq">Voir la répartition</button></div>' +
        '<p class="aide">Action par action : ce que vous faites, ce que fait votre cabinet, ce que vous partagez et ce que 60secondes fait seul.</p>' +
        '<div class="s60c-actions" style="margin-top:16px"><button type="button" class="s60c-btn" data-s60c="voir-ann">' + ic('refresh') + 'Changer de cabinet</button>' +
        '<button type="button" class="s60c-btn lien" data-s60c="retirer">' + (retraitArme ? 'Confirmer : retirer ' + esc(cab.nom) : 'Retirer ce cabinet') + '</button></div></section>';
    }
    /* Accès et garde-fous */
    var cleTxt = cle.etat === 'lecture' ? 'Vérification…' : cle.etat === 'inconnu' ? 'Impossible de lire vos paramètres pour l\'instant.' : cle.val ? 'Clé créée (••••' + esc(cle.val.slice(-4)) + '). Le cabinet consulte vos données sans être un utilisateur de votre compte.' : 'Aucune clé pour l\'instant. Créez-la dans Paramètres › Comptable, puis donnez-la à votre cabinet.';
    h += '<section class="s60c-boite"><h2>Accès et garde-fous</h2><p class="aide">Ce qui protège votre entreprise quand le cabinet agit en son nom.</p><div class="s60c-garde">' +
      '<div class="' + (cle.val ? 'ok' : cle.etat === 'ok' ? 'warn' : '') + '">' + ic('key') + '<div><b>Clé comptable</b><span>' + cleTxt + '</span>' + (cle.etat === 'ok' ? '<a class="s60c-btn lien" href="wbfSetting" target="_top">Ouvrir Paramètres › Comptable</a>' : '') + '</div></div>' +
      '<div>' + ic('lock') + '<div><b>Vous gardez le contrôle</b><span>Vous pouvez changer la répartition ou retirer votre cabinet en tout temps. Les honoraires, s\'il y en a, relèvent du cabinet.</span></div></div>' +
      '</div></section>';
    vMon.innerHTML = h;
  }
  /* ---------- Vue 2 : Qui fait quoi ----------
     La page QuiFaitQuoi.aspx (répartition action par action, inventaire 60secondes) dans un cadre.
     Chargée à la première ouverture de l'onglet ; rechargée si le cabinet choisi change (elle l'affiche). */
  var cadreQfq = null, cabQfq = null;
  function rendreQfq() {
    if (!cadreQfq) {
      vQfq.innerHTML = '<iframe class="s60c-qfq-cadre" title="Qui fait quoi"></iframe>';
      cadreQfq = $('iframe', vQfq);
    }
  }
  /* Après l'enregistrement : si le cabinet a changé, la page relit son contexte au serveur. */
  function actualiserQfq() {
    var nom = S.cabinet ? S.cabinet.nom : '';
    if (cadreQfq && cadreQfq.getAttribute('src') && cabQfq !== nom) { cabQfq = nom; cadreQfq.contentWindow.location.reload(); }
  }
  function chargerQfq() { if (cadreQfq && !cadreQfq.getAttribute('src')) { cabQfq = S.cabinet ? S.cabinet.nom : ''; cadreQfq.setAttribute('src', 'QuiFaitQuoi'); } }
  function mailInvitation() {
    return 'mailto:?subject=' + encodeURIComponent('Invitation : travailler dans mon dossier 60secondes') +
      '&body=' + encodeURIComponent('Bonjour,\n\nJ\'utilise 60secondes pour la comptabilité de mon entreprise. J\'aimerais que vous puissiez y travailler directement (tenue de livres, taxes, paie, fin d\'exercice) et, si vous le souhaitez, devenir cabinet certifié.\n\nVous pouvez commencer ici : https://www.60sec.ca\n\nMerci !');
  }
  /* ---------- Événements ---------- */
  page.addEventListener('click', function (e) {
    var b = e.target.closest('[data-s60c]'); if (!b) return;
    var k = b.getAttribute('data-s60c');
    if (k === 'voir-ann') { montrer('annuaire'); var champ = $('#cabRecherche'); if (champ) champ.focus(); }
    else if (k === 'voir-qfq') montrer('qfq');
    else if (k === 'inviter') { b.setAttribute('href', mailInvitation()); }
    else if (k === 'retirer' && lectureSeule()) { return; }
    else if (k === 'retirer') {
      if (!retraitArme) { retraitArme = true; rendreMon(); var bt = $('[data-s60c="retirer"]', vMon); if (bt) bt.focus(); setTimeout(function () { if (retraitArme) { retraitArme = false; rendreMon(); } }, 6000); return; }
      retraitArme = false; var nom = S.cabinet && S.cabinet.nom; S.cabinet = null; S.envoye = ''; sauver(); toutRendre(); avis(nom + ' n\'est plus votre cabinet.');
    }
  });

  function toutRendre() { rendreMon(); rendreQfq(); rendreCartes(); droits(); }
  /* Lecture seule : les contrôles de modification sont désactivés (le serveur refuse de toute façon). */
  function droits() {
    page.classList.toggle('s60c-ro', charge && !modifiable);
    $$('.s60c-choisir, [data-s60c="retirer"]', page).forEach(function (el) { el.disabled = charge && !modifiable; });
  }
  page.setAttribute('aria-busy', 'true'); toutRendre(); lireCle(); charger();
  var dep = ''; try { dep = sessionStorage.getItem(CLE + '-onglet') || ''; } catch (e) {}
  montrer(dep || (S.cabinet ? 'moncab' : 'moncab'));
})();

