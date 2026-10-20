/* =====================================================================
   60secondes · Paramètres (wbfsetting.aspx) — améliorations d'affichage v1 (2026-10-20)
   Côté navigateur seulement. Ne change ni les clés, ni les valeurs enregistrées,
   ni les contrôles serveur. Les boutons de la barre d'enregistrement cliquent
   simplement les vrais boutons Enregistrer (btnSave) et Recharger (btnReload).
   ===================================================================== */
(function () {
  'use strict';
  var root = document.getElementById('divMain');
  if (!root || !root.querySelector('.form-grid')) return;
  var $$ = function (s, r) { return [].slice.call((r || root).querySelectorAll(s)); };

  /* Sections par onglet : [titre, description, [clés]] — l'ordre suit la liste.
     Une clé ajoutée plus tard en base s'affiche quand même, à la fin. */
  var SECTIONS = {
    rpEntreprise: [
      ['Identité de l\'entreprise', 'Tel qu\'inscrit au Registraire des entreprises et à l\'ARC.', ['LEGAL_NAME', 'TRADE_NAME', 'STRUCTURE', 'INCORP_DATE', 'NEQ', 'FED_BN', 'CAE', 'SIN']],
      ['Coordonnées', 'L\'adresse et le téléphone qui paraissent sur vos documents.', ['PHONE', 'ADDR1', 'ADDR2', 'CITY', 'PROVINCE', 'POSTAL', 'COUNTRY']],
      ['Exercice financier', 'Sert aux rapports, à la fermeture d\'année et aux échéances fiscales.', ['FISCAL_YEAR_END']]
    ],
    rpTaxes: [
      ['Inscription', 'Vos numéros paraissent sur chaque facture.', ['GST_NO', 'QST_NO', 'TPS_REG_DATE', 'TVQ_REG_DATE', 'HST_NO']],
      ['Calcul des taxes', 'Les taux du Québec sont préremplis. Ne les changez que sur avis de votre comptable.', ['TAX_MODE', 'TAX_ROUNDING', 'GST_RATE', 'QST_RATE']],
      ['Remises', 'Quand et d\'où sont payées vos remises de TPS et de TVQ.', ['TAX_FREQ', 'TAX_PAY_BANK']]
    ],
    rpEmail: [['Expéditeur', 'L\'adresse et la signature des courriels envoyés à vos clients.', ['MAIL_FROM_EMAIL', 'MAIL_SIGNATURE']]],
    rpPdf: [
      ['Numérotation des factures', 'Chaque facture reçoit un numéro unique et suivi.', ['INV_NUM_PREFIX', 'INV_NUM_FORMAT', 'INV_NUM_DIGITS', 'INV_NUM_START', 'INV_NUM_RESET_YEARLY', 'INV_DRAFT_PREFIX']],
      ['Document PDF', 'Ce qui s\'imprime sur vos factures et ce qui se passe après le paiement.', ['PDF_TEMPLATE', 'PDF_PAID_STAMP', 'PDF_EMAIL_AFTER_PAY', 'PDF_PAYMENT_TERMS', 'PDF_NOTES']]
    ],
    rpTraitement: [['Traitement automatique', 'Ce que 60secondes fait sans vous demander.', ['RECEIPT_AUTO_POST']]],
    rpComptabilite: [
      ['Ventes et achats', 'Les comptes utilisés par la comptabilisation automatique.', ['VP', 'AP', 'CC', 'CF']],
      ['Capitaux propres', 'Les comptes du propriétaire et des résultats accumulés.', ['DP', 'BNR', 'BNE']],
      ['Journal', '', ['JOURNAL_OD']]
    ],
    rpBancaire: [['Compte par défaut', '', ['COMPTE_BANQUE']]],
    rpComptable: [['Accès de votre comptable', '', ['COMPTABLE']]]
  };
  var PLEINE = { MAIL_SIGNATURE: 1, PDF_PAYMENT_TERMS: 1, PDF_NOTES: 1, COMPTE_BANQUE: 1, COMPTABLE: 1 };
  var NOTES = {
    NEQ: '10 chiffres, au Registraire des entreprises du Québec.',
    FED_BN: 'Numéro d\'entreprise de l\'ARC : 9 chiffres, puis RC0001.',
    CAE: 'Code SCIAN de 6 chiffres qui décrit votre activité principale.',
    SIN: 'Masqué à l\'écran. Requis seulement pour une entreprise individuelle.',
    STRUCTURE: 'Ex. entreprise individuelle, société par actions, SENC.',
    GST_NO: '9 chiffres, puis RT0001.', QST_NO: '10 chiffres, puis TQ0001.', HST_NO: 'Seulement si vous êtes inscrit à la TVH (provinces harmonisées).',
    TAX_MODE: 'Taxes en sus : les prix de vos produits sont avant taxes.',
    TAX_ROUNDING: 'Recommandé : 2 décimales (au cent).',
    MAIL_FROM_EMAIL: 'Vérifiez l\'adresse pour que vos courriels n\'arrivent pas dans les indésirables.',
    INV_NUM_DIGITS: 'Ex. 4 chiffres donne 0001.',
    INV_DRAFT_PREFIX: 'Numéro temporaire d\'une facture pas encore émise.',
    PDF_PAID_STAMP: 'Ajoute la mention PAYÉ sur le PDF d\'une facture réglée.',
    PDF_EMAIL_AFTER_PAY: 'Envoie le reçu au client dès que son paiement est reçu.',
    RECEIPT_AUTO_POST: 'Oui : les reçus analysés sont inscrits aux livres sans attendre votre approbation.',
    JOURNAL_OD: 'Code utilisé pour les écritures de régularisation (opérations diverses).',
    COMPTE_BANQUE: 'Compte utilisé pour les encaissements et les décaissements.',
    COMPTABLE: 'Donnez cette clé à votre comptable : il consulte vos données sans être un utilisateur de votre compte.'
  };

  /* ---------- Repérage des champs par leur clé ---------- */
  var champs = {};
  $$('input[id*="hidShortName"]').forEach(function (h) {
    var f = h.closest('.field'); if (!f) return;
    var k = h.value; champs[k] = f; f.setAttribute('data-cle', k);
    var lab = f.querySelector('label'); if (lab) lab.title = k;
    if (PLEINE[k]) f.classList.add('s60-large');
  });
  function saisie(k) { var f = champs[k]; return f && (f.querySelector('input.riTextBox, textarea.riTextBox, input.rcbInput')); }
  function valeur(k) { var i = saisie(k); return i ? i.value.trim() : ''; }
  function ecrire(k, v) { var i = saisie(k); if (!i || i.value === v) return; var c = window.$find && $find(i.id); if (c && c.set_value) c.set_value(v); else i.value = v; }
  function note(k, txt, cls) {
    var f = champs[k]; if (!f) return; var n = f.querySelector('.s60-note');
    if (!n) { n = document.createElement('div'); n.className = 's60-note'; f.appendChild(n); }
    n.innerHTML = txt || ''; f.classList.remove('s60-err', 's60-ok', 's60-warn'); if (cls) f.classList.add(cls);
  }

  /* ---------- Sections (ordre visuel seulement, aucun déplacement de contrôle) ---------- */
  $$('.rmpView .form-grid').forEach(function (g) {
    var any = g.querySelector('input[id*="hidShortName"]'); if (!any) return;
    var rp = (any.name.match(/\$(rp\w+)\$/) || [])[1]; var secs = SECTIONS[rp]; if (!secs) return;
    var ordre = 0;
    secs.forEach(function (s, i) {
      var t = document.createElement('div'); t.className = 's60-sec' + (i === 0 ? ' premier' : ''); ordre += 10; t.style.order = ordre;
      t.innerHTML = '<h3><span class="n">' + (i + 1) + '</span>' + s[0] + '</h3>' + (s[1] ? '<p>' + s[1] + '</p>' : '');
      g.appendChild(t);
      s[2].forEach(function (k) { if (champs[k] && g.contains(champs[k])) { ordre += 10; champs[k].style.order = ordre; } });
    });
    $$('.field', g).forEach(function (f) { if (!f.style.order) f.style.order = 9000; });
  });
  Object.keys(NOTES).forEach(function (k) { if (champs[k]) note(k, NOTES[k]); });

  /* ---------- NAS : masqué, avec un œil ---------- */
  (function () {
    var f = champs.SIN, i = saisie('SIN'); if (!f || !i) return;
    var lab = f.querySelector('label'); if (lab) lab.insertAdjacentHTML('beforeend', ' <span class="s60-sensible">Confidentiel</span>');
    var w = i.closest('.RadInput') || i.parentNode; w.classList.add('s60-avec-btn'); f.classList.add('s60-masque');
    i.setAttribute('autocomplete', 'off');
    var b = document.createElement('button'); b.type = 'button'; b.className = 's60-oeil'; b.setAttribute('aria-label', 'Afficher ou masquer le NAS');
    b.addEventListener('click', function () { f.classList.toggle('s60-masque'); }); w.appendChild(b);
  })();

  /* ---------- Validation douce (mise en forme au départ du champ) ---------- */
  var REGLES = {
    NEQ: function (v) { v = v.replace(/\s/g, ''); return [v, !v || /^\d{10}$/.test(v) ? '' : 'Le NEQ compte 10 chiffres.']; },
    FED_BN: function (v) { v = v.replace(/\s/g, '').toUpperCase(); return [v, !v || /^\d{9}([A-Z]{2}\d{4})?$/.test(v) ? '' : 'Format attendu : 123456789RC0001.']; },
    GST_NO: function (v) { v = v.replace(/\s/g, '').toUpperCase(); return [v, !v || /^\d{9}RT\d{4}$/.test(v) ? '' : 'Format attendu : 123456789RT0001.']; },
    QST_NO: function (v) { v = v.replace(/\s/g, '').toUpperCase(); return [v, !v || /^\d{10}TQ\d{4}$/.test(v) ? '' : 'Format attendu : 1234567890TQ0001.']; },
    POSTAL: function (v) { var c = v.replace(/\s/g, '').toUpperCase(); return /^[A-Z]\d[A-Z]\d[A-Z]\d$/.test(c) ? [c.slice(0, 3) + ' ' + c.slice(3), ''] : [v, v ? 'Format attendu : A1A 1A1.' : '']; },
    PHONE: function (v) { var d = v.replace(/\D/g, ''); if (d.length === 11 && d[0] === '1') d = d.slice(1); return d.length === 10 ? [d.slice(0, 3) + '-' + d.slice(3, 6) + '-' + d.slice(6), ''] : [v, v ? 'Numéro à 10 chiffres.' : '']; },
    CAE: function (v) { v = v.replace(/\s/g, ''); return [v, !v || /^\d{4,6}$/.test(v) ? '' : 'Code de 4 à 6 chiffres.']; },
    SIN: function (v) { var d = v.replace(/\D/g, ''); if (!v) return [v, '']; if (d.length !== 9) return [v, 'Le NAS compte 9 chiffres.'];
      var s = 0; for (var i = 0; i < 9; i++) { var n = +d[i] * (i % 2 ? 2 : 1); s += n > 9 ? n - 9 : n; } return [d, s % 10 ? 'Ce NAS ne semble pas valide.' : '']; },
    MAIL_FROM_EMAIL: function (v) { return [v.trim(), !v || /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v) ? '' : 'Adresse courriel incomplète.']; }
  };
  Object.keys(REGLES).forEach(function (k) {
    var i = saisie(k); if (!i) return;
    i.addEventListener('blur', function () {
      setTimeout(function () { var r = REGLES[k](i.value); ecrire(k, r[0]);
        if (r[1]) note(k, r[1], 's60-err'); else note(k, NOTES[k] || '', i.value ? 's60-ok' : ''); }, 0);
    });
  });

  /* ---------- Noms des comptes (lus dans le plan comptable, en lecture seule) ---------- */
  var COMPTES_CLES = ['VP', 'AP', 'CC', 'CF', 'DP', 'BNR', 'BNE', 'TAX_PAY_BANK'];
  var noms = null;
  function nommer() {
    if (!noms) return;
    COMPTES_CLES.forEach(function (k) {
      var v = valeur(k); if (!champs[k] || !v) return;
      var base = k === 'TAX_PAY_BANK' ? 'Compte du grand livre d\'où partent vos remises. ' : '';
      if (noms[v]) note(k, base + '<b>' + v + ' · ' + noms[v] + '</b>'); else note(k, base + 'Compte ' + v + ' introuvable dans le plan comptable.', 's60-warn');
    });
  }
  if (window.__s60PlanApercu) { noms = window.__s60PlanApercu; nommer(); COMPTES_CLES.forEach(function (k) { var i = saisie(k); if (i) i.addEventListener('blur', function () { setTimeout(nommer, 0); }); }); }
  else if (COMPTES_CLES.some(function (k) { return champs[k]; })) {
    fetch('wbfRapportPlanComptable', { credentials: 'same-origin' }).then(function (r) { return r.text(); }).then(function (h) {
      var d = new DOMParser().parseFromString(h, 'text/html'); noms = {};
      [].slice.call(d.querySelectorAll('.comptes-table tbody tr')).forEach(function (tr) {
        var n = tr.querySelector('.col-numero'), m = tr.querySelector('.col-nom'); if (n && m) noms[n.textContent.trim()] = m.textContent.trim(); });
      nommer();
    }).catch(function () {});
    COMPTES_CLES.forEach(function (k) { var i = saisie(k); if (i) i.addEventListener('blur', function () { setTimeout(nommer, 0); }); });
  }

  /* ---------- Encarts calculés ---------- */
  function encart(apresCle, id, cls) {
    var f = champs[apresCle]; if (!f) return null; var e = document.getElementById(id);
    if (!e) { e = document.createElement('div'); e.id = id; e.className = 's60-encart ' + (cls || ''); f.parentNode.appendChild(e); e.style.order = (+f.style.order || 0) + 5; }
    return e;
  }
  function argent(v) { v = Math.round(v * 100 + 1e-7) / 100; return v.toFixed(2).replace('.', ',').replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + ' $'; }
  function num(v) { return parseFloat(String(v).replace(/\s/g, '').replace(',', '.')) || 0; }
  function exempleTaxes() {
    var e = encart('QST_RATE', 's60-ex-taxes'); if (!e) return;
    var t = num(valeur('GST_RATE')), q = num(valeur('QST_RATE')), inc = /inclus/i.test(valeur('TAX_MODE')), b = 100;
    if (inc) { var h = b / (1 + (t + q) / 100); e.innerHTML = 'Exemple : un prix de <b>' + argent(b) + '</b> taxes incluses = ' + argent(h) + ' + TPS ' + argent(h * t / 100) + ' + TVQ ' + argent(h * q / 100) + '.'; }
    else e.innerHTML = 'Exemple : un service de ' + argent(b) + ' + TPS ' + argent(b * t / 100) + ' + TVQ ' + argent(b * q / 100) + ' = <b>' + argent(b * (1 + (t + q) / 100)) + '</b>.';
  }
  var FORMATS = { 'PREFIXE-2026-0001': '{PREFIXE}-{AAAA}-{NUMERO}', 'PREFIXE202612-0001': '{PREFIXE}{AAAA}{MM}-{NUMERO}', 'PREFIXE-0001': '{PREFIXE}-{NUMERO}', '2026-0001': '{AAAA}-{NUMERO}', '0001': '{NUMERO}' };
  function numeroFacture() {
    var e = encart('INV_DRAFT_PREFIX', 's60-ex-num', 'bleu'); if (!e) return;
    var fmtTxt = valeur('INV_NUM_FORMAT'), cb = saisie('INV_NUM_FORMAT'), c = cb && window.$find && $find(cb.id.replace(/_Input$/, ''));
    var fmt = (c && c.get_value && c.get_value()) || FORMATS[fmtTxt] || FORMATS[fmtTxt.replace(/\d{4}/, '2026')] || '{PREFIXE}-{NUMERO}';
    var d = new Date(), n = String(Math.max(1, parseInt(valeur('INV_NUM_START'), 10) || 1)), z = Math.min(10, parseInt(valeur('INV_NUM_DIGITS'), 10) || 4);
    while (n.length < z) n = '0' + n;
    var no = fmt.replace('{PREFIXE}', valeur('INV_NUM_PREFIX')).replace('{AAAA}', d.getFullYear()).replace('{MM}', ('0' + (d.getMonth() + 1)).slice(-2)).replace('{NUMERO}', n);
    var bro = valeur('INV_DRAFT_PREFIX');
    e.innerHTML = 'Première facture : <b>' + no + '</b>' + (bro ? ' · un brouillon s\'affiche ainsi : <b>' + bro + '-…</b>' : '') + (/oui/i.test(valeur('INV_NUM_RESET_YEARLY')) ? ' · le compteur repart à ' + n + ' chaque année.' : '');
  }
  function etatBancaire() { if (!champs.COMPTE_BANQUE) return; var v = valeur('COMPTE_BANQUE');
    if (!v || /sélectionnez|aucun/i.test(v)) note('COMPTE_BANQUE', 'Aucun compte par défaut choisi : choisissez celui qui reçoit vos encaissements.', 's60-warn'); else note('COMPTE_BANQUE', NOTES.COMPTE_BANQUE); }
  function etatComptable() { if (!champs.COMPTABLE) return; if (!valeur('COMPTABLE')) note('COMPTABLE', 'Aucune clé pour l\'instant. ' + NOTES.COMPTABLE, 's60-warn'); else note('COMPTABLE', NOTES.COMPTABLE); }
  function majCalculs() { exempleTaxes(); numeroFacture(); etatBancaire(); etatComptable(); }
  majCalculs();

  /* ---------- Barre « modifications non enregistrées » ---------- */
  var form = root.closest('form') || document.forms[0];
  function instantane() { var o = {}; $$('.rmpView input[name], .rmpView textarea[name]').forEach(function (i) { if (i.type === 'hidden' || /ClientState/.test(i.name)) return; o[i.name] = i.type === 'checkbox' ? i.checked : (i.type === 'file' ? (i.files && i.files.length ? 'f' : '') : i.value); }); return o; }
  var depart = instantane(), envoi = false;
  var barre = document.createElement('div'); barre.className = 's60-barre';
  barre.innerHTML = '<span class="t"></span><button type="button" class="a">Annuler</button><button type="button" class="p">Enregistrer</button>';
  document.body.appendChild(barre);
  function compte() { var a = instantane(), n = 0; Object.keys(a).forEach(function (k) { if (a[k] !== depart[k]) n++; }); return n; }
  setInterval(function () {
    var n = compte(); barre.classList.toggle('on', n > 0);
    barre.querySelector('.t').textContent = n + ' modification' + (n > 1 ? 's' : '') + ' non enregistrée' + (n > 1 ? 's' : '');
    majCalculs();
  }, 700);
  function cliquer(id) { envoi = true; var b = root.querySelector('[id$="' + id + '"]'); if (b) b.click(); }
  barre.querySelector('.p').addEventListener('click', function () { cliquer('btnSave'); });
  barre.querySelector('.a').addEventListener('click', function () { cliquer('btnReload'); });
  if (form) form.addEventListener('submit', function () { envoi = true; }, true);
  if (typeof window.__doPostBack === 'function') { var pb = window.__doPostBack; window.__doPostBack = function () { envoi = true; return pb.apply(this, arguments); }; }
  document.addEventListener('click', function (e) { if (e.target.closest('button[type=submit], input[type=submit]')) envoi = true; }, true);
  window.addEventListener('beforeunload', function (e) { if (!envoi && compte() > 0) { e.preventDefault(); e.returnValue = ''; } });

  window.s60Parametres = { champs: champs, valeur: valeur, maj: majCalculs };
})();

