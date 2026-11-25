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
#imp2 .btn.ghost.danger{color:var(--bad);border-color:#f0b4b4}
#imp2 .btn.ghost.danger:hover{background:var(--bad-soft)}
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
/* données déjà en préparation (étapes 1 et 2) */
#imp2 .prep{display:flex;gap:14px;align-items:center;justify-content:space-between;flex-wrap:wrap;border:1px solid var(--ok);background:var(--ok-soft);border-radius:14px;padding:12px 16px;margin:0 0 14px}
#imp2 .prep b{display:block;font-weight:800}
#imp2 .prep span{font-size:.86rem;color:var(--muted);font-weight:600}
#imp2 .prep .btn{flex:none}
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
#imp2 .vault{border:1px solid var(--line);border-radius:12px;overflow:hidden;margin:4px 0 10px}
#imp2 .vault[hidden]{display:none}
#imp2 .vault iframe{display:block;width:100%;height:620px;border:0}
#imp2 .dateauto{margin:0 0 10px;font-size:.85rem;color:var(--muted)}
#imp2 .dateauto[hidden],#imp2 #i2DateBloc[hidden]{display:none}
#imp2 .safe{display:flex;gap:8px;align-items:flex-start;font-size:.8rem;color:var(--muted);font-weight:600}
#imp2 .safe svg{flex:none;color:var(--ok);margin-top:1px}
#imp2 .recap{display:grid;grid-template-columns:auto 1fr;gap:4px 14px;font-size:.88rem;margin:12px 0 0}
#imp2 .recap dt{color:var(--muted);font-weight:700}
#imp2 .recap dd{margin:0;font-weight:800}
#imp2 .pill.act{background:var(--act-soft);color:#7a5c00}
#imp2 .pill.run{background:#DDF6FA;color:#0b6b7d}

