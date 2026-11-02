<%@ Page Title="Profil du cabinet — Portail comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabProfil.aspx.vb" Inherits="MngConsul.wbfCabProfil" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Profil du cabinet — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap">
<style>
/* ---- Profil du cabinet (maquette v4) : tout est confiné sous #cp pour ne pas
      déteindre sur le reste du portail (Site.Master). ---- */
#cp{
  --encre:#0E1F3D; --encre2:#44536E; --encre3:#6A7891;
  --fond:#F2F5F9; --carte:#FFFFFF; --filet:#E3E9F1; --bord:#D5DDE8;
  --champ:#F7F9FC; --pastille:#E8EDF5; --choisi:#E3EBF7; --choisi-bord:#1B4F9C;
  --marine:#1B4F9C; --marine-fonce:#143A73; --nuit:#0E1F3D; --or:#D9A03C;
  --rouge:#B3261E; --vert:#1E7B45;
  color:var(--encre);font-size:15px;
  font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
}
#cp *{box-sizing:border-box}
#cp button,#cp input,#cp textarea,#cp select{font:inherit;color:inherit}
#cp a{color:inherit}
#cp h1{font-size:30px;font-weight:800;margin:0}
#cp .chapeau{color:var(--encre2);font-size:16px;margin:6px 0 20px}

/* Bandeau du cabinet */
#cp .bandeau{background:var(--nuit);color:#fff;border-radius:22px;padding:18px 20px;display:flex;align-items:center;gap:18px;margin-bottom:16px}
#cp .monogramme{width:64px;height:64px;border-radius:16px;background:#fff;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:22px;flex:none}
#cp .bandeau h2{margin:0;font-size:22px;font-weight:800;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
#cp .badge{display:inline-flex;align-items:center;background:var(--pastille);color:var(--encre2);border-radius:999px;padding:4px 12px;font-size:14px;font-weight:700}
#cp .bandeau .badge{background:rgba(255,255,255,.14);color:#fff;font-size:13px}
#cp .bandeau p{margin:4px 0 0;color:#C9D3E3;font-size:14px}

/* Onglets */
#cp .onglets{display:inline-flex;flex-wrap:wrap;gap:2px;background:var(--pastille);border-radius:14px;padding:4px;margin-bottom:16px}
#cp .onglets button{border:0;background:transparent;height:38px;padding:0 14px;border-radius:11px;font-weight:800;font-size:15px;color:var(--encre2);cursor:pointer}
#cp .onglets button[aria-selected=true]{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}

#cp .carte{background:var(--carte);border:1px solid var(--filet);border-radius:18px;padding:18px 20px}
#cp .carte h3{margin:0 0 12px;font-size:18px;font-weight:800;display:flex;align-items:baseline;gap:8px;flex-wrap:wrap}
#cp .carte h3 small{font-size:13px;font-weight:600;color:var(--encre3)}
#cp .carte h3 .compte{margin-left:auto;font-size:14px;color:var(--marine);font-weight:800}
#cp .panneau[hidden]{display:none}

/* Champs */
#cp .grille{display:grid;grid-template-columns:repeat(3,1fr);gap:12px 16px}
#cp .c2{grid-column:span 2}#cp .c3{grid-column:1/-1}
#cp .champ label{display:block;font-size:12px;font-weight:800;letter-spacing:.06em;text-transform:uppercase;color:var(--encre3);margin-bottom:6px}
#cp .champ input,#cp .champ textarea{width:100%;background:var(--champ);border:1px solid var(--bord);border-radius:10px;height:42px;padding:0 12px;font-size:15px}
#cp .champ textarea{height:auto;min-height:84px;padding:10px 12px;resize:vertical}
#cp .champ input:focus,#cp .champ textarea:focus{outline:2px solid var(--marine);outline-offset:1px;background:#fff}
#cp .champ input::placeholder{color:#9AA6BA}

#cp .duo{display:grid;grid-template-columns:1fr 1fr;gap:16px}
#cp .pile{display:flex;flex-direction:column;gap:16px}

