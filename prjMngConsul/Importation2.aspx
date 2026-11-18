<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Importation2.aspx.vb" Inherits="MngConsul.Importation2" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importation 2 — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&amp;display=swap" />
<style>
/* Importation 2 — charte 60secondes (maquette « Importation des données » du 16 nov. 2026).
   Tout est sous #imp2 : rien ne déborde sur le reste de l'ERP. */
#imp2{
  --page:#F2F5F9; --card:#fff; --text:#0E1F3D; --muted:#44536E; --line:#D5DDE8; --line2:#AEBBCD;
  --primary:#1B4F9C; --primary-dark:#143A73; --soft:#E8EDF5; --soft2:#E3EBF7; --cyan:#06b6d4; --navy:#0E1F3D;
  --ok:#1E9E5A; --ok-soft:#E1F6E9; --act-soft:#FFF6C2; --bad:#C62E2E; --bad-soft:#FDE8E8;
  --radius:16px; --shadow:0 1px 3px rgba(14,31,61,.08); --ring:0 0 0 4px rgba(27,79,156,.18);
  font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
  color:var(--text); font-size:14px; line-height:1.45;
  display:flex; flex-direction:column; gap:10px; max-width:1800px; margin:0 auto;
}
#imp2 *{box-sizing:border-box}
#imp2 [hidden]{display:none!important}
#imp2 button{font:inherit;color:inherit}
#imp2 h1,#imp2 h2,#imp2 h3{margin:0;font-weight:800}

/* barre du haut */
#imp2 .top{display:flex;align-items:center;justify-content:space-between;gap:10px 18px;flex-wrap:wrap}
#imp2 .ttl{display:flex;align-items:center;gap:12px}
#imp2 .ttl .logo{width:40px;height:40px;flex:none}
#imp2 .ttl h1{font-size:1.55rem;letter-spacing:-.01em;line-height:1.1;color:var(--text)}
#imp2 .ttl p{margin:1px 0 0;color:var(--muted);font-size:.86rem;font-weight:600}
#imp2 .ctrls{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
#imp2 .btn{border:0;border-radius:12px;padding:9px 16px;background:var(--primary);color:#fff;font-weight:800;cursor:pointer;display:inline-flex;align-items:center;gap:7px;transition:background .15s,box-shadow .15s;white-space:nowrap}
#imp2 .btn:hover{background:var(--primary-dark)}
#imp2 .btn.ghost{background:var(--card);color:var(--text);border:1px solid var(--line)}
#imp2 .btn.ghost:hover{background:var(--soft)}
#imp2 .btn:focus-visible,#imp2 .tile:focus-visible,#imp2 .link:focus-visible{outline:none;box-shadow:var(--ring)}
#imp2 .demo-badge{display:inline-block;vertical-align:middle;margin-left:8px;font-size:.7rem;font-weight:900;padding:3px 10px;border-radius:99px;background:#FFF6C2;color:#524000;border:1px solid #f1d66b}
#imp2 .link{background:none;border:0;padding:0;color:var(--primary);font-weight:700;cursor:pointer;text-decoration:underline;text-underline-offset:2px}
#imp2 .syschip{display:flex;align-items:center;gap:8px;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:4px 10px 4px 5px;font-weight:700;font-size:.86rem}
#imp2 .glyph{width:30px;height:30px;border-radius:9px;display:grid;place-items:center;color:#fff;font-weight:900;font-size:.78rem;flex:none;letter-spacing:-.02em}

/* bande marine */
#imp2 .stage{background:radial-gradient(120% 170% at 35% 0%,#1d3d70,var(--navy) 70%);color:#EAF1F8;border-radius:20px;padding:12px 18px;display:flex;flex-direction:column;gap:10px;overflow:hidden}
#imp2 .bridge{display:grid;grid-template-columns:minmax(0,230px) minmax(0,1fr) auto minmax(0,330px);gap:14px;align-items:center}
#imp2 .end{display:flex;align-items:center;gap:10px;min-width:0}
#imp2 .end .glyph{width:46px;height:46px;border-radius:13px;font-size:1rem;position:relative;box-shadow:0 0 0 3px rgba(255,255,255,.08)}
#imp2 .end .live{position:absolute;right:-4px;top:-4px;width:13px;height:13px;border-radius:50%;background:#8ea4bb;border:2px solid var(--navy)}
#imp2 .end .live.on{background:#4ADE80;box-shadow:0 0 0 3px rgba(74,222,128,.25)}
#imp2 .lbl{font-size:.64rem;text-transform:uppercase;letter-spacing:.1em;color:#9fb3c9;font-weight:800}
#imp2 .end .nm{font-weight:800;font-size:1.02rem;line-height:1.15;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#imp2 .end .via{font-size:.72rem;color:#9fb3c9;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#imp2 .end .txt{min-width:0}
#imp2 .flow{position:relative;height:72px;min-width:0}
#imp2 .flow canvas{position:absolute;inset:0;width:100%;height:100%}
#imp2 .chip{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);display:flex;gap:8px;align-items:center;font-size:.8rem;font-weight:700;background:rgba(9,20,40,.82);border:1px solid #2b4a74;border-radius:99px;padding:5px 13px;white-space:nowrap;max-width:100%;overflow:hidden}
#imp2 .chip .dot{width:8px;height:8px;border-radius:50%;background:var(--chip,#4ADE80);flex:none}
#imp2 .ring{position:relative;width:72px;height:72px;flex:none}
#imp2 .ring svg{width:100%;height:100%;transform:rotate(-90deg)}
#imp2 .ring .trk{fill:none;stroke:#28466e;stroke-width:9}
#imp2 .ring .val{fill:none;stroke:var(--cyan);stroke-width:9;stroke-linecap:round;transition:stroke-dashoffset .6s}
#imp2 .ring .pct{position:absolute;inset:0;display:grid;place-items:center;font-weight:900;font-size:1.05rem}
#imp2 .stats{display:grid;grid-template-columns:1fr 1fr;gap:6px 14px;border-left:1px solid #2b4a74;padding-left:16px}
#imp2 .stats div{display:flex;flex-direction:column;min-width:0}
#imp2 .stats b{font-weight:800;font-size:1.05rem;white-space:nowrap}
#imp2 .stats span{font-size:.68rem;color:#9fb3c9;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#imp2 .stats b.save{color:#86EFAC}
#imp2 .steps{list-style:none;margin:0;padding:10px 0 0;display:grid;grid-template-columns:repeat(7,minmax(0,1fr));border-top:1px solid #2b4a74}
#imp2 .steps li{display:flex;align-items:center;gap:8px;font-size:.8rem;font-weight:700;color:#8ea4bb;min-width:0;padding-right:8px}
#imp2 .steps li:not(:last-child)::after{content:"";flex:1;height:2px;background:#2b4a74;min-width:10px;border-radius:2px}
#imp2 .steps li.done::after{background:#4ADE80}
#imp2 .steps .b{width:23px;height:23px;border-radius:50%;display:grid;place-items:center;border:2px solid #2b4a74;font-size:.7rem;flex:none;background:var(--navy)}
#imp2 .steps .l{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#imp2 .steps li.run{color:#fff}
#imp2 .steps li.run .b{border-color:var(--cyan);color:var(--cyan);box-shadow:0 0 0 4px rgba(6,182,212,.2)}
#imp2 .steps li.done{color:#EAF1F8}
#imp2 .steps li.done .b{background:#4ADE80;border-color:#4ADE80;color:#0B3B22}

