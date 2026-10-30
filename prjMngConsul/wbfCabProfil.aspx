<%@ Page Title="Profil du cabinet" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabProfil.aspx.vb" Inherits="MngConsul.wbfCabProfil" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Portail comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
#cp{--encre:#0E1F3D;--encre2:#44536E;--encre3:#6A7891;--fond:#F2F5F9;--carte:#FFFFFF;--filet:#E3E9F1;--bord:#D5DDE8;--champ:#F7F9FC;--pastille:#E8EDF5;--choisi:#E3EBF7;--choisi-bord:#1B4F9C;--marine:#1B4F9C;--marine-fonce:#143A73;--nuit:#0E1F3D;--or:#D9A03C;--rouge:#B3261E;--vert:#1E7B45;max-width:1080px;color:var(--encre)}
#cp *{box-sizing:border-box}
#cp h1{font-size:28px;font-weight:800;margin:0}
#cp .chapeau{color:var(--encre2);font-size:16px;margin:6px 0 18px}
#cp .bandeau{background:var(--nuit);color:#fff;border-radius:22px;padding:18px 20px;display:flex;align-items:center;gap:18px;margin-bottom:16px}
#cp .monogramme{width:64px;height:64px;border-radius:16px;background:#fff;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:22px;flex:none}
#cp .bandeau h2{margin:0;font-size:22px;font-weight:800;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
#cp .bandeau .badge{background:rgba(255,255,255,.14);color:#fff;font-size:13px;border-radius:999px;padding:4px 12px;font-weight:700}
#cp .bandeau p{margin:4px 0 0;color:#C9D3E3;font-size:14px}
#cp .onglets{display:inline-flex;flex-wrap:wrap;gap:2px;background:var(--pastille);border-radius:14px;padding:4px;margin-bottom:16px}
#cp .onglets button{border:0;background:transparent;height:38px;padding:0 14px;border-radius:11px;font-weight:800;font-size:15px;color:var(--encre2);cursor:pointer}
#cp .onglets button[aria-selected=true]{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}
#cp .carte{background:var(--carte);border:1px solid var(--filet);border-radius:18px;padding:18px 20px}
#cp .carte h3{margin:0 0 12px;font-size:18px;font-weight:800;display:flex;align-items:baseline;gap:8px;flex-wrap:wrap}
#cp .carte h3 small{font-size:13px;font-weight:600;color:var(--encre3)}
#cp .carte h3 .compte{margin-left:auto;font-size:14px;color:var(--marine);font-weight:800}
#cp .panneau[hidden]{display:none}
#cp .grille{display:grid;grid-template-columns:repeat(3,1fr);gap:12px 16px}
#cp .c2{grid-column:span 2}#cp .c3{grid-column:1/-1}
#cp .champ label{display:block;font-size:12px;font-weight:800;letter-spacing:.06em;text-transform:uppercase;color:var(--encre3);margin-bottom:6px}
#cp .champ input,#cp .champ textarea{width:100%;background:var(--champ);border:1px solid var(--bord);border-radius:10px;height:42px;padding:0 12px;font-size:15px;color:var(--encre)}
#cp .champ textarea{height:auto;min-height:84px;padding:10px 12px;resize:vertical}
#cp .champ input:focus,#cp .champ textarea:focus{outline:2px solid var(--marine);outline-offset:1px;background:#fff}
#cp .duo{display:grid;grid-template-columns:1fr 1fr;gap:16px}
#cp .pile{display:flex;flex-direction:column;gap:16px}
#cp .choix{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
#cp .opt{display:flex;align-items:center;gap:12px;border:2px solid var(--bord);background:#fff;border-radius:14px;padding:10px 12px;cursor:pointer;min-height:56px;position:relative}
#cp .opt input{position:absolute;opacity:0;pointer-events:none}
#cp .opt .ic{width:34px;height:34px;border-radius:10px;background:var(--fond);color:var(--encre3);display:grid;place-items:center;flex:none;font-weight:800;font-size:13px}
#cp .opt .ic svg{width:18px;height:18px}
#cp .opt .tx{flex:1;min-width:0}#cp .opt .tx b{display:block;font-size:15px}#cp .opt .tx small{color:var(--encre3);font-size:12.5px}
#cp .opt .case{width:22px;height:22px;border-radius:6px;border:2px solid var(--bord);background:#fff;display:grid;place-items:center;flex:none}
#cp .opt:has(input:checked){border-color:var(--choisi-bord);background:var(--choisi)}
#cp .opt:has(input:checked) .ic{background:var(--marine);color:#fff}
#cp .opt:has(input:checked) .case{background:var(--marine);border-color:var(--marine)}
#cp .opt:has(input:checked) .case::after{content:"";width:10px;height:6px;border-left:2.5px solid #fff;border-bottom:2.5px solid #fff;transform:rotate(-45deg) translate(1px,-1px)}
#cp .bascule{display:flex;gap:14px;align-items:flex-start;border:2px solid var(--bord);border-radius:18px;padding:16px;background:#fff;cursor:pointer}
#cp .bascule:has(input:checked){border-color:var(--choisi-bord);background:#F3F7FD}
#cp .bascule .ic{width:40px;height:40px;border-radius:12px;background:var(--marine);color:#fff;display:grid;place-items:center;flex:none}
#cp .bascule .tx{flex:1}#cp .bascule .tx b{display:block;font-size:17px;font-weight:800}
#cp .bascule .tx p{margin:4px 0 8px;color:var(--encre2);font-size:14px;line-height:1.45}
#cp .etat{display:inline-block;background:var(--pastille);color:var(--marine-fonce);border-radius:999px;padding:2px 10px;font-size:12.5px;font-weight:800}
#cp .bascule:not(:has(input:checked)) .etat{color:var(--encre3)}
#cp .inter{position:relative;width:52px;height:30px;flex:none}
#cp .inter input{position:absolute;inset:0;opacity:0;margin:0;cursor:pointer}
#cp .inter i{position:absolute;inset:0;border-radius:999px;background:#C3CDDB;transition:.2s}
#cp .inter i::after{content:"";position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;background:#fff;transition:.2s}
#cp .inter input:checked + i{background:var(--marine)}
#cp .inter input:checked + i::after{left:25px}
#cp .apercu{background:var(--nuit);color:#fff;border-radius:16px;padding:14px 16px;margin-top:16px}
#cp .apercu small{display:block;color:var(--or);font-weight:800;letter-spacing:.08em;font-size:12px;margin-bottom:4px}
#cp .apercu p{margin:0;font-weight:700;line-height:1.45}
#cp .pastille{display:inline-grid;place-items:center;min-width:20px;height:20px;border-radius:999px;background:var(--rouge);color:#fff;font-size:12px;font-weight:800;margin-left:6px;padding:0 6px}
#cp .pastille:empty{display:none}
#cp .progres{height:8px;border-radius:999px;background:var(--pastille);overflow:hidden;margin:4px 0 14px}
#cp .progres i{display:block;height:100%;background:var(--or);border-radius:999px}
#cp .etapes,#cp .garanties,#cp .contacts{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:10px}
#cp .etapes li{display:flex;align-items:center;gap:14px;background:var(--champ);border-radius:12px;padding:10px 12px}
#cp .etapes .rond{width:28px;height:28px;border-radius:50%;border:2px solid var(--bord);display:grid;place-items:center;flex:none;background:#fff}
#cp .etapes li.fait .rond{background:var(--marine);border-color:var(--marine)}
#cp .etapes li.fait .rond::after{content:"";width:10px;height:6px;border-left:2.5px solid #fff;border-bottom:2.5px solid #fff;transform:rotate(-45deg) translate(1px,-1px)}
#cp .etapes .tx{flex:1}#cp .etapes b{display:block;font-size:16px}#cp .etapes small{color:var(--encre3)}
#cp .btn-petit{background:var(--marine);color:#fff;border:0;border-radius:8px;padding:7px 12px;font-weight:800;cursor:pointer}
#cp .ligne-inter{display:flex;align-items:flex-start;gap:14px;margin-bottom:14px;cursor:pointer}
#cp .ligne-inter b{display:block;font-size:16px}#cp .ligne-inter small{color:var(--encre2);font-size:14px}
#cp .garanties li{display:flex;gap:12px;align-items:flex-start}
#cp .garanties svg{width:18px;height:18px;color:var(--marine);flex:none;margin-top:3px}
#cp .garanties b{display:block;font-size:16px}#cp .garanties small{color:var(--encre2);font-size:14px}
#cp .intro{color:var(--encre2);margin:0 0 14px;line-height:1.45}
#cp .deux-etapes{display:grid;grid-template-columns:1fr 1fr;gap:10px}
#cp .etape-boite{display:flex;align-items:center;gap:12px;border:2px solid var(--bord);border-radius:14px;padding:12px;font:inherit;text-align:left;background:#fff;cursor:pointer;width:100%}
#cp .etape-boite.ici{border-color:var(--marine);background:#F3F7FD}
#cp .etape-boite .num{width:28px;height:28px;border-radius:50%;background:var(--pastille);display:grid;place-items:center;font-weight:800;color:var(--encre2);flex:none}
#cp .etape-boite.ici .num{background:var(--marine);color:#fff}
#cp .etape-boite>span:nth-child(2){flex:1}#cp .etape-boite b{display:block}#cp .etape-boite small{color:var(--encre3)}
#cp .offre-barre{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin:16px 0}
#cp .offre-barre .total{background:var(--nuit);color:#fff;border-radius:999px;padding:6px 14px;font-size:14px}
#cp .offre-barre .total b{font-size:16px}
#cp .offre-barre .aide{color:var(--encre2);font-size:13.5px;flex:1}
#cp .btn-ghost{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:7px 12px;font-weight:700;cursor:pointer}
#cp .blocs{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:start}
#cp .bloc h4{display:flex;align-items:center;gap:10px;margin:0 0 6px;font-size:17px;font-weight:800}
#cp .bloc h4 .ic{width:30px;height:30px;border-radius:9px;background:var(--nuit);color:#fff;display:grid;place-items:center}
#cp .bloc h4 .ic svg{width:16px;height:16px}
#cp .bloc h4 .compte{margin-left:auto;font-size:13px;color:var(--encre2)}
#cp .groupe{margin:12px 0 4px;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3)}
#cp .act{display:flex;align-items:center;gap:12px;padding:6px 0}
#cp .act .inter{width:44px;height:26px}#cp .act .inter i::after{width:20px;height:20px}#cp .act .inter input:checked + i::after{left:21px}
#cp .act span.nom{flex:1;font-size:14.5px;line-height:1.3}
#cp .tag{font-size:12px;font-weight:800;border-radius:999px;padding:3px 9px;white-space:nowrap;color:#fff}
#cp .tag.cc{background:#4F6B2C}#cp .tag.c{background:#C0632A}#cp .tag.h{background:#6A7891}
#cp .act:not(:has(input:checked)) .nom{color:var(--encre3)}
#cp .act:not(:has(input:checked)) .tag{opacity:.35}
#cp .plus{font-size:12.5px;color:var(--encre3);margin:2px 0 0 56px}
#cp .attr-tete{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-top:18px}
#cp .titre2{margin:0 6px 0 0;font-size:22px;font-weight:800}
#cp .puce{border-radius:999px;padding:6px 14px;font-size:14px;font-weight:800}#cp .puce b{font-size:19px;margin-right:4px}
#cp .puce.bleu{background:#DCE7F6;color:var(--marine-fonce)}#cp .puce.rouge{background:var(--rouge);color:#fff}#cp .puce.nuit{background:var(--nuit);color:#fff}
#cp .puce.rouge.zero{background:var(--pastille);color:var(--encre2)}
#cp .cibles{background:var(--nuit);border-radius:22px;padding:18px 20px;margin:14px 0 18px}
#cp .cibles>small{display:block;color:var(--or);font-weight:800;margin-bottom:10px}
#cp #cibles{display:flex;gap:10px;flex-wrap:wrap}
#cp .cible{display:flex;align-items:center;gap:10px;min-width:190px;text-align:left;border:2px solid #34466A;background:transparent;color:#fff;border-radius:14px;padding:10px 12px;cursor:pointer;font:inherit}
#cp .cible .av2{width:36px;height:36px;border-radius:50%;background:#F2D9A6;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:13px;flex:none}
#cp .cible b{display:block;font-size:16px}#cp .cible small{color:#C9D3E3;font-size:13px}
#cp .cible .jauge{display:block;height:5px;border-radius:999px;background:#34466A;margin-top:6px;overflow:hidden}
#cp .cible .jauge i{display:block;height:100%;background:var(--or)}
#cp .cible[aria-pressed=true]{background:#fff;color:var(--encre);border-color:var(--or)}
#cp .cible[aria-pressed=true] small{color:var(--encre2)}
#cp .domaine{display:flex;align-items:center;gap:10px;margin:18px 0 10px;flex-wrap:wrap}
#cp .domaine .ic{width:32px;height:32px;border-radius:9px;background:var(--nuit);color:#fff;display:grid;place-items:center}
#cp .domaine .ic svg{width:16px;height:16px}
#cp .domaine h4{margin:0;font-size:20px;font-weight:800}#cp .domaine small{color:var(--encre2);font-weight:700}
#cp .badge-r{background:var(--rouge);color:#fff;border-radius:999px;padding:2px 10px;font-size:13px;font-weight:800}
#cp .sujets{display:grid;grid-template-columns:1fr 1fr;gap:12px}
#cp .sujet{background:#fff;border:1px solid var(--filet);border-radius:18px;padding:14px 18px}
#cp .sujet.ouvert{grid-column:1/-1;border:2px solid var(--marine)}
#cp .sujet-tete{display:flex;align-items:flex-start;gap:10px;width:100%;background:none;border:0;padding:0;text-align:left;cursor:pointer;font:inherit;color:inherit}
#cp .sujet-tete .tx{flex:1}#cp .sujet-tete b{display:flex;align-items:center;gap:8px;font-size:17px}
#cp .sujet-tete .compte2{color:var(--encre2);font-size:14px;margin:4px 0 8px;display:block}
#cp .alerte-n{width:22px;height:22px;border-radius:50%;background:var(--rouge);color:#fff;font-size:12px;display:grid;place-items:center}
#cp .chips{display:flex;gap:8px;flex-wrap:wrap}
#cp .chip{display:inline-flex;align-items:center;gap:6px;background:var(--champ);border-radius:999px;padding:2px 10px 2px 2px;font-size:14px;font-weight:700}
#cp .chip i{width:22px;height:22px;border-radius:50%;color:#fff;font-style:normal;font-size:12px;font-weight:800;display:grid;place-items:center}
#cp .r-client{background:#1E6B3A}#cp .r-cab{background:#C0632A}#cp .r-cc{background:linear-gradient(90deg,#1E6B3A 50%,#C0632A 50%)}#cp .r-60{background:#111}
#cp .progres2{height:6px;border-radius:999px;background:var(--pastille);margin-top:12px;overflow:hidden}#cp .progres2 i{display:block;height:100%;background:var(--marine)}
#cp .chev{transition:.2s;color:var(--encre2)}#cp .ouvert .chev{transform:rotate(90deg)}
#cp .sujet-actions{display:flex;justify-content:flex-end;gap:8px;margin:14px 0 6px;flex-wrap:wrap}
#cp .btn-clair{background:#DCE7F6;color:var(--marine-fonce);border:0;border-radius:999px;padding:8px 14px;font-weight:800;cursor:pointer;font:inherit}
#cp .tab-act{width:100%;border-collapse:collapse;font-size:14.5px}
#cp .tab-act th{font-size:12.5px;color:var(--encre2);text-align:left;padding:8px 6px;border-bottom:1px solid var(--filet);font-weight:800}
#cp .tab-act th.r{text-align:center}
#cp .tab-act th span{color:#fff;border-radius:999px;padding:3px 10px;font-size:12px;white-space:nowrap}
#cp .tab-act td{padding:10px 6px;border-bottom:1px solid var(--filet);vertical-align:middle}
#cp .tab-act td.r{text-align:center;width:96px}
#cp .rb{width:30px;height:30px;border-radius:50%;border:2px dashed #C3CDDB;background:#fff;cursor:pointer;display:inline-grid;place-items:center}
#cp .rb[aria-pressed=true]{border:0}
#cp .rb[aria-pressed=true]::after{content:"";width:10px;height:6px;border-left:2.5px solid #fff;border-bottom:2.5px solid #fff;transform:rotate(-45deg) translate(1px,-1px)}
#cp .rb[aria-pressed=true].r-client{background:#1E6B3A}#cp .rb[aria-pressed=true].r-cab{background:#C0632A}#cp .rb[aria-pressed=true].r-cc{background:linear-gradient(90deg,#1E6B3A 50%,#C0632A 50%)}#cp .rb[aria-pressed=true].r-60{background:#111}
#cp .attrib{border:0;border-radius:999px;padding:6px 12px;font:inherit;font-size:13px;font-weight:800;cursor:pointer;white-space:nowrap}
#cp .attrib.vide{background:#FDECEC;color:var(--rouge)}#cp .attrib.equipe{background:var(--nuit);color:#fff}#cp .attrib.perso{background:#F2D9A6;color:var(--nuit)}
#cp .hors{color:var(--encre3);font-size:13px;font-weight:700}
#cp .equipes{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
#cp .equipe{display:flex;flex-direction:column;gap:12px;border:1px solid var(--bord);background:#fff;border-radius:16px;padding:16px}
#cp .eq-tete{display:flex;align-items:center;gap:12px}
#cp .eq-tete>span:nth-child(2){flex:1}#cp .eq-tete b{display:block;font-size:17px}#cp .eq-tete small{color:var(--encre3)}
#cp .mono-or{width:40px;height:40px;border-radius:12px;background:var(--nuit);color:var(--or);display:grid;place-items:center;font-weight:800;flex:none}
#cp .avatars{display:flex;align-items:center}
#cp .avatars i{width:30px;height:30px;border-radius:50%;background:#F2D9A6;color:var(--nuit);font-style:normal;font-size:11px;font-weight:800;display:grid;place-items:center;border:2px solid #fff;margin-left:-6px}
#cp .avatars i:first-child{margin-left:0}
#cp .avatars span{margin-left:10px;font-weight:800;font-size:14px;color:var(--encre2)}
#cp .alerte{display:flex;align-items:center;gap:8px;background:#FDECEC;color:var(--rouge);border-radius:10px;padding:8px 12px;font-weight:800;font-size:14px}
#cp .alerte svg{width:16px;height:16px;flex:none}
#cp .contacts li{display:flex;align-items:center;gap:14px;background:var(--champ);border-radius:12px;padding:10px 12px}
#cp .contacts small{display:block;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3)}
#cp .contacts b{font-size:15px}
#cp .barre{display:flex;align-items:center;gap:14px;margin-top:18px}
#cp .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 22px;font-weight:800;cursor:pointer}
#cp .btn:hover{background:var(--marine-fonce)}
#cp .msg{font-weight:700;color:var(--vert);font-size:14px}
@media (max-width:1020px){#cp .blocs,#cp .sujets,#cp .deux-etapes,#cp .duo{grid-template-columns:1fr}#cp .tab-act-wrap{overflow-x:auto}#cp .tab-act{min-width:620px}}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="cp">
  <h1 data-l="titre"></h1>
  <p class="chapeau" data-l="chapeau"></p>

  <section class="bandeau">
    <div class="monogramme" id="mono"></div>
    <div><h2><span id="b-nom"></span> <span class="badge" id="b-badge"></span></h2><p id="resume"></p></div>
  </section>

  <div class="onglets" role="tablist">
    <button type="button" role="tab" aria-selected="true" data-p="p-ident" data-l="tIdent"></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-certif"><span data-l="tCertif"></span> <span class="pastille" id="n-certif"></span></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-secu"><span data-l="tSecu"></span> <span class="pastille" id="n-secu"></span></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-service" data-l="tService"></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-clients" data-l="tClients"></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-offre"><span data-l="tOffre"></span> <span class="pastille" id="n-offre"></span></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-orga" data-l="tOrga"></button>
    <button type="button" role="tab" aria-selected="false" data-p="p-contacts" data-l="tContacts"></button>
  </div>

  <section class="panneau" id="p-ident">
    <div class="carte"><h3 data-l="tIdent"></h3>
      <div class="grille">
        <div class="champ c2"><label data-l="lNom"></label><input id="f-nom"></div>
        <div class="champ"><label data-l="lResp"></label><input id="f-resp"></div>
        <div class="champ c3"><label data-l="lDesc"></label><textarea id="f-desc"></textarea></div>
        <div class="champ c2"><label data-l="lVille"></label><input id="f-ville"></div>
        <div class="champ"><label data-l="lProv"></label><input id="f-prov"></div>
        <div class="champ"><label data-l="lMail"></label><input id="f-mail" type="email"></div>
        <div class="champ"><label data-l="lTel"></label><input id="f-tel" type="tel" placeholder="450 000-0000"></div>
        <div class="champ"><label data-l="lSite"></label><input id="f-site" placeholder="votrecabinet.ca"></div>
      </div>
    </div>
  </section>

  <section class="panneau" id="p-certif" hidden>
    <div class="carte"><h3><span data-l="certifTitre"></span> <span class="compte" id="c-certif"></span></h3>
      <div class="progres"><i id="barre-certif"></i></div>
      <ul class="etapes" id="etapes"></ul>
    </div>
  </section>

  <section class="panneau" id="p-secu" hidden>
    <div class="carte"><h3 data-l="secuTitre"></h3>
      <label class="ligne-inter"><span class="inter"><input type="checkbox" id="f-mfa"><i></i></span>
        <span><b data-l="mfaT"></b><small data-l="mfaS"></small></span></label>
      <ul class="garanties" id="garanties"></ul>
    </div>
  </section>

  <section class="panneau" id="p-service" hidden>
    <div class="pile">
      <div class="carte"><h3><span data-l="specTitre"></span> <small data-l="specSous"></small><span class="compte" id="c-spec"></span></h3>
        <div class="choix trois" id="spec"></div></div>
      <div class="carte"><h3><span data-l="langTitre"></span> <small data-l="langSous"></small><span class="compte" id="c-lang"></span></h3>
        <div class="choix trois" id="lang"></div></div>
    </div>
  </section>

  <section class="panneau" id="p-clients" hidden>
    <div class="duo">
      <label class="bascule"><span class="ic"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="8" r="4"/><path d="M2 21c0-4 4-6 8-6M17 14v6M14 17h6"/></svg></span>
        <span class="tx"><b data-l="accepteT"></b><p data-l="accepteS"></p><span class="etat" id="etat-accepte"></span></span>
        <span class="inter"><input type="checkbox" id="f-accepte"><i></i></span></label>
      <label class="bascule"><span class="ic"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg></span>
        <span class="tx"><b data-l="publiqueT"></b><p data-l="publiqueS"></p><span class="etat" id="etat-publique"></span></span>
        <span class="inter"><input type="checkbox" id="f-publique"><i></i></span></label>
    </div>
    <div class="apercu" aria-live="polite"><small data-l="apercuTitre"></small><p id="apercu"></p></div>
  </section>

  <section class="panneau" id="p-offre" hidden>
    <div class="carte"><h3 data-l="offreTitre"></h3><p class="intro" data-l="offreIntro"></p>
      <div class="deux-etapes">
        <button type="button" class="etape-boite ici" data-etape="1"><span class="num">1</span><span><b data-l="etape1"></b><small id="offre-resume"></small></span></button>
        <button type="button" class="etape-boite" data-etape="2"><span class="num">2</span><span><b data-l="etape2"></b><small data-l="etape2S"></small></span><span class="pastille" id="n-qui"></span></button>
      </div>
    </div>
    <div id="etape1">
      <div class="offre-barre"><span class="total"><b id="offre-n"></b> <span data-l="offertesSur"></span> <b id="offre-t"></b></span>
        <span class="aide" data-l="offreAide"></span><button type="button" class="btn-ghost" id="tout-offrir" data-l="toutOffrir"></button></div>
      <div class="blocs" id="blocs"></div>
    </div>
    <div id="etape2" hidden>
      <div class="attr-tete"><h3 class="titre2" data-l="activitesAttribuer"></h3>
        <span class="puce bleu"><b id="q-couv"></b> <span data-l="couvertes"></span></span>
        <span class="puce rouge"><b id="q-non"></b> <span data-l="nonAttribuees"></span></span>
        <span class="puce nuit"><b id="q-equipe"></b> <span data-l="aEquipe"></span></span></div>
      <div class="cibles"><small data-l="attribuerA"></small><div id="cibles"></div></div>
      <div id="sujets"></div>
    </div>
  </section>

  <section class="panneau" id="p-orga" hidden>
    <div class="carte"><h3><span data-l="orgaTitre"></span> <small data-l="orgaSous"></small></h3>
      <div class="equipes" id="equipes"></div></div>
  </section>

  <section class="panneau" id="p-contacts" hidden>
    <div class="carte"><h3 data-l="contactsTitre"></h3><ul class="contacts" id="contacts"></ul></div>
  </section>

  <div class="barre"><button class="btn" type="button" id="f-save" data-l="enregistrer"></button><span class="msg" id="msg" role="status"></span></div>
</div>

<script>
(function () {
  var D = <asp:Literal ID="litData" runat="server" />;
  var L = <asp:Literal ID="litLabels" runat="server" />;
  var root = document.getElementById('cp');
  if (!root || !D) return;
  var $ = function (s) { return root.querySelector(s); }, $$ = function (s) { return [].slice.call(root.querySelectorAll(s)); };
  var membres = D.membres || [];

  // Libellés
  $$('[data-l]').forEach(function (e) { e.textContent = L[e.getAttribute('data-l')] || ''; });

  // Onglets
  $$('[role=tab]').forEach(function (t) {
    t.addEventListener('click', function () {
      $$('[role=tab]').forEach(function (x) {
        var on = x === t; x.setAttribute('aria-selected', on);
        $('#' + x.getAttribute('data-p')).hidden = !on;
      });
    });
  });

  // Champs Identification
  var P = D.profil || {};
  function setv(id, v) { var e = $(id); if (e) e.value = v || ''; }
  setv('#f-nom', P.nom); setv('#f-resp', P.resp); setv('#f-desc', P.desc); setv('#f-ville', P.ville);
  setv('#f-prov', P.prov); setv('#f-mail', P.mail); setv('#f-tel', P.tel); setv('#f-site', P.site);
  $('#f-accepte').checked = !!P.accepte; $('#f-publique').checked = !!P.publique; $('#f-mfa').checked = !!D.mfa;

  // Spécialités + langues
  var SPEC = [['ta', L.specTravailleurs], ['soc', L.specSocietes], ['paie', L.specPaie], ['constr', L.specConstr], ['sante', L.specSante]];
  var LANG = [['FR', L.langFr], ['EN', L.langEn], ['ES', L.langEs]];
  function opt(name, val, lab, ic, on) {
    return '<label class="opt"><input type="checkbox" name="' + name + '" value="' + val + '"' + (on ? ' checked' : '') + '>'
      + '<span class="ic">' + ic + '</span><span class="tx"><b>' + esc(lab) + '</b></span><span class="case"></span></label>';
  }
  var specOn = {}; (P.spec || []).forEach(function (s) { specOn[s] = 1; });
  var langOn = {}; (P.langues || []).forEach(function (s) { langOn[s] = 1; });
  $('#spec').innerHTML = SPEC.map(function (s) { return opt('spec', s[0], s[1], iconSpec(s[0]), specOn[s[0]]); }).join('');
  $('#lang').innerHTML = LANG.map(function (s) { return opt('lang', s[0], s[1], s[0], langOn[s[0]]); }).join('');

  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function initiales(n) { var m = String(n || '').replace(/\(.*?\)/g, '').trim().split(/\s+/); return (((m[0] || '')[0] || '') + ((m[1] || '')[0] || '')).toUpperCase() || '?'; }
  function liste(a) { return a.length < 2 ? a.join('') : a.slice(0, -1).join(', ') + ' ' + (L.langEs && 'et') + ' ' + a[a.length - 1]; }
  function iconSpec(k) {
    var m = {
      ta: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg>',
      soc: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 21V5l8-3 8 3v16M9 21v-4h6v4"/></svg>',
      paie: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="8" r="3"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5M16 11a3 3 0 1 0 0-6M21 20c0-2-1.5-4-4-4.5"/></svg>',
      constr: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18M5 21V11l7-5 7 5v10M10 21v-5h4v5"/></svg>',
      sante: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 21s-7-4.5-7-10a4 4 0 0 1 7-2.5A4 4 0 0 1 19 11c0 5.5-7 10-7 10z"/></svg>'
    };
    return m[k] || '';
  }

  // Résumé / aperçu / compteurs
  function maj() {
    var nom = $('#f-nom').value.trim() || L.titre;
    $('#b-nom').textContent = nom; $('#mono').textContent = initiales(nom);
    $('#resume').textContent = $('#f-ville').value + ' (' + $('#f-prov').value + ') · ' + L.resume + ' : ' + $('#f-resp').value;
    var spec = $$('#spec input:checked').map(function (i) { return i.value; });
    var lang = $$('#lang input:checked').map(function (i) { return i.value; });
    $('#c-spec').textContent = spec.length + ' / 5'; $('#c-lang').textContent = lang.length + ' / 3';
    $('#etat-accepte').textContent = $('#f-accepte').checked ? L.accepteOn : L.accepteOff;
    $('#etat-publique').textContent = $('#f-publique').checked ? L.publiqueOn : L.publiqueOff;
    var specNoms = spec.map(function (c) { return (SPEC.find(function (s) { return s[0] === c; }) || [, c])[1]; });
    var langNoms = lang.map(function (c) { return (LANG.find(function (s) { return s[0] === c; }) || [, c])[1]; });
    var t;
    if (!$('#f-publique').checked) t = nom + ' ' + L.pasAnnuaire;
    else {
      t = nom + ' ' + ($('#f-accepte').checked ? L.ouvertAux : L.fermeAux);
      if (specNoms.length) t += ' · ' + L.specialites + ' : ' + specNoms.join(' · ');
      if (langNoms.length) t += ' · ' + L.serviceEn + ' ' + langNoms.join(', ');
      t += ' · ' + $('#f-ville').value + '.';
    }
    $('#apercu').textContent = t;
  }

  // Certification
  var ETAPES = [
    { t: "Administrateur inscrit et validé", s: "Identité confirmée", fait: true },
    { t: "Permis d'exercice vérifié", s: "Auprès de l'Ordre des CPA", fait: true },
    { t: "Assurance responsabilité professionnelle", s: "Attestation en vigueur à téléverser", b: "Téléverser" },
    { t: "Formation 60secondes terminée", s: "Parcours guidé par 60, à votre rythme", b: "Commencer" },
    { t: "Convention de cabinet certifié signée", s: "Signature électronique", b: "Signer" }];
  var faits = {}; String(D.certif || '').split(',').forEach(function (i) { if (i !== '') faits[+i] = 1; });
  ETAPES.forEach(function (e, i) { e.fait = e.fait || !!faits[i]; });
  function certif() {
    $('#etapes').innerHTML = ETAPES.map(function (e, i) {
      return '<li class="' + (e.fait ? 'fait' : '') + '"><span class="rond"></span><span class="tx"><b>' + esc(e.t) + '</b><small>' + esc(e.s) + '</small></span>'
        + (e.fait ? '' : '<button type="button" class="btn-petit" data-i="' + i + '">' + esc(e.b) + '</button>') + '</li>';
    }).join('');
    var n = ETAPES.filter(function (e) { return e.fait; }).length;
    $('#c-certif').textContent = L.certifEtapes.replace('{n}', n).replace('{t}', ETAPES.length);
    $('#barre-certif').style.width = (n / ETAPES.length * 100) + '%';
    $('#n-certif').textContent = (ETAPES.length - n) || '';
    $('#b-badge').textContent = n === ETAPES.length ? L.certifFait : L.certifEnCours;
  }
  $('#etapes').addEventListener('click', function (e) { var b = e.target.closest('[data-i]'); if (b) { ETAPES[+b.dataset.i].fait = true; certif(); } });

  // Sécurité
  var GAR = [[L.garantie1T, L.garantie1S], [L.garantie2T, L.garantie2S], [L.garantie3T, L.garantie3S]];
  $('#garanties').innerHTML = GAR.map(function (g) {
    return '<li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg><span><b>' + esc(g[0]) + '</b><small>' + esc(g[1]) + '</small></span></li>';
  }).join('');
  function secu() { $('#n-secu').textContent = $('#f-mfa').checked ? '' : '1'; }

  // Organisation
  $('#equipes').innerHTML = '<div class="equipe"><span class="eq-tete"><span class="mono-or">' + esc(initiales(P.nom || L.titre))
    + '</span><span><b>' + esc(L.orgaTitre) + '</b><small>' + esc(L.responsable + ' : ' + (D.adminNom || '')) + '</small></span></span>'
    + '<span class="avatars">' + membres.map(function (m) { return '<i>' + esc(m.ini) + '</i>'; }).join('')
    + '<span>' + membres.length + ' ' + esc(L.membres) + '</span></span>'
    + '<span class="alerte"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M17 2l4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4M21 13v2a3 3 0 0 1-3 3H3"/></svg>'
    + membres.length + ' ' + esc(L.sansRemplacant) + '</span></div>';

  // Contacts
  var ci = D.adminIni || initiales(D.adminNom), cn = D.adminNom || '';
  function contactLi(sm, b) { return '<li><span class="mono-or">' + esc(ci) + '</span><span><small>' + esc(sm) + '</small><b>' + esc(b) + '</b></span></li>'; }
  $('#contacts').innerHTML = contactLi(L.contactAdmin, cn + ' · ' + L.contactAdminS)
    + contactLi(L.contactLoi25, cn + ' · ' + L.contactLoi25S)
    + contactLi(L.contact60, cn + ' · ' + L.contact60S);

  // ---- Offre de services ----
  var OFFRE = [{"t":"Mise en place et relation","g":[{"t":"DÉMARRAGE ET TRANSFERT","a":[["Transférer les données de l'ancien logiciel (QuickBooks, Sage, Acomba, Odoo…)","Cabinet et client"],["Vérifier les soldes d'ouverture après le transfert","Cabinet"],["Configurer l'entreprise selon son métier","Cabinet et client"],["Former le client aux fonctions qu'il utilisera","Cabinet"]],"x":0},{"t":"ÉCHANGES CLIENT ET CABINET","a":[["Échanger des messages rattachés à une action","Cabinet et client"],["Demander un document au client, avec relances","Cabinet"]],"x":2},{"t":"ACCÈS, DROITS ET ÉQUIPE DU CABINET","a":[["Convenir des droits du cabinet, action par action","Cabinet et client"],["Consulter le journal des actions","Cabinet et client"],["Voir l'écran du client en miroir","Cabinet"],["Confier le dossier à un employé du cabinet","Cabinet"],["Inviter d'autres clients sur 60secondes","Cabinet"]],"x":2}]},{"t":"Revenus","g":[{"t":"VENTES ET FACTURATION","a":[["Préparer une soumission","Cabinet et client"],["Émettre une note de crédit ou annuler une facture","Cabinet et client"],["Importer les ventes de Square, de la caisse ou de la boutique en ligne","Cabinet et client"],["Fixer les prix et les conditions de paiement","Cabinet et client"]],"x":1},{"t":"COMPTES CLIENTS ET ENCAISSEMENTS","a":[["Apparier les encaissements aux factures","Cabinet et client"],["Envoyer les relances de comptes clients","Cabinet et client"],["Suspendre ou reporter une relance","Cabinet et client"],["Décider de radier une mauvaise créance","Cabinet et client"]],"x":0}]},{"t":"Dépenses, paiements et banque","g":[{"t":"DÉPENSES ET FOURNISSEURS","a":[["Capter les reçus et factures (photo, courriel, papier)","Cabinet et client"],["Classer les dépenses et extraire les taxes","Cabinet et client"],["Répondre aux questions de 60 sur une transaction","Cabinet et client"],["Approuver une facture fournisseur à payer","Cabinet et client"]],"x":1},{"t":"PAIEMENTS","a":[["Préparer le lot de paiements fournisseurs","Cabinet et client"],["Déclencher un paiement fournisseur","Cabinet et client"]],"x":2},{"t":"BANQUE ET CONCILIATION","a":[["Importer et apparier les transactions bancaires","Cabinet et client"],["Régler un appariement incertain","Cabinet"],["Approuver la conciliation mensuelle","Cabinet"]],"x":1}]},{"t":"Paie et remises","g":[{"t":"PAIE ET EMPLOYÉS","a":[["Faire la paie des clients du cabinet qui ne sont pas sur 60secondes","Cabinet"]],"x":0},{"t":"TAXES DE VENTE ET REMISES","a":[["Approuver et produire la déclaration de taxes","Cabinet et client"],["S'inscrire aux taxes à l'approche du seuil","Cabinet et client"]],"x":2}]},{"t":"Fiscalité et conformité","g":[{"t":"IMPÔT DE L'ENTREPRISE ET DU PROPRIÉTAIRE","a":[["Préparer et transmettre la déclaration personnelle du travailleur autonome","Cabinet et client"],["Planifier l'impôt en cours d'année","Cabinet"]],"x":1},{"t":"OBLIGATIONS CORPORATIVES ET DE MÉTIER","a":[["Produire la déclaration annuelle au registre des entreprises","Cabinet et client"],["Gérer les obligations de la construction (CCQ, RBQ, CMEQ, attestation de Revenu Québec)","Cabinet et client"]],"x":1},{"t":"GOUVERNEMENT ET VÉRIFICATIONS","a":[["Recevoir et classer le courrier gouvernemental","Cabinet et client"],["Répondre à un avis de cotisation ou à une vérification","Cabinet et client"],["Signer les procurations et autorisations aux gouvernements","Cabinet et client"]],"x":0}]},{"t":"Clôture et conseil","g":[{"t":"LIVRES ET FIN D'EXERCICE","a":[["Classer les transactions dans le plan comptable","Cabinet et client"],["Ajuster le plan comptable","Cabinet"],["Passer les écritures de régularisation et d'amortissement","Cabinet"],["Fermer une période","Cabinet"],["Rouvrir une période fermée","Cabinet et client"],["Produire les états financiers","Cabinet"],["Exporter le dossier de fin d'exercice avec les pièces","Cabinet"]],"x":0},{"t":"TRÉSORERIE, CONSEIL ET CROISSANCE","a":[["Établir un budget et des prévisions","Cabinet"],["Préparer le dossier pour la banque ou une demande de financement","Cabinet et client"],["Évaluer l'incorporation d'un travailleur autonome","Cabinet"],["Préparer la vente ou la relève de l'entreprise","Cabinet"],["Proposer un mandat au client au bon moment","Cabinet"]],"x":2}]}];
  var ICB = ['<path d="M3 11l9-7 9 7v9H3z"/>', '<path d="M4 17l5-5 4 4 7-8M14 8h6v6"/>', '<rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/>', '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>', '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>', '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>'];
  var RESP = { client: { n: L.respClient, c: 'r-client' }, cab: { n: L.respCab, c: 'r-cab' }, cc: { n: L.respCc, c: 'r-cc' }, s60: { n: L.resp60, c: 'r-60' } };
  var MEMBRES = membres.map(function (m) { return { id: m.id, ini: m.ini, nom: m.nom }; });
  var ACTS = [];
  OFFRE.forEach(function (b, bi) { b.g.forEach(function (g, gi) { g.a.forEach(function (a) { ACTS.push({ id: 'a' + ACTS.length, b: bi, g: gi, nom: a[0], resp: a[1] === 'Cabinet' ? 'cab' : 'cc', offert: true, att: 'equipe' }); }); }); });
  // Appliquer l'état sauvegardé
  try { var sv = D.offre ? JSON.parse(D.offre) : null; if (sv) ACTS.forEach(function (a) { var s = sv[a.id]; if (s) { a.offert = !!s.o; a.resp = s.r || a.resp; a.att = (s.a === undefined ? a.att : s.a); } }); } catch (e) { }
  var auCabinet = function (a) { return a.resp === 'cab' || a.resp === 'cc'; };
  var cible = 'equipe', ouvert = null;

  $('#blocs').innerHTML = OFFRE.map(function (b, bi) {
    return '<div class="carte bloc"><h4><span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">' + ICB[bi] + '</svg></span>' + esc(b.t) + '<span class="compte" data-b="' + bi + '"></span></h4>'
      + b.g.map(function (g, gi) {
        return '<div class="groupe">' + esc(g.t) + '</div>' + ACTS.filter(function (a) { return a.b === bi && a.g === gi; }).map(function (a) {
          return '<label class="act"><span class="inter"><input type="checkbox"' + (a.offert ? ' checked' : '') + ' data-a="' + a.id + '"><i></i></span><span class="nom">' + esc(a.nom) + '</span><span class="tag ' + (a.resp === 'cab' ? 'c' : 'cc') + '" data-tag="' + a.id + '">' + esc(RESP[a.resp].n) + '</span></label>';
        }).join('') + (g.x ? '<div class="plus">+ ' + g.x + ' ' + (g.x > 1 ? 'activités hors cabinet' : 'activité hors cabinet') + '</div>' : '');
      }).join('') + '</div>';
  }).join('');
  $('#blocs').addEventListener('change', function (e) { var a = ACTS.find(function (x) { return x.id === e.target.dataset.a; }); if (a) { a.offert = e.target.checked; tout(); } });
  $('#tout-offrir').addEventListener('click', function () { ACTS.forEach(function (a) { a.offert = true; }); $$('#blocs input').forEach(function (i) { i.checked = true; }); tout(); });
  $$('[data-etape]').forEach(function (b) { b.addEventListener('click', function () { var deux = b.dataset.etape === '2'; $$('[data-etape]').forEach(function (x) { x.classList.toggle('ici', x === b); }); $('#etape1').hidden = deux; $('#etape2').hidden = !deux; tout(); }); });
  var nomCible = function (c) { return c === 'equipe' ? L.touteEquipe : ((MEMBRES.find(function (m) { return m.id === c; }) || {}).nom || ''); };

  function rendreEtape2() {
    var vis = ACTS.filter(function (a) { return a.offert; }), cab = vis.filter(auCabinet);
    $('#cibles').innerHTML = [{ id: 'equipe', ini: '', nom: L.touteEquipe }].concat(MEMBRES).map(function (m) {
      var n = m.id === 'equipe' ? null : cab.filter(function (a) { return a.att === m.id || a.att === 'equipe'; }).length;
      return '<button type="button" class="cible" data-cible="' + m.id + '" aria-pressed="' + (cible === m.id) + '">' + (m.ini ? '<span class="av2">' + esc(m.ini) + '</span>' : '')
        + '<span style="flex:1"><b>' + esc(m.id === 'equipe' ? L.touteEquipe : m.nom.split(' ')[0]) + '</b><small>' + (m.id === 'equipe' ? MEMBRES.length + ' ' + L.membres : n + ' / ' + cab.length)
        + '</small>' + (m.id === 'equipe' ? '' : '<span class="jauge"><i style="width:' + (cab.length ? n / cab.length * 100 : 0) + '%"></i></span>') + '</span></button>';
    }).join('');
    $('#sujets').innerHTML = OFFRE.map(function (b, bi) {
      var acts = vis.filter(function (a) { return a.b === bi; }); if (!acts.length) return '';
      var nonB = acts.filter(function (a) { return auCabinet(a) && !a.att; }).length;
      var gs = b.g.map(function (g, gi) { return { g: g, gi: gi, acts: acts.filter(function (a) { return a.g === gi; }) }; }).filter(function (x) { return x.acts.length; });
      return '<div class="domaine"><span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">' + ICB[bi] + '</svg></span><h4>' + esc(b.t) + '</h4><small>' + gs.length + ' · ' + acts.length + ' actions</small>' + (nonB ? '<span class="badge-r">' + nonB + ' ' + L.nonAttribuees + '</span>' : '') + '</div><div class="sujets">'
        + gs.map(function (o) {
          var g = o.g, gi = o.gi, gacts = o.acts, key = bi + '-' + gi, ouv = ouvert === key;
          var c = gacts.filter(auCabinet), att = c.filter(function (a) { return a.att; }), hors = gacts.length - c.length, non = c.length - att.length;
          var cnt = Object.keys(RESP).map(function (r) { return [r, gacts.filter(function (a) { return a.resp === r; }).length]; }).filter(function (x) { return x[1]; });
          var titre = g.t.charAt(0) + g.t.slice(1).toLowerCase();
          return '<div class="sujet ' + (ouv ? 'ouvert' : '') + '"><button type="button" class="sujet-tete" data-ouvrir="' + key + '"><span class="tx"><b>' + (non ? '<span class="alerte-n">' + non + '</span>' : '') + esc(titre) + '</b><span class="compte2">' + att.length + ' / ' + c.length + ' ' + L.attribuees + (hors ? ' · ' + hors + ' ' + L.horsCabinet.toLowerCase() : '') + '</span><span class="chips">' + cnt.map(function (p) { return '<span class="chip"><i class="' + RESP[p[0]].c + '">' + p[1] + '</i>' + esc(RESP[p[0]].n) + '</span>'; }).join('') + '</span></span><svg class="chev" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M9 6l6 6-6 6"/></svg></button><div class="progres2"><i style="width:' + (c.length ? att.length / c.length * 100 : 100) + '%"></i></div>'
            + (ouv ? '<div class="sujet-actions"><button type="button" class="btn-clair" data-tout="' + key + '">+ ' + esc(nomCible(cible)) + '</button><button type="button" class="btn-ghost" data-retirer="' + key + '">✕</button></div><div class="tab-act-wrap"><table class="tab-act"><thead><tr><th>Action</th>' + Object.keys(RESP).map(function (r) { return '<th class="r"><span class="' + RESP[r].c + '">' + esc(RESP[r].n) + '</span></th>'; }).join('') + '<th></th></tr></thead><tbody>'
              + gacts.map(function (a) { return '<tr><td>' + esc(a.nom) + '</td>' + Object.keys(RESP).map(function (r) { return '<td class="r"><button type="button" class="rb ' + (a.resp === r ? RESP[r].c : '') + '" aria-pressed="' + (a.resp === r) + '" data-resp="' + r + '" data-act="' + a.id + '"></button></td>'; }).join('') + '<td>' + (auCabinet(a) ? '<button type="button" class="attrib ' + (!a.att ? 'vide' : a.att === 'equipe' ? 'equipe' : 'perso') + '" data-att="' + a.id + '">' + esc(!a.att ? L.nonAttribuee : a.att === 'equipe' ? L.touteEquipe : (MEMBRES.find(function (m) { return m.id === a.att; }) || { nom: '?' }).nom) + '</button>' : '<span class="hors">' + esc(L.horsCabinet) + '</span>') + '</td></tr>'; }).join('') + '</tbody></table></div>' : '') + '</div>';
        }).join('') + '</div>';
    }).join('');
  }
  $('#etape2').addEventListener('click', function (e) {
    var t = e.target.closest('button'); if (!t) return;
    if (t.dataset.cible) cible = t.dataset.cible;
    else if (t.dataset.ouvrir) ouvert = ouvert === t.dataset.ouvrir ? null : t.dataset.ouvrir;
    else if (t.dataset.resp) { var a = ACTS.find(function (x) { return x.id === t.dataset.act; }); a.resp = t.dataset.resp; if (!auCabinet(a)) a.att = ''; else if (!a.att) a.att = cible; }
    else if (t.dataset.att) { var a2 = ACTS.find(function (x) { return x.id === t.dataset.att; }); a2.att = a2.att === cible ? '' : cible; }
    else if (t.dataset.tout || t.dataset.retirer) { var k = (t.dataset.tout || t.dataset.retirer).split('-').map(Number); ACTS.filter(function (a) { return a.offert && a.b === k[0] && a.g === k[1] && auCabinet(a); }).forEach(function (a) { a.att = t.dataset.tout ? cible : ''; }); }
    else return;
    tout();
  });
  function tout() {
    var vis = ACTS.filter(function (a) { return a.offert; }), cab = vis.filter(auCabinet), non = cab.filter(function (a) { return !a.att; }).length;
    $('#offre-n').textContent = vis.length; $('#offre-t').textContent = ACTS.length; $('#offre-resume').textContent = vis.length + ' / ' + ACTS.length;
    OFFRE.forEach(function (b, bi) { var x = ACTS.filter(function (a) { return a.b === bi; }); var el = $('[data-b="' + bi + '"]'); if (el) el.textContent = x.filter(function (a) { return a.offert; }).length + ' / ' + x.length; });
    ACTS.forEach(function (a) { var t = $('[data-tag="' + a.id + '"]'); if (t) { t.textContent = RESP[a.resp].n; t.className = 'tag ' + (a.resp === 'cab' ? 'c' : a.resp === 'cc' ? 'cc' : 'h'); } });
    $('#q-couv').textContent = (vis.length - non) + ' / ' + vis.length;
    $('#q-non').textContent = non; $('#q-non').parentElement.classList.toggle('zero', !non);
    $('#q-equipe').textContent = cab.filter(function (a) { return a.att === 'equipe'; }).length + ' / ' + vis.length;
    $('#n-qui').textContent = non || ''; $('#n-offre').textContent = non || '';
    if (!$('#etape2').hidden) rendreEtape2();
  }

  // Enregistrer
  function sauver() {
    var offre = {}; ACTS.forEach(function (a) { offre[a.id] = { o: a.offert, r: a.resp, a: a.att }; });
    var certifFaits = []; ETAPES.forEach(function (e, i) { if (e.fait) certifFaits.push(i); });
    var core = {
      nom: $('#f-nom').value.trim(), resp: $('#f-resp').value.trim(), desc: $('#f-desc').value.trim(),
      ville: $('#f-ville').value.trim(), prov: $('#f-prov').value.trim(), mail: $('#f-mail').value.trim(),
      tel: $('#f-tel').value.trim(), site: $('#f-site').value.trim(),
      langues: $$('#lang input:checked').map(function (i) { return i.value; }),
      spec: $$('#spec input:checked').map(function (i) { return i.value; }),
      accepte: $('#f-accepte').checked, publique: $('#f-publique').checked
    };
    var payload = { core: core, mfa: $('#f-mfa').checked, certif: certifFaits.join(','), offre: JSON.stringify(offre) };
    var msg = $('#msg');
    fetch(window.location.href, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'op=save&data=' + encodeURIComponent(JSON.stringify(payload)) })
      .then(function (r) { return r.json(); })
      .then(function (j) { msg.textContent = (j && j.ok) ? L.enregistre : L.erreur; msg.style.color = (j && j.ok) ? '' : '#B3261E'; setTimeout(function () { msg.textContent = ''; }, 3000); })
      .catch(function () { msg.textContent = L.erreur; msg.style.color = '#B3261E'; });
  }
  $('#f-save').addEventListener('click', sauver);
  root.addEventListener('input', maj); root.addEventListener('change', function () { maj(); secu(); });

  certif(); secu(); maj(); tout();
})();
</script>
</asp:Content>