/* Interrupteurs */
#cp .bascule{display:flex;gap:14px;align-items:flex-start;border:2px solid var(--bord);border-radius:18px;padding:16px;background:#fff;cursor:pointer}
#cp .bascule:has(input:checked){border-color:var(--choisi-bord);background:#F3F7FD}
#cp .bascule .ic{width:40px;height:40px;border-radius:12px;background:var(--marine);color:#fff;display:grid;place-items:center;flex:none}
#cp .bascule .tx{flex:1}
#cp .bascule .tx b{display:block;font-size:17px;font-weight:800}
#cp .bascule .tx p{margin:4px 0 8px;color:var(--encre2);font-size:14px;line-height:1.45}
#cp .etat{display:inline-block;background:var(--pastille);color:var(--marine-fonce);border-radius:999px;padding:2px 10px;font-size:12.5px;font-weight:800}
#cp .bascule:not(:has(input:checked)) .etat{color:var(--encre3)}
#cp .inter{position:relative;width:52px;height:30px;flex:none}
#cp .inter input{position:absolute;inset:0;opacity:0;margin:0;cursor:pointer}
#cp .inter i{position:absolute;inset:0;border-radius:999px;background:#C3CDDB;transition:.2s}
#cp .inter i::after{content:"";position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;background:#fff;transition:.2s}
#cp .inter input:checked + i{background:var(--marine)}
#cp .inter input:checked + i::after{left:25px}
#cp .inter input:focus-visible + i{outline:2px solid var(--marine);outline-offset:2px}

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
#cp .ligne-inter b,#cp .garanties b{display:block;font-size:16px}
#cp .ligne-inter small,#cp .garanties small{color:var(--encre2);font-size:14px}
#cp .garanties li{display:flex;gap:12px;align-items:flex-start}
#cp .garanties svg{width:18px;height:18px;color:var(--marine);flex:none;margin-top:3px}
#cp .intro{color:var(--encre2);margin:0 0 14px;line-height:1.45}

/* Organisation */
#cp .equipes{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
#cp .equipe{display:flex;flex-direction:column;gap:12px;text-align:left;border:1px solid var(--bord);background:#fff;border-radius:16px;padding:16px}
#cp .eq-tete{display:flex;align-items:center;gap:12px}
#cp .eq-tete>span:nth-child(2){flex:1}#cp .eq-tete b{display:block;font-size:17px}#cp .eq-tete small{color:var(--encre3)}
#cp .mono-or{width:40px;height:40px;border-radius:12px;background:var(--nuit);color:var(--or);display:grid;place-items:center;font-weight:800;flex:none}
#cp .avatars{display:flex;align-items:center}
#cp .avatars i{width:30px;height:30px;border-radius:50%;background:#F2D9A6;color:var(--nuit);font-style:normal;font-size:11px;font-weight:800;display:grid;place-items:center;border:2px solid #fff;margin-left:-6px}
#cp .avatars i:first-child{margin-left:0}
#cp .avatars span{margin-left:10px;font-weight:800;font-size:14px;color:var(--encre2)}
#cp .alerte{display:flex;align-items:center;gap:8px;background:#FDECEC;color:var(--rouge);border-radius:10px;padding:8px 12px;font-weight:800;font-size:14px}

/* Contacts */
#cp .contacts li{display:flex;align-items:center;gap:14px;background:var(--champ);border-radius:12px;padding:10px 12px}
#cp .contacts small{display:block;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3)}
#cp .contacts b{font-size:15px}

/* Barre d'enregistrement */
#cp .barre{display:flex;align-items:center;gap:14px;margin-top:18px}
#cp .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 22px;font-weight:800;cursor:pointer}
#cp .btn:hover{background:var(--marine-fonce)}
#cp .msg{font-weight:700;color:var(--vert);font-size:14px}

/* Offre de services : vue par rythme */
#cp .of-phase{border-radius:999px;padding:2px 9px;font-size:12px;font-weight:800;white-space:nowrap}
#cp .of-phase.dep{background:#E6F4EA;color:#1E6B3A}#cp .of-phase.tard{background:var(--pastille);color:var(--encre2)}
#cp .of-inter{display:flex;align-items:center;cursor:pointer;position:relative}
#cp .of-inter input{position:absolute;opacity:0;width:1px;height:1px}
#cp .of-inter i{width:46px;height:26px;border-radius:999px;background:#C5CFDC;position:relative;transition:background .15s;flex:none}
#cp .of-inter i::after{content:"";position:absolute;top:3px;left:3px;width:20px;height:20px;border-radius:50%;background:#fff;transition:left .15s;box-shadow:0 1px 3px rgba(0,0,0,.2)}
#cp .of-inter input:checked+i{background:var(--marine)}
#cp .of-inter input:checked+i::after{left:23px}
#cp .of-inter input:focus-visible+i{outline:2px solid var(--marine);outline-offset:2px}

