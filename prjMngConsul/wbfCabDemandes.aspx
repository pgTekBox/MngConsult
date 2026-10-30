<%@ Page Title="Clients non associés" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabDemandes.aspx.vb" Inherits="MngConsul.wbfCabDemandes" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Portail comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
#dna{--encre:#0E1F3D;--encre2:#44536E;--encre3:#6A7891;--fond:#F2F5F9;--filet:#E3E9F1;--bord:#D5DDE8;--champ:#F7F9FC;--pastille:#E8EDF5;--choisi:#E3EBF7;--marine:#1B4F9C;--marine-fonce:#143A73;--nuit:#0E1F3D;--or:#D9A03C;--rouge:#B3261E;--rouge-pale:#FDECEC;--ambre:#9A5B00;--ambre-pale:#FFF4DF;--vert:#1E6B3A;--vert-pale:#E6F4EA;width:100%;color:var(--encre)}
#dna *{box-sizing:border-box}
#dna h1{font-size:28px;font-weight:800;margin:0}
#dna .chapeau{color:var(--encre2);font-size:16px;margin:6px 0 18px}
#dna .chapeau b{color:var(--encre)}
#dna .chapeau .rouge{color:var(--rouge);font-weight:800}
#dna .liste{display:flex;flex-direction:column;gap:14px}
#dna .carte-c{background:#fff;border:1px solid var(--filet);border-radius:20px;padding:18px 20px;display:grid;grid-template-columns:auto 1fr auto;gap:6px 16px;align-items:center}
#dna .carte-c.urgent{box-shadow:inset 5px 0 0 var(--rouge)}
#dna .mono{width:52px;height:52px;border-radius:50%;background:#F2D9A6;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:17px}
#dna .carte-c .mono{grid-row:span 3;align-self:start}
#dna .qui{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap}
#dna .qui h2{margin:0;font-size:19px;font-weight:800}
#dna .qui .ou{color:var(--encre2);font-size:14px}
#dna .demande-tx{grid-column:2;font-size:15.5px;line-height:1.5;color:var(--encre);margin:0}
#dna .demande-tx .pour{color:var(--encre2)}
#dna .demande-tx b{font-weight:800}
#dna .citation{grid-column:2;margin:4px 0 0;font-size:14.5px;color:var(--encre2);font-style:italic;border-left:3px solid var(--or);padding-left:10px}
#dna .decision{grid-column:3;grid-row:1 / span 3;display:flex;flex-direction:column;align-items:flex-end;gap:8px;align-self:center}
#dna .attente{display:inline-flex;align-items:center;gap:6px;border-radius:999px;padding:4px 10px;font-size:12.5px;font-weight:800;white-space:nowrap}
#dna .attente.ok{background:var(--pastille);color:var(--encre2)}
#dna .attente.moyen{background:var(--ambre-pale);color:var(--ambre)}
#dna .attente.urgent{background:var(--rouge-pale);color:var(--rouge)}
#dna .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 20px;font-weight:800;cursor:pointer;white-space:nowrap}
#dna .btn:hover{background:var(--marine-fonce)}
#dna .d-sec{display:flex;gap:8px}
#dna .lien{background:none;border:0;color:var(--encre2);font-weight:800;font-size:14px;cursor:pointer;padding:4px 6px;border-radius:8px}
#dna .lien:hover{background:var(--fond);color:var(--encre)}
#dna .plus-info{grid-column:2 / span 2;margin-top:6px}
#dna .details{display:flex;flex-wrap:wrap;gap:8px 22px;padding:12px 14px;background:var(--champ);border-radius:12px;font-size:14px}
#dna .details span{color:var(--encre3);font-weight:700}
#dna .details b{color:var(--encre)}
#dna .details a{color:var(--marine-fonce);font-weight:800;text-decoration:none}
#dna .decliner{grid-column:1 / -1;margin:8px -20px -18px;border-top:1px solid var(--filet);background:var(--champ);padding:14px 20px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;border-radius:0 0 20px 20px}
#dna .decliner[hidden]{display:none}
#dna .decliner select{border:1px solid var(--bord);background:#fff;border-radius:10px;height:40px;padding:0 10px;font-weight:700;min-width:260px}
#dna .btn-rouge{background:var(--rouge);color:#fff;border:0;border-radius:999px;height:40px;padding:0 16px;font-weight:800;cursor:pointer}
#dna .traites{margin-top:26px}
#dna .traites h2{font-size:18px;margin:0 0 10px}
#dna .traite{display:flex;align-items:center;gap:12px;background:#fff;border:1px solid var(--filet);border-radius:14px;padding:10px 14px;margin-bottom:8px}
#dna .traite .mono{width:36px;height:36px;font-size:13px}
#dna .traite .tx{flex:1}#dna .traite b{display:block}#dna .traite small{color:var(--encre2)}
#dna .statut{border-radius:999px;padding:3px 10px;font-size:12.5px;font-weight:800}
#dna .statut.acc{background:var(--vert-pale);color:var(--vert)}#dna .statut.dec{background:var(--rouge-pale);color:var(--rouge)}
#dna .vide{background:#fff;border:1px dashed var(--bord);border-radius:20px;padding:30px;text-align:center;color:var(--encre2)}
#dna-toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:#0E1F3D;color:#fff;border-radius:999px;padding:12px 18px;font-weight:800;display:flex;gap:14px;align-items:center;box-shadow:0 8px 24px rgba(14,31,61,.25);z-index:60}
#dna-toast[hidden]{display:none}
#dna-toast button{background:none;border:0;color:#D9A03C;font-weight:800;cursor:pointer}
@media (max-width:760px){
  #dna .carte-c{grid-template-columns:auto 1fr}
  #dna .demande-tx,#dna .citation,#dna .plus-info{grid-column:1 / -1}
  #dna .decision{grid-column:1 / -1;grid-row:auto;align-items:stretch;margin-top:8px}
  #dna .decision .btn{width:100%}
  #dna .decision .d-sec{justify-content:center}
  #dna .carte-c .mono{grid-row:span 2}
  #dna .decliner select{min-width:0;width:100%}
}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="dna">
  <h1 id="dna-titre"></h1>
  <p class="chapeau" id="dna-chapeau"></p>
  <div class="liste" id="dna-liste"></div>
  <section class="traites" id="dna-traites" hidden>
    <h2 id="dna-traites-titre"></h2>
    <div id="dna-liste-traites"></div>
  </section>
