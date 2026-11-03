<%@ Page Title="Activités de l'Avatar 60 — Portail comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabAvatar60.aspx.vb" Inherits="MngConsul.wbfCabAvatar60" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Activités de l'Avatar 60 — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap">
<style>
/* ---- « Activités de l'Avatar 60 » : tout est confiné sous .a60 pour ne pas
      déteindre sur le reste du portail (Site.Master). Jetons de couleur de la
      maquette portés sur .a60 : ils descendent jusqu'à la fenêtre de détail. ---- */
.a60{
  --encre:#0E1F3D; --encre2:#44536E; --encre3:#6A7891;
  --fond:#F2F5F9; --filet:#E3E9F1; --bord:#D5DDE8; --champ:#F7F9FC; --pastille:#E8EDF5;
  --choisi:#E3EBF7; --marine:#1B4F9C; --marine-fonce:#143A73; --nuit:#0E1F3D; --or:#D9A03C;
  --rouge:#B3261E; --rouge-pale:#FDECEC; --ambre:#9A5B00; --ambre-pale:#FFF4DF; --vert:#1E6B3A; --vert-pale:#E6F4EA;
  width:100%;color:var(--encre);font-size:15px;
  font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
}
.a60 *{box-sizing:border-box}
.a60 button,.a60 select,.a60 textarea,.a60 input{font:inherit;color:inherit}
.a60 a{color:inherit}
.a60 h1{font-size:30px;font-weight:800;margin:0}
.a60 .chapeau{color:var(--encre2);font-size:16px;margin:6px 0 18px}

.a60 .a60-demo{display:flex;gap:8px;align-items:center;background:var(--ambre-pale);color:var(--ambre);
  border-radius:12px;padding:10px 14px;font-weight:700;font-size:13.5px;margin-bottom:14px}
.a60 .a60-demo svg{width:18px;height:18px;flex:none}
.a60 .a60-demo[hidden]{display:none}