#cp .rv-tete{display:flex;align-items:center;gap:20px}
#cp .rv-tete .intro{margin:0}
#cp .rv-compteur{margin-left:auto;display:flex;align-items:center;gap:10px;background:var(--nuit);color:#fff;border-radius:18px;padding:12px 18px;flex:none}
#cp .rv-compteur b{font-size:34px;line-height:1;color:var(--or)}
#cp .rv-compteur span{font-size:13px;font-weight:700;line-height:1.25}
#cp .rv-grille,#cp .rv-legende,#cp .rv-ligne{display:grid;grid-template-columns:250px 1fr 1fr 1fr 190px;gap:0 14px;align-items:start}
#cp .rv-legende{margin:18px 0 6px;padding:0 16px;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#cp .rv-legende span{display:flex;align-items:center;gap:8px}
#cp .rv-legende i,#cp .rv-col::before{font-style:normal;width:24px;height:24px;border-radius:50%;display:grid;place-items:center;font-weight:800;font-size:11px;color:#fff;letter-spacing:0;flex:none}
#cp .rv-legende .l60 i{background:#111;color:var(--or)}#cp .rv-legende .lcab i{background:#C0632A}#cp .rv-legende .lcli i{background:#1E6B3A}
#cp .rv-rythme{margin-bottom:16px}
#cp .rv-rythme h4{display:flex;align-items:baseline;gap:10px;margin:14px 0 8px;font-size:16px;font-weight:800}
#cp .rv-rythme h4 small{font-weight:700;color:var(--encre3);font-size:13px}
#cp .rv-ligne{background:var(--champ);border:1px solid var(--filet);border-radius:18px;padding:14px 16px;margin-bottom:10px;align-items:center;transition:background .15s,border-color .15s}
#cp .rv-ligne.on{background:#fff;border-color:var(--marine);box-shadow:inset 5px 0 0 var(--marine)}
#cp .rv-bloc{display:flex;align-items:center;gap:12px}
#cp .rv-ic{width:38px;height:38px;border-radius:12px;background:var(--pastille);color:var(--encre2);display:grid;place-items:center;flex:none}
#cp .rv-ligne.on .rv-ic{background:var(--nuit);color:#fff}
#cp .rv-ic svg{width:19px;height:19px}
#cp .rv-nom{display:flex;flex-direction:column;align-items:flex-start;gap:4px;min-width:0}
#cp .rv-nom b{font-size:16.5px}
#cp .rv-col{list-style:none;margin:0;padding:10px 12px;border-radius:12px;font-size:14px;line-height:1.35;display:flex;flex-direction:column;gap:4px;align-self:stretch;justify-content:center}
#cp .rv-col li{position:relative;padding-left:12px}
#cp .rv-col li::before{content:"";position:absolute;left:0;top:7px;width:5px;height:5px;border-radius:50%;background:currentColor;opacity:.6}
#cp .rv-col.c60{background:#F1F1F1;color:#222}
#cp .rv-col.ccab{background:#FBEDE4;color:#7A3A12;font-weight:700}
#cp .rv-col.ccli{background:#E6F4EA;color:#1E4F2E}
#cp .rv-ligne:not(.on) .rv-col{background:transparent;color:var(--encre3);font-weight:600}
#cp .rv-ligne:not(.on) .rv-col.ccab{border:1px dashed var(--bord)}
#cp .rv-qui select{width:100%;border:1px solid var(--bord);background:#fff;border-radius:10px;height:40px;padding:0 10px;font-weight:700}
#cp .rv-off{display:block;text-align:center;color:var(--encre3);font-weight:800;font-size:13.5px}
#cp .rv-apercu{margin:8px 0 0;background:#fff;border:1px solid var(--filet);border-radius:14px;padding:12px 16px;color:var(--encre2)}
#cp .rv-apercu b{color:var(--encre)}

