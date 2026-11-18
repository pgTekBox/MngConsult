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
  var L = IMP2L, S = { sys: IMP2.logiciel || null };
  function $(id) { return document.getElementById(id); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  /* logiciels d'origine (couleurs et sigles de la maquette) */
  var SYS = [
    { k: 'qbo', n: 'QuickBooks Online', g: 'qb', col: '#2CA01C', live: 1 },
    { k: 'qbd', n: 'QuickBooks Desktop', g: 'qbd', col: '#1d7f16', live: 1 },
    { k: 'xero', n: 'Xero', g: 'X', col: '#13B5EA', live: 1 },
    { k: 'sagebca', n: L.sageEnLigne, g: 'S', col: '#00A651', live: 1 },
    { k: 'fresh', n: 'FreshBooks', g: 'F', col: '#0075DD', live: 1 },
    { k: 'wave', n: 'Wave', g: 'W', col: '#1C4DA1', live: 1 },
    { k: 'zoho', n: 'Zoho Books', g: 'Z', col: '#D7262D', live: 1 },
    { k: 'odoo', n: 'Odoo', g: 'O', col: '#714B67', live: 1 },
    { k: 'sage50', n: L.sage50, g: 'S50', col: '#007E45', live: 0 },
    { k: 'acomba', n: 'Acomba', g: 'Ac', col: '#B5121B', live: 0 },
    { k: 'autre', n: L.autre, g: '…', col: '#44536E', live: 0 }
  ];
  SYS.forEach(function (s) { s.line = L['ligne_' + s.k]; });
  function sysObj() { for (var i = 0; i < SYS.length; i++) if (SYS[i].k === S.sys) return SYS[i]; return null; }

  /* 60 : dessin officiel de 60sec.ca (maquette) */
  var AV = (function () {
    var C = { sarcelle: ['#C8F7F1', '#3DDCCB', '#06524C'], vert: ['#CFF7DF', '#4ADE80', '#0B5229', '#1E9E5A'], rouge: ['#FFC2C2', '#FF5E5E', '#7A0E0E', '#C62E2E'] };
    var X = { principal: { c: 'sarcelle', eye: 'blink', mouth: 'M99 166 q29 16 58 0' }, bonjour: { c: 'sarcelle', eye: 'happy', mouth: 'M97 164 q31 24 62 0' }, travail: { c: 'sarcelle', eye: 'spin', mouth: 'M106 168 q22 6 44 0' }, regle: { c: 'vert', eye: 'happy', mouth: 'M97 164 q31 24 62 0', bdg: 'ok' }, probleme: { c: 'rouge', eye: 'blink', mouth: 'M103 178 q25 -14 50 0', bdg: 'x' }, pause: { c: 'sarcelle', eye: 'closed', mouth: 'M108 168 q20 4 40 0' } };
    var n = 0;
    return function (expr, size) {
      var e = X[expr] || X.principal, c = C[e.c], k = c[2], id = 'imp2av' + (n++);
      var eye = { blink: '<ellipse class="av-blink" cx="160" cy="110" rx="15" ry="25" fill="none" stroke="' + k + '" stroke-width="12"/>', happy: '<path d="M142 116 q18 -24 36 0" fill="none" stroke="' + k + '" stroke-width="12" stroke-linecap="round"/>', spin: '<ellipse class="av-spin" cx="160" cy="110" rx="21" ry="21" fill="none" stroke="' + k + '" stroke-width="12" stroke-dasharray="88 44" stroke-linecap="round"/>', closed: '<path d="M142 110 q18 10 36 0" fill="none" stroke="' + k + '" stroke-width="12" stroke-linecap="round"/>' }[e.eye];
      var ring = '<circle cx="224.5" cy="42" r="23" fill="' + (c[3] || '#1E9E5A') + '" stroke="#fff" stroke-width="4"/>';
      var b = { ok: ring + '<path d="M214 42 l7.5 7.5 l13 -15" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>', x: ring + '<path d="M216 33.5 l17 17 M233 33.5 l-17 17" stroke="#fff" stroke-width="6" stroke-linecap="round"/>' }[e.bdg] || '';
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
  $('i2FaComptes').textContent = L.faComptes; $('i2FaFiches').textContent = L.faFiches; $('i2FaFactures').textContent = L.faFactures; $('i2FaBalance').textContent = L.faBalance;
  $('i2Fine').textContent = L.fine;

  /* 60 parle */
  function dire(expr, etape, texte, pill, cls) {
    $('i2NarrAv').innerHTML = AV(expr, 40); $('i2NarrEtape').textContent = etape;
    $('i2NarrTexte').textContent = texte; $('i2NarrTexte').title = texte;
    var p = $('i2NarrPill'); p.textContent = pill || ''; p.className = 'pill ' + (cls || ''); p.hidden = !pill;
  }

  /* étapes */
  function etapes(courante) {
    var s = sysObj();
    var noms = [L.e1, s && !s.live ? L.e2Fichiers : L.e2, L.e3, L.e4, L.e5, L.e6, L.e7];
    $('i2Etapes').innerHTML = noms.map(function (n, i) {
      var cls = i + 1 < courante ? 'done' : (i + 1 === courante ? 'run' : '');
      return '<li class="' + cls + '"><span class="b">' + (i + 1 < courante ? '✓' : (i + 1)) + '</span><span class="l">' + esc(n) + '</span></li>';
    }).join('');
  }

  /* origine dans la bande marine */
  function origine(s) {
    if (!s) { $('i2SrcGT').textContent = '?'; $('i2SrcG').style.background = '#3a5a86'; $('i2SrcN').textContent = L.aChoisir; $('i2SrcVia').textContent = L.origineVia; $('i2FlowT').textContent = L.enAttente; $('i2FlowChip').style.setProperty('--chip', '#4ADE80'); $('i2Chip').hidden = true; return; }
    $('i2SrcGT').textContent = s.g; $('i2SrcG').style.background = s.col; $('i2SrcN').textContent = s.n;
    $('i2SrcVia').textContent = s.live ? L.viaDirect : L.viaFichiers;
    $('i2FlowT').textContent = s.live ? L.fluxConnexion : L.fluxFichiers; $('i2FlowChip').style.setProperty('--chip', '#FFDD33');
    $('i2Chip').hidden = false; $('i2ChipG').textContent = s.g; $('i2ChipG').style.background = s.col; $('i2ChipN').textContent = s.n;
  }

  /* Étape 1 : choisir le logiciel */
  function vueChoix() {
    S.sys = null;
    var tuiles = SYS.map(function (s) {
      return '<button class="tile" type="button" data-sys="' + s.k + '" data-lecture="1"><span class="glyph" style="background:' + s.col + '">' + esc(s.g) + '</span><span><b>' + esc(s.n) + '</b><span class="how">' + esc(s.line) + '</span><span class="badge ' + (s.live ? 'live' : 'file') + '">' + esc(s.live ? L.enDirect : L.parFichier) + '</span></span></button>';
    }).join('');
    $('i2Main').innerHTML = '<h2>' + esc(L.question) + '</h2><p class="lead">' + esc(L.lead) + '</p><div class="tiles">' + tuiles + '</div><p class="note">' + esc(L.noteAutre) + '</p>';
    Array.prototype.forEach.call($('i2Main').querySelectorAll('[data-sys]'), function (b) { b.addEventListener('click', function () { choisir(b.getAttribute('data-sys')); }); });
    origine(null); etapes(1); flux(false);
    dire('bonjour', L.bonjour, L.bonjourTexte, L.etape1, '');
  }

  /* Étape 2 (à venir) : la suite pour le logiciel choisi */
  function vueSuite() {
    var s = sysObj(); if (!s) return vueChoix();
    $('i2Main').innerHTML = '<h2>' + esc(s.live ? L.e2Titre : L.e2TitreFichiers) + '</h2><p class="lead">' + esc((s.live ? L.e2Lead : L.e2LeadFichiers).replace('{0}', s.n)) + '</p>' +
      '<div class="suite"><span class="glyph" style="background:' + s.col + '">' + esc(s.g) + '</span><div><b>' + esc(s.n) + '</b><span>' + esc(s.line) + ' · ' + esc(s.live ? L.enDirect : L.parFichier) + '</span></div></div>' +
      '<p class="note">' + esc(L.aVenir) + ' <button class="link" type="button" id="i2Autre" data-lecture="1">' + esc(L.changerLogiciel) + '</button></p>';
    $('i2Autre').addEventListener('click', changer);
    origine(s); etapes(2); flux(true);
    dire('regle', L.choisi, L.choisiTexte.replace('{0}', s.n), L.etape2, 'ok');
  }

  /* serveur : retenir / oublier le logiciel (session) */
  function poster(op, donnees) {
    var corps = 'op=' + encodeURIComponent(op);
    for (var k in (donnees || {})) corps += '&' + k + '=' + encodeURIComponent(donnees[k]);
    return fetch(location.pathname, { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: corps })
      .then(function (r) { return r.json().catch(function () { return { ok: false }; }); });
  }
  function erreur(msg) { dire('probleme', L.erreur, msg || L.erreurTexte, L.erreur, 'bad'); }
  function choisir(k) {
    dire('travail', L.bonjour, L.enregistrement, '', '');
    poster('source', { logiciel: k }).then(function (j) {
      if (!j || !j.ok) return erreur(j && j.erreur);
      S.sys = k; vueSuite();
    }).catch(function () { erreur(); });
  }
  function oublier(apres) {
    poster('vider').then(function (j) { if (!j || !j.ok) return erreur(j && j.erreur); apres(); }).catch(function () { erreur(); });
  }
  function changer() { oublier(vueChoix); }
  $('i2Changer').addEventListener('click', changer);
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

  /* démarrage : reprendre le logiciel déjà choisi */
  if (S.sys && sysObj()) vueSuite(); else vueChoix();
})();
</script>
</asp:Content>
