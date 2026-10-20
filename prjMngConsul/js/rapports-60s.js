/* =====================================================================
   60secondes · Rapports — améliorations d'affichage v1 (2026-10-20)
   Uniquement côté navigateur : ne fait aucun appel serveur, ne déclenche aucun
   postback, ne modifie ni les valeurs des champs ni les contrôles ASP.NET.
   1. Montants au format québécois (2,955.45 $ -> 2 955,45 $)
   2. Bouton « Masquer / afficher les comptes à zéro » (états financiers)
   3. Tuiles de résumé lues dans les lignes déjà affichées
   Se relance après chaque mise à jour partielle (RadAjax / UpdatePanel).
   ===================================================================== */
(function () {
  'use strict';
  var NBSP = '\u00A0', NNBSP = '\u00A0';
  var AMOUNT_SEL = '.report-body td, .bv-stat-value, .stat-value, .period-stat-row .value, .category-total .value,' +
                   ' .item-amount, .pay-table td, .bank-value, .s60-kpi .v';

  function store(k, v) { try { if (v === undefined) return localStorage.getItem(k); localStorage.setItem(k, v); } catch (e) { return null; } }

  /* --- 1. Format des montants --------------------------------------- */
  // Convertit un montant à l'anglaise (1,234.56) en format fr-CA (1 234,56) dans un texte.
  function frAmounts(txt) {
    return txt.replace(/(-?)(\d{1,3}(?:,\d{3})+|\d+)\.(\d{2})(\s?\$)/g, function (m, sign, int, dec, cur) {
      return sign + int.replace(/,/g, NNBSP) + ',' + dec + NBSP + '$';
    });
  }
  function formatAmounts(root) {
    var els = root.querySelectorAll(AMOUNT_SEL);
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.children.length) {            // ne réécrit que les nœuds texte, garde les balises
        var w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null);
        var n; while ((n = w.nextNode())) { var t = frAmounts(n.nodeValue); if (t !== n.nodeValue) n.nodeValue = t; }
      } else {
        var t2 = frAmounts(el.textContent); if (t2 !== el.textContent) el.textContent = t2;
      }
    }
  }
  // Lit un montant affiché, quel que soit son format : « 2,955.45 $ », « (37 227,81 $) », « — ».
  function parseAmount(txt) {
    if (!txt) return null;
    var s = txt.replace(/[\s  $]/g, '');
    if (!s || s === '—' || s === '-') return 0;
    var neg = /^\(.*\)$/.test(s) || s.charAt(0) === '-';
    s = s.replace(/[()\-]/g, '');
    if (/,\d{2}$/.test(s)) s = s.replace(/\./g, '').replace(',', '.'); else s = s.replace(/,/g, '');
    var v = parseFloat(s); if (isNaN(v)) return null;
    return neg ? -v : v;
  }
  function money(v) {
    var s = Math.abs(v).toFixed(2).split('.');
    var out = s[0].replace(/\B(?=(\d{3})+(?!\d))/g, NNBSP) + ',' + s[1] + NBSP + '$';
    return v < 0 ? '(' + out + ')' : out;
  }

  /* --- 2. Comptes à zéro --------------------------------------------- */
  function isZeroRow(tr) { var a = tr.querySelector('.er-amount, .bi-amount, .ft-amount'); return a && a.classList.contains('amt-zero'); }
  function markZeros(table, p) {
    var rows = table.querySelectorAll('tr'), count = 0, group = [], allZero = true;
    function flush() { if (group.length && allZero) group.forEach(function (r) { r.classList.add('s60-zero'); }); group = []; allZero = true; }
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i], c = r.className;
      if (c === p + '-sub-header') { flush(); group.push(r); continue; }
      if (c === p + '-line') { if (isZeroRow(r)) { r.classList.add('s60-zero'); count++; } else allZero = false; if (group.length) group.push(r); continue; }
      if (c === p + '-sub-total') { if (group.length) { group.push(r); flush(); } continue; }
      flush();
    }
    flush();
    return count;
  }
  function addToggle(body, table, count) {
    var actions = document.querySelector('#divMain .report-actions');
    if (!actions || !count || actions.querySelector('.s60-toggle')) return;
    var key = 's60-rapports-compact', compact = store(key) !== '0';
    var b = document.createElement('button');
    b.type = 'button'; b.className = 'btn s60-toggle';
    function paint() {
      table.classList.toggle('s60-compact', compact);
      b.innerHTML = (compact ? 'Afficher les comptes à zéro' : 'Masquer les comptes à zéro') + ' <span class="n">' + count + '</span>';
      b.setAttribute('aria-pressed', compact ? 'true' : 'false');
    }
    b.addEventListener('click', function () { compact = !compact; store(key, compact ? '1' : '0'); paint(); });
    var print = actions.querySelector('.btn.primaire');
    actions.insertBefore(b, print || null);
    paint();
  }

  /* --- 3. Tuiles de résumé ------------------------------------------- */
  function rowVal(tr) { if (!tr) return null; var a = tr.querySelector('.er-amount, .bi-amount, .ft-amount'); return a ? parseAmount(a.textContent) : null; }
  function rowLabel(tr) { var tds = tr.querySelectorAll('td'); return tds.length > 1 ? tds[1].textContent.trim() : tr.textContent.trim(); }
  function tile(label, v, cls, sub) {
    return '<div class="s60-kpi ' + (cls || '') + '"><div class="k">' + label + '</div><div class="v">' + (v === null ? '—' : money(v)) + '</div>' + (sub ? '<div class="s">' + sub + '</div>' : '') + '</div>';
  }
  function kpis(body, html) {
    if (body.querySelector('.s60-kpis') || !html) return;
    var d = document.createElement('div'); d.className = 's60-kpis'; d.innerHTML = html;
    var hdr = body.querySelector('.report-header');
    if (hdr && hdr.nextSibling) body.insertBefore(d, hdr.nextSibling); else body.appendChild(d);
  }
  function summaryER(body, t) {
    var tot = t.querySelectorAll('tr.er-total'), calc = t.querySelectorAll('tr.er-calc'), net = t.querySelector('tr.er-net');
    var rev = rowVal(tot[0]), brut = rowVal(calc[0]), nv = net ? rowVal(net) : null;
    var marge = rev ? Math.round(nv / rev * 1000) / 10 : null;
    kpis(body, tile('Revenus', rev) + tile('Bénéfice brut', brut) +
      tile('Bénéfice net', nv, 'main') + tile('Marge nette', null, nv >= 0 ? 'pos' : 'neg').replace('<div class="v">—</div>', '<div class="v">' + (marge === null ? '—' : String(marge).replace('.', ',') + NBSP + '%') + '</div>'));
  }
  function summaryBI(body, t) {
    var g = t.querySelectorAll('tr.bi-grand-total'), html = '';
    for (var i = 0; i < g.length && i < 3; i++) html += tile(rowLabel(g[i]).replace(/^TOTAL (DE L'|DU |DES )?/i, '').toLowerCase().replace(/^./, function (c) { return c.toUpperCase(); }), rowVal(g[i]), i === g.length - 1 ? 'main' : '');
    kpis(body, html);
  }
  function summaryFT(body, t) {
    var tot = t.querySelectorAll('tr.ft-total'), names = ['Exploitation', 'Investissement', 'Financement'], html = '';
    for (var i = 0; i < tot.length && i < 3; i++) { var v = rowVal(tot[i]); html += tile(names[i], v, v > 0 ? 'pos' : (v < 0 ? 'neg' : '')); }
    var fin = t.querySelector('tr.ft-encaisse-fin'); if (fin) html += tile('Trésorerie de fin', rowVal(fin), 'main');
    kpis(body, html);
  }

  /* --- Lancement ------------------------------------------------------ */
  function run() {
    var root = document.getElementById('divMain'); if (!root) return;
    var body = root.querySelector('.report-body');
    if (body) {
      var map = [['er', summaryER], ['bi', summaryBI], ['ft', summaryFT]];
      for (var i = 0; i < map.length; i++) {
        var t = body.querySelector('table.' + map[i][0] + '-table');
        if (!t) continue;
        map[i][1](body, t);
        if (!t.getAttribute('data-s60')) { t.setAttribute('data-s60', '1'); addToggle(body, t, markZeros(t, map[i][0])); }
      }
    }
    formatAmounts(root);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run); else run();
  // Mises à jour partielles ASP.NET AJAX (IA Paiement, IA Ventes)
  try { if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) Sys.WebForms.PageRequestManager.getInstance().add_endRequest(run); } catch (e) {}
  var root0 = document.getElementById('divMain');
  if (root0 && window.MutationObserver) { var busy = false; new MutationObserver(function () { if (busy) return; busy = true; setTimeout(function () { run(); busy = false; }, 60); }).observe(root0, { childList: true, subtree: true }); }
  window.s60Rapports = { run: run, frAmounts: frAmounts, parseAmount: parseAmount };
})();