/* 60 parle */
#imp2 .narr{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:7px 12px;display:flex;gap:12px;align-items:center;min-width:0;box-shadow:var(--shadow)}
#imp2 .who60{display:flex;flex-direction:column;align-items:center;flex:none}
#imp2 .who60 small{font-size:.66rem;font-weight:900;color:var(--muted)}
#imp2 .narr .txt{display:flex;flex-direction:column;min-width:0;flex:1}
#imp2 .narr .step{font-size:.66rem;text-transform:uppercase;letter-spacing:.08em;font-weight:900;color:var(--primary)}
#imp2 .narr p{margin:0;font-size:.92rem;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
#imp2 .pill{flex:none;font-size:.74rem;font-weight:800;padding:5px 11px;border-radius:99px;white-space:nowrap;background:var(--soft);color:var(--muted)}
#imp2 .pill.ok{background:var(--ok-soft);color:var(--ok)}
#imp2 .pill.bad{background:var(--bad-soft);color:var(--bad)}
#imp2 .av-inline{display:block}
#imp2 .av-blink{animation:imp2avb 4.5s infinite;transform-box:fill-box;transform-origin:center}
#imp2 .av-spin{animation:imp2avs 1.1s linear infinite;transform-box:fill-box;transform-origin:center}
@keyframes imp2avb{0%,93%,100%{transform:scaleY(1)}96%{transform:scaleY(.12)}}
@keyframes imp2avs{to{transform:rotate(360deg)}}

/* zone principale */
#imp2 .panel{min-height:470px;background:var(--card);border:1px solid var(--line);border-radius:20px;box-shadow:var(--shadow);padding:18px 20px}
#imp2 .panel h2{font-size:1.25rem;color:var(--text)}
#imp2 .panel .lead{color:var(--muted);margin:4px 0 14px;font-weight:600}
#imp2 .tiles{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}
#imp2 .tile{display:flex;gap:12px;align-items:flex-start;text-align:left;background:var(--card);border:1.5px solid var(--line);border-radius:16px;padding:12px;cursor:pointer;transition:border-color .15s,box-shadow .15s,transform .15s}
#imp2 .tile:hover{border-color:var(--primary);box-shadow:0 6px 18px -10px rgba(27,79,156,.5);transform:translateY(-1px)}
#imp2 .tile.choisi{border-color:var(--primary);background:var(--soft2)}
#imp2 .tile .glyph{width:40px;height:40px;border-radius:12px;font-size:.92rem}
#imp2 .tile b{display:block;font-size:.98rem;line-height:1.2}
#imp2 .tile .how{display:block;font-size:.76rem;color:var(--muted);margin-top:2px;font-weight:600}
#imp2 .badge{display:inline-flex;align-items:center;gap:5px;font-size:.68rem;font-weight:800;padding:2px 8px;border-radius:99px;margin-top:6px}
#imp2 .badge.live{background:var(--ok-soft);color:var(--ok)}
#imp2 .badge.live::before{content:"";width:6px;height:6px;border-radius:50%;background:var(--ok)}
#imp2 .badge.file{background:var(--soft2);color:var(--primary)}
#imp2 .note{font-size:.76rem;color:var(--muted);margin:12px 0 0;font-weight:600}
#imp2 .suite{display:flex;gap:16px;align-items:center;border:1px solid var(--line);border-radius:16px;padding:16px;background:var(--page);margin-top:6px}
#imp2 .suite .glyph{width:52px;height:52px;border-radius:14px;font-size:1.05rem}
#imp2 .suite b{display:block;font-size:1.05rem}
#imp2 .suite span{color:var(--muted);font-weight:600;font-size:.86rem}