.a60 .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 20px;font-weight:800;cursor:pointer;white-space:nowrap}
.a60 .btn:hover{background:var(--marine-fonce)}
.a60 .btn-sec{background:#fff;color:var(--encre);border:1px solid var(--bord);border-radius:999px;height:44px;padding:0 16px;font-weight:800;cursor:pointer}
.a60 .btn-sec:hover{border-color:var(--marine)}
.a60 .btn-ghost{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:7px 12px;font-weight:700;cursor:pointer}
.a60 .btn-ghost:hover{border-color:var(--marine)}
.a60 .lien{background:none;border:0;color:var(--encre2);font-weight:800;font-size:14px;cursor:pointer;padding:4px 6px;border-radius:8px}
.a60 .lien:hover{background:var(--fond);color:var(--encre)}

/* En-tête de page */
.a60 .av-tete{display:flex;align-items:flex-start;gap:14px}
.a60 .av60{width:52px;height:52px;flex:none;margin-top:2px}
.a60 .av60 svg{width:100%;height:100%;display:block}
.a60 .av-tete .chapeau{margin-bottom:16px}

/* Tuiles de synthèse */
.a60 .av-tuiles{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:16px}
.a60 .av-tuile{text-align:left;background:#fff;border:1px solid var(--filet);border-radius:18px;padding:14px 16px;cursor:pointer}
.a60 .av-tuile:hover{border-color:var(--marine)}
.a60 .av-tuile small{display:block;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase}
.a60 .av-tuile b{display:block;font-size:28px;font-weight:800;margin-top:2px;line-height:1.1}
.a60 .av-tuile span{color:var(--encre2);font-size:13.5px}
.a60 .av-tuile.nuit{background:var(--nuit);border-color:var(--nuit);color:#fff}
.a60 .av-tuile.nuit small{color:var(--or)}
.a60 .av-tuile.nuit span{color:#C9D3E3}
.a60 .av-tuile b.ambre{color:var(--ambre)}
.a60 .av-tuile b.rouge{color:var(--rouge)}

/* Filtres */
.a60 .av-filtres{background:#fff;border:1px solid var(--filet);border-radius:18px;padding:12px 16px;display:flex;flex-direction:column;gap:10px;margin-bottom:14px}
.a60 .av-rang{display:flex;align-items:center;gap:10px 12px;flex-wrap:wrap}
.a60 .av-rang .lab{flex:0 0 84px;font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3)}
.a60 .seg{display:inline-flex;background:var(--pastille);border-radius:12px;padding:3px;gap:2px}
.a60 .seg button{border:0;background:transparent;border-radius:9px;padding:7px 14px;font-weight:800;color:var(--encre2);cursor:pointer}
.a60 .seg button[aria-pressed=true]{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}
.a60 .av-cherche{margin-left:auto;flex:1 1 280px;max-width:420px;display:flex;align-items:center;gap:8px;border:1px solid var(--bord);border-radius:12px;padding:0 12px;height:40px;background:#fff}
.a60 .av-cherche svg{width:17px;height:17px;color:var(--encre3);flex:none}
.a60 .av-cherche input{border:0;outline:0;flex:1;font:inherit;min-width:0;background:transparent}
.a60 .av-cherche:focus-within{outline:2px solid var(--marine);outline-offset:1px}
.a60 .av-puces{display:flex;flex-wrap:wrap;gap:6px}
.a60 .puce-f{display:inline-flex;align-items:center;gap:7px;border:1px solid var(--bord);background:#fff;border-radius:999px;padding:6px 12px;font-weight:800;font-size:14px;cursor:pointer}
.a60 .puce-f .pt{width:9px;height:9px;border-radius:50%}
.a60 .puce-f i{font-style:normal;min-width:20px;height:20px;border-radius:999px;background:var(--pastille);color:var(--encre2);font-size:12px;display:inline-grid;place-items:center;padding:0 5px}
.a60 .puce-f[aria-pressed=true]{background:var(--nuit);border-color:var(--nuit);color:#fff}
.a60 .puce-f[aria-pressed=true] i{background:rgba(255,255,255,.18);color:#fff}
.a60 .av-rang.selects label{display:flex;flex-direction:column;gap:4px;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase}
.a60 .av-rang.selects select{border:1px solid var(--bord);background:#fff;border-radius:10px;height:40px;padding:0 10px;font-weight:700;font-size:14px;color:var(--encre);letter-spacing:0;text-transform:none;min-width:220px}
.a60 .av-rang.selects .lien{align-self:flex-end;height:40px;color:var(--marine-fonce)}
.a60 .av-rang.selects .lien[hidden]{display:none}

.a60 .av-compte{margin:0 0 10px;color:var(--encre2);font-weight:700;font-size:14px}

/* Liste groupée par jour */
.a60 .jour{background:#fff;border:1px solid var(--filet);border-radius:20px;overflow:hidden;margin-bottom:14px}
.a60 .jour h2{margin:0;padding:10px 16px;font-size:15px;font-weight:800;background:var(--champ);border-bottom:1px solid var(--filet);display:flex;gap:10px;align-items:center}
.a60 .jour h2 small{color:var(--encre3);font-weight:700;font-size:13px}
.a60 .ligne{width:100%;display:grid;grid-template-columns:56px 40px minmax(0,1fr) 190px 150px 110px 20px;gap:12px;align-items:center;padding:11px 16px;border:0;border-bottom:1px solid var(--filet);background:#fff;text-align:left;cursor:pointer;color:inherit}
.a60 .jour .ligne:last-child{border-bottom:0}
.a60 .ligne:hover{background:#F7FAFE}
.a60 .ligne:hover .chev{color:var(--marine)}
.a60 .ligne .h{color:var(--encre3);font-weight:800;font-size:13.5px;font-variant-numeric:tabular-nums}
.a60 .ic-act{width:36px;height:36px;border-radius:50%;display:grid;place-items:center}
.a60 .ic-act svg{width:17px;height:17px}
.a60 .ligne .quoi{min-width:0}
.a60 .ligne .quoi b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.a60 .ligne .quoi small{display:block;color:var(--encre2);font-size:13.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.a60 .ligne .cli b{display:block;font-size:14px}
.a60 .ligne .cli small{color:var(--encre3);font-size:12.5px}
.a60 .ligne .mt{text-align:right;font-weight:800;font-variant-numeric:tabular-nums}
.a60 .ligne .mt:empty::before{content:"—";color:var(--encre3);font-weight:700}
.a60 .chev{color:var(--encre3);width:18px;height:18px}
.a60 .res{display:inline-flex;align-items:center;gap:6px;border-radius:999px;padding:3px 10px;font-size:12.5px;font-weight:800;white-space:nowrap;justify-self:start}
.a60 .res .pt{width:8px;height:8px;border-radius:50%;background:currentColor}
.a60 .res.fait{background:var(--vert-pale);color:var(--vert)}
.a60 .res.avalider{background:var(--ambre-pale);color:var(--ambre)}
.a60 .res.signale{background:var(--rouge-pale);color:var(--rouge)}
.a60 .res.arrete{background:var(--pastille);color:var(--encre2)}
.a60 .vide{background:#fff;border:1px dashed var(--bord);border-radius:20px;padding:30px;text-align:center;color:var(--encre2)}
.a60 .vide b{display:block;font-size:18px;color:var(--encre);margin-bottom:4px}

/* Fenêtre de détail */
.a60 #detail{border:0;border-radius:22px;padding:0;width:min(860px,calc(100% - 24px));max-height:calc(100vh - 32px);box-shadow:0 24px 70px rgba(14,31,61,.38);color:var(--encre)}
.a60 #detail[open]{display:flex;flex-direction:column}
.a60 #detail::backdrop{background:rgba(14,31,61,.5)}
.a60 .dt-tete{display:flex;gap:14px;align-items:flex-start;padding:20px 22px 14px;border-bottom:1px solid var(--filet)}
.a60 .dt-ic{width:48px;height:48px;border-radius:50%;display:grid;place-items:center;flex:none}
.a60 .dt-ic svg{width:22px;height:22px}
.a60 .dt-id{flex:1;min-width:0}
.a60 .dt-id small{font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3);text-transform:uppercase}
.a60 .dt-id h2{margin:2px 0 6px;font-size:21px;line-height:1.25}
.a60 .dt-meta{display:flex;flex-wrap:wrap;gap:6px 14px;align-items:center;color:var(--encre2);font-size:14px;font-weight:700}
.a60 .dt-fermer{border:0;background:var(--fond);width:40px;height:40px;border-radius:50%;cursor:pointer;display:grid;place-items:center;flex:none}
.a60 .dt-fermer svg{width:18px;height:18px}
.a60 .dt-corps{padding:16px 22px;overflow:auto}
.a60 .dt-resume{border-radius:14px;padding:12px 14px;font-weight:700;line-height:1.45;margin-bottom:14px}
.a60 .dt-resume.fait{background:var(--vert-pale)}
.a60 .dt-resume.avalider{background:var(--ambre-pale)}
.a60 .dt-resume.signale{background:var(--rouge-pale)}
.a60 .dt-resume.arrete{background:var(--pastille)}
.a60 .dt-grille{display:grid;grid-template-columns:1.1fr 1fr;gap:18px}
.a60 .dt-corps h3{margin:0 0 8px;font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3);text-transform:uppercase}
.a60 .dt-etapes{list-style:none;margin:0;padding:0;position:relative}
.a60 .dt-etapes li{position:relative;padding:0 0 12px 26px;font-size:14.5px;line-height:1.4}
.a60 .dt-etapes li::before{content:"";position:absolute;left:5px;top:5px;width:10px;height:10px;border-radius:50%;background:var(--marine)}
.a60 .dt-etapes li::after{content:"";position:absolute;left:9px;top:17px;bottom:-1px;width:2px;background:var(--filet)}
.a60 .dt-etapes li:last-child::after{display:none}
.a60 .dt-etapes li.att::before{background:var(--or)}
.a60 .dt-etapes li.stop::before{background:var(--rouge)}
.a60 .dt-etapes time{display:block;font-size:12.5px;color:var(--encre3);font-weight:800}
.a60 .dt-donnees{display:grid;grid-template-columns:auto 1fr;gap:6px 14px;margin:0 0 14px;font-size:14.5px}
.a60 .dt-donnees dt{color:var(--encre3);font-weight:700}
.a60 .dt-donnees dd{margin:0;font-weight:800;font-variant-numeric:tabular-nums}
.a60 .dt-pieces{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:6px}
.a60 .dt-pieces li{display:flex;align-items:center;gap:8px;background:var(--champ);border:1px solid var(--filet);border-radius:10px;padding:7px 10px;font-weight:700;font-size:14px}
.a60 .dt-pieces svg{width:16px;height:16px;color:var(--marine);flex:none}
.a60 .dt-pourquoi{margin-top:14px;background:var(--champ);border:1px solid var(--filet);border-radius:14px;padding:12px 14px}
.a60 .dt-pourquoi p{margin:0;font-size:14.5px;line-height:1.45}
.a60 .dt-regle{margin-top:6px!important;color:var(--encre2)}
.a60 .dt-ref{margin:12px 0 0;font-size:12.5px;color:var(--encre3);font-weight:700}
.a60 .dt-pied{display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap;padding:12px 22px;border-top:1px solid var(--filet);background:var(--champ)}
.a60 .dt-nav{display:flex;align-items:center;gap:8px;color:var(--encre2);font-weight:700;font-size:14px}
.a60 .dt-nav button[disabled]{opacity:.4;cursor:default}
.a60 .dt-act{display:flex;gap:8px;flex-wrap:wrap}

/* Toast */
.a60 .toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:var(--nuit);color:#fff;border-radius:999px;padding:12px 18px;font-weight:800;display:flex;gap:14px;align-items:center;box-shadow:0 8px 24px rgba(14,31,61,.25);z-index:60}
.a60 .toast[hidden]{display:none}
.a60 .toast button{background:none;border:0;color:var(--or);font-weight:800;cursor:pointer}

.a60 button:focus-visible,.a60 select:focus-visible,.a60 a:focus-visible,.a60 input:focus-visible{outline:2px solid var(--marine);outline-offset:2px}

@media (max-width:1180px){
  .a60 .ligne{grid-template-columns:48px 36px minmax(0,1fr) 150px 120px 20px}
  .a60 .ligne .mt{display:none}
}
@media (max-width:1100px){
  .a60 .av-tuiles{grid-template-columns:1fr 1fr}
}
@media (max-width:860px){
  .a60 .av-tuiles{grid-template-columns:1fr 1fr}
  .a60 .ligne{grid-template-columns:36px minmax(0,1fr) 20px;gap:4px 10px}
  .a60 .ligne .h{grid-column:2;grid-row:1;font-size:12.5px}
  .a60 .ligne .ic-act{grid-row:1 / span 3}
  .a60 .ligne .quoi{grid-column:2}
  .a60 .ligne .cli{grid-column:2;display:flex;gap:6px;align-items:baseline}
  .a60 .ligne .res{grid-column:2}
  .a60 .ligne .quoi b,.a60 .ligne .quoi small{white-space:normal}
  .a60 .dt-pied{padding:12px 16px}
  .a60 .dt-corps{padding:14px 16px}
  .a60 .dt-tete{padding:16px}
  .a60 .ligne .chev{grid-column:3;grid-row:1 / span 3}
  .a60 .dt-grille{grid-template-columns:1fr}
  .a60 .av-cherche{margin-left:0;max-width:none}
  .a60 .av-rang .lab{flex-basis:100%}
  .a60 .av-rang.selects label,.a60 .av-rang.selects select{width:100%;min-width:0}
}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<section class="a60">
  <div class="a60-demo" id="demo" hidden>
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v5M12 16h.01"/></svg>
    Données de démonstration — aucune activité au journal des dossiers pour l'instant, voici la page à l'œuvre sur un jeu d'exemple.
  </div>

  <div class="av-tete">
    <span class="av60" aria-hidden="true"><svg viewBox="0 0 256 256"><circle cx="128" cy="128" r="104" fill="#5E35C9"/><circle cx="96" cy="120" r="16" fill="none" stroke="#FFFFFF" stroke-width="12"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round"/><ellipse cx="162" cy="106" rx="15" ry="25" fill="none" stroke="#FFFFFF" stroke-width="12" transform="rotate(12 160 110)"/><path d="M148 68 q16 -9 30 0" fill="none" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round"/><path d="M108 170 q20 6 40 -6" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/></svg></span>
    <div>
      <h1>Activités de l'Avatar 60</h1>
      <p class="chapeau">Tout ce que 60 a fait seul pour vos clients, selon les droits convenus avec chacun. Touchez une ligne pour voir le détail.</p>
    </div>
  </div>

  <div class="av-tuiles">
    <button type="button" class="av-tuile nuit" data-raccourci="tous"><small>Activités faites par 60</small><b id="k-tot">0</b><span id="k-per">ces 30 jours</span></button>
    <button type="button" class="av-tuile" data-raccourci="avalider"><small>À valider</small><b id="k-val" class="ambre">0</b><span>préparées par 60, en attente</span></button>
    <button type="button" class="av-tuile" data-raccourci="signale"><small>Signalées</small><b id="k-sig" class="rouge">0</b><span>60 a vu quelque chose</span></button>
    <button type="button" class="av-tuile" data-raccourci="arrete"><small>Arrêtées par une règle</small><b id="k-arr">0</b><span>droits ou plafonds</span></button>
  </div>

  <section class="av-filtres" aria-label="Filtres">
    <div class="av-rang">
      <span class="lab">PÉRIODE</span>
      <div class="seg" role="group" aria-label="Période" id="f-per">
        <button type="button" data-per="0" aria-pressed="false">Aujourd'hui</button>
        <button type="button" data-per="7" aria-pressed="false">7 jours</button>
        <button type="button" data-per="30" aria-pressed="true">30 jours</button>
      </div>
      <label class="av-cherche"><svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg><input id="f-q" type="search" placeholder="Chercher un client, un fournisseur, un montant…" aria-label="Chercher"></label>
    </div>
    <div class="av-rang">
      <span class="lab">RÉSULTAT</span>
      <div class="av-puces" role="group" aria-label="Résultat" id="f-res"></div>
    </div>
    <div class="av-rang selects">
      <label>Famille d'activités<select id="f-fam"></select></label>
      <label>Client<select id="f-cli"></select></label>
      <label>Qui valide<select id="f-val">
        <option value="tous">Tous</option>
        <option value="60">Personne : 60 agit seul</option>
        <option value="cabinet">Le cabinet</option>
        <option value="client">Le client</option>
      </select></label>
      <button type="button" class="lien" id="f-raz" hidden>Effacer les filtres</button>
    </div>
  </section>

  <p class="av-compte" id="compte" aria-live="polite"></p>
  <div id="jours"></div>

  <dialog id="detail" aria-labelledby="dt-titre">
    <div class="dt-tete">
      <span class="dt-ic" id="dt-ic" aria-hidden="true"></span>
      <div class="dt-id">
        <small id="dt-fam"></small>
        <h2 id="dt-titre"></h2>
        <div class="dt-meta" id="dt-meta"></div>
      </div>
      <button type="button" class="dt-fermer" id="dt-fermer" aria-label="Fermer">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M6 6l12 12M18 6L6 18"/></svg>
      </button>
    </div>
    <div class="dt-corps">
      <div class="dt-resume" id="dt-resume"></div>
      <div class="dt-grille">
        <section><h3>Ce que 60 a fait</h3><ol class="dt-etapes" id="dt-etapes"></ol></section>
        <section><h3>Données de la transaction</h3><dl class="dt-donnees" id="dt-donnees"></dl>
          <div id="dt-pieces-z"><h3>Pièces</h3><ul class="dt-pieces" id="dt-pieces"></ul></div>
        </section>
      </div>
      <section class="dt-pourquoi"><h3>Pourquoi 60 pouvait le faire</h3><p id="dt-droit"></p><p class="dt-regle" id="dt-regle"></p></section>
      <p class="dt-ref" id="dt-ref"></p>
    </div>
    <div class="dt-pied">
      <div class="dt-nav">
        <button type="button" class="btn-ghost" id="dt-prec">‹ Précédente</button>
        <span id="dt-pos"></span>
        <button type="button" class="btn-ghost" id="dt-suiv">Suivante ›</button>
      </div>
      <div class="dt-act" id="dt-act"></div>
    </div>
  </dialog>

  <div class="toast" id="toast" role="status" hidden><span id="toast-tx"></span></div>
</section>

<script type="text/javascript">
// Données réelles injectées par le serveur (journal du cabinet via s0961), ou null.
var SRV = <asp:Literal ID="litData" runat="server" />;
const REEL = !!(SRV && SRV.reel);
if(!REEL){ const d=document.getElementById('demo'); if(d) d.hidden=false; }
const AUJ = (REEL && SRV.auj) ? new Date(SRV.auj[0],SRV.auj[1],SRV.auj[2]) : new Date(2026,9,30);
const BUILTIN_CLIENTS=[
  {nom:'Marc Allard',metier:'électricien',profil:'Compagnie avec employés'},
  {nom:'Annie Roy',metier:'photographe',profil:'Travailleuse autonome'},
  {nom:'Luc Gendron',metier:'consultant TI',profil:'Compagnie sans employé'},
  {nom:'Julie Fortin',metier:'designer',profil:'Travailleuse autonome'},
  {nom:'Pierre Ménard',metier:'menuisier',profil:'Compagnie avec employés'},
  {nom:'Nathalie Bisson',metier:'nutritionniste',profil:'Travailleuse autonome'}
];
const CLIENTS = REEL ? SRV.clients : BUILTIN_CLIENTS;
// Familles d'activités : mêmes libellés que la page Droits par activité.
const FAM={
  ventes:['Ventes et facturation','M4 4h16v16H4zM8 9h8M8 13h8M8 17h5'],
  encaiss:['Comptes clients et encaissements','M3 7h18v10H3zM7 12h.01M17 12h.01M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z'],
  depenses:['Dépenses et fournisseurs','M6 2h9l5 5v15H6zM14 2v6h6M9 13h6M9 17h6'],
  paiements:['Paiements','M2 6h20v12H2zM2 10h20M6 15h4'],
  banque:['Banque et conciliation','M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18'],
  paie:['Paie et employés','M16 11a4 4 0 1 0-8 0M4 21a8 8 0 0 1 16 0'],
  taxes:['Taxes de vente et remises','M19 5L5 19M7.5 7.5h.01M16.5 16.5h.01'],
  impot:["Impôt de l'entreprise et du propriétaire",'M4 20V10M10 20V4M16 20v-7M22 20H2'],
  corpo:['Obligations corporatives et de métier','M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z'],
  livres:["Livres et fin d'exercice",'M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5zM4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5'],
  gouv:['Gouvernement et vérifications','M4 6h16v12H4zM4 7l8 6 8-6'],
  treso:['Trésorerie, conseil et croissance','M3 17l6-6 4 4 8-8M15 7h6v6'],
  echanges:['Échanges client et cabinet','M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z']
};
const RES={fait:'Fait par 60',avalider:'À valider',signale:'Signalé',arrete:'Arrêté par une règle'};
const RESC={fait:'#1E6B3A',avalider:'#D9A03C',signale:'#B3261E',arrete:'#6A7891'};
const ICC={fait:['#E6F4EA','#1E6B3A'],avalider:['#FFF4DF','#9A5B00'],signale:['#FDECEC','#B3261E'],arrete:['#E8EDF5','#44536E']};

// j = il y a j jours ; val = qui valide (60 = personne, 60 agit seul)
const E=(j,h,c,fam,act,resume,res,val,mt,etapes,don,pcs,regle,extra)=>({j,h,c,fam,act,resume,res,val,mt,etapes,don,pcs,regle,...(extra||{})});
const BUILTIN_DATA=[
 E(0,'07:42',0,'banque','Importer et apparier les transactions bancaires','Relevé Desjardins importé : 38 transactions, 36 appariées','signale','cabinet','',
   [['07:40','Relevé du compte d\'opérations Desjardins reçu par le lien bancaire'],['07:41','38 transactions lues, du 23 au 29 octobre'],['07:42','36 transactions appariées aux factures et dépenses'],['07:42','2 transactions incertaines laissées au cabinet','att']],
   [['Compte','Desjardins · opérations ••• 4471'],['Période','23 au 29 octobre 2026'],['Transactions','38'],['Appariées','36'],['Incertaines','2 (412,00 $ et 89,95 $)']],
   ['Relevé Desjardins 23-29 oct.csv'],'Un appariement est incertain quand le montant ou le tiers ne correspond pas exactement. 60 ne devine pas : il laisse la décision au cabinet.'),
 E(0,'07:15',2,'taxes','Préparer la déclaration de taxes','Déclaration TPS/TVQ du 3e trimestre préparée : 1 284,55 $ à remettre','avalider','cabinet','1 284,55 $',
   [['07:10','Ventes et dépenses du 1er juillet au 30 septembre rassemblées'],['07:12','TPS et TVQ perçues et payées calculées sur 214 transactions'],['07:14','Comparaison avec le 2e trimestre : écart normal (+6 %)'],['07:15','Déclaration prête, en attente de votre révision','att']],
   [['Période','1er juillet au 30 septembre 2026'],['TPS perçue','1 412,30 $'],['TPS payée (CTI)','498,62 $'],['TVQ perçue','2 817,54 $'],['TVQ payée (RTI)','1 446,67 $'],['À remettre','1 284,55 $'],['Échéance','31 octobre 2026']],
   ['Brouillon TPS-TVQ T3 2026.pdf','Sommaire des taxes par mois.xlsx'],'La déclaration est produite seulement après l\'approbation du cabinet. Le client la voit dans son application.'),
 E(0,'06:30',4,'paie','Calculer la paie','Paie du 30 octobre calculée : 3 employés, 4 126,80 $ nets','avalider','client','4 126,80 $',
   [['06:20','Heures de la semaine reçues des employés (application mobile)'],['06:25','Retenues du Québec calculées (RRQ, RQAP, AE, impôts)'],['06:28','Solde bancaire vérifié : suffisant pour la paie et les remises'],['06:30','Paie envoyée au client pour approbation','att']],
   [['Période','19 au 25 octobre 2026'],['Employés','3'],['Brut','5 610,00 $'],['Retenues','1 483,20 $'],['Net versé','4 126,80 $'],['Dépôt prévu','30 octobre 2026']],
   ['Registre de paie 2026-10-30.pdf'],'60 calcule ; le client approuve et déclenche la paie. Le cabinet voit tout.'),
 E(0,'06:05',3,'treso','Avertir d\'un manque de liquidités à venir','Solde prévu sous zéro le 12 novembre (−640 $)','signale','60','−640 $',
   [['06:00','Prévision de trésorerie recalculée sur 30 jours'],['06:04','Acompte provisionnel de 1 150 $ dû le 15 décembre pris en compte'],['06:05','Manque prévu le 12 novembre : client et cabinet avisés','stop']],
   [['Solde actuel','2 318,40 $'],['Entrées prévues','3 200,00 $'],['Sorties prévues','6 158,40 $'],['Point bas','−640 $ le 12 novembre']],
   [],'60 avertit dès qu\'un manque est prévu dans les 30 prochains jours. Il ne déplace jamais d\'argent sans approbation.'),
 E(1,'16:48',1,'depenses','Classer les dépenses et extraire les taxes','Facture B&H Photo 1 249,99 $ classée en Équipement photo','fait','60','1 249,99 $',
   [['16:46','Facture reçue par courriel à factures@annieroy.60sec.ca'],['16:47','Fournisseur, date, montant et taxes lus sur la facture'],['16:48','Classée en Équipement photo (immobilisation) selon la règle apprise']],
   [['Fournisseur','B&H Photo'],['Date','28 octobre 2026'],['Avant taxes','1 087,18 $'],['TPS','54,36 $'],['TVQ','108,45 $'],['Total','1 249,99 $'],['Compte','1820 · Équipement photo']],
   ['Facture B&H 8812-441.pdf'],'Règle apprise le 3 août : les achats de plus de 500 $ chez B&H Photo vont en immobilisation.',{renv:true,conf:98}),
 E(1,'14:20',0,'encaiss','Envoyer les relances de comptes clients','2e relance envoyée à Constructions Lemay, facture 1043 (2 350,00 $)','fait','60','2 350,00 $',
   [['14:20','Facture 1043 en retard de 34 jours'],['14:20','2e relance envoyée avec la facture jointe et un lien de paiement'],['14:20','Prochaine relance prévue le 6 novembre si rien ne bouge']],
   [['Client facturé','Constructions Lemay inc.'],['Facture','1043 du 26 septembre 2026'],['Montant','2 350,00 $'],['Retard','34 jours'],['Relance','2 de 3']],
   ['Relance 2 - facture 1043.pdf'],'Les relances automatiques suivent le calendrier choisi par le client : 7, 30 et 45 jours.'),
 E(1,'11:02',4,'paiements','Déclencher un paiement fournisseur','Paiement de 3 200,00 $ à Bois Franc Lessard arrêté','arrete','client','3 200,00 $',
   [['11:00','Facture approuvée par le client, échéance le 2 novembre'],['11:02','Montant supérieur au plafond de 2 500 $ par paiement','stop'],['11:02','Paiement arrêté ; le client doit le déclencher lui-même']],
   [['Bénéficiaire','Bois Franc Lessard inc.'],['Facture','BF-20931'],['Montant','3 200,00 $'],['Plafond par paiement','2 500,00 $'],['Échéance','2 novembre 2026']],
   ['Facture BF-20931.pdf'],'Plafonds fixés par le client : 2 500 $ par paiement, 10 000 $ par mois. Au-delà, 60 s\'arrête.'),
 E(1,'09:30',5,'ventes','Importer les ventes de Square, de la caisse ou de la boutique en ligne','Ventes Square du 29 octobre importées : 11 consultations','fait','60','1 045,00 $',
   [['09:28','Ventes Square du 29 octobre lues'],['09:29','11 ventes, taxes exonérées (services de santé)'],['09:30','Dépôt Square du 30 octobre apparié, frais de 28,73 $ classés']],
   [['Source','Square'],['Ventes','11'],['Total','1 045,00 $'],['Frais Square','28,73 $'],['Dépôt net','1 016,27 $']],
   ['Rapport Square 2026-10-29.csv'],'Importation quotidienne confiée à 60 par la cliente.'),
 E(2,'15:10',2,'gouv','Recevoir et classer le courrier gouvernemental','Avis de cotisation T2 2025 de l\'ARC lu et classé : aucun montant dû','fait','60','',
   [['15:08','Avis reçu dans Mon dossier d\'entreprise de l\'ARC'],['15:09','Avis lu : cotisation conforme à la déclaration'],['15:10','Classé au dossier 2025 ; cabinet avisé']],
   [['Organisme','Agence du revenu du Canada'],['Document','Avis de cotisation T2'],['Année','2025'],['Montant dû','0,00 $']],
   ['Avis de cotisation T2 2025.pdf'],'Lecture et classement du courrier confiés à 60.'),
 E(2,'10:45',0,'gouv','Recevoir et classer le courrier gouvernemental','Demande de renseignements de Revenu Québec : réponse avant le 20 novembre','signale','cabinet','',
   [['10:43','Lettre reçue dans Mon dossier pour les entreprises'],['10:44','Demande : pièces justificatives des CTI/RTI de juin'],['10:45','12 pièces déjà rassemblées ; urgent pour le cabinet','att']],
   [['Organisme','Revenu Québec'],['Objet','Pièces justificatives TPS/TVQ'],['Période visée','Juin 2026'],['Date limite','20 novembre 2026'],['Pièces prêtes','12 sur 12']],
   ['Lettre RQ 2026-10-28.pdf','Pièces CTI-RTI juin 2026.zip'],'60 lit et prépare ; la réponse à une vérification revient toujours au cabinet.'),
 E(2,'08:00',1,'impot','Calculer les acomptes provisionnels','Acompte du 15 décembre recalculé : 1 150 $ (au lieu de 980 $)','fait','60','1 150,00 $',
   [['08:00','Revenus de l\'année mis à jour (+12 % par rapport aux prévisions)'],['08:00','Acomptes fédéral et Québec recalculés'],['08:00','Cliente avisée ; rappel prévu le 8 décembre']],
   [['Prochain acompte','15 décembre 2026'],['Fédéral','510,00 $'],['Québec','640,00 $'],['Total','1 150,00 $']],
   [],'Calcul des acomptes confié à 60 (responsabilité 60 dans les droits).'),
 E(3,'13:30',4,'corpo','Renouveler les permis et attestations','Attestation de Revenu Québec renouvelée (valide jusqu\'au 31 janvier 2027)','fait','60','',
   [['13:28','Attestation actuelle échue le 31 octobre'],['13:29','Demande faite en ligne : aucun montant en souffrance'],['13:30','Nouvelle attestation déposée au dossier']],
   [['Document','Attestation de Revenu Québec'],['Valide jusqu\'au','31 janvier 2027'],['Usage','Contrats de construction de plus de 25 000 $']],
   ['Attestation RQ 2026-10-27.pdf'],'Renouvellement des attestations confié à 60.'),
 E(3,'09:12',3,'echanges','Demander un document au client, avec relances','Relevé Visa de septembre demandé à Julie Fortin (relance 1)','fait','60','',
   [['09:12','Document manquant pour fermer septembre'],['09:12','Demande envoyée dans l\'application de la cliente'],['09:12','Relance automatique prévue le 2 novembre']],
   [['Document demandé','Relevé Visa Desjardins, septembre 2026'],['Raison','Fermeture de la période de septembre'],['Relance','1 de 3']],
   [],'Demandes de documents faites au nom du cabinet, avec relances automatiques.'),
 E(4,'17:05',0,'paie','Calculer la paie','Paie du 23 octobre calculée et approuvée : 4 employés','fait','client','6 812,44 $',
   [['06:15','Paie calculée'],['08:40','Approuvée par Marc Allard dans son application'],['17:05','Dépôts faits ; remises à la source mises à jour']],
   [['Employés','4'],['Net versé','6 812,44 $'],['Remises RQ','2 104,18 $'],['Remises ARC','1 387,90 $']],
   ['Registre de paie 2026-10-23.pdf'],'60 calcule ; le client approuve. Fait ici avec son approbation.'),
 E(4,'10:20',2,'depenses','Classer les dépenses et extraire les taxes','Facture AWS 186,42 $ US convertie et classée en Hébergement','fait','60','254,61 $',
   [['10:19','Facture reçue par courriel'],['10:20','Convertie au taux de la Banque du Canada (1,3658)'],['10:20','Classée en Hébergement et logiciels ; aucune taxe canadienne']],
   [['Fournisseur','Amazon Web Services'],['Montant US','186,42 $ US'],['Montant CA','254,61 $'],['Compte','5420 · Hébergement et logiciels']],
   ['Facture AWS octobre.pdf'],'Règle : factures AWS en Hébergement ; conversion au taux du jour.',{renv:true,conf:99}),
 E(5,'16:00',5,'encaiss','Apparier les encaissements aux factures','3 virements Interac appariés à 3 factures','fait','60','585,00 $',
   [['16:00','3 virements reçus'],['16:00','Appariés aux factures 2026-118, 2026-121 et 2026-124'],['16:00','Factures marquées payées']],
   [['Virements','3'],['Total','585,00 $'],['Factures soldées','3']],[],'Appariement automatique quand le montant et le payeur concordent exactement.',{renv:true,conf:100}),
 E(6,'11:11',4,'paiements','Préparer le lot de paiements fournisseurs','Lot de 5 paiements préparé (4 820,15 $) selon les échéances','avalider','client','4 820,15 $',
   [['11:05','Factures fournisseurs à payer d\'ici 10 jours repérées'],['11:09','Trésorerie vérifiée : lot couvert'],['11:11','Lot envoyé au client pour approbation','att']],
   [['Paiements','5'],['Total','4 820,15 $'],['Plus grand','1 980,00 $'],['Date prévue','2 novembre 2026']],
   ['Lot paiements 2026-11-02.pdf'],'60 prépare ; le client approuve et déclenche, dans ses plafonds.'),
 E(8,'14:40',3,'taxes','S\'inscrire aux taxes à l\'approche du seuil','Ventes à 27 400 $ sur 4 trimestres : seuil de 30 000 $ en vue','signale','client','27 400 $',
   [['14:40','Ventes des 4 derniers trimestres calculées'],['14:40','91 % du seuil du petit fournisseur atteint','stop'],['14:40','Cliente et cabinet avisés']],
   [['Ventes 4 trimestres','27 400 $'],['Seuil','30 000 $'],['Dépassement prévu','Janvier 2027']],[],'60 avertit à 90 % du seuil ; l\'inscription se fait par la cliente ou le cabinet.'),
 E(9,'08:30',2,'banque','Importer et apparier les transactions bancaires','Relevé Banque Nationale importé : 22 transactions, toutes appariées','fait','60','',
   [['08:29','Relevé reçu par le lien bancaire'],['08:30','22 transactions appariées']],
   [['Compte','Banque Nationale ••• 0912'],['Transactions','22'],['Appariées','22']],['Relevé BN 2026-10-21.csv'],'Importation et appariement confiés à 60.',{conf:100}),
 E(12,'07:00',0,'livres','Classer les transactions dans le plan comptable','64 transactions de septembre classées ; 2 corrigées par le cabinet','fait','60','',
   [['07:00','64 transactions classées'],['10:15','2 classements corrigés par Louise Bérubé ; règle apprise']],
   [['Période','Septembre 2026'],['Transactions','64'],['Corrigées','2']],[],'Classement confié à 60 ; chaque correction du cabinet devient une règle.'),
 E(15,'09:00',4,'taxes','Calculer les taxes sur chaque transaction','Taxes de la quinzaine calculées sur 87 transactions','fait','60','',
   [['09:00','87 transactions traitées'],['09:00','TPS 1 902,11 $ et TVQ 3 794,74 $ cumulées']],
   [['Transactions','87'],['TPS cumulée','1 902,11 $'],['TVQ cumulée','3 794,74 $']],[],'Calcul des taxes : responsabilité de 60.'),
 E(18,'15:30',1,'paiements','Déclencher un paiement fournisseur','Paiement à un nouveau bénéficiaire arrêté (Studio Lumen)','arrete','client','720,00 $',
   [['15:30','Bénéficiaire absent de la liste approuvée par la cliente','stop'],['15:30','Demande d\'approbation envoyée à la cliente']],
   [['Bénéficiaire','Studio Lumen'],['Montant','720,00 $']],['Facture Lumen 0412.pdf'],'Tout nouveau bénéficiaire doit d\'abord être approuvé par le client.'),
 E(22,'10:00',5,'impot','Calculer les acomptes provisionnels','Acompte du 15 septembre payé et inscrit','fait','60','860,00 $',
   [['10:00','Paiement confirmé par la banque'],['10:00','Inscrit au dossier fiscal 2026']],[['Montant','860,00 $']],[],'Calcul des acomptes confié à 60.'),
 E(27,'08:45',3,'livres','Classer les transactions dans le plan comptable','41 transactions d\'août classées','fait','60','',
   [['08:45','41 transactions classées sans correction']],[['Période','Août 2026'],['Transactions','41']],[],'Classement confié à 60.')
];
const DATA = REEL ? SRV.data : BUILTIN_DATA;
DATA.forEach((d,i)=>{d.id=i;d.date=new Date(AUJ);d.date.setDate(AUJ.getDate()-d.j);d.ref='A60-'+fmtD(d.date)+'-'+String(1000+i*37).slice(-4);});
function fmtD(d){return d.getFullYear()+String(d.getMonth()+1).padStart(2,'0')+String(d.getDate()).padStart(2,'0')}

const JOURS=['dimanche','lundi','mardi','mercredi','jeudi','vendredi','samedi'],MOIS=['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
const jourLib=d=>{const j=Math.round((AUJ-d)/864e5);const base=`${JOURS[d.getDay()]} ${d.getDate()} ${MOIS[d.getMonth()]}`;return j===0?`Aujourd'hui · ${base}`:j===1?`Hier · ${base}`:base[0].toUpperCase()+base.slice(1)};
const cliLib=c=>CLIENTS[c].metier?`${CLIENTS[c].nom}, ${CLIENTS[c].metier}`:CLIENTS[c].nom;
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const svg=(p,w=2.2)=>`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${p}"/></svg>`;
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];

const F={per:30,res:'tous',fam:'tous',cli:'tous',val:'tous',q:''};
let liste=[],courant=null;

function dansPeriode(d){return d.j<=F.per}
function filtre(sauf){
  const q=F.q.trim().toLowerCase();
  return DATA.filter(d=>dansPeriode(d)
    &&(sauf==='res'||F.res==='tous'||d.res===F.res)
    &&(F.fam==='tous'||d.fam===F.fam)
    &&(F.cli==='tous'||d.c==F.cli)
    &&(F.val==='tous'||d.val===F.val)
    &&(!q||[d.act,d.resume,cliLib(d.c),d.mt,...d.don.map(x=>x[1])].join(' ').toLowerCase().includes(q)));
}
function remplirSelects(){
  const p=DATA.filter(dansPeriode);
  const fams=Object.keys(FAM).filter(k=>p.some(d=>d.fam===k));
  $('#f-fam').innerHTML=`<option value="tous">Toutes les familles</option>`+fams.map(k=>`<option value="${k}" ${F.fam===k?'selected':''}>${esc(FAM[k][0])} (${p.filter(d=>d.fam===k).length})</option>`).join('');
  $('#f-cli').innerHTML=`<option value="tous">Tous les clients</option>`+CLIENTS.map((c,i)=>({c,i})).filter(o=>p.some(d=>d.c===o.i)).map(({c,i})=>`<option value="${i}" ${F.cli==i?'selected':''}>${esc(c.nom)} (${p.filter(d=>d.c===i).length})</option>`).join('');
  if(F.fam!=='tous'&&!fams.includes(F.fam)){F.fam='tous'}
}
function rendre(){
  remplirSelects();
  const p=DATA.filter(dansPeriode);
  $('#k-tot').textContent=p.length;
  $('#k-per').textContent=F.per===0?"aujourd'hui":`ces ${F.per} jours`;
  $('#k-val').textContent=p.filter(d=>d.res==='avalider').length;
  $('#k-sig').textContent=p.filter(d=>d.res==='signale').length;
  $('#k-arr').textContent=p.filter(d=>d.res==='arrete').length;
  $$('[data-per]').forEach(b=>b.setAttribute('aria-pressed',String(+b.dataset.per===F.per)));
  $('#f-val').value=F.val;

  const base=filtre('res');
  $('#f-res').innerHTML=[['tous','Tous','']].concat(Object.keys(RES).map(k=>[k,RES[k],RESC[k]])).map(([k,lab,c])=>{
    const n=k==='tous'?base.length:base.filter(d=>d.res===k).length;
    return `<button type="button" class="puce-f" data-res="${k}" aria-pressed="${F.res===k}">${c?`<span class="pt" style="background:${c}"></span>`:''}${lab}<i>${n}</i></button>`}).join('');

  liste=filtre().sort((a,b)=>a.j-b.j||b.h.localeCompare(a.h));
  const actifs=F.res!=='tous'||F.fam!=='tous'||F.cli!=='tous'||F.val!=='tous'||F.q;
  $('#f-raz').hidden=!actifs;
  $('#compte').textContent=liste.length?`${liste.length} ${liste.length>1?'activités':'activité'}${actifs?' pour ces filtres':''}`:'';

  const G=[];liste.forEach(d=>{let g=G.find(x=>x.j===d.j);if(!g)G.push(g={j:d.j,date:d.date,l:[]});g.l.push(d)});
  $('#jours').innerHTML=G.length?G.map(g=>`<section class="jour"><h2>${jourLib(g.date)}<small>${g.l.length} ${g.l.length>1?'activités':'activité'}</small></h2>${g.l.map(d=>{
    const [bg,fg]=ICC[d.res];
    return `<button type="button" class="ligne" data-id="${d.id}" aria-label="Voir le détail : ${esc(d.act)}, ${esc(CLIENTS[d.c].nom)}">
      <span class="h">${d.h}</span>
      <span class="ic-act" style="background:${bg};color:${fg}">${svg(FAM[d.fam][1])}</span>
      <span class="quoi"><b>${esc(d.resume)}</b><small>${esc(d.act)}</small></span>
      <span class="cli"><b>${esc(CLIENTS[d.c].nom)}</b><small>${esc(CLIENTS[d.c].metier)}</small></span>
      <span class="res ${d.res}"><span class="pt"></span>${RES[d.res]}</span>
      <span class="mt">${esc(d.mt)}</span>
      <span class="chev">${svg('M9 6l6 6-6 6',2.6)}</span>
    </button>`}).join('')}</section>`).join('')
  :`<div class="vide"><b>Aucune activité pour ces filtres</b>Changez la période ou effacez les filtres.</div>`;
}

// ---------- Fenêtre de détail ----------
const VALIDE={ '60':'Personne : 60 agit seul', cabinet:'Le cabinet', client:'Le client' };
function droit(d){
  const c=CLIENTS[d.c].nom;
  if(d.val==='60') return `Activité confiée à 60 dans les droits convenus avec ${c} (Droits par activité : « Qui le fait : 60 »).`;
  if(d.val==='cabinet') return `60 prépare ; le cabinet valide. Droits convenus avec ${c}.`;
  return `60 prépare ; ${c} approuve dans son application. Le cabinet voit tout.`;
}
function ouvrir(id){
  const d=DATA[id]; courant=id;
  const [bg,fg]=ICC[d.res];
  $('#dt-ic').style.background=bg; $('#dt-ic').style.color=fg; $('#dt-ic').innerHTML=svg(FAM[d.fam][1]);
  $('#dt-fam').textContent=FAM[d.fam][0];
  $('#dt-titre').textContent=d.act;
  $('#dt-meta').innerHTML=`<span class="res ${d.res}"><span class="pt"></span>${RES[d.res]}</span><span>${esc(cliLib(d.c))}</span><span>${jourLib(d.date)} à ${d.h.replace(':',' h ')}</span>${d.mt?`<span>${esc(d.mt)}</span>`:''}`;
  const rz=$('#dt-resume'); rz.className='dt-resume '+d.res; rz.textContent=d.resume+'.';
  $('#dt-etapes').innerHTML=d.etapes.map(([h,t,c])=>`<li class="${c||''}"><time>${h.replace(':',' h ')}</time>${esc(t)}</li>`).join('');
  $('#dt-donnees').innerHTML=d.don.map(([k,v])=>`<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join('')+`<dt>Client</dt><dd>${esc(CLIENTS[d.c].nom)}${CLIENTS[d.c].profil?' · '+esc(CLIENTS[d.c].profil):''}</dd><dt>Qui valide</dt><dd>${VALIDE[d.val]}</dd>`+(d.conf?`<dt>Confiance de 60</dt><dd>${d.conf} %</dd>`:'');
  $('#dt-pieces-z').hidden=!d.pcs.length;
  $('#dt-pieces').innerHTML=d.pcs.map(p=>`<li>${svg('M6 2h9l5 5v15H6zM14 2v6h6')}${esc(p)}</li>`).join('');
  $('#dt-droit').textContent=droit(d);
  $('#dt-regle').textContent=d.regle;
  $('#dt-ref').textContent=`Référence au journal : ${d.ref} · horodaté et conservé 7 ans · visible par le client dans son application`;
  const i=liste.findIndex(x=>x.id===id);
  $('#dt-pos').textContent=i>=0?`${i+1} sur ${liste.length}`:'';
  $('#dt-prec').disabled=i<=0; $('#dt-suiv').disabled=i<0||i>=liste.length-1;
  const A=[];
  if(d.res==='avalider'&&d.val==='cabinet') A.push(['btn','valider','Valider maintenant']);
  if(d.res==='avalider'&&d.val==='client') A.push(['btn','relancer','Relancer le client']);
  if(d.res==='signale') A.push(['btn','prendre','Je m\'en occupe']);
  if(d.res==='arrete') A.push(['btn-sec','plafonds','Voir les droits et plafonds']);
  if(d.renv&&d.res==='fait') A.push(['btn-sec','renverser','Annuler ce classement']);
  A.push(['btn-sec','dossier','Ouvrir le dossier du client'],['btn-sec','erreur','Signaler une erreur à 60']);
  $('#dt-act').innerHTML=A.map(([c,a,l])=>`<button type="button" class="${c}" data-a="${a}">${l}</button>`).join('');
  if(!$('#detail').open) $('#detail').showModal();
}
function toast(t){$('#toast-tx').textContent=t;$('#toast').hidden=false;clearTimeout(toast.t);toast.t=setTimeout(()=>$('#toast').hidden=true,3500)}
function maintenant(){const n=new Date();return String(n.getHours()).padStart(2,'0')+':'+String(n.getMinutes()).padStart(2,'0')}
function agir(a){
  const d=DATA[courant],c=CLIENTS[d.c].nom;
  if(a==='valider'){d.res='fait';d.etapes.push([maintenant(),'Validé par Louise Bérubé ; 60 a terminé l\'activité']);toast('Validé. 60 termine et l\'inscrit au journal du client.')}
  else if(a==='prendre'){d.etapes.push([maintenant(),'Pris en charge par Louise Bérubé']);d.res='fait';toast('Pris en charge. Le client voit que vous vous en occupez.')}
  else if(a==='relancer'){d.etapes.push([maintenant(),`Relance envoyée à ${c}`,'att']);toast(`Relance envoyée à ${c}.`)}
  else if(a==='renverser'){d.etapes.push([maintenant(),'Classement annulé par Louise Bérubé ; transaction remise à classer','stop']);d.res='signale';d.renv=false;toast('Classement annulé. La transaction est à classer.')}
  else if(a==='erreur'){toast('Merci. 60 revoit cette activité et la règle utilisée.');return}
  else if(a==='dossier'){toast(`Ouverture du dossier de ${c}.`);return}
  else if(a==='plafonds'){toast(`Ouverture des droits et plafonds de ${c}.`);return}
  rendre(); ouvrir(courant);
}

// ---------- Événements ----------
document.addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  if(b.dataset.per!==undefined){F.per=+b.dataset.per;rendre()}
  else if(b.dataset.res){F.res=b.dataset.res;rendre()}
  else if(b.dataset.raccourci){F.res=b.dataset.raccourci;rendre();$('#f-res').scrollIntoView({block:'nearest'})}
  else if(b.dataset.id!==undefined){ouvrir(+b.dataset.id)}
  else if(b.dataset.a){agir(b.dataset.a)}
  else if(b.id==='f-raz'){Object.assign(F,{res:'tous',fam:'tous',cli:'tous',val:'tous',q:''});$('#f-q').value='';rendre()}
  else if(b.id==='dt-fermer'){$('#detail').close()}
  else if(b.id==='dt-prec'){const i=liste.findIndex(x=>x.id===courant);if(i>0)ouvrir(liste[i-1].id)}
  else if(b.id==='dt-suiv'){const i=liste.findIndex(x=>x.id===courant);if(i>=0&&i<liste.length-1)ouvrir(liste[i+1].id)}
});
$('#detail').addEventListener('click',e=>{if(e.target===$('#detail'))$('#detail').close()});
$('#detail').addEventListener('close',()=>{const r=document.querySelector(`.ligne[data-id="${courant}"]`);if(r)r.focus()});
document.addEventListener('keydown',e=>{if(!$('#detail').open)return;if(e.key==='ArrowRight')$('#dt-suiv').click();if(e.key==='ArrowLeft')$('#dt-prec').click()});
$('#f-fam').addEventListener('change',e=>{F.fam=e.target.value;rendre()});
$('#f-cli').addEventListener('change',e=>{F.cli=e.target.value;rendre()});
$('#f-val').addEventListener('change',e=>{F.val=e.target.value;rendre()});
$('#f-q').addEventListener('input',e=>{F.q=e.target.value;rendre()});
rendre();
</script>
</asp:Content>