/* étape 3 : le tableau des imports */
#imp2 .panel.board{background:transparent;border:0;box-shadow:none;padding:0;min-height:0}
#imp2 .cartes{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}
#imp2 .carte{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:12px 12px 0;display:flex;flex-direction:column;min-height:300px;overflow:hidden}
#imp2 .carte.suivante{border-color:#7c6ad8;box-shadow:0 0 0 2px rgba(124,106,216,.22)}
#imp2 .carte .hd{display:flex;align-items:center;gap:8px}
#imp2 .carte .ico{width:28px;height:28px;border-radius:8px;display:grid;place-items:center;background:var(--soft2);color:var(--primary);flex:none}
#imp2 .carte .no{font-weight:800;font-size:.82rem;color:var(--muted)}
#imp2 .carte .oeil{margin-left:auto;background:none;border:0;padding:4px;color:var(--muted);cursor:pointer;border-radius:8px;display:grid}
#imp2 .carte .oeil:hover{background:var(--soft)}
#imp2 .carte .rond{width:22px;height:22px;border-radius:50%;border:2px solid var(--primary);display:grid;place-items:center;font-size:.72rem;font-weight:900;flex:none}
#imp2 .carte .rond.fait{background:var(--ok);border-color:var(--ok);color:#fff}
#imp2 .carte .rond.decider{background:#6d5bd0;border-color:#6d5bd0;color:#fff}
#imp2 .carte h3{font-size:1rem;margin:8px 0 1px}
#imp2 .carte .src{font-size:.76rem;color:var(--muted);font-weight:600}
#imp2 .carte ul{list-style:none;margin:8px 0 0;padding:0;display:flex;flex-direction:column;gap:3px}
#imp2 .carte li{display:flex;gap:6px;align-items:flex-start;font-size:.76rem;font-weight:600;line-height:1.3}
#imp2 .carte li::before{content:"";flex:none;width:12px;height:12px;border-radius:50%;margin-top:1px;border:1.5px solid var(--line2)}
#imp2 .carte li.ok::before{background:var(--ok) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 12 12'%3E%3Cpath d='M3 6.2l2 2 4-4.4' fill='none' stroke='%23fff' stroke-width='1.8' stroke-linecap='round'/%3E%3C/svg%3E") center/100% no-repeat;border-color:var(--ok)}
#imp2 .carte li.mid::before{background:#E9A800;border-color:#E9A800}
#imp2 .carte li.todo{color:var(--muted)}
#imp2 .carte .sp{flex:1;min-height:10px}
#imp2 .carte .puces{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:8px}
#imp2 .carte .puces span{font-size:.68rem;font-weight:800;padding:2px 7px;border-radius:7px;background:var(--soft);color:var(--muted)}
#imp2 .carte .puces .ok{background:var(--ok-soft);color:var(--ok)}
#imp2 .carte .puces .act{background:var(--act-soft);color:#7a5c00}
#imp2 .carte .puces .bad{background:var(--bad-soft);color:var(--bad)}
#imp2 .carte .puces .dec{background:#ECE8FB;color:#5340b8}
#imp2 .carte .pied{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:10px}
#imp2 .carte .compte b{font-size:1.25rem;font-weight:900}
#imp2 .carte .compte span{font-size:.76rem;color:var(--muted);font-weight:600;margin-left:4px}
#imp2 .carte .pied.haut{margin-bottom:8px;justify-content:flex-end}
#imp2 .carte .chiffres{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:6px;margin-bottom:10px}
#imp2 .carte .chiffres div{border:1px solid var(--line);border-radius:10px;padding:5px 8px;display:flex;flex-direction:column;min-width:0}
#imp2 .carte .chiffres b{font-size:1.15rem;font-weight:900;line-height:1.1}
#imp2 .carte .chiffres span{font-size:.68rem;color:var(--muted);font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#imp2 .carte .chiffres .ok b{color:var(--ok)}
#imp2 .carte .chiffres .dec{border-color:#c9bff3;background:#F4F1FD}
#imp2 .carte .chiffres .dec b{color:#5340b8}
#imp2 .carte .btn{padding:6px 11px;font-size:.8rem;border-radius:9px;background:var(--ok)}
#imp2 .carte .btn:hover{background:#17804a}
#imp2 .carte .btn.dec{background:#6d5bd0}
#imp2 .carte .btn.dec:hover{background:#5340b8}
#imp2 .carte .btn[disabled]{background:#9fd3b6}
#imp2 .carte .barre3{height:5px;margin:0 -12px;background:var(--soft)}
#imp2 .carte .barre3 i{display:block;height:100%;background:var(--primary);transition:width .5s}
#imp2 .carte.fait .barre3 i{background:var(--ok)}
#imp2 .carte.vide{opacity:.7}
#imp2 .t3date{margin:0 0 10px;font-size:.88rem;color:var(--muted)}
#imp2 .t3date b{color:var(--ink,#0E1F3D);font-weight:800}
#imp2 .t3note{display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap;margin-top:8px}
#imp2 .fen3{position:fixed;inset:0;background:rgba(14,31,61,.45);display:flex;align-items:center;justify-content:center;z-index:2000;padding:16px}
#imp2 .fen3 .boite{background:#fff;border-radius:18px;width:min(960px,100%);height:min(1000px,100%);display:flex;flex-direction:column;overflow:hidden;box-shadow:0 20px 60px rgba(14,31,61,.35);position:relative}
#imp2 .fen3 .barre{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:8px 10px;border-bottom:1px solid var(--line);cursor:move;user-select:none;touch-action:none}
#imp2 .fen3 .barre .poignee{font-size:12.5px;color:var(--ink-2,#44536E);display:flex;align-items:center;gap:6px}
#imp2 .fen3.glisse iframe{pointer-events:none}
#imp2 .fen3 iframe{flex:1;border:0;width:100%}
@media (max-width:1300px){#imp2 .cartes{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media (max-width:700px){#imp2 .cartes{grid-template-columns:minmax(0,1fr)}}

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
      <button class="btn ghost danger" type="button" id="i2Reinit" hidden></button>
      <button class="btn ghost" type="button" id="i2Vider"></button>
    </div>
  </header>

  <section class="stage">
    <div class="bridge">
      <div class="end"><div class="glyph" id="i2SrcG" style="background:#3a5a86"><span id="i2SrcGT">?</span><span class="live" id="i2Live"></span></div><div class="txt"><div class="lbl" id="i2LblOrigine"></div><div class="nm" id="i2SrcN"></div><div class="via" id="i2SrcVia"></div></div></div>
      <div class="flow"><canvas id="i2Flow" aria-hidden="true"></canvas><div class="chip" id="i2FlowChip"><span class="dot"></span><span id="i2FlowT"></span></div></div>
      <div class="end"><div class="ring"><svg viewBox="0 0 120 120"><circle class="trk" cx="60" cy="60" r="50"/><circle class="val" cx="60" cy="60" r="50" stroke-dasharray="314.16" stroke-dashoffset="314.16"/></svg><div class="pct">0/11</div></div><div class="txt"><div class="lbl" id="i2LblDest"></div><div class="nm">60secondes</div><div class="via" id="i2DestVia"></div></div></div>
      <div class="stats">
        <div><b>—</b><span id="i2StRes"></span></div>
        <div><b>0/11</b><span id="i2StImp"></span></div>
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
  var L = IMP2L, S = { sys: IMP2.logiciel || null, mode: IMP2.mode || 'direct', bascule: IMP2.bascule || '', freq: IMP2.freq || 'trimestre', relie: !!IMP2.relie, viaPrep: !!IMP2.viaPrep, prep: IMP2.prep || null, debutLivres: IMP2.debutLivres || '', dateProposee: IMP2.dateProposee || '', exercice: IMP2.exercice || '', exerciceProposee: IMP2.exerciceProposee || '' };
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
    qbo: { plan: 'Comptabilité ▸ Plan comptable ▸ Exécuter le rapport ▸ Exporter vers Excel', bal: "Rapports ▸ Balance de vérification ▸ période jusqu'à la date de début de la comptabilité ▸ Exporter vers Excel", clients: 'Ventes ▸ Clients ▸ icône Exporter vers Excel', fourn: 'Dépenses ▸ Fournisseurs ▸ icône Exporter vers Excel', prod: 'Ventes ▸ Produits et services ▸ icône Exporter vers Excel', fv: 'Rapports ▸ Liste des transactions (factures et factures fournisseurs) ▸ Exporter vers Excel' },
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
  function etapes(courante, sous) {
    var noms = [L.e1, how() === 'file' ? L.e2Fichiers : L.e2, L.e3, L.e4, L.e5, L.e6, L.e7];
    $('i2Etapes').innerHTML = noms.map(function (n, i) {
      var cls = i + 1 < courante ? 'done' : (i + 1 === courante ? 'run' : '');
      var s = sous && sous[i + 1] ? ' <small style="opacity:.75">' + esc(sous[i + 1]) + '</small>' : '';
      return '<li class="' + cls + '"><span class="b">' + (i + 1 < courante ? '✓' : (i + 1)) + '</span><span class="l">' + esc(n) + s + '</span></li>';
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
  function prendreEtat(e) { if (!e) return; S.sys = e.logiciel || null; S.mode = e.mode || 'direct'; S.bascule = e.bascule || ''; S.freq = e.freq || 'trimestre'; S.relie = !!e.relie; S.viaPrep = !!e.viaPrep; S.prep = e.prep || null; S.debutLivres = e.debutLivres || ''; S.dateProposee = e.dateProposee || ''; S.exercice = e.exercice || ''; S.exerciceProposee = e.exerciceProposee || ''; }

  /* ===== Données déjà en préparation : continuer sans relier la source ===== */
  function nomLogiciel(k) { for (var i = 0; i < SYS.length; i++) if (SYS[i].k === k) return SYS[i].n; return k || 'QuickBooks'; }
  function bandeauPrep(k) {
    var p = S.prep; if (!p || !p.nb) return '';
    if (k && p.logiciel && k !== p.logiciel) return '';   // étape 2 : seulement pour le logiciel extrait
    var n = nomLogiciel(p.logiciel);
    return '<div class="prep"><div><b>' + esc(L.prepTitre) + '</b><span>' + esc(f(L.prepTexte, { nb: p.nb.toLocaleString(), r: p.ressources, n: n, d: dateLisible(p.derniere) })) + '</span></div>' +
      '<button class="btn" type="button" id="i2Prep" data-lecture="1">' + esc(L.prepContinuer) + '</button></div>';
  }
  function brancherPrep() {
    var b = $('i2Prep'); if (!b) return;
    b.addEventListener('click', function () {
      var ex = $('i2Exercice'), fr = $('i2Freq'), donnees = {};
      if (ex && ex.value) { donnees.exercice = ex.value; donnees.freq = fr ? fr.value : S.freq; }
      b.disabled = true;
      poster('continuerPrep', donnees).then(function (j) {
        b.disabled = false;
        if (!j || !j.ok) return erreur(j && j.erreur);
        prendreEtat(j.etat); vueSuivante();
      }).catch(function () { b.disabled = false; erreur(); });
    });
  }
  function erreur(msg, etape) { dire('probleme', etape || L.erreur, msg || L.erreurTexte, L.erreur, 'bad'); }

  /* ===== Étape 1 : choisir le logiciel ===== */
  function vueChoix() {
    var tuiles = SYS.map(function (s) {
      return '<button class="tile" type="button" data-sys="' + s.k + '" data-lecture="1"><span class="glyph" style="background:' + s.col + '">' + esc(s.g) + '</span><span><b>' + esc(s.n) + '</b><span class="how">' + esc(s.line) + '</span><span class="badge ' + (s.live ? 'live' : 'file') + '">' + esc(s.live ? L.enDirect : L.parFichier) + '</span></span></button>';
    }).join('');
    TAB = null; $('i2Main').className = 'panel';
    $('i2Main').innerHTML = bandeauPrep(null) + '<h2>' + esc(L.question) + '</h2><p class="lead">' + esc(L.lead) + '</p><div class="tiles">' + tuiles + '</div><p class="note">' + esc(L.noteAutre) + '</p>';
    brancherPrep();
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
    var freq = '<div class="field"><label for="i2Freq">' + esc(L.taxes) + '</label><select id="i2Freq" data-lecture="1"><option value="trimestre">' + esc(L.trimestre) + '</option><option value="mois">' + esc(L.mois) + '</option><option value="annee">' + esc(L.annee) + '</option></select></div>';
    // La date de début de l'exercice : QuickBooks n'en a pas (seulement un mois) ;
    // demandée ici, mémorisée pour la compagnie (T411), proposée ensuite.
    var exo = '<div class="field"><label for="i2Exercice">' + esc(L.exercice) + '</label><input type="date" id="i2Exercice" value="' + esc(S.exercice || S.exerciceProposee || '') + '" required data-lecture="1" /><small>' + esc(L.exerciceAide) + '</small></div>';
    var alt = s.how !== 'file'
      ? '<button class="link" type="button" id="i2Alt" data-lecture="1">' + esc(h === 'file' ? L.preferDirect : L.preferFichiers) + '</button>' : '';
    var pas = '', boite = '', titre, lead, dit, expr = 'action';
    if (h === 'oauth') {
      pas = li(f(L.oa1, v), f(L.oa1d, v)) + li(L.oa2, f(L.oa2d, v)) + li(L.oa3, L.oa3d);
      boite = exo + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(f(L.seConnecter, v)) + '</button>' +
        '<div class="vault" id="i2Vault" hidden></div>' + sur(f(L.securiteOauth, v)) + alt;
      dit = f(L.ditOauth, v);
    } else if (h === 'agent') {
      pas = li(L.qb1, L.qb1d) + li(L.qb2, L.qb2d) + li(L.qb3, L.qb3d) + li(L.qb4, L.qb4d);
      boite = exo + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.preparerLiaison) + '</button>' + sur(L.securiteQbd) + alt;
      dit = L.ditQbd;
    } else if (h === 'apikey') {
      pas = li(L.od1, L.od1d) + li(L.od2, L.od2d) + li(L.od3, L.od3d);
      boite = '<div class="field"><label for="i2Url">' + esc(L.adresseOdoo) + '</label><input id="i2Url" placeholder="https://…" autocomplete="url" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2Db">' + esc(L.base) + '</label><input id="i2Db" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2User">' + esc(L.utilisateur) + '</label><input id="i2User" autocomplete="username" data-lecture="1" /></div>' +
        '<div class="field"><label for="i2Key">' + esc(L.cleApi) + '</label><input id="i2Key" type="password" autocomplete="off" data-lecture="1" /></div>' +
        exo + freq + '<button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.verifier) + '</button>' + sur(L.securiteOdoo) + alt;
      dit = L.ditOdoo;
    } else {
      pas = MODS.map(function (k) { return li(L['nom_' + k], consigneExport(s, k)); }).join('');
      boite = exo + '<div class="field"><label>' + esc(L.accepte) + '</label><small>' + esc(L.accepteAide) + '</small></div><button class="btn" type="button" id="i2Go" data-lecture="1">' + esc(L.passerFichiers) + '</button>' + sur(L.securiteFichiers) + alt;
      dit = ditChoix ? L.ditFichiersChoix : f(L.ditFichiers, v); expr = 'info';
    }
    titre = h === 'file' ? f(L.exportsTitre, v) : f(L.relierTitre, v);
    lead = h === 'file' ? L.exportsLead : L.relierLead;
    TAB = null; $('i2Main').className = 'panel';
    $('i2Main').innerHTML = bandeauPrep(s.k) + '<div class="conn"><div><h2>' + esc(titre) + '</h2><p class="lead">' + esc(lead) + '</p><ol>' + pas + '</ol></div><div class="box">' + boite + '</div></div>';
    brancherPrep();
    var fr = $('i2Freq'); if (fr) fr.value = S.freq;
    var exi = $('i2Exercice'); if (exi) exi.addEventListener('change', function (e) { S.exercice = S.bascule = e.target.value || ''; bilan(); });
    $('i2Go').addEventListener('click', aller);
    var a = $('i2Alt'); if (a) a.addEventListener('click', basculerMode);
    S.relie = false; origine(); etapes(2); flux(false); bilan();
    dire(expr, h === 'file' ? L.etape2Fichiers : L.etape2Connexion, dit, etapeN(2), '');
  }
  function reglages() {
    var fr = $('i2Freq'); if (fr) S.freq = fr.value;
    // La date de début de l'exercice est obligatoire : QuickBooks n'en donne que le mois.
    var ex = $('i2Exercice'); S.exercice = ex ? (ex.value || '') : S.exercice;
    S.bascule = S.exercice; bilan();
    if (!S.exercice) { dire('action', L.exercice, L.exerciceAide, L.aCompleter, 'act'); if (ex) ex.focus(); return null; }
    return { freq: S.freq, exercice: S.exercice };
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
    // Chaque import repart d'une comptabilité vide (T412) : on le dit et on
    // demande l'accord AVANT d'aller chez la source. Sans accord, rien ne part.
    if (!S.reinitOk) {
      var nomC = IMP2.compagnie || '';
      if (window.appConfirm) appConfirm(f(L.importEfface, { 0: nomC, n: v.n }), { titre: L.importEffaceTitre, ok: L.importEffaceOk, danger: true })
        .then(function (oui) { if (oui) { S.reinitOk = true; aller(); } });
      return;
    }
    // OAuth : plus de fenêtre à part. La page de connexion s'ouvre DANS la boîte
    // « Relier », sous le bouton ; quand la liaison est faite, on passe à la suite.
    occupe(true);
    dire('travail', L.etape2Connexion, L.enregistrement, L.connexion, 'run');
    poster('connexion', r).then(function (j) {
      if (!j || !j.ok || (!j.url && !j.direct)) { occupe(false); return erreur(j && j.erreur, L.etape2Connexion); }
      if (j.url && !j.direct) {
        var zone = $('i2Vault');
        if (zone) { zone.innerHTML = '<iframe src="' + esc(j.url) + '" title="' + esc(f(L.seConnecter, v)) + '"></iframe>'; zone.hidden = false; }
      }
      dire('travail', L.etape2Connexion, f(L.attenteAutorisation, v), L.connexion, 'run');
      flux(true); sonder(Date.now());
    }).catch(function () { occupe(false); erreur(); });
  }
  /* La source reliée : on lit ses données (fil de fond), puis le tableau. */
  function extraire() {
    var s = sysObj() || {}, titre = f(L.extraction, { n: s.n || '' });
    var zone = $('i2Vault'); if (zone) { zone.innerHTML = ''; zone.hidden = true; }
    occupe(true); flux(true);
    dire('travail', titre, L.enregistrement, L.connexion, 'run');
    poster('extraire', { reinit: S.reinitOk ? '1' : '' }).then(function (j) {
      S.reinitOk = false;
      if (!j || !j.ok || !j.run) { occupe(false); flux(false); return erreur(j && j.erreur, titre); }
      suivreExtraction(j.run, titre);
    }).catch(function () { occupe(false); flux(false); erreur(); });
  }
  function suivreExtraction(run, titre) {
    fetch('ApideckEtat.ashx?run=' + encodeURIComponent(run), { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (e) {
        if (!e || e.erreur) { occupe(false); flux(false); return erreur(e && e.erreur, titre); }
        if (e.statut === 'EN_COURS') {
          dire('travail', titre, f(L.extractionProgres, { 0: e.lues, 1: e.demandees, 2: e.progression || '' }), L.connexion, 'run');
          return setTimeout(function () { suivreExtraction(run, titre); }, 2000);
        }
        occupe(false); flux(false);
        vueSuivante();
        dire(e.echecs > 0 ? 'info' : 'regle', titre, f(L.extractionFin, { 0: (e.total || 0).toLocaleString(), 1: e.echecs || 0 }) + (e.note ? ' ' + e.note : ''), L.t3Fait, e.echecs > 0 ? '' : 'ok');
      })
      .catch(function () { setTimeout(function () { suivreExtraction(run, titre); }, 3000); });
  }
  function sonder(debut) {
    if (Date.now() - debut > 300000) { occupe(false); flux(false); return dire('pause', L.etape2Connexion, L.pasRecu, L.enAttente, ''); }
    poster('etatConnexion').then(function (j) {
      if (j && j.ok && j.statut === 'connecte') { prendreEtat(j.etat); return extraire(); }
      if (j && !j.ok) { occupe(false); flux(false); return erreur(j.erreur, L.etape2Connexion); }
      setTimeout(function () { sonder(debut); }, 2000);
    }).catch(function () { setTimeout(function () { sonder(debut); }, 2000); });
  }

  /* ===== Étape 3 : le tableau des imports, une fois la source reliée ===== */
  var ICO = {
    plan: '<path d="M4 5h16M4 12h16M4 19h10"/><circle cx="18" cy="19" r="2"/>',
    lien: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    balance: '<path d="M12 3v18M5 7h14M5 7l-3 7a3 3 0 0 0 6 0zM19 7l-3 7a3 3 0 0 0 6 0z"/>',
    clients: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    fournisseurs: '<path d="M3 7h11v9H3zM14 10h4l3 3v3h-7z"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/>',
    produits: '<path d="M12 3 3 8l9 5 9-5zM3 8v8l9 5 9-5V8"/>',
    factures: '<path d="M6 3h9l4 4v14H6z"/><path d="M9 11h7M9 15h7"/>',
    taxes: '<path d="M19 5 5 19"/><circle cx="7" cy="7" r="2.5"/><circle cx="17" cy="17" r="2.5"/>',
    reglements: '<path d="M7 7h13l-3-3M17 17H4l3 3"/>',
    rapprochement: '<path d="M3 10h18M5 10v8M9 10v8M15 10v8M19 10v8M3 21h18M12 3l9 5H3z"/>',
    comptesbanque: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>',
    rapportstaxes: '<path d="M6 3h9l4 4v14H6z"/><path d="M9 17l6-6"/><circle cx="9.5" cy="11.5" r="1"/><circle cx="14.5" cy="16.5" r="1"/>',
    paie: '<circle cx="12" cy="12" r="9"/><path d="M15 9.5c-.5-1-1.6-1.5-3-1.5-1.7 0-3 .8-3 2s1.3 1.7 3 2 3 .8 3 2-1.3 2-3 2c-1.4 0-2.5-.5-3-1.5M12 6v2M12 16v2"/>',
    tiers: '<path d="M4 21V5l8-3v19M12 9h8v12M7 8h2M7 12h2M7 16h2M2 21h20"/><circle cx="17" cy="13" r="2"/><path d="M14 19a3 3 0 0 1 6 0"/>',
    societe: '<path d="M4 21V5l8-3v19M12 9h8v12M7 8h2M7 12h2M7 16h2M15 13h2M15 17h2M2 21h20"/>'
  };
  var OEIL = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>';
  var GROUPES = { 3: ['tiers'], 4: ['plan'], 5: ['produits', 'factures'], 6: ['balance', 'comptesbanque', 'reglements', 'rapprochement', 'taxes', 'rapportstaxes', 'paie'] };
  var TAB = null;

  function vueSuivante() {
    var s = sysObj(); if (!s) return vueChoix();
    S.relie = true; origine(); flux(false); bilan();
    $('i2Main').className = 'panel board';
    if (!TAB) { etapes(3); dire('travail', etapeN(3), L.t3Charge, '', 'run'); }
    poster('tableau').then(function (j) {
      if (!j || !j.ok) return erreur(j && j.erreur, etapeN(3));
      TAB = j.tableau; rendreTableau();
    }).catch(function () { erreur(null, etapeN(3)); });
  }

  function carteHtml(c, suivante) {
    var rond = c.etat === 'fait' ? '<span class="rond fait">✓</span>' : (c.etat === 'decider' ? '<span class="rond decider">?</span>' : '<span class="rond"></span>');
    var b = c.bouton || {}, pct = Math.max(0, Math.min(100, c.pct || 0));
    var bouton = (c.etat === 'vide' || b.cache) ? '' :
      '<button class="btn' + (b.op === 'fenetre' ? ' dec' : '') + '" type="button" data-k="' + esc(c.k) + '"' + (b.actif ? '' : ' disabled') + (b.info ? ' title="' + esc(b.info) + '"' : '') + ' data-lecture="1">' + esc(b.t) + '</button>';
    return '<article class="carte ' + esc(c.etat) + (suivante ? ' suivante' : '') + '">' +
      '<div class="hd"><span class="ico"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + (ICO[c.ico] || '') + '</svg></span>' +
      '<span class="no">' + c.no + '.</span><button class="oeil" type="button" data-voir="' + esc(c.voir) + '" title="' + esc(L.t3Voir) + '" aria-label="' + esc(L.t3Voir) + '">' + OEIL + '</button>' + rond + '</div>' +
      '<h3>' + esc(c.titre) + '</h3><div class="src">' + esc(c.src) + '</div>' +
      '<ul>' + (c.liste || []).map(function (p) { return '<li class="' + esc(p.e) + '">' + esc(p.t) + '</li>'; }).join('') + '</ul>' +
      '<div class="sp"></div>' +
      '<div class="puces">' + (c.etat === 'vide' ? '<span>' + esc(L.t3Vide) + '</span>' : (c.puces || []).map(function (p) { return '<span class="' + esc(p.c) + '">' + esc(p.t) + '</span>'; }).join('')) + '</div>' +
      (c.chiffres && c.etat !== 'vide'
        ? (bouton ? '<div class="pied haut">' + bouton + '</div>' : '') +
          '<div class="chiffres">' + c.chiffres.map(function (x) { return '<div class="' + esc(x.c) + '"><b>' + (x.n || 0).toLocaleString() + '</b><span>' + esc(x.t) + '</span></div>'; }).join('') + '</div>'
        : '<div class="pied"><div class="compte"><b>' + (c.n || 0).toLocaleString() + '</b><span>' + esc(c.unite) + esc(c.extra || '') + '</span></div>' + bouton + '</div>') +
      '<div class="barre3"><i style="width:' + pct + '%"></i></div></article>';
  }

  function rendreTableau() {
    var t = TAB, cartes = t.cartes || [], parK = {};
    cartes.forEach(function (c) { parK[c.k] = c; });
    var faites = cartes.filter(function (c) { return c.etat === 'fait'; }).length;
    var suivante = null;
    for (var i = 0; i < cartes.length; i++) if (cartes[i].etat !== 'fait' && cartes[i].etat !== 'vide') { suivante = cartes[i]; break; }

    // La date de début de la comptabilité retenue — lue dans la source, ou choisie à la main.
    var dateDebut = t.bascule
      ? '<div class="t3date">' + esc(L.exercice) + ' : <b>' + esc(t.bascule) + '</b></div>'
      : '';
    $('i2Main').innerHTML = dateDebut + '<div class="cartes">' + cartes.map(function (c) { return carteHtml(c, c === suivante); }).join('') + '</div>' +
      '<div class="t3note"><p class="note" style="margin:0">' + esc(L.t3Ordre) + ' <button class="link" type="button" id="i2Retour" data-lecture="1">' + esc(L.modifierReglages) + '</button></p>' +
      '<button class="btn ghost" type="button" id="i2Recharger">' + esc(L.t3Recharger) + '</button></div>';
    Array.prototype.forEach.call($('i2Main').querySelectorAll('.carte .btn[data-k]'), function (b) { b.addEventListener('click', function () { agir(parK[b.getAttribute('data-k')], b); }); });
    Array.prototype.forEach.call($('i2Main').querySelectorAll('[data-voir]'), function (b) { b.addEventListener('click', function () { ouvrirPage(b.getAttribute('data-voir')); }); });
    $('i2Recharger').addEventListener('click', vueSuivante);
    $('i2Retour').addEventListener('click', function () {
      poster('retour').then(function (j) { if (j && j.ok) { TAB = null; $('i2Main').className = 'panel'; prendreEtat(j.etat); vueConnexion(); } else erreur(j && j.erreur); }).catch(function () { erreur(); });
    });

    /* fil des étapes : chaque groupe avec son compte de cartes faites */
    var sous = {}, courante = 7;
    for (var n = 3; n <= 6; n++) {
      var g = GROUPES[n].map(function (k) { return parK[k]; }).filter(Boolean);
      var ok = g.filter(function (c) { return c.etat === 'fait'; }).length;
      sous[n] = ok + '/' + g.length;
      if (ok < g.length && courante === 7) courante = n;
    }
    etapes(courante, sous);

    /* bande marine */
    var ring = document.querySelector('#imp2 .ring .val');
    if (ring) ring.setAttribute('stroke-dashoffset', String(314.16 * (1 - faites / Math.max(1, cartes.length))));
    var pctEl = document.querySelector('#imp2 .ring .pct'); if (pctEl) pctEl.textContent = faites + '/' + cartes.length;
    $('i2StRes').previousElementSibling.textContent = t.ressources ? String(t.ressources) : '—';
    $('i2StImp').previousElementSibling.textContent = faites + '/' + cartes.length;
    $('i2StEnr').previousElementSibling.textContent = (t.enregistrements || 0).toLocaleString();
    $('i2StSaisie').previousElementSibling.textContent = ((t.enregistrements || 0) * 45 / 3600).toLocaleString(L.lang === 'en' ? 'en-CA' : 'fr-CA', { maximumFractionDigits: 1 }) + ' h';
    puce(L.t3Lecture, '#4ADE80');
    $('i2Demo').hidden = true;   // l'étape 3 lit les vraies données en préparation

    /* 60 parle : la prochaine carte */
    if (!suivante) dire('regle', etapeN(7), L.t3ToutFait, L.t3Fait, 'ok');
    else dire(suivante.etat === 'decider' ? 'action' : 'info', suivante.no + '. ' + suivante.titre, suivante.dit || L.t3Ordre,
      (suivante.puces && suivante.puces[0]) ? suivante.puces[0].t : '', suivante.etat === 'decider' ? 'act' : '');

    /* bilan du bas */
    $('i2FinTitre').textContent = t.aDecider > 0 ? f(L.t3EnCours, { 0: t.aDecider }) : L.t3EnCoursSans;
    var fa = document.querySelectorAll('#imp2 .fact b');
    fa[0].textContent = t.comptesTotal ? t.comptesDecides + '/' + t.comptesTotal : '—';
    fa[1].textContent = t.fichesCreees ? String(t.fichesCreees) : '—';
    fa[2].textContent = t.facturesBrouillon ? String(t.facturesBrouillon) : '—';
    fa[3].textContent = t.balanceTotal ? (t.balanceEquilibree ? f(L.t3Equilibree, { 0: t.balanceTotal }) : L.t3Desequilibree) : '—';
  }

  function agir(c, bouton) {
    if (!c || !c.bouton) return;
    var b = c.bouton;
    if (b.op === 'page') return ouvrirPage(b.url);
    if (b.op === 'fenetre') return ouvrirFenetre(b.url);
    if (b.op !== 'creerFiches' && b.op !== 'creerTiers' && b.op !== 'creerFactures' && b.op !== 'creerOuverture') return;
    bouton.disabled = true;
    dire('travail', c.no + '. ' + c.titre, L.t3Travail, '', 'run'); flux(true);
    poster(b.op, b.type ? { type: b.type } : {}).then(function (j) {
      flux(false);
      if (!j || !j.ok) { bouton.disabled = false; return erreur(j && j.erreur, c.no + '. ' + c.titre); }
      TAB = j.tableau; rendreTableau();
      dire('regle', c.no + '. ' + c.titre, j.message, L.t3Fait, 'ok');
    }).catch(function () { flux(false); bouton.disabled = false; erreur(); });
  }

  /* Les écrans détaillés s'ouvrent dans un onglet ; au retour, le tableau se relit. */
  function ouvrirPage(url) { if (url) window.open(url, '_blank'); }
  window.addEventListener('focus', function () { if (TAB && !document.querySelector('#imp2 .fen3')) vueSuivante(); });

  /* « Décider un par un » : AssocierCompte.aspx?popup=1 dans une fenêtre par-dessus.
     La page appelle window.parent.fermerFenetre() et pose window.parent.fenModifie. */
  function ouvrirFenetre(url) {
    var v = document.createElement('div');
    v.className = 'fen3';
    v.innerHTML = '<div class="boite" role="dialog" aria-modal="true"><div class="barre"><span class="poignee" aria-hidden="true">⠿ ' + esc(L.t3Deplacer) + '</span><button class="btn ghost" type="button">' + esc(L.t3Fermer) + '</button></div><iframe src="' + esc(url) + '" title="' + esc(url) + '"></iframe></div>';
    v.addEventListener('click', function (e) { if (e.target === v && !v.dataset.glisse) window.fermerFenetre(); });
    v.querySelector('.barre button').addEventListener('click', function () { window.fermerFenetre(); });
    // La fenêtre se déplace en la tenant par sa barre ; l'iframe ne capte pas
    // la souris pendant le glissement (.glisse), et la fenêtre reste à l'écran.
    (function () {
      var boite = v.querySelector('.boite'), barre = v.querySelector('.barre');
      var dx = 0, dy = 0, x0 = 0, y0 = 0, actif = false;
      barre.addEventListener('pointerdown', function (e) {
        if (e.button !== 0 || e.target.closest('button')) return;
        actif = true; x0 = e.clientX - dx; y0 = e.clientY - dy;
        v.classList.add('glisse'); barre.setPointerCapture(e.pointerId); e.preventDefault();
      });
      barre.addEventListener('pointermove', function (e) {
        if (!actif) return;
        var r = boite.getBoundingClientRect(), nx = e.clientX - x0, ny = e.clientY - y0;
        var bx = r.left - dx, by = r.top - dy;  // position sans déplacement
        nx = Math.min(Math.max(nx, -bx - r.width + 80), window.innerWidth - bx - 80);
        ny = Math.min(Math.max(ny, -by), window.innerHeight - by - 40);
        dx = nx; dy = ny; boite.style.transform = 'translate(' + dx + 'px,' + dy + 'px)';
      });
      var fin = function (e) {
        if (!actif) return; actif = false; v.classList.remove('glisse');
        try { barre.releasePointerCapture(e.pointerId); } catch (x) { }
        v.dataset.glisse = '1'; setTimeout(function () { delete v.dataset.glisse; }, 0);
      };
      barre.addEventListener('pointerup', fin); barre.addEventListener('pointercancel', fin);
    })();
    $('imp2').appendChild(v);
    document.body.style.overflow = 'hidden';
  }
  window.fenModifie = false;
  window.fermerFenetre = function () {
    var v = document.querySelector('#imp2 .fen3'); if (v) v.parentNode.removeChild(v);
    document.body.style.overflow = '';
    window.fenModifie = false;
    vueSuivante();
  };
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && document.querySelector('#imp2 .fen3')) window.fermerFenetre(); });

  /* changer de logiciel / vider la préparation */
  function oublier(apres) {
    poster('vider').then(function (j) { if (!j || !j.ok) return erreur(j && j.erreur); S.bascule = ''; S.freq = 'trimestre'; S.relie = false; apres(); }).catch(function () { erreur(); });
  }
  $('i2Changer').addEventListener('click', function () { oublier(vueChoix); });

  /* OUTIL DE TEST : réinitialiser la compagnie (seulement si Web.config la liste) */
  (function () {
    var b = $('i2Reinit'); if (!IMP2.reinit) return;
    var nom = IMP2.compagnie || '';
    b.hidden = false; b.textContent = f(L.reinit, { 0: nom }); b.title = L.reinitTip;
    b.addEventListener('click', function () {
      var go = function () {
        b.disabled = true;
        dire('travail', f(L.reinit, { 0: nom }), L.t3Travail, '', 'run');
        poster('reinitialiser').then(function (j) {
          b.disabled = false;
          if (!j || !j.ok) return erreur(j && j.erreur, f(L.reinit, { 0: nom }));
          prendreEtat(j.etat);
          var detail = (j.lignes || []).map(function (l) { return l.quoi + ' : ' + l.nb; }).join('\n');
          if (sysObj() && S.relie) vueSuivante(); else if (sysObj()) vueConnexion(); else vueChoix();
          dire('regle', L.reinitOk, f(L.reinitTexte, { 0: nom }), L.reinitOk, 'ok');
          if (window.showAppMessage) showAppMessage(detail, L.reinitOk); else alert(detail);
        }).catch(function () { b.disabled = false; erreur(); });
      };
      if (window.appConfirm) appConfirm(f(L.reinitConfirme, { 0: nom }), { titre: f(L.reinit, { 0: nom }), ok: f(L.reinit, { 0: nom }), danger: true }).then(function (oui) { if (oui) go(); });
      else if (confirm(f(L.reinitConfirme, { 0: nom }))) go();
    });
  })();
  $('i2Vider').addEventListener('click', function () {
    var b = $('i2Vider');
    var go = function () {
      b.disabled = true;
      dire('travail', L.vider, L.t3Travail, '', 'run');
      poster('recommencer').then(function (j) {
        b.disabled = false;
        if (!j || !j.ok) return erreur(j && j.erreur, L.vider);
        prendreEtat(j.etat);
        S.bascule = ''; S.freq = 'trimestre'; S.relie = false;
        vueChoix();
        var detail = (j.lignes || []).map(function (l) { return l.quoi + ' : ' + l.nb; }).join('\n');
        if (detail) { if (window.showAppMessage) showAppMessage(detail, L.viderOk); else alert(detail); }
      }).catch(function () { b.disabled = false; erreur(); });
    };
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