@media (max-width:1020px){#cp .duo{grid-template-columns:1fr}}
@media (max-width:1180px){
  #cp .rv-legende{display:none}
  #cp .rv-ligne{grid-template-columns:1fr 1fr 1fr;gap:10px}
  #cp .rv-bloc{grid-column:1 / 3}
  #cp .rv-qui{grid-column:3}
  #cp .rv-col::before{content:attr(data-l);width:auto;height:auto;border-radius:0;background:none!important;color:inherit;font-weight:800;display:block;font-size:11.5px;letter-spacing:.06em;text-transform:uppercase;opacity:.8;margin-bottom:2px}
}
@media (max-width:700px){
  #cp .rv-tete{flex-direction:column;align-items:flex-start}
  #cp .rv-compteur{margin-left:0}
  #cp .rv-ligne{grid-template-columns:1fr}
  #cp .rv-bloc,#cp .rv-qui{grid-column:auto}
}
@media (max-width:640px){
  #cp .grille{grid-template-columns:1fr}#cp .c2{grid-column:auto}
  #cp h1{font-size:24px}
  #cp .bandeau{flex-direction:column;align-items:flex-start}
}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="cp">
  <h1>Profil du cabinet</h1>
  <p class="chapeau">Ce que vos clients et 60secondes savent de votre cabinet.</p>

  <section class="bandeau" aria-label="Résumé du cabinet">
    <div class="monogramme" id="mono">C6</div>
    <div>
      <h2><span data-lie="nom">Cabinet</span> <span class="badge">Certification en cours</span></h2>
      <p id="resume"></p>
    </div>
  </section>

  <div class="onglets" role="tablist" aria-label="Sections du profil">
    <button type="button" role="tab" aria-selected="true" aria-controls="p-ident" id="t-ident">Identification</button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-certif" id="t-certif">Certification <span class="pastille" id="n-certif"></span></button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-secu" id="t-secu">Sécurité <span class="pastille" id="n-secu"></span></button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-clients" id="t-clients">Clients et visibilité</button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-offre" id="t-offre">Offre de services <span class="pastille" id="n-offre"></span></button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-orga" id="t-orga">Organisation</button>
    <button type="button" role="tab" aria-selected="false" aria-controls="p-contacts" id="t-contacts">Contacts</button>
  </div>

  <div id="profil">
    <!-- Identification -->
    <section class="panneau" id="p-ident" role="tabpanel" aria-labelledby="t-ident">
      <div class="carte">
        <h3>Identification</h3>
        <div class="grille">
          <div class="champ c2"><label for="nom">Nom du cabinet</label><input id="nom"></div>
          <div class="champ"><label for="resp">Responsable</label><input id="resp"></div>
          <div class="champ c3"><label for="desc">Description</label><textarea id="desc"></textarea></div>
          <div class="champ c2"><label for="ville">Ville</label><input id="ville"></div>
          <div class="champ"><label for="prov">Province</label><input id="prov"></div>
          <div class="champ"><label for="mail">Courriel</label><input id="mail" type="email"></div>
          <div class="champ"><label for="tel">Téléphone</label><input id="tel" type="tel" placeholder="450 000-0000"></div>
          <div class="champ"><label for="site">Site web</label><input id="site" placeholder="votrecabinet.ca"></div>
        </div>
      </div>
    </section>

    <!-- Certification -->
    <section class="panneau" id="p-certif" role="tabpanel" aria-labelledby="t-certif" hidden>
      <div class="carte">
        <h3>Certification 60secondes <span class="compte" id="c-certif"></span></h3>
        <div class="progres"><i id="barre-certif"></i></div>
        <ul class="etapes" id="etapes"></ul>
      </div>
    </section>

    <!-- Sécurité -->
    <section class="panneau" id="p-secu" role="tabpanel" aria-labelledby="t-secu" hidden>
      <div class="carte">
        <h3>Sécurité et confidentialité</h3>
        <label class="ligne-inter">
          <span class="inter"><input type="checkbox" id="mfa" aria-label="Double vérification obligatoire"><i></i></span>
          <span><b>Double vérification obligatoire</b><small>Chaque membre confirme sa connexion avec son téléphone.</small></span>
        </label>
        <ul class="garanties">
          <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg><span><b>Données hébergées au Canada</b><small>Elles ne quittent jamais le Canada.</small></span></li>
          <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg><span><b>Journal de chaque action</b><small>Tout ce qui est fait au nom d'un client est conservé et consultable.</small></span></li>
          <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg><span><b>Accès limité à ce que le client autorise</b><small>Chaque client choisit ce que votre cabinet peut voir et faire.</small></span></li>
        </ul>
      </div>
    </section>

    <!-- Clients et visibilité -->
    <section class="panneau" id="p-clients" role="tabpanel" aria-labelledby="t-clients" hidden>
      <div class="duo">
        <label class="bascule">
          <span class="ic"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="8" r="4"/><path d="M2 21c0-4 4-6 8-6M17 14v6M14 17h6"/></svg></span>
          <span class="tx"><b>Accepter de nouveaux clients</b><p>Les entreprises qui cherchent un comptable peuvent vous choisir.</p><span class="etat" data-on="Ouvert aux nouveaux clients" data-off="Fermé aux nouveaux clients"></span></span>
          <span class="inter"><input type="checkbox" id="accepte" aria-label="Accepter de nouveaux clients"><i></i></span>
        </label>
        <label class="bascule">
          <span class="ic"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg></span>
          <span class="tx"><b>Fiche visible dans l'annuaire</b><p>Votre cabinet apparaît dans « Cabinets certifiés » des entreprises.</p><span class="etat" data-on="Visible" data-off="Masquée"></span></span>
          <span class="inter"><input type="checkbox" id="publique" aria-label="Fiche visible dans l'annuaire"><i></i></span>
        </label>
      </div>
      <div class="apercu" aria-live="polite">
        <small>CE QUE VOIENT LES ENTREPRISES</small>
        <p id="apercu"></p>
      </div>
    </section>

    <!-- Offre de services -->
    <section class="panneau" id="p-offre" role="tabpanel" aria-labelledby="t-offre" hidden>
      <div class="carte rv-tete">
        <div>
          <h3>Vos opérations financières pour vos clients</h3>
          <p class="intro">Allumez les blocs que votre cabinet offre. Pour chacun, voyez d'un coup d'œil ce que fait 60, ce que fait votre cabinet et ce qui reste au client.</p>
        </div>
        <div class="rv-compteur"><b id="rv-n">0</b><span>blocs offerts<br>sur <span id="rv-t">0</span></span></div>
      </div>

      <div class="rv-legende" aria-hidden="true">
        <span></span>
        <span class="l60"><i>60</i>60 prépare</span>
        <span class="lcab"><i>C</i>Votre cabinet</span>
        <span class="lcli"><i>$</i>Le client</span>
        <span>Qui le fait</span>
      </div>
      <div id="rv-rythmes"></div>
      <p class="rv-apercu" id="rv-apercu"></p>
    </section>

    <!-- Organisation -->
    <section class="panneau" id="p-orga" role="tabpanel" aria-labelledby="t-orga" hidden>
      <div class="carte">
        <h3>Votre cabinet <small>Les membres de votre cabinet.</small></h3>
        <div class="equipes" id="orga-equipes"></div>
      </div>
    </section>

    <!-- Contacts -->
    <section class="panneau" id="p-contacts" role="tabpanel" aria-labelledby="t-contacts" hidden>
      <div class="carte">
        <h3>Personnes-ressources</h3>
        <ul class="contacts" id="contacts-list"></ul>
      </div>
    </section>

    <div class="barre">
      <button class="btn" type="button" id="btn-save">Enregistrer</button>
      <span class="msg" id="msg" role="status"></span>
    </div>
  </div>
</div>

<script type="text/javascript">
(function(){
  const CP=document.getElementById('cp');
  const $=s=>CP.querySelector(s), $$=s=>[...CP.querySelectorAll(s)];
  const D = <asp:Literal ID="litData" runat="server" />;
  const L = <asp:Literal ID="litLabels" runat="server" />;
  const P = (D && D.profil) ? D.profil : {};

  // ---- Onglets
  $$('[role=tab]').forEach(t=>t.addEventListener('click',()=>{
    $$('[role=tab]').forEach(x=>{x.setAttribute('aria-selected',x===t);$('#'+x.getAttribute('aria-controls')).hidden=x!==t});
  }));

  const liste=a=>a.length<2?a.join(''):a.slice(0,-1).join(', ')+' et '+a.at(-1);
  function initiales(n){const m=(n||'').replace(/\(.*?\)/g,'').trim().split(/\s+/);return ((m[0]||'')[0]+(m[1]||'')[0]||'').toUpperCase()||'?'}

  // ---- Pré-remplissage (données réelles)
  $('#nom').value=P.nom||''; $('#resp').value=P.resp||''; $('#desc').value=P.desc||'';
  $('#ville').value=P.ville||''; $('#prov').value=P.prov||''; $('#mail').value=P.mail||'';
  $('#tel').value=P.tel||''; $('#site').value=P.site||'';
  $('#accepte').checked = P.accepte!==false; $('#publique').checked = P.publique!==false;
  $('#mfa').checked = !!D.mfa;

  function maj(){
    const nom=$('#nom').value.trim()||'Votre cabinet';
    $$('[data-lie=nom]').forEach(e=>e.textContent=nom);
    $('#mono').textContent=initiales(nom);
    const bits=[]; const vp=[$('#ville').value, $('#prov').value].filter(Boolean).join(' ');
    if(vp) bits.push(vp);
    if($('#resp').value.trim()) bits.push('responsable : '+$('#resp').value.trim());
    $('#resume').textContent=bits.join(' · ');
    $$('.etat').forEach(e=>{const on=e.closest('.bascule').querySelector('input').checked;e.textContent=on?e.dataset.on:e.dataset.off});
    let t;
    if(!$('#publique').checked) t=nom+" n'apparaît pas dans l'annuaire des cabinets certifiés.";
    else{ t=nom+' '+($('#accepte').checked?'accepte':"n'accepte pas")+' de nouveaux clients'; if($('#ville').value.trim()) t+=' · '+$('#ville').value.trim(); t+='.'; }
    $('#apercu').textContent=t;
  }

  // ---- Certification (étapes ; état « fait » depuis la BD si présent)
  const etapes=[
   {t:"Administrateur inscrit et validé",s:"Identité confirmée"},
   {t:"Permis d'exercice vérifié",s:"Auprès de l'Ordre des CPA"},
   {t:"Assurance responsabilité professionnelle",s:"Attestation en vigueur à téléverser",b:"Téléverser"},
   {t:"Formation 60secondes terminée",s:"Parcours guidé par 60, à votre rythme",b:"Commencer"},
   {t:"Convention de cabinet certifié signée",s:"Signature électronique",b:"Signer"}];
  (function initCertif(){
    const csv=(D.certif||'').toString().trim();
    if(csv!==''){ const done=csv.split(',').map(x=>parseInt(x,10)).filter(x=>!isNaN(x)); etapes.forEach((e,i)=>e.fait=done.includes(i)); }
    else { etapes.forEach((e,i)=>e.fait=i<2); }
  })();
  function certif(){
    $('#etapes').innerHTML=etapes.map((e,i)=>`<li class="${e.fait?'fait':''}"><span class="rond"></span><span class="tx"><b>${e.t}</b><small>${e.s}</small></span>${e.fait?'':`<button type="button" class="btn-petit" data-i="${i}">${e.b}</button>`}</li>`).join('');
    const n=etapes.filter(e=>e.fait).length;
    $('#c-certif').textContent=`${n} sur ${etapes.length} étapes`; $('#barre-certif').style.width=(n/etapes.length*100)+'%';
    $('#n-certif').textContent=etapes.length-n||'';
    $$('.badge').forEach(b=>b.textContent=n===etapes.length?'Cabinet certifié':'Certification en cours');
  }
  $('#etapes').addEventListener('click',e=>{const b=e.target.closest('[data-i]');if(b){etapes[b.dataset.i].fait=true;certif()}});
  certif();

  // ---- Sécurité
  const secu=()=>$('#n-secu').textContent=$('#mfa').checked?'':'1';
  $('#mfa').addEventListener('change',secu); secu();

  // ---- Offre de services : vue par rythme (60 / cabinet / client)
  const MEMBRES=[{id:'equipe',nom:"Toute l'équipe"}].concat((D.membres||[]).map(m=>({id:m.id,nom:m.nom})));
  const RYTHMES=[
   {t:'Chaque mois',s:'Le rythme régulier du dossier',blocs:['mois','paie','paiements']},
   {t:'À chaque déclaration de taxes',s:'Au mois, au trimestre ou à l’année, selon le client',blocs:['taxes']},
   {t:'Chaque année',s:'La fin d’exercice du client',blocs:['annee']}];
  const BLOCS={
   mois:{t:'Fin de mois',dep:true,ic:'<path d="M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18"/>',
     s60:['Importe et apparie la banque','Classe les dépenses'],cab:['Approuve la conciliation','Règle ce que 60 n’a pas su classer'],cli:['Répond aux questions de 60, au besoin']},
   paie:{t:'Paie',dep:false,ic:'<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>',
     s60:['Calcule la paie et les retenues'],cab:['Valide la paie','Produit les T4 et RL-1 en fin d’année'],cli:['Déclenche la paie, ou vous y autorise']},
   paiements:{t:'Paiements',dep:false,ic:'<rect x="2" y="6" width="20" height="12" rx="2"/><path d="M2 10h20M6 15h4"/>',
     s60:['Prépare le lot selon les échéances'],cab:['Approuve les factures fournisseurs','Déclenche paiements et remises, si autorisé'],cli:['Fixe ses plafonds','Déclenche, ou vous y autorise']},
   taxes:{t:'Taxes de vente',dep:true,ic:'<path d="M19 5L5 19"/><circle cx="7" cy="7" r="2"/><circle cx="17" cy="17" r="2"/>',
     s60:['Calcule les taxes de chaque transaction','Prépare la déclaration'],cab:['Révise et produit la TPS/TVQ','Inscrit le client à l’approche du seuil'],cli:['Voit la déclaration produite']},
   annee:{t:'Fin d’année',dep:true,ic:'<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>',
     s60:['Produit la T2, la CO-17 et les états financiers'],cab:['Vérifie et transmet les déclarations','Présente les états financiers'],cli:['Signe et reçoit ses documents']}};
  (function initOffre(){
    let saved=null; try{ if(D.offre) saved=(typeof D.offre==='object')?D.offre:JSON.parse(D.offre); }catch(e){}
    Object.keys(BLOCS).forEach(k=>{
      if(saved && saved[k]){ BLOCS[k].offert=!!saved[k].offert; BLOCS[k].qui=saved[k].qui||'equipe'; }
      else { BLOCS[k].offert=BLOCS[k].dep; BLOCS[k].qui='equipe'; }
    });
  })();
  const li=a=>a.map(x=>`<li>${x}</li>`).join('');
  function rendreOffre(){
    $('#rv-rythmes').innerHTML=RYTHMES.map(r=>`
     <section class="rv-rythme"><h4>${r.t}<small>${r.s}</small></h4>
     ${r.blocs.map(k=>{const b=BLOCS[k];return `
      <article class="rv-ligne ${b.offert?'on':''}">
        <div class="rv-bloc">
          <label class="of-inter" title="${b.offert?'Retirer':'Offrir'} ce bloc"><input type="checkbox" data-bloc="${k}" ${b.offert?'checked':''}><i></i></label>
          <span class="rv-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${b.ic}</svg></span>
          <span class="rv-nom"><b>${b.t}</b><span class="of-phase ${b.dep?'dep':'tard'}">${b.dep?'Pour commencer':'Quand vous serez prêts'}</span></span>
        </div>
        <ul class="rv-col c60" data-l="60 prépare">${li(b.s60)}</ul>
        <ul class="rv-col ccab" data-l="Votre cabinet">${li(b.cab)}</ul>
        <ul class="rv-col ccli" data-l="Le client">${li(b.cli)}</ul>
        <div class="rv-qui">${b.offert?`<select data-qui="${k}" aria-label="Qui le fait au cabinet : ${b.t}">${MEMBRES.map(m=>`<option value="${m.id}" ${b.qui===m.id?'selected':''}>${m.nom}</option>`).join('')}</select>`:`<span class="rv-off">Non offert</span>`}</div>
      </article>`}).join('')}
     </section>`).join('');
    const off=Object.values(BLOCS).filter(b=>b.offert);
    $('#rv-n').textContent=off.length; $('#rv-t').textContent=Object.keys(BLOCS).length;
    $('#rv-apercu').innerHTML=off.length?`<b>Vos clients verront :</b> ${liste(off.map(b=>b.t.toLowerCase()))}.`:'<b>Aucun bloc offert :</b> vos clients ne pourront rien vous confier.';
    $('#n-offre').textContent=off.length?'':'!';
  }
  $('#rv-rythmes').addEventListener('change',e=>{
    const t=e.target;
    if(t.dataset.bloc){BLOCS[t.dataset.bloc].offert=t.checked;rendreOffre()}
    else if(t.dataset.qui){BLOCS[t.dataset.qui].qui=t.value}
  });
  rendreOffre();

  // ---- Organisation (membres réels)
  (function orga(){
    const membres=(D.membres||[]);
    const avatars=membres.map(m=>`<i>${m.ini}</i>`).join('')||`<i>${D.adminIni||'?'}</i>`;
    const n=membres.length||1;
    $('#orga-equipes').innerHTML=`<div class="equipe">
      <span class="eq-tete"><span class="mono-or">${initiales($('#nom').value||P.nom||'Votre cabinet')}</span><span><b>Votre cabinet</b><small>Responsable : ${D.adminNom||P.resp||''}</small></span></span>
      <span class="avatars">${avatars}<span>${n} membre${n>1?'s':''}</span></span>
      <span class="alerte"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M17 2l4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4M21 13v2a3 3 0 0 1-3 3H3"/></svg>${n} sans remplaçant planifié</span>
    </div>`;
  })();

  // ---- Contacts (dérivés de l'administrateur)
  (function contacts(){
    const nom=D.adminNom||P.resp||'Administrateur', ini=D.adminIni||initiales(nom);
    const c=[
     ['ADMINISTRATEUR DU CABINET', nom+' · seul à pouvoir modifier ce profil'],
     ['RESPONSABLE DE LA PROTECTION DES RENSEIGNEMENTS (LOI 25)', nom+' · désigné par défaut, modifiable'],
     ['CONTACT POUR 60SECONDES', nom+' · reçoit les messages de certifies@60secondes.ca']];
    $('#contacts-list').innerHTML=c.map(([s,b])=>`<li><span class="mono-or">${ini}</span><span><small>${s}</small><b>${b}</b></span></li>`).join('');
  })();

  // ---- Suivi live + enregistrement
  CP.querySelector('#profil').addEventListener('input',maj);
  CP.querySelector('#profil').addEventListener('change',maj);
  maj();

  function offreState(){const o={};Object.keys(BLOCS).forEach(k=>o[k]={offert:BLOCS[k].offert,qui:BLOCS[k].qui});return o;}
  $('#btn-save').addEventListener('click',()=>{
    const payload={
      core:{
        nom:$('#nom').value.trim(), resp:$('#resp').value.trim(), desc:$('#desc').value.trim(),
        ville:$('#ville').value.trim(), prov:$('#prov').value.trim(), mail:$('#mail').value.trim(),
        tel:$('#tel').value.trim(), site:$('#site').value.trim(),
        langues:(P.langues||[]), spec:(P.spec||[]),
        accepte:$('#accepte').checked, publique:$('#publique').checked
      },
      mfa:$('#mfa').checked,
      certif:etapes.map((e,i)=>e.fait?i:-1).filter(i=>i>=0).join(','),
      offre:JSON.stringify(offreState())
    };
    $('#msg').textContent='…';
    fetch(location.pathname,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'op=save&data='+encodeURIComponent(JSON.stringify(payload))})
      .then(r=>r.json())
      .then(j=>{ $('#msg').textContent=j.ok?((L&&L.enregistre)||'Profil enregistré.'):((L&&L.erreur)||"L'enregistrement a échoué."); setTimeout(()=>$('#msg').textContent='',2500); })
      .catch(()=>{ $('#msg').textContent=(L&&L.erreur)||"L'enregistrement a échoué."; });
  });
})();
</script>
</asp:Content>
