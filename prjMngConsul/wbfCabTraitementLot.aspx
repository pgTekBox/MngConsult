<%@ Page Title="Traitement en lot — Portail comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabTraitementLot.aspx.vb" Inherits="MngConsul.wbfCabTraitementLot" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Traitement en lot — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap">
<style>
/* ---- « Traitement en lot » : tout est confiné sous .lot60 pour ne pas déteindre
      sur le reste du portail (Site.Master). Jetons de couleur de la maquette
      portés sur .lot60 : ils descendent jusqu'à la fenêtre de confirmation. ---- */
.lot60{
  --encre:#0E1F3D; --encre2:#44536E; --encre3:#6A7891;
  --fond:#F2F5F9; --filet:#E3E9F1; --bord:#D5DDE8; --champ:#F7F9FC; --pastille:#E8EDF5;
  --choisi:#E3EBF7; --marine:#1B4F9C; --marine-fonce:#143A73; --nuit:#0E1F3D; --or:#D9A03C;
  --rouge:#B3261E; --rouge-pale:#FDECEC; --ambre:#9A5B00; --ambre-pale:#FFF4DF; --vert:#1E6B3A; --vert-pale:#E6F4EA;
  width:100%;color:var(--encre);font-size:15px;padding-bottom:110px;
  font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
}
.lot60 *{box-sizing:border-box}
.lot60 button,.lot60 select,.lot60 textarea,.lot60 input{font:inherit;color:inherit}
.lot60 a{color:inherit}
.lot60 h1{font-size:30px;font-weight:800;margin:0}
.lot60 .chapeau{color:var(--encre2);font-size:16px;margin:10px 0 18px;max-width:900px}

.lot60 .lot-demo{display:flex;gap:8px;align-items:center;background:var(--ambre-pale);color:var(--ambre);
  border-radius:12px;padding:10px 14px;font-weight:700;font-size:13.5px;margin-bottom:14px}
.lot60 .lot-demo svg{width:18px;height:18px;flex:none}