/* étape 2 : relier la source */
#imp2 .conn{display:grid;grid-template-columns:minmax(0,1.25fr) minmax(0,1fr);gap:22px}
#imp2 .conn ol{margin:10px 0 0;padding:0;list-style:none;counter-reset:s;display:flex;flex-direction:column;gap:10px}
#imp2 .conn ol li{counter-increment:s;display:grid;grid-template-columns:30px 1fr;gap:10px;align-items:start}
#imp2 .conn ol li::before{content:counter(s);width:28px;height:28px;border-radius:50%;background:var(--soft2);color:var(--primary);font-weight:900;display:grid;place-items:center}
#imp2 .conn ol li b{display:block}
#imp2 .conn ol li span span{color:var(--muted);font-size:.86rem;font-weight:600}
#imp2 .box{border:1px solid var(--line);border-radius:16px;padding:14px;display:flex;flex-direction:column;gap:12px;background:var(--page)}
#imp2 .field{display:flex;flex-direction:column;gap:4px}
#imp2 .field label{font-size:.72rem;font-weight:900;text-transform:uppercase;letter-spacing:.06em;color:var(--muted)}
#imp2 .field input,#imp2 .field select{border:1px solid var(--line);border-radius:10px;padding:8px 10px;background:var(--card);font:inherit;font-weight:600;color:var(--text)}
#imp2 .field input:focus,#imp2 .field select:focus{outline:none;box-shadow:var(--ring)}
#imp2 .field small{font-size:.74rem;color:var(--muted);font-weight:600}
#imp2 .box .btn{justify-content:flex-start}
#imp2 .box .link{align-self:center}
#imp2 .btn[disabled]{opacity:.55;cursor:default}
#imp2 .safe{display:flex;gap:8px;align-items:flex-start;font-size:.8rem;color:var(--muted);font-weight:600}
#imp2 .safe svg{flex:none;color:var(--ok);margin-top:1px}
#imp2 .recap{display:grid;grid-template-columns:auto 1fr;gap:4px 14px;font-size:.88rem;margin:12px 0 0}
#imp2 .recap dt{color:var(--muted);font-weight:700}
#imp2 .recap dd{margin:0;font-weight:800}
#imp2 .pill.act{background:var(--act-soft);color:#7a5c00}
#imp2 .pill.run{background:#DDF6FA;color:#0b6b7d}