</div>
<div id="dna-toast" role="status" hidden><span id="dna-toast-tx"></span><button type="button" id="dna-toast-annuler"></button></div>

<script>
(function () {
  var D = <asp:Literal ID="litData" runat="server" />;
  var L = <asp:Literal ID="litLabels" runat="server" />;
  var root = document.getElementById('dna');
  if (!root || !D) return;
  var demandes = (D.demandes || []).slice();      // toutes les demandes en attente
  var traites = [], dernier = null, toastT = null;

  var $ = function (id) { return document.getElementById(id); };
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function fmt(t, o) { return String(t).replace('{n}', o.n).replace('{nom}', o.nom); }
  function liste(a) { return a.length < 2 ? a.join('') : a.slice(0, -1).join(', ') + ' et ' + a[a.length - 1]; }
  function niveau(j) { return j >= 5 ? 'urgent' : j >= 3 ? 'moyen' : 'ok'; }
  function attendTxt(j) { return j === 1 ? L.attendUn : fmt(L.attendDepuis, { n: j }); }

  $('dna-titre').textContent = L.titre;
  $('dna-traites-titre').textContent = L.traites;
  $('dna-toast-annuler').textContent = L.annuler;

  function ouverts() { return demandes.filter(function (d) { return !traites.some(function (t) { return t.d.id === d.id; }); }); }

  function carte(d) {
    var n = niveau(d.jours);
    var ou = [d.profil, d.ville].filter(Boolean).join(' · ');
    var contact = '<div><span>' + esc(L.contact) + ' </span><b>' + esc(d.contact.nom) + '</b>'
      + (d.contact.mail ? ' · <a href="mailto:' + esc(d.contact.mail) + '">' + esc(d.contact.mail) + '</a>' : '')
      + (d.contact.tel ? ' · <a href="tel:' + esc(d.contact.tel.replace(/\s/g, '')) + '">' + esc(d.contact.tel) + '</a>' : '') + '</div>';
    var det = (d.details || []).map(function (x) { return '<div><span>' + esc(x.k) + ' </span><b>' + esc(x.v) + '</b></div>'; }).join('');
    var opts = [L.raison1, L.raison2, L.raison3, L.raison4].map(function (r) { return '<option>' + esc(r) + '</option>'; }).join('');
    return '<article class="carte-c ' + (n === 'urgent' ? 'urgent' : '') + '">'
      + '<span class="mono" aria-hidden="true">' + esc(d.ini) + '</span>'
      + '<div class="qui"><h2>' + esc(d.nom) + (d.metier ? ', ' + esc(d.metier) : '') + '</h2>' + (ou ? '<span class="ou">' + esc(ou) + '</span>' : '') + '</div>'
      + '<div class="decision">'
      + '<span class="attente ' + n + '">' + esc(L.attendLab + ' ' + attendTxt(d.jours).toLowerCase()) + '</span>'
      + '<button class="btn" type="button" data-accepter="' + d.id + '">' + esc(L.accepter) + '</button>'
      + '<div class="d-sec"><button class="lien" type="button" data-ecrire="' + d.id + '">' + esc(L.ecrire) + '</button><button class="lien" type="button" data-decliner="' + d.id + '">' + esc(L.decliner) + '</button></div>'
      + '</div>'
      + '<p class="demande-tx"><span class="pour">' + esc(L.souhaite) + ' </span><b>' + esc(liste(d.services)) + '</b>.</p>'
      + (d.message ? '<p class="citation">« ' + esc(d.message) + ' »</p>' : '')
      + '<div class="plus-info"><div class="details">' + contact + det + '</div></div>'
      + '<div class="decliner" id="dna-dec-' + d.id + '" hidden>'
      + '<label style="font-weight:800" for="dna-raison-' + d.id + '">' + esc(L.raison) + '</label>'
      + '<select id="dna-raison-' + d.id + '">' + opts + '</select>'
      + '<button class="btn-rouge" type="button" data-confirmer="' + d.id + '">' + esc(L.decliner) + '</button>'
      + '<button class="lien" type="button" data-annulerdec="' + d.id + '">' + esc(L.annuler) + '</button>'
      + '<small style="color:var(--encre2);flex-basis:100%">' + esc(L.declineNote) + '</small>'
      + '</div></article>';
  }

  function render() {
    var a = ouverts().sort(function (x, y) { return y.jours - x.jours; });
    if (a.length) {
      var v = a[0];
      var txt = '<b>' + a.length + '</b> ' + esc(a.length > 1 ? L.introN : L.introUne) + ' ';
      if (v.jours >= 5) txt += '<span class="rouge">' + esc(fmt(L.attendRouge, { nom: v.nom, n: v.jours })) + '</span> ';
      txt += esc(L.introFin);
      $('dna-chapeau').innerHTML = txt;
      $('dna-liste').innerHTML = a.map(carte).join('');
    } else {
      $('dna-chapeau').innerHTML = '';
      $('dna-liste').innerHTML = '<div class="vide">' + esc(L.vide) + '</div>';
    }
    $('dna-traites').hidden = !traites.length;
    $('dna-liste-traites').innerHTML = traites.map(function (t) {
      return '<div class="traite"><span class="mono">' + esc(t.d.ini) + '</span><span class="tx"><b>' + esc(t.d.nom) + (t.d.metier ? ', ' + esc(t.d.metier) : '')
        + '</b><small>' + (t.acc ? esc(L.ajoute) : esc(L.declineTxt) + ' · ' + esc(t.raison || '')) + '</small></span>'
        + '<span class="statut ' + (t.acc ? 'acc' : 'dec') + '">' + esc(t.acc ? L.accepte : L.decline) + '</span></div>';
    }).join('');
  }

  function toast(tx) { $('dna-toast-tx').textContent = tx; $('dna-toast').hidden = false; clearTimeout(toastT); toastT = setTimeout(function () { $('dna-toast').hidden = true; }, 5000); }
  function post(op, id) { return fetch(window.location.href, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'op=' + op + '&id=' + encodeURIComponent(id) }).then(function (r) { return r.json(); }); }

  root.addEventListener('click', function (e) {
    var b = e.target.closest('button'); if (!b) return;
    var find = function (id) { return demandes.find(function (x) { return x.id === +id; }); };
    if (b.dataset.accepter) {
      var d = find(b.dataset.accepter);
      post('accept', d.id).then(function (j) {
        if (!j || !j.ok) return toast(L.erreur);
        traites.unshift({ d: d, acc: true }); dernier = d.id; render(); toast(fmt(L.estClient, { nom: d.nom }));
      });
    } else if (b.dataset.decliner) { var dd = $('dna-dec-' + b.dataset.decliner); if (dd) dd.hidden = false; }
    else if (b.dataset.annulerdec) { var dd2 = $('dna-dec-' + b.dataset.annulerdec); if (dd2) dd2.hidden = true; }
    else if (b.dataset.confirmer) {
      var d2 = find(b.dataset.confirmer), sel = $('dna-raison-' + d2.id);
      post('decline', d2.id).then(function (j) {
        if (!j || !j.ok) return toast(L.erreur);
        traites.unshift({ d: d2, acc: false, raison: sel ? sel.value : '' }); dernier = d2.id; render(); toast(fmt(L.declinee, { nom: d2.nom }));
      });
    } else if (b.dataset.ecrire) {
      var d3 = find(b.dataset.ecrire);
      if (d3.contact.mail) location.href = 'mailto:' + d3.contact.mail + '?subject=' + encodeURIComponent(L.sujetCourriel);
    } else if (b.id === 'dna-toast-annuler' && dernier) {
      var id = dernier;
      post('restore', id).then(function (j) {
        if (!j || !j.ok) return toast(L.erreur);
        traites = traites.filter(function (t) { return t.d.id !== id; }); dernier = null; $('dna-toast').hidden = true; render();
      });
    }
  });

  render();
})();
</script>
</asp:Content>