.lot60 .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 20px;font-weight:800;cursor:pointer;white-space:nowrap}
.lot60 .btn:hover{background:var(--marine-fonce)}
.lot60 .btn[disabled]{background:#AEB9CA;cursor:not-allowed}
.lot60 .btn-ghost{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:7px 12px;font-weight:700;cursor:pointer}
.lot60 .btn-ghost:hover{border-color:var(--marine)}

/* En-tête de page */
.lot60 .lot-tete{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.lot60 .lot-tete h1{margin-right:6px}
.lot60 .puce{border-radius:999px;padding:6px 14px;font-size:14px;font-weight:800}
.lot60 .puce b{font-size:19px;margin-right:4px}
.lot60 .puce.nuit{background:var(--nuit);color:#fff}
.lot60 .puce.bleu{background:#DCE7F6;color:var(--marine-fonce)}
.lot60 .puce.rouge{background:var(--rouge);color:#fff}

/* Barre « Regrouper par » */
.lot60 .barre-vue{display:flex;align-items:center;gap:12px;flex-wrap:wrap;background:#fff;border:1px solid var(--filet);border-radius:16px;padding:10px 14px;margin-bottom:18px}
.lot60 .barre-vue .lab{font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3)}
.lot60 .seg{display:inline-flex;background:var(--pastille);border-radius:12px;padding:3px;gap:2px}
.lot60 .seg button{border:0;background:transparent;border-radius:9px;padding:7px 14px;font-weight:800;color:var(--encre2);cursor:pointer}
.lot60 .seg button[aria-pressed=true]{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}
.lot60 .barre-vue .aide{color:var(--encre2);font-size:14px}

/* Lot */
.lot60 .lot{background:#fff;border:1px solid var(--filet);border-radius:20px;margin-bottom:16px;overflow:hidden}
.lot60 .lot-h{display:flex;align-items:flex-start;gap:14px;padding:16px 20px;flex-wrap:wrap}
.lot60 .lot-h .nb{width:40px;height:40px;border-radius:12px;display:grid;place-items:center;font-weight:800;font-size:17px;flex:none}
.lot60 .nb.urgent{background:var(--rouge-pale);color:var(--rouge)}
.lot60 .nb.surveiller{background:var(--ambre-pale);color:var(--ambre)}
.lot60 .nb.normal{background:var(--pastille);color:var(--encre2)}
.lot60 .lot-h .tx{flex:1;min-width:240px}
.lot60 .lot-h h2{margin:0;font-size:19px;font-weight:800;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.lot60 .lot-h .sous{color:var(--encre2);font-size:14px;margin-top:2px}
.lot60 .lot-h .pourquoi{margin-top:6px;font-size:13.5px;color:var(--encre2)}
.lot60 .lot-h .pourquoi b{color:var(--ambre)}
.lot60 .urg{border-radius:999px;padding:2px 9px;font-size:12px;font-weight:800}
.lot60 .urg.urgent{background:var(--rouge-pale);color:var(--rouge)}
.lot60 .urg.surveiller{background:var(--ambre-pale);color:var(--ambre)}
.lot60 .urg.normal{background:var(--pastille);color:var(--encre2)}
.lot60 .lot-cta{display:flex;flex-direction:column;align-items:flex-end;gap:4px}
.lot60 .lot-cta small{color:var(--encre2);font-weight:700}

/* Table des transactions */
.lot60 table.tx{width:100%;border-collapse:collapse;font-size:14.5px}
.lot60 table.tx th{font-size:12px;letter-spacing:.06em;color:var(--encre3);text-align:left;padding:8px 12px;border-top:1px solid var(--filet);border-bottom:1px solid var(--filet);background:var(--champ);font-weight:800}
.lot60 table.tx td{padding:10px 12px;border-bottom:1px solid var(--filet);vertical-align:middle}
.lot60 table.tx tr:last-child td{border-bottom:0}
.lot60 table.tx td.c{width:44px}
.lot60 table.tx td.d{width:150px}
.lot60 table.tx td.a{width:260px;text-align:right;white-space:nowrap}
.lot60 .inc{width:22px;height:22px;accent-color:var(--marine);cursor:pointer}
.lot60 .qui b{display:block}
.lot60 .qui small{color:var(--encre3)}
.lot60 .ech{display:inline-block;border-radius:999px;padding:3px 10px;font-size:12.5px;font-weight:800}
.lot60 .ech.urgent{background:var(--rouge-pale);color:var(--rouge)}
.lot60 .ech.surveiller{background:var(--ambre-pale);color:var(--ambre)}
.lot60 .ech.normal{background:var(--pastille);color:var(--encre2)}
.lot60 .btn-une{background:#DCE7F6;color:var(--marine-fonce);border:0;border-radius:999px;padding:7px 14px;font-weight:800;cursor:pointer}
.lot60 .btn-une:hover{background:#C9DAF1}
.lot60 .exclure{background:none;border:0;color:var(--encre2);font-weight:800;cursor:pointer;padding:6px 8px;border-radius:8px;margin-left:4px}
.lot60 .exclure:hover{background:var(--fond);color:var(--rouge)}
.lot60 tr.exclue td{background:#FAFBFD}
.lot60 tr.exclue .qui,.lot60 tr.exclue .ech,.lot60 tr.exclue .act-lib{opacity:.45}
.lot60 tr.exclue .qui b{text-decoration:line-through}
.lot60 .tag-exclue{display:inline-block;margin-left:8px;background:var(--pastille);color:var(--encre2);border-radius:999px;padding:2px 8px;font-size:12px;font-weight:800;opacity:1}
.lot60 .reintegrer{background:none;border:1px solid var(--bord);border-radius:999px;padding:6px 12px;font-weight:800;cursor:pointer}
.lot60 .act-lib{font-size:13.5px;color:var(--encre2)}
.lot60 .lot-pied{display:flex;gap:10px;align-items:center;justify-content:space-between;flex-wrap:wrap;padding:10px 20px;background:var(--champ);border-top:1px solid var(--filet);font-size:14px;color:var(--encre2)}
.lot60 .lot-pied button{background:none;border:0;color:var(--marine-fonce);font-weight:800;cursor:pointer;padding:4px 6px}

/* Faits aujourd'hui */
.lot60 .faits-jour{margin-top:24px}
.lot60 .faits-jour[hidden]{display:none}
.lot60 .faits-jour h2{font-size:18px;margin:0 0 10px}
.lot60 .faits-jour h2 small{color:var(--encre2);font-weight:700;font-size:14px}
.lot60 .fait{display:flex;align-items:center;gap:12px;background:#fff;border:1px solid var(--filet);border-radius:14px;padding:10px 14px;margin-bottom:8px}
.lot60 .fait .ok{width:28px;height:28px;border-radius:50%;background:var(--vert);display:grid;place-items:center;flex:none}
.lot60 .fait .ok::after{content:"";width:10px;height:6px;border-left:2.5px solid #fff;border-bottom:2.5px solid #fff;transform:rotate(-45deg) translate(1px,-1px)}
.lot60 .fait .t{flex:1}
.lot60 .fait b{display:block}
.lot60 .fait small{color:var(--encre2)}

/* Barre globale fixe + fenêtre de confirmation + toast */
.lot60 .barre-globale{position:fixed;left:0;right:0;bottom:0;background:var(--nuit);color:#fff;display:flex;justify-content:center;align-items:center;gap:20px;padding:12px 20px;z-index:15;flex-wrap:wrap}
.lot60 .barre-globale[hidden]{display:none}
.lot60 .barre-globale .btn{background:var(--or);color:var(--nuit)}

.lot60 dialog{border:0;border-radius:20px;padding:0;max-width:520px;width:calc(100% - 32px);box-shadow:0 20px 60px rgba(14,31,61,.35);color:var(--encre)}
.lot60 dialog::backdrop{background:rgba(14,31,61,.45)}
.lot60 .cf-wrap{padding:22px 24px}
.lot60 dialog h2{margin:0 0 6px;font-size:20px}
.lot60 dialog ul{margin:10px 0;padding-left:20px;max-height:220px;overflow:auto}
.lot60 dialog li{margin-bottom:4px}
.lot60 .cf-note{font-size:13.5px;color:var(--encre2)}
.lot60 .cf-act{display:flex;justify-content:flex-end;gap:10px;margin-top:14px}

.lot60 .toast{position:fixed;left:50%;bottom:84px;transform:translateX(-50%);background:var(--nuit);color:#fff;border-radius:999px;padding:12px 18px;font-weight:800;display:flex;gap:14px;align-items:center;box-shadow:0 8px 24px rgba(14,31,61,.25);z-index:20}
.lot60 .toast[hidden]{display:none}
.lot60 .toast button{background:none;border:0;color:var(--or);font-weight:800;cursor:pointer}

.lot60 .vide{background:#fff;border:1px dashed var(--bord);border-radius:20px;padding:30px;text-align:center;color:var(--encre2)}
.lot60 .vide b{display:block;font-size:18px;color:var(--encre);margin-bottom:4px}

.lot60 button:focus-visible,.lot60 select:focus-visible,.lot60 a:focus-visible{outline:2px solid var(--marine);outline-offset:2px}

@media (max-width:900px){
  .lot60 table.tx thead{display:none}
  .lot60 table.tx tr{display:grid;grid-template-columns:44px 1fr auto;gap:4px 8px;padding:10px 12px;border-bottom:1px solid var(--filet)}
  .lot60 table.tx td{border:0;padding:2px 0}
  .lot60 table.tx td.d{grid-column:2;width:auto}
  .lot60 table.tx td.a{grid-column:1 / -1;width:auto;text-align:left;margin-top:6px}
  .lot60 table.tx td.c{grid-row:span 2}
  .lot60 .lot-cta{align-items:stretch;width:100%}
}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<section class="lot60">
  <div class="lot-demo">
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v5M12 16h.01"/></svg>
    Données de démonstration — le moteur réel de traitement en lot n'est pas encore branché.
  </div>

  <div class="lot-tete">
    <h1>Traitement en lot</h1>
    <span class="puce nuit"><b id="k-actions">0</b> actions à faire</span>
    <span class="puce bleu"><b id="k-clients">0</b> clients</span>
    <span class="puce rouge"><b id="k-urg">0</b> urgentes</span>
  </div>
  <p class="chapeau">Faites la même action pour plusieurs clients d'un seul geste, ou une à la fois. Retirez du lot ce qui doit attendre. Chaque action est faite au nom du client, avec ses propres chiffres, et inscrite au journal.</p>

  <div class="barre-vue">
    <span class="lab">REGROUPER PAR</span>
    <div class="seg" role="group" aria-label="Regrouper par" id="seg">
      <button type="button" data-vue="activite" aria-pressed="true">Activité</button>
      <button type="button" data-vue="client" aria-pressed="false">Client</button>
      <button type="button" data-vue="urgence" aria-pressed="false">Urgence</button>
      <button type="button" data-vue="echeance" aria-pressed="false">Échéance</button>
    </div>
    <span class="aide" id="aide-vue"></span>
  </div>

  <div id="lots"></div>

  <section class="faits-jour" id="faits" hidden>
    <h2>Faits aujourd'hui <small id="n-faits"></small></h2>
    <div id="liste-faits"></div>
  </section>

  <div class="barre-globale" id="barre-globale" hidden>
    <span><b id="g-n">0</b> actions incluses dans <b id="g-l">0</b> lots</span>
    <button type="button" class="btn" id="g-lancer">Lancer tous les lots</button>
  </div>

  <dialog id="confirm" aria-labelledby="cf-titre">
    <div class="cf-wrap">
      <h2 id="cf-titre"></h2>
      <p id="cf-tx"></p>
      <ul id="cf-liste"></ul>
      <p class="cf-note">Chaque action est faite au nom du client, avec ses propres chiffres, et inscrite au journal. Vous pouvez annuler pendant 10 secondes.</p>
      <div class="cf-act"><button type="button" value="non" class="btn-ghost" data-cf="non">Revenir</button><button type="button" value="oui" class="btn" id="cf-ok" data-cf="oui">Lancer</button></div>
    </div>
  </dialog>

  <div class="toast" id="toast" role="status" hidden><span id="toast-tx"></span><button type="button" id="toast-annuler">Annuler</button></div>
</section>

<script type="text/javascript">
const ACTIVITES={
  paiement:{nom:'Déclencher un paiement fournisseur',verbe:'Déclencher',cat:'Paiements',pourquoi:'le client, ou le cabinet autorisé dans ses plafonds.'},
  taxes:{nom:'Approuver et produire la déclaration de taxes',verbe:'Produire',cat:'Taxes de vente et remises',pourquoi:'le cabinet révise, le client voit.'},
  seuil:{nom:"S'inscrire aux taxes à l'approche du seuil",verbe:'Inscrire',cat:'Taxes de vente et remises',pourquoi:"60 avertit ; le client s'inscrit lui-même ou le cabinet le fait pour lui."},
  facture:{nom:'Approuver une facture fournisseur à payer',verbe:'Approuver',cat:'Dépenses et fournisseurs',pourquoi:'le client ou le cabinet approuve, selon les plafonds convenus.'},
  concil:{nom:'Approuver la conciliation mensuelle',verbe:'Approuver',cat:'Banque et conciliation',pourquoi:'signature du cabinet sur la fin de mois.'},
  incorpo:{nom:"Évaluer l'incorporation d'un travailleur autonome",verbe:'Évaluer',cat:'Trésorerie, conseil et croissance',pourquoi:'60 signale le moment ; le cabinet conseille.'}
};
const TX=[
  {id:1,act:'paiement',client:'Marc Allard, électricien',secteur:'Construction',jours:2},
  {id:2,act:'paiement',client:'Annie Roy, photographe',secteur:'Arts et médias',jours:3},
  {id:3,act:'taxes',client:'Luc Gendron, consultant TI',secteur:'Services',jours:0},
  {id:4,act:'seuil',client:'Julie Fortin, designer',secteur:'Services',jours:1},
  {id:5,act:'facture',client:'Julie Fortin, designer',secteur:'Services',jours:6},
  {id:6,act:'concil',client:'Pierre Ménard, menuisier',secteur:'Construction',jours:5},
  {id:7,act:'incorpo',client:'Luc Gendron, consultant TI',secteur:'Services',jours:9}
].map(t=>({...t,exclue:false,faite:false}));
const URG={urgent:'Urgent',surveiller:'À surveiller',normal:'Sans urgence'};
const urg=t=>t.jours<=0||(t.act==='paiement'&&t.jours<=3)?'urgent':t.jours<=1?'surveiller':'normal';
const echLib=j=>j<=0?"Aujourd'hui":j===1?'Demain':`Dans ${j} jours`;
const AIDES={activite:'Une même activité pour plusieurs clients : le plus rapide.',client:'Tout ce qui est à faire pour un même client.',urgence:"Ce qui presse d'abord.",echeance:"Selon la date d'échéance."};
let vue='activite', dernier=null, enAttente=null;
const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

function groupes(){
  const a=TX.filter(t=>!t.faite);
  const G=new Map(); const add=(k,o,t)=>{if(!G.has(k))G.set(k,{...o,tx:[]});G.get(k).tx.push(t)};
  a.forEach(t=>{
    const A=ACTIVITES[t.act];
    if(vue==='activite') add(t.act,{titre:A.nom,sous:A.cat,pourquoi:A.pourquoi,verbe:A.verbe},t);
    else if(vue==='client') add(t.client,{titre:t.client,sous:t.secteur,verbe:'Lancer'},t);
    else if(vue==='urgence'){const u=urg(t);add(u,{titre:URG[u],ordre:['urgent','surveiller','normal'].indexOf(u),verbe:'Lancer'},t)}
    else {const k=t.jours<=1?'a':t.jours<=7?'b':'c';add(k,{titre:{a:"Aujourd'hui et demain",b:'Cette semaine',c:'Plus tard'}[k],ordre:'abc'.indexOf(k),verbe:'Lancer'},t)}
  });
  let L=[...G.values()];
  L.forEach(g=>{g.tx.sort((x,y)=>x.jours-y.jours);g.niv=g.tx.some(t=>urg(t)==='urgent')?'urgent':g.tx.some(t=>urg(t)==='surveiller')?'surveiller':'normal';g.min=Math.min(...g.tx.map(t=>t.jours))});
  L.sort((x,y)=>(x.ordre??['urgent','surveiller','normal'].indexOf(x.niv))-(y.ordre??['urgent','surveiller','normal'].indexOf(y.niv))||x.min-y.min);
  return L;
}
function rendre(){
  const a=TX.filter(t=>!t.faite);
  $('#k-actions').textContent=a.length;
  $('#k-clients').textContent=new Set(a.map(t=>t.client)).size;
  $('#k-urg').textContent=a.filter(t=>urg(t)==='urgent').length;
  $('#aide-vue').textContent=AIDES[vue];
  const L=groupes();
  $('#lots').innerHTML=L.length?L.map((g,gi)=>{
    const inc=g.tx.filter(t=>!t.exclue).length;
    const montrerAct=vue!=='activite';
    return `<section class="lot" aria-labelledby="lot-${gi}">
      <div class="lot-h">
        <span class="nb ${g.niv}">${g.tx.length}</span>
        <div class="tx">
          <h2 id="lot-${gi}">${esc(g.titre)} ${vue!=='urgence'?`<span class="urg ${g.niv}">${URG[g.niv]}</span>`:''}</h2>
          <div class="sous">${g.tx.length} ${g.tx.length>1?'transactions':'transaction'}${g.sous?' · '+esc(g.sous):''}</div>
          ${g.pourquoi?`<div class="pourquoi"><b>Qui décide :</b> ${esc(g.pourquoi)}</div>`:''}
        </div>
        ${g.tx.length>1?`<div class="lot-cta">
          <button type="button" class="btn" data-lot="${gi}" ${inc?'':'disabled'}>Lancer le lot (${inc})</button>
          <small>${inc} sur ${g.tx.length} incluses</small>
        </div>`:''}
      </div>
      <table class="tx">
        <thead><tr><th>Lot</th><th>${vue==='client'?'Transaction':montrerAct?'Transaction et client':'Client'}</th><th>Échéance</th><th style="text-align:right">Action</th></tr></thead>
        <tbody>${g.tx.map(t=>{const A=ACTIVITES[t.act];return `<tr class="${t.exclue?'exclue':''}">
          <td class="c"><input type="checkbox" class="inc" data-inc="${t.id}" ${t.exclue?'':'checked'} aria-label="Inclure ${esc(t.client)} dans le lot"></td>
          <td>${vue==='client'?`<span class="qui"><b>${esc(A.nom)}${t.exclue?'<span class="tag-exclue">Exclue du lot</span>':''}</b><small>${esc(A.cat)}</small></span>`:`${montrerAct?`<div class="act-lib">${esc(A.nom)}</div>`:''}<span class="qui"><b>${esc(t.client)}${t.exclue?'<span class="tag-exclue">Exclue du lot</span>':''}</b><small>${esc(t.secteur)}</small></span>`}</td>
          <td class="d"><span class="ech ${urg(t)}">${echLib(t.jours)}</span></td>
          <td class="a">${t.exclue?`<button type="button" class="reintegrer" data-inc-btn="${t.id}">Remettre dans le lot</button>`:`<button type="button" class="btn-une" data-une="${t.id}">${A.verbe} celle-ci</button><button type="button" class="exclure" data-exclure="${t.id}">Exclure</button>`}</td>
        </tr>`}).join('')}</tbody>
      </table>
      ${g.tx.length>1?`<div class="lot-pied"><span>Décochez une ligne pour la garder hors du lot ; elle reste dans la liste pour plus tard.</span><span><button type="button" data-tout="${gi}">Tout inclure</button><button type="button" data-rien="${gi}">Tout exclure</button></span></div>`:''}
    </section>`}).join(''):`<div class="vide"><b>Tout est fait</b>Il n'y a plus d'action à faire en lot. Les nouvelles actions apparaîtront ici.</div>`;
  window._L=L;
  // Faits
  const F=TX.filter(t=>t.faite);
  $('#faits').hidden=!F.length; $('#n-faits').textContent=F.length?`· ${F.length}`:'';
  $('#liste-faits').innerHTML=F.map(t=>`<div class="fait"><span class="ok" aria-hidden="true"></span><span class="t"><b>${esc(ACTIVITES[t.act].nom)}</b><small>${esc(t.client)} · inscrit au journal</small></span></div>`).join('');
  // Barre globale
  const lots=L.filter(g=>g.tx.some(t=>!t.exclue)), n=lots.reduce((s,g)=>s+g.tx.filter(t=>!t.exclue).length,0);
  $('#barre-globale').hidden=lots.length<2; $('#g-n').textContent=n; $('#g-l').textContent=lots.length;
  $$('[data-vue]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.vue===vue));
}
function confirmer(titre,tx,liste,ok){
  $('#cf-titre').textContent=titre; $('#cf-tx').textContent=tx;
  $('#cf-liste').innerHTML=liste.map(t=>`<li><b>${esc(t.client)}</b> — ${esc(ACTIVITES[t.act].nom)} · ${echLib(t.jours)}</li>`).join('');
  enAttente=ok; $('#confirm').showModal();
}
$('#confirm').addEventListener('close',()=>{if($('#confirm').returnValue==='oui'&&enAttente)enAttente();enAttente=null});
function faire(liste,msg){
  liste.forEach(t=>t.faite=true); dernier=liste.map(t=>t.id); rendre();
  $('#toast-tx').textContent=msg; $('#toast').hidden=false; clearTimeout(faire.t); faire.t=setTimeout(()=>{$('#toast').hidden=true;dernier=null},10000);
}
document.addEventListener('change',e=>{const id=e.target.dataset.inc;if(id){TX.find(t=>t.id==id).exclue=!e.target.checked;rendre()}});
document.addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  const T=id=>TX.find(t=>t.id==id), L=window._L||[];
  if(b.dataset.cf!==undefined){$('#confirm').close(b.dataset.cf)}
  else if(b.dataset.vue){vue=b.dataset.vue;rendre()}
  else if(b.dataset.exclure){T(b.dataset.exclure).exclue=true;rendre()}
  else if(b.dataset.incBtn){T(b.dataset.incBtn).exclue=false;rendre()}
  else if(b.dataset.tout){L[b.dataset.tout].tx.forEach(t=>t.exclue=false);rendre()}
  else if(b.dataset.rien){L[b.dataset.rien].tx.forEach(t=>t.exclue=true);rendre()}
  else if(b.dataset.une){const t=T(b.dataset.une),A=ACTIVITES[t.act];
    confirmer(`${A.verbe} pour ${t.client.split(',')[0]} ?`,'Cette action est lancée seule, sans le reste du lot.',[t],()=>faire([t],`${A.nom} — fait pour ${t.client.split(',')[0]}.`))}
  else if(b.dataset.lot){const g=L[b.dataset.lot],l=g.tx.filter(t=>!t.exclue),x=g.tx.length-l.length;
    confirmer(`Lancer le lot : ${l.length} action${l.length>1?'s':''} ?`,`${g.titre}${x?` · ${x} exclue${x>1?'s':''}, gardée${x>1?'s':''} pour plus tard`:''}.`,l,()=>faire(l,`Lot lancé : ${l.length} action${l.length>1?'s':''} faite${l.length>1?'s':''}.`))}
  else if(b.id==='g-lancer'){const l=L.flatMap(g=>g.tx.filter(t=>!t.exclue));
    confirmer(`Lancer tous les lots : ${l.length} actions ?`,'Les transactions exclues restent dans la liste pour plus tard.',l,()=>faire(l,`${l.length} actions faites et inscrites au journal.`))}
  else if(b.id==='toast-annuler'&&dernier){dernier.forEach(id=>T(id).faite=false);dernier=null;$('#toast').hidden=true;rendre()}
});
rendre();
</script>
</asp:Content>