/* bilan */
#imp2 .final{background:var(--card);border:1.5px solid var(--line);border-radius:var(--radius);padding:8px 14px;display:flex;flex-wrap:wrap;gap:8px 18px;align-items:center;box-shadow:var(--shadow)}
#imp2 .final .hd{display:flex;align-items:center;gap:10px;flex:1;min-width:260px}
#imp2 .final h3{font-size:1rem;line-height:1.2;color:var(--text)}
#imp2 .final .sub{margin:0;color:var(--muted);font-size:.76rem;font-weight:600}
#imp2 .facts{display:flex;gap:8px;flex-wrap:wrap}
#imp2 .fact{border:1px solid var(--line);border-radius:12px;padding:4px 11px;display:flex;flex-direction:column;min-width:118px}
#imp2 .fact b{font-weight:900;font-size:.9rem;white-space:nowrap}
#imp2 .fact span{font-size:.66rem;color:var(--muted);font-weight:700}
#imp2 .fine{font-size:.68rem;color:var(--muted);margin:0;flex-basis:100%;font-weight:600}
@media (prefers-reduced-motion:reduce){#imp2 *{transition:none!important;animation:none!important}}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="imp2">
  <header class="top">
    <div class="ttl">
      <span class="logo" id="i2Logo"></span>
      <div><h1><span id="i2Titre"></span> <span class="demo-badge" id="i2Demo"></span></h1><p id="i2SousTitre"></p></div>
    </div>
    <div class="ctrls">
      <div class="syschip" id="i2Chip" hidden><span class="glyph" id="i2ChipG"></span><span id="i2ChipN"></span><button class="link" type="button" id="i2Changer"></button></div>
      <button class="btn ghost" type="button" id="i2Vider"></button>
    </div>
  </header>

  <section class="stage">
    <div class="bridge">
      <div class="end"><div class="glyph" id="i2SrcG" style="background:#3a5a86"><span id="i2SrcGT">?</span><span class="live" id="i2Live"></span></div><div class="txt"><div class="lbl" id="i2LblOrigine"></div><div class="nm" id="i2SrcN"></div><div class="via" id="i2SrcVia"></div></div></div>
      <div class="flow"><canvas id="i2Flow" aria-hidden="true"></canvas><div class="chip" id="i2FlowChip"><span class="dot"></span><span id="i2FlowT"></span></div></div>
      <div class="end"><div class="ring"><svg viewBox="0 0 120 120"><circle class="trk" cx="60" cy="60" r="50"/><circle class="val" cx="60" cy="60" r="50" stroke-dasharray="314.16" stroke-dashoffset="314.16"/></svg><div class="pct">0/8</div></div><div class="txt"><div class="lbl" id="i2LblDest"></div><div class="nm">60secondes</div><div class="via" id="i2DestVia"></div></div></div>
      <div class="stats">
        <div><b>—</b><span id="i2StRes"></span></div>
        <div><b>0/8</b><span id="i2StImp"></span></div>
        <div><b>0</b><span id="i2StEnr"></span></div>
        <div><b class="save">0 h</b><span id="i2StSaisie"></span></div>
      </div>
    </div>
    <ol class="steps" id="i2Etapes"></ol>
  </section>

  <div class="narr" aria-live="polite">
    <div class="who60"><span id="i2NarrAv"></span><small>60</small></div>
    <div class="txt"><span class="step" id="i2NarrEtape"></span><p id="i2NarrTexte"></p></div>
    <span class="pill" id="i2NarrPill"></span>
  </div>

  <main class="panel" id="i2Main"></main>

  <section class="final">
    <div class="hd"><span id="i2FinAv"></span><div><h3 id="i2FinTitre"></h3><p class="sub" id="i2FinSous"></p></div></div>
    <div class="facts">
      <div class="fact"><b>—</b><span id="i2FaComptes"></span></div>
      <div class="fact"><b>—</b><span id="i2FaFiches"></span></div>
      <div class="fact"><b>—</b><span id="i2FaFactures"></span></div>
      <div class="fact"><b>—</b><span id="i2FaBalance"></span></div>
    </div>
    <p class="fine" id="i2Fine"></p>
  </section>
</div>

<script>
var IMP2 = <asp:Literal ID="litData" runat="server" />;
var IMP2L = <asp:Literal ID="litLabels" runat="server" />;
</script>
<script>
(function () {
  var L = IMP2L, S = { sys: IMP2.logiciel || null, mode: IMP2.mode || 'direct', bascule: IMP2.bascule || '', freq: IMP2.freq || 'trimestre', relie: !!IMP2.relie };
  function $(id) { return document.getElementById(id); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function f(txt, v) { return String(txt).replace(/\{(\w+)\}/g, function (m, k) { return v && v[k] != null ? v[k] : m; }); }

  /* logiciels d'origine (couleurs et sigles de la maquette) ; how : oauth | agent | apikey | file */
  var SYS = [
    { k: 'qbo', n: 'QuickBooks Online', g: 'qb', col: '#2CA01C', how: 'oauth', who: 'Intuit' },
    { k: 'qbd', n: 'QuickBooks Desktop', g: 'qbd', col: '#1d7f16', how: 'agent' },
    { k: 'xero', n: 'Xero', g: 'X', col: '#13B5EA', how: 'oauth', who: 'Xero' },
    { k: 'sagebca', n: L.sageEnLigne, g: 'S', col: '#00A651', how: 'oauth', who: 'Sage' },
    { k: 'fresh', n: 'FreshBooks', g: 'F', col: '#0075DD', how: 'oauth', who: 'FreshBooks' },
    { k: 'wave', n: 'Wave', g: 'W', col: '#1C4DA1', how: 'oauth', who: 'Wave' },
    { k: 'zoho', n: 'Zoho Books', g: 'Z', col: '#D7262D', how: 'oauth', who: 'Zoho' },
    { k: 'odoo', n: 'Odoo', g: 'O', col: '#714B67', how: 'apikey' },
    { k: 'sage50', n: L.sage50, g: 'S50', col: '#007E45', how: 'file' },
    { k: 'acomba', n: 'Acomba', g: 'Ac', col: '#B5121B', how: 'file' },
    { k: 'autre', n: L.autre, g: '…', col: '#44536E', how: 'file' }
  ];
  SYS.forEach(function (s) { s.line = L['ligne_' + s.k]; s.live = s.how !== 'file'; });
  function sysObj() { for (var i = 0; i < SYS.length; i++) if (SYS[i].k === S.sys) return SYS[i]; return null; }
  function how() { var s = sysObj(); return !s ? null : (S.mode === 'fichier' ? 'file' : s.how); }

  /* chemins d'export connus (menus en français) ; sinon une consigne générale */
  var EXP = {
    qbo: { plan: 'Comptabilité ▸ Plan comptable ▸ Exécuter le rapport ▸ Exporter vers Excel', bal: "Rapports ▸ Balance de vérification ▸ période jusqu'à la date de bascule ▸ Exporter vers Excel", clients: 'Ventes ▸ Clients ▸ icône Exporter vers Excel', fourn: 'Dépenses ▸ Fournisseurs ▸ icône Exporter vers Excel', prod: 'Ventes ▸ Produits et services ▸ icône Exporter vers Excel', fv: 'Rapports ▸ Liste des transactions (factures et factures fournisseurs) ▸ Exporter vers Excel' },
    xero: { plan: 'Comptabilité ▸ Plan comptable ▸ Exporter', bal: 'Rapports ▸ Balance de vérification ▸ Exporter ▸ Excel' }
  };
  var MODS = ['plan', 'bal', 'clients', 'fourn', 'prod', 'fv'];
  function consigneExport(s, k) {
    if (L.lang === 'fr' && EXP[s.k] && EXP[s.k][k]) return f(L.exporterChemin, { n: s.n, c: EXP[s.k][k] });
    return f(L.exporterGenerique, { n: s.n, r: L['exp_' + k] });
  }

  /* 60 : dessin officiel de 60sec.ca (maquette) */
  var AV = (function () {
    var C = { sarcelle: ['#C8F7F1', '#3DDCCB', '#06524C'], bleu: ['#D2E9FF', '#5AAEFF', '#0B3F80', '#2F6FD6'], vert: ['#CFF7DF', '#4ADE80', '#0B5229', '#1E9E5A'], rouge: ['#FFC2C2', '#FF5E5E', '#7A0E0E', '#C62E2E'], jaune: ['#FFF6C2', '#FFDD33', '#524000', '#D9A300'], gris: ['#EEF2F6', '#B8C4D1', '#2E3B48'] };
    var X = { principal: { c: 'sarcelle', eye: 'blink', mouth: 'M99 166 q29 16 58 0' }, bonjour: { c: 'sarcelle', eye: 'happy', mouth: 'M97 164 q31 24 62 0' }, travail: { c: 'sarcelle', eye: 'spin', mouth: 'M106 168 q22 6 44 0' }, info: { c: 'bleu', eye: 'blink', mouth: 'M103 166 q25 12 50 0', bdg: 'i' }, regle: { c: 'vert', eye: 'happy', mouth: 'M97 164 q31 24 62 0', bdg: 'ok' }, probleme: { c: 'rouge', eye: 'blink', brow: 'M144 74 l30 -9', mouth: 'M103 178 q25 -14 50 0', bdg: 'x' }, action: { c: 'jaune', eye: 'blink', brow: 'M145 72 l30 -6', mouth: 'M102 166 q26 12 52 0', bdg: 'arrow' }, pause: { c: 'gris', eye: 'closed', mouth: 'M108 168 q20 4 40 0' } };
    var n = 0;
    return function (expr, size) {
      var e = X[expr] || X.principal, c = C[e.c], k = c[2], id = 'imp2av' + (n++);
      var eye = { blink: '<ellipse class="av-blink" cx="160" cy="110" rx="15" ry="25" fill="none" stroke="' + k + '" stroke-width="12"/>', happy: '<path d="M142 116 q18 -24 36 0" fill="none" stroke="' + k + '" stroke-width="12" stroke-linecap="round"/>', spin: '<ellipse class="av-spin" cx="160" cy="110" rx="21" ry="21" fill="none" stroke="' + k + '" stroke-width="12" stroke-dasharray="88 44" stroke-linecap="round"/>', closed: '<path d="M142 110 q18 10 36 0" fill="none" stroke="' + k + '" stroke-width="12" stroke-linecap="round"/>' }[e.eye];
      if (e.brow) eye += '<path d="' + e.brow + '" stroke="' + k + '" stroke-width="9" stroke-linecap="round"/>';
      var ring = '<circle cx="224.5" cy="42" r="23" fill="' + (c[3] || '#1E9E5A') + '" stroke="#fff" stroke-width="4"/>';
      var b = { ok: ring + '<path d="M214 42 l7.5 7.5 l13 -15" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>', x: ring + '<path d="M216 33.5 l17 17 M233 33.5 l-17 17" stroke="#fff" stroke-width="6" stroke-linecap="round"/>', arrow: ring + '<path d="M214 42 h19 M226 34.5 l7.5 7.5 l-7.5 7.5" fill="none" stroke="#fff" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round"/>', i: ring + '<rect x="221.5" y="39" width="6" height="16" rx="3" fill="#fff"/><circle cx="224.5" cy="31.5" r="3.8" fill="#fff"/>' }[e.bdg] || '';
      return '<svg class="av-inline" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="' + size + '" height="' + size + '" overflow="visible" role="img" aria-label="60"><defs><radialGradient id="' + id + '" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="' + c[0] + '"/><stop offset="1" stop-color="' + c[1] + '"/></radialGradient></defs><circle cx="128" cy="128" r="104" fill="url(#' + id + ')"/><ellipse cx="96" cy="62" rx="44" ry="20" fill="#fff" opacity=".45" transform="rotate(-20 96 62)"/><circle cx="128" cy="128" r="102" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="3"/><circle cx="96" cy="120" r="16" fill="none" stroke="' + k + '" stroke-width="12"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="' + k + '" stroke-width="12" stroke-linecap="round"/>' + eye + '<path d="' + e.mouth + '" fill="none" stroke="' + k + '" stroke-width="10" stroke-linecap="round"/>' + b + '</svg>';
    };
  })();

  /* libellés fixes */
  $('i2Logo').innerHTML = AV('principal', 40);
  $('i2Titre').textContent = L.titre; $('i2Demo').textContent = L.demo; $('i2Demo').title = L.demoTip;
  $('i2SousTitre').textContent = L.sousTitre;
  $('i2Vider').textContent = L.vider; $('i2Vider').title = L.viderTip; $('i2Changer').textContent = L.changer;
  $('i2LblOrigine').textContent = L.origine; $('i2LblDest').textContent = L.destination; $('i2DestVia').textContent = L.destVia;
  $('i2StRes').textContent = L.stRes; $('i2StImp').textContent = L.stImp; $('i2StEnr').textContent = L.stEnr; $('i2StSaisie').textContent = L.stSaisie;
  $('i2FinAv').innerHTML = AV('pause', 32);
  $('i2FinTitre').textContent = L.finTitre; $('i2FinSous').textContent = L.finSous;
  $('i2FaComptes').textContent = L.faComptes; $('i2FaFiches').textContent = L.faFiches; $('i2FaFactures').textContent = L.faFactures;
  $('i2Fine').textContent = L.fine;
  function dateLisible(iso) {
    if (!iso) return '—';
    var p = iso.split('-'), d = new Date(+p[0], +p[1] - 1, +p[2]);
    try { return d.toLocaleDateString(L.lang === 'en' ? 'en-CA' : (L.lang === 'es' ? 'es-ES' : 'fr-CA'), { day: 'numeric', month: 'long', year: 'numeric' }); } catch (e) { return iso; }
  }
  function bilan() { $('i2FaBalance').textContent = f(L.faBalance, { 0: S.bascule ? dateLisible(S.bascule) : '—' }); }

  /* 60 parle */
  function dire(expr, etape, texte, pill, cls) {
    $('i2NarrAv').innerHTML = AV(expr, 40); $('i2NarrEtape').textContent = etape;
    $('i2NarrTexte').textContent = texte; $('i2NarrTexte').title = texte;
    var p = $('i2NarrPill'); p.textContent = pill || ''; p.className = 'pill ' + (cls || ''); p.hidden = !pill;
  }
  function etapeN(n) { return f(L.etapeNsur7, { 0: n }); }

  /* étapes */
  function etapes(courante) {
    var noms = [L.e1, how() === 'file' ? L.e2Fichiers : L.e2, L.e3, L.e4, L.e5, L.e6, L.e7];
    $('i2Etapes').innerHTML = noms.map(function (n, i) {
      var cls = i + 1 < courante ? 'done' : (i + 1 === courante ? 'run' : '');
      return '<li class="' + cls + '"><span class="b">' + (i + 1 < courante ? '✓' : (i + 1)) + '</span><span class="l">' + esc(n) + '</span></li>';
    }).join('');
  }

  /* origine dans la bande marine */
  function origine() {
    var s = sysObj();
    if (!s) { $('i2SrcGT').textContent = '?'; $('i2SrcG').style.background = '#3a5a86'; $('i2SrcN').textContent = L.aChoisir; $('i2SrcVia').textContent = L.origineVia; $('i2Live').className = 'live'; puce(L.enAttente, '#4ADE80'); $('i2Chip').hidden = true; return; }
    $('i2SrcGT').textContent = s.g; $('i2SrcG').style.background = s.col; $('i2SrcN').textContent = s.n;
    var direct = how() !== 'file';
    $('i2SrcVia').textContent = !direct ? L.viaFichiers : (S.relie ? L.viaRelie : L.viaDirect);
    $('i2Live').className = 'live' + (direct && S.relie ? ' on' : '');
    if (S.relie) puce(direct ? L.fluxRelie : L.fluxFichiers, '#4ADE80'); else puce(L.enAttente, '#4ADE80');
    $('i2Chip').hidden = false; $('i2ChipG').textContent = s.g; $('i2ChipG').style.background = s.col; $('i2ChipN').textContent = s.n;
  }
  function puce(t, col) { $('i2FlowT').textContent = t; $('i2FlowChip').style.setProperty('--chip', col); }

  /* serveur : POST op=… (session, par compagnie) */
  function poster(op, donnees) {
    var corps = 'op=' + encodeURIComponent(op);
    for (var k in (donnees || {})) corps += '&' + k + '=' + encodeURIComponent(donnees[k]);
    return fetch(location.pathname, { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: corps })
      .then(function (r) { return r.json().catch(function () { return { ok: false }; }); });
  }
  function prendreEtat(e) { if (!e) return; S.sys = e.logiciel || null; S.mode = e.mode || 'direct'; S.bascule = e.bascule || ''; S.freq = e.freq || 'trimestre'; S.relie = !!e.relie; }
  function erreur(msg, etape) { dire('probleme', etape || L.erreur, msg || L.erreurTexte, L.erreur, 'bad'); }

  /* ===== Étape 1 : choisir le logiciel ===== */
  function vueChoix() {
    var tuiles = SYS.map(function (s) {
      return '<button class="tile" type="button" data-sys="' + s.k + '" data-lecture="1"><span class="glyph" style="background:' + s.col + '">' + esc(s.g) + '</span><span><b>' + esc(s.n) + '</b><span class="how">' + esc(s.line) + '</span><span class="badge ' + (s.live ? 'live' : 'file') + '">' + esc(s.live ? L.enDirect : L.parFichier) + '</span></span></button>';
    }).join('');
    $('i2Main').innerHTML = '<h2>' + esc(L.question) + '</h2><p class="lead">' + esc(L.lead) + '</p><div class="tiles">' + tuiles + '</div><p class="note">' + esc(L.noteAutre) + '</p>';
    Array.prototype.forEach.call($('i2Main').querySelectorAll('[data-sys]'), function (b) { b.addEventListener('click', function () { choisir(b.getAttribute('data-sys')); }); });
    S.sys = null; origine(); etapes(1); flux(false); bilan();
    dire('bonjour', L.bonjour, L.bonjourTexte, etapeN(1), '');
  }
  function choisir(k) {
    dire('travail', L.bonjour, L.enregistrement, '', '');
    poster('source', { logiciel: k }).then(function (j) {
      if (!j || !j.ok) return erreur(j && j.erreur);
      prendreEtat(j.etat); vueConnexion();
    }).catch(function () { erreur(); });
  }

  /* ===== Étape 2 : la bonne connexion selon le logiciel ===== */
  var BOUCLIER = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z"/><path d="m9 12 2 2 4-4"/></svg>';
  function sur(t) { return '<div class="safe">' + BOUCLIER + '<span>' + esc(t) + '</span></div>'; }
  function li(t, d) { return '<li><span><b>' + esc(t) + '</b><span>' + esc(d) + '</span></span></li>'; }

  function vueConnexion(ditChoix) {
    var s = sysObj(); if (!s) return vueChoix();
    var h = how(), v = { n: s.n, w: s.who || s.n };
    var date = '<div class="field"><label for="i2Date">' + esc(L.date) + '</label><input type="date" id="i2Date" value="' + esc(S.bascule) + '" required data-lecture="1" /><small>' + esc(L.dateAide) + '</small></div>';
    var freq = '<div class="field"><label for="i2Freq">' + esc(L.taxes) + '</label><select id="i2Freq" data-lecture="1"><option value="trimestre">' + esc(L.trimestre) + '</option><option value="mois">' + esc(L.mois) + '</option><option value="annee">' + esc(L.annee) + '</option></select></div>';
    var alt = s.how !== 'file'
      ? '<button class="link" type="button" id="i2Alt" data-lecture="1">' + esc(h === 'file' ? L.preferDirect : L.preferFichiers) + '</button>' : '';
    var pas = '', boite = '', titre, lead, dit, expr = 'action';
    if (h === 'oauth') {
      pas = li(f(L.oa1, v), f(L.oa1d, v)) + li(L.oa2, f(L.oa2d, v)) + li(L.oa3, L.oa3d);
      boite = date + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(f(L.seConnecter, v)) + '</button>' + sur(f(L.securiteOauth, v)) + alt;
      dit = f(L.ditOauth, v);
    } else if (h === 'agent') {
      pas = li(L.qb1, L.qb1d) + li(L.qb2, L.qb2d) + li(L.qb3, L.qb3d) + li(L.qb4, L.qb4d);
      boite = date + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.preparerLiaison) + '</button>' + sur(L.securiteQbd) + alt;
      dit = L.ditQbd;
    } else if (h === 'apikey') {
      pas = li(L.od1, L.od1d) + li(L.od2, L.od2d) + li(L.od3, L.od3d);
      boite = '<div class="field"><label for="i2Url">' + esc(L.adresseOdoo) + '</label><input id="i2Url" placeholder="https://…" autocomplete="url" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2Db">' + esc(L.base) + '</label><input id="i2Db" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2User">' + esc(L.utilisateur) + '</label><input id="i2User" autocomplete="username" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2Key">' + esc(L.cleApi) + '</label><input id="i2Key" type="password" autocomplete="off" data-lecture="1" /></div>' +
        date + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.verifier) + '</button>' + sur(L.securiteOdoo) + alt;
      dit = L.ditOdoo;
    } else {
      pas = MODS.map(function (k) { return li(L['nom_' + k], consigneExport(s, k)); }).join('');
      boite = date + '<div class="field"><label>' + esc(L.accepte) + '</label><small>' + esc(L.accepteAide) + '</small></div><button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.passerFichiers) + '</button>' + sur(L.securiteFichiers) + alt;
      dit = ditChoix ? L.ditFichiersChoix : f(L.ditFichiers, v); expr = 'info';
    }
    titre = h === 'file' ? f(L.exportsTitre, v) : f(L.relierTitre, v);
    lead = h === 'file' ? L.exportsLead : L.relierLead;
    $('i2Main').innerHTML = '<div class="conn"><div><h2>' + esc(titre) + '</h2><p class="lead">' + esc(lead) + '</p><ol>' + pas + '</ol></div><div class="box">' + boite + '</div></div>';
    var fr = $('i2Freq'); if (fr) fr.value = S.freq;
    $('i2Date').addEventListener('change', function (e) { S.bascule = e.target.value || ''; bilan(); });
    $('i2Go').addEventListener('click', aller);
    var a = $('i2Alt'); if (a) a.addEventListener('click', basculerMode);
    S.relie = false; origine(); etapes(2); flux(false); bilan();
    dire(expr, h === 'file' ? L.etape2Fichiers : L.etape2Connexion, dit, etapeN(2), '');
  }
  function reglages() {
    S.bascule = $('i2Date').value || ''; var fr = $('i2Freq'); if (fr) S.freq = fr.value; bilan();
    if (!S.bascule) { dire('action', L.date, L.dateAide, L.aCompleter, 'act'); $('i2Date').focus(); return null; }
    return { bascule: S.bascule, freq: S.freq };
  }
  function basculerMode() {
    var vers = how() === 'file' ? 'direct' : 'fichier';
    poster('mode', { mode: vers }).then(function (j) {
      if (!j || !j.ok) return erreur(j && j.erreur);
      var b = S.bascule, fq = S.freq; prendreEtat(j.etat); if (!S.bascule) S.bascule = b; S.freq = fq || S.freq;
      vueConnexion(vers === 'fichier');
    }).catch(function () { erreur(); });
  }
  function occupe(on) { var g = $('i2Go'); if (g) g.disabled = !!on; }

  function aller() {
    var r = reglages(); if (!r) return;
    var s = sysObj(), h = how(), v = { n: s.n, w: s.who || s.n };
    if (h === 'file') {
      occupe(true);
      poster('fichiers', r).then(function (j) {
        occupe(false);
        if (!j || !j.ok) return erreur(j && j.erreur, L.etape2Fichiers);
        prendreEtat(j.etat); vueSuivante();
      }).catch(function () { occupe(false); erreur(); });
      return;
    }
    if (h === 'apikey') {
      var ok = /^https:\/\/[^\s/]+\.[^\s/]+/.test(($('i2Url').value || '').trim()) && $('i2Db').value.trim() && $('i2User').value.trim() && $('i2Key').value;
      if (!ok) return dire('probleme', L.etape2Connexion, L.odooManque, L.aCompleter, 'bad');
      $('i2Key').value = '';   // la clé n'est jamais envoyée tant que la liaison Odoo n'existe pas
    }
    // OAuth : la fenêtre s'ouvre au clic (sinon le bloqueur la retient), puis reçoit l'adresse
    var fen = h === 'oauth' ? window.open('', 'connexion60', 'width=560,height=760') : null;
    occupe(true);
    dire('travail', L.etape2Connexion, L.enregistrement, L.connexion, 'run');
    poster('connexion', r).then(function (j) {
      if (!j || !j.ok || !j.url) { occupe(false); if (fen) fen.close(); return erreur(j && j.erreur, L.etape2Connexion); }
      if (fen && !fen.closed) fen.location = j.url; else window.open(j.url, 'connexion60', 'width=560,height=760');
      dire('travail', L.etape2Connexion, f(L.attenteAutorisation, v), L.connexion, 'run');
      flux(true); sonder(Date.now());
    }).catch(function () { occupe(false); if (fen) fen.close(); erreur(); });
  }
  function sonder(debut) {
    if (Date.now() - debut > 300000) { occupe(false); flux(false); return dire('pause', L.etape2Connexion, L.pasRecu, L.enAttente, ''); }
    poster('etatConnexion').then(function (j) {
      if (j && j.ok && j.statut === 'connecte') { occupe(false); prendreEtat(j.etat); return vueSuivante(); }
      if (j && !j.ok) { occupe(false); flux(false); return erreur(j.erreur, L.etape2Connexion); }
      setTimeout(function () { sonder(debut); }, 2000);
    }).catch(function () { setTimeout(function () { sonder(debut); }, 2000); });
  }

  /* ===== Étape 3 (à venir) : la suite, une fois la source reliée ===== */
  function vueSuivante() {
    var s = sysObj(); if (!s) return vueChoix();
    var h = how(), v = { n: s.n };
    var freqNom = { trimestre: L.trimestre, mois: L.mois, annee: L.annee }[S.freq] || S.freq;
    $('i2Main').innerHTML = '<h2>' + esc(L.e3Titre) + '</h2><p class="lead">' + esc(f(h === 'file' ? L.e3LeadFichiers : L.e3LeadDirect, v)) + '</p>' +
      '<div class="suite"><span class="glyph" style="background:' + s.col + '">' + esc(s.g) + '</span><div><b>' + esc(s.n) + '</b><span>' + esc(h === 'file' ? L.viaFichiers : L.viaRelie) + '</span>' +
      '<dl class="recap"><dt>' + esc(L.date) + '</dt><dd>' + esc(dateLisible(S.bascule)) + '</dd><dt>' + esc(L.taxes) + '</dt><dd>' + esc(freqNom) + '</dd></dl></div></div>' +
      '<p class="note">' + esc(L.aVenir) + ' <button class="link" type="button" id="i2Retour" data-lecture="1">' + esc(L.modifierReglages) + '</button></p>';
    $('i2Retour').addEventListener('click', function () {
      poster('retour').then(function (j) { if (j && j.ok) { prendreEtat(j.etat); vueConnexion(); } else erreur(j && j.erreur); }).catch(function () { erreur(); });
    });
    S.relie = true; origine(); etapes(3); flux(h !== 'file'); bilan();
    if (h === 'file') dire('regle', L.fichiersOk, L.fichiersTexte, etapeN(3), 'ok');
    else dire('regle', L.relieOk, f(L.relieTexte, v), etapeN(3), 'ok');
  }

  /* changer de logiciel / vider la préparation */
  function oublier(apres) {
    poster('vider').then(function (j) { if (!j || !j.ok) return erreur(j && j.erreur); S.bascule = ''; S.freq = 'trimestre'; S.relie = false; apres(); }).catch(function () { erreur(); });
  }
  $('i2Changer').addEventListener('click', function () { oublier(vueChoix); });
  $('i2Vider').addEventListener('click', function () {
    var go = function () { oublier(vueChoix); };
    if (window.appConfirm) appConfirm(L.viderConfirme, { titre: L.vider, ok: L.vider, danger: true }).then(function (oui) { if (oui) go(); });
    else go();
  });

  /* flux animé de la bande marine (maquette) */
  var cv = $('i2Flow'), ctx = cv.getContext('2d'), parts = [], coule = false, acc = 0, W = 0, H = 0, avant = performance.now();
  var calme = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  function taille() { var r = cv.getBoundingClientRect(), d = window.devicePixelRatio || 1; W = r.width; H = r.height; cv.width = W * d; cv.height = H * d; ctx.setTransform(d, 0, 0, d, 0, 0); }
  window.addEventListener('resize', taille);
  function voies() { return [-.34, -.12, .12, .34].map(function (o) { return { y0: H / 2 + o * H, y1: H / 2 + o * H * .3 }; }); }
  function pt(l, t) { var e = t * t * (3 - 2 * t); return { x: t * W, y: l.y0 + (l.y1 - l.y0) * e }; }
  function image(now) {
    var dt = Math.min(60, now - avant); avant = now; ctx.clearRect(0, 0, W, H); var V = voies();
    ctx.lineWidth = 1; ctx.strokeStyle = 'rgba(159,179,201,.18)';
    V.forEach(function (l) { ctx.beginPath(); for (var t = 0; t <= 1.001; t += .05) { var p = pt(l, t); if (t) ctx.lineTo(p.x, p.y); else ctx.moveTo(p.x, p.y); } ctx.stroke(); });
    if (coule && !calme) { acc += dt * .012; while (acc > 1) { acc--; parts.push({ l: V[(Math.random() * 4) | 0], t: 0, v: .0004 + Math.random() * .0004, s: 2 + Math.random() * 2, c: '#06b6d4' }); } }
    parts.forEach(function (p) { p.t += p.v * dt; }); parts = parts.filter(function (p) { return p.t < 1; });
    parts.forEach(function (p) { var q = pt(p.l, p.t); ctx.globalAlpha = Math.sin(Math.PI * p.t); ctx.fillStyle = p.c; ctx.fillRect(q.x - p.s, q.y - p.s * 1.3, p.s * 2, p.s * 2.6); });
    ctx.globalAlpha = 1; requestAnimationFrame(image);
  }
  function flux(on) { coule = on; }
  requestAnimationFrame(function (t) { taille(); image(t); });

  /* démarrage : reprendre là où l'usager s'est arrêté */
  if (!sysObj()) vueChoix();
  else if (S.relie) vueSuivante();
  else vueConnexion();
})();
</script>
</asp:Content>
