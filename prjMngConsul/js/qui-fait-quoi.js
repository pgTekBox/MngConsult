/*
  ====================================================================
  60secondes — page « Qui fait quoi » (fichier unique, autonome)
  Contient : la page, les styles, le script et les données de l'inventaire
  (v5.2, 20 oct. 2026 : 3 profils, 201 métiers, 655 activités).
  Seule dépendance externe : la police Nunito (Google Fonts), avec repli système.
  ====================================================================

  CONTEXTE FOURNI PAR LA PLATEFORME (non saisi sur la page, seulement affiché)
  La page lit, dans cet ordre, le premier qui existe :

  1) Un objet global défini AVANT ce script, par exemple dans la page .aspx :
       <script> (balise d'ouverture)
         window.QFQ_CONTEXTE = {
           entreprise: "INFORMATIQUE MG",
           profil:     "Cie 1-4",            // "TA" | "Cie 0" | "Cie 1-4"
           metier:     "Électricien",        // nom exact du métier (liste dans DATA.M)
           cabinet:    { nom: "Cabinet X", certifie: true },   // ou null si aucun cabinet
           choix:      [ { id: "ALL-S-05", moi: true, cabinet: true } ],  // choix déjà enregistrés (facultatif)
           urlEnregistrer: "/api/qui-fait-quoi"   // facultatif : POST JSON à l'enregistrement
         };
       (puis la balise de fermeture du script)
  2) Des attributs sur <body> : data-entreprise, data-profil, data-metier,
     data-cabinet (nom), data-cabinet-certifie ("true"/"false").
  3) L'adresse : ?entreprise=...&profil=Cie%201-4&metier=%C3%89lectricien&cabinet=...&certifie=1

  ENREGISTREMENT
   - événement document « qfq:enregistrer » (detail = profil, métier, cabinet, actions) ;
   - window.QuiFaitQuoi.choix() retourne le même contenu ;
   - si urlEnregistrer est fourni : envoi POST application/json.

  RÈGLES
   - Activités du profil ET du métier (socle + famille + métier), regroupées en blocs
     qui s'ouvrent tous de la même façon ; un seul ouvert à la fois ; « Bloc suivant ».
   - Point de départ : toujours la proposition de 60 (partagée si le cabinet peut agir,
     conseiller ou selon les droits ; sinon « Moi »).
   - Deux choix par action : Moi (vert) / Mon cabinet (orange) ; les deux = partagée.
   - Niveau A = « 60secondes » (noir, fixe). « Phase 2 » et « Hors 60secondes » sans choix.
   - Métier exonéré : les lignes du socle sur les taxes de vente ne s'affichent pas.
   - Sans cabinet : tout revient au client.
*/

var BLOCS = [
 {k:"agenda", t:"Mon agenda", d:"Disponibilités, rendez-vous, annulations", ico:"M8 3v3M16 3v3M4 8h16M5 5h14a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"},
 {k:"ventes", t:"Ma facturation", d:"Soumissions, factures, encaissements, relances", ico:"M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h7"},
 {k:"depenses", t:"Mes dépenses", d:"Reçus, fournisseurs et leurs paiements", ico:"M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6"},
 {k:"argent", t:"Mon argent", d:"Banque, réserves, ce que je peux me verser, mes décisions", ico:"M3 10l9-6 9 6M5 10v9M19 10v9M9 10v9M15 10v9M3 21h18"},
 {k:"taxes", t:"Mes taxes", d:"TPS, TVQ : inscription, déclarations, remises", ico:"M19 5L5 19M7 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM17 18a1 1 0 1 0 0-2 1 1 0 0 0 0 2z"},
 {k:"impots", t:"Mes impôts", d:"Acomptes, déclarations de revenus, avis du gouvernement", ico:"M4 4h16v16H4zM8 9h8M8 13h8M8 17h5"},
 {k:"societe", t:"Ma société", d:"Rémunération, dividendes, registre, résolutions", ico:"M3 21h18M5 21V8l7-5 7 5v13M9 21v-6h6v6"},
 {k:"employes", t:"Mes employés et la paie", d:"Embauche, horaires, paie, relevés, santé-sécurité", ico:"M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM2 20c0-3 3-5 6-5s6 2 6 5M17 11a3 3 0 1 0 0-6M22 20c0-2-2-4-4-4.5"},
 {k:"metier", t:"Mon métier", d:"", ico:"M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z", met:true}
];
var DOM2BLOC = {"1":"agenda","2":"ventes","3":"depenses","4":"argent","5":"taxes","6":"impots","7":"argent","8":"societe","9":"employes"};
function blocDe(a){ var d=a.d.charAt(0); if(a.c==="S") return DOM2BLOC[d]; if(d==="1") return "agenda"; if(d==="9") return "employes"; return "metier"; }
var NIV = {A:"Fait par 60", B:"À approuver", C:"À faire", D:"À décider"};
var NOM_PROFIL = {"TA":"Travailleur autonome","Cie 0":"Société sans employé","Cie 1-4":"Société avec employés"};

var etat = { profil:null, metier:null, entreprise:"", cabinet:"aucun", cabNom:"", urlEnregistrer:null, resp:{}, ouvert:null, vus:{}, sauve:"{}", tout:false };
function normProfil(p){
  var s=String(p||"").toLowerCase().replace(/\s|_|-/g,"");
  if(s==="ta"||s==="travailleurautonome") return "TA";
  if(s==="cie0"||s==="societesansemploye"||s==="société sans employé") return "Cie 0";
  if(s==="cie14"||s==="cie1"||s==="societeavecemployes") return "Cie 1-4";
  return p;
}
function lireContexte(){
  var c=window.QFQ_CONTEXTE||null, b=document.body.dataset, q=new URLSearchParams(location.search);
  var src = c ? c : (b.profil ? {entreprise:b.entreprise, profil:b.profil, metier:b.metier,
                    cabinet: b.cabinet ? {nom:b.cabinet, certifie:b.cabinetCertifie==="true"} : null}
             : (q.get("profil") ? {entreprise:q.get("entreprise"), profil:q.get("profil"), metier:q.get("metier"),
                    cabinet: q.get("cabinet") ? {nom:q.get("cabinet"), certifie:q.get("certifie")==="1"||q.get("certifie")==="true"} : null}
             : null));
  if(!src){ /* démonstration seulement */
    src={entreprise:"[Nom de l'entreprise]", profil:"TA", metier:"Massothérapeute", cabinet:{nom:"[Nom du cabinet]", certifie:true}};
  }
  etat.entreprise = src.entreprise || "";
  etat.profil = normProfil(src.profil);
  etat.metier = src.metier || null;
  if(src.cabinet && src.cabinet.nom){ etat.cabNom=src.cabinet.nom; etat.cabinet = src.cabinet.certifie ? "certifie" : "invite"; }
  else { etat.cabNom=""; etat.cabinet="aucun"; }
  etat.urlEnregistrer = src.urlEnregistrer || null;
  etat.lecture = !!src.lectureSeule;      /* ERP : seuls les administrateurs modifient (le serveur refuse les autres) */
  (src.choix||[]).forEach(function(x){ if(x && x.id) etat.resp[x.id]={moi:!!x.moi, cab:!!(x.cabinet||x.cab)}; });
  etat.sauve = JSON.stringify(etat.resp);
}
var $ = function(id){ return document.getElementById(id); };
function esc(s){ return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;"); }
function combo(){ for (var i=0;i<DATA.M.length;i++){ var m=DATA.M[i]; if(m.p===etat.profil && m.m===etat.metier) return m; } return null; }

/* Règles par action : quels choix sont permis */
function regle(a){
  if (a.e==="Phase 2") return "p2";
  if (a.e==="Hors 60secondes") return "hors";
  if (a.n==="A") return "60";
  /* ERP : ce sont des paramètres de la compagnie, réglables en tout temps, même sans cabinet
     (ils s'appliquent dès qu'un cabinet est choisi). */
  return "libre";
}
/* Proposition de 60 : {moi, cab} */
function propose(a){
  var r=regle(a);
  if (r!=="libre") return {moi:true,cab:false};
  if (a.k==="Oui" || a.k==="Oui selon les droits" || a.k==="Oui (conseil)") return {moi:true,cab:true};
  return {moi:true,cab:false};
}
function choixDe(a){ var r=regle(a); if(r==="60"||r==="p2"||r==="hors") return null; if(r!=="libre") return {moi:true,cab:false}; return etat.resp[a.id] || propose(a); }
function statut(a){
  var r=regle(a); if(r==="60") return "60"; if(r==="p2"||r==="hors") return r;
  var c=choixDe(a); return c.moi&&c.cab ? "par" : c.cab ? "cab" : "moi";
}
function basculer(a,qui){
  var r=regle(a); if(r!=="libre") return;
  var c=Object.assign({}, choixDe(a)); c[qui]=!c[qui];
  if(!c.moi && !c.cab) return;           /* au moins un responsable */
  etat.resp[a.id]=c;
}
/* ERP : sans profil ou métier reconnu, ou sur demande (« Toutes les actions »), tous les
   paramètres « Qui fait quoi » : les actions où l'entreprise ou son cabinet a un rôle. */
function tousParametres(){
  return DATA.A.filter(function(a){ return !/^Choisir qui/.test(a.a) && a.n!=="A" && a.e!=="Phase 2" && a.e!=="Hors 60secondes"; });
}
function activites(){
  var c=combo(); if(!c || etat.tout) return tousParametres();
  var T={"Tous":1}; T[c.p]=1; T[c.g]=1; var exo=/^Exonéré/.test(c.t||"");
  return DATA.A.filter(function(a){
    if(!T[a.p]) return false;
    if(!(a.c==="S" || (a.c==="F" && a.f===c.f) || (a.c==="M" && a.m===c.m))) return false;
    if(/^Choisir qui/.test(a.a)) return false;
    if(exo && a.c==="S" && a.d==="5. Taxes de vente") return false;
    return true;
  });
}
function duo(attr, moi, cab, dMoi, dCab, label){
  return '<div class="duo" role="group" aria-label="'+esc(label)+'">'+
    '<button class="choix" '+attr+' data-qui="moi" aria-pressed="'+moi+'"'+(dMoi||etat.lecture?' disabled':'')+'>Moi</button>'+
    '<button class="choix" '+attr+' data-qui="cab" aria-pressed="'+cab+'"'+(dCab||etat.lecture?' disabled':'')+'>Mon cabinet</button></div>';
}
function cellule(a){
  var r=regle(a);
  if(r==="60") return '<span class="fixe">60secondes</span>';
  if(r==="p2") return '<span class="fixe p2">Phase 2</span>';
  if(r==="hors") return '<span class="fixe p2">Hors 60secondes</span>';
  var c=choixDe(a), id='data-id="'+esc(a.a.length?a.id:"")+'"';
  if(r==="libre") return duo(id, c.moi, c.cab, false, false, a.a);
  return duo(id, true, false, true, true, a.a);
}
function noteDe(a){
  var r=regle(a), c=choixDe(a);
  if(a.k==="Oui si autorisé" && c && c.cab) return '<span class="warn">Votre cabinet pourra déclencher ce paiement avec votre autorisation distincte : plafonds, bénéficiaires approuvés, échéance de 12 mois.</span>';
  return '';
}
function dessiner(){
  var liste=activites(), c=combo(), n={"60":0,moi:0,par:0,cab:0};
  $("ctxEntreprise").textContent = etat.entreprise || "—";
  $("ctxProfil").textContent = NOM_PROFIL[etat.profil] || (etat.profil||"Profil inconnu");
  $("ctxMetier").textContent = etat.metier || "Métier inconnu";
  $("cabNom").textContent = etat.cabinet==="aucun" ? "Aucun cabinet" : etat.cabNom;
  /* ERP : profil et métier viennent de Paramètres › Entreprise ; sans eux, tous les paramètres s'affichent */
  var tous = !c || etat.tout, bandeau='';
  if(!c){
    var lienParam=' <a href="wbfSetting" target="_top">Ouvrir Paramètres › Entreprise</a>';
    var msg = (!etat.profil || !etat.metier)
      ? 'Vous voyez tous les paramètres « Qui fait quoi » ('+liste.length+' actions). Choisissez le profil et le métier de votre entreprise pour ne garder que ceux qui vous concernent.'
      : 'Le métier « '+esc(etat.metier)+' » n\'est pas prévu pour le profil « '+esc(NOM_PROFIL[etat.profil]||etat.profil)+' » : vous voyez tous les paramètres « Qui fait quoi » ('+liste.length+' actions). Vérifiez le profil et le métier.';
    bandeau='<div class="qfq-bandeau">'+msg+lienParam+'</div>';
  }
  liste.forEach(function(a){ var s=statut(a); if(n[s]!==undefined) n[s]++; });
  var cel=function(cls,nv,lab){ return '<span class="st '+cls+(nv?'':' zero')+'"><b>'+nv+'</b><span>'+lab+'</span></span>'; };
  $("resStats").innerHTML = cel("st-moi",n.moi,"Moi")+cel("st-par",n.par,n.par>1?"Partagées":"Partagée")+cel("st-cab",n.cab,"Cabinet")+cel("st-60",n["60"],"Par 60");
  var nb=BLOCS.filter(function(b){return liste.some(function(a){return blocDe(a)===b.k;});});
  var revus=nb.filter(function(b){return etat.vus[b.k];}).length;
  $("resTot").innerHTML = liste.length+" actions · "+revus+" de "+nb.length+" blocs revus"+
    (c ? ' · <button type="button" class="voir-tout" data-tout>'+(etat.tout ? 'Mon profil et mon métier seulement' : 'Toutes les actions ('+tousParametres().length+')')+'</button>' : '');
  var diff=0, avant=JSON.parse(etat.sauve);
  Object.keys(etat.resp).forEach(function(k){ if(JSON.stringify(etat.resp[k])!==JSON.stringify(avant[k])) diff++; });
  Object.keys(avant).forEach(function(k){ if(!etat.resp[k]) diff++; });
  $("btnSave").disabled = diff===0 || etat.lecture;
  $("btnSave").textContent = etat.lecture ? "Consultation seulement" : diff ? "Enregistrer ("+diff+")" : "Enregistré";
  $("btnSave").title = etat.lecture ? "Seul un administrateur de votre compagnie peut modifier la répartition." : "";
  $("cabEtat").innerHTML = etat.cabinet==="aucun" ? '<span style="color:#44536E">Aucun cabinet choisi : ces réglages s\'appliqueront dès que vous en choisirez un.</span>'
    : etat.cabinet==="certifie" ? '<svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>Cabinet certifié 60secondes'
    : '<span style="color:#7A5200">Cabinet invité, pas encore certifié</span>';
  var G={}; liste.forEach(function(a){ var k=blocDe(a); (G[k]=G[k]||[]).push(a); });
  var rang={"60":1,"p2":2,"hors":3};
  var html="";
  var visibles=BLOCS.filter(function(b){return G[b.k]&&G[b.k].length;});
  visibles.forEach(function(b,ib){
    var g=G[b.k];
    var hum=g.filter(function(a){ return regle(a)!=="60" && regle(a)!=="p2" && regle(a)!=="hors"; });
    var aut=g.filter(function(a){ return !(regle(a)!=="60" && regle(a)!=="p2" && regle(a)!=="hors"); });
    var m={"60":0,moi:0,par:0,cab:0}; g.forEach(function(a){ var s=statut(a); if(m[s]!==undefined) m[s]++; });
    var ouvert=etat.ouvert===b.k;
    var libres=hum.filter(function(a){ return regle(a)==="libre"; });
    var desc=b.met ? (tous ? "Tous les métiers · ordres, permis, organismes et règles propres à chacun" : c.m+" · ordres, permis, organismes et règles propres") : b.d;
    var tot=g.length, pct=function(x){ return (100*x/tot).toFixed(1)+"%"; };
    var cell=function(cls,nv,lab){ return '<span class="st '+cls+(nv?'':' zero')+'"><b>'+nv+'</b><span>'+lab+'</span></span>'; };
    html+='<section class="bloc'+(ouvert?' ouvert':'')+'" id="s-'+b.k+'"><button class="bloc-btn" data-k="'+b.k+'" aria-expanded="'+ouvert+'" aria-controls="b-'+b.k+'">'+
      '<span class="bloc-ico'+(b.met?' met':'')+'"><svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="'+b.ico+'"/></svg></span>'+
      '<span class="bloc-info"><span class="bloc-t">'+esc(b.t)+'</span><span class="bloc-d">'+esc(desc)+'</span>'+
        '<span class="bloc-meta"><span>'+tot+(tot>1?' actions':' action')+'</span>'+
        (etat.vus[b.k]?'<span class="revu"><svg aria-hidden="true" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>Revu</span>':'<span class="arevoir">À revoir</span>')+'</span>'+
        '<span class="barre" aria-hidden="true"><i class="b-moi" style="width:'+pct(m.moi)+'"></i><i class="b-par" style="width:'+pct(m.par)+'"></i><i class="b-cab" style="width:'+pct(m.cab)+'"></i><i class="b-60" style="width:'+pct(m["60"])+'"></i></span></span>'+
      '<span class="stats">'+cell("st-moi",m.moi,"Moi")+cell("st-par",m.par,m.par>1?"Partagées":"Partagée")+cell("st-cab",m.cab,"Cabinet")+cell("st-60",m["60"],"Par 60")+'</span>'+
      '<svg class="chev" aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#5B6B86" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>'+
      '</button><div id="b-'+b.k+'"'+(ouvert?'':' hidden')+'>';
    if(libres.length>1){
      var tMoi=libres.every(function(a){return choixDe(a).moi;}), tCab=libres.every(function(a){return choixDe(a).cab;});
      html+='<div class="tout"><span class="tout-l">Tout le bloc</span>'+duo('data-bloc="'+b.k+'"', tMoi, tCab, false, false, "Tout le bloc "+b.t)+'</div>';
    }
    /* ERP : en vue « tous les paramètres », les actions propres à une famille ou à un métier sont regroupées sous leur nom */
    var dern='';
    if(tous) hum.sort(function(x,y){ var kx=x.c==="S"?"0":"1|"+x.f+"|"+x.m, ky=y.c==="S"?"0":"1|"+y.f+"|"+y.m; return kx.localeCompare(ky,"fr"); });
    hum.forEach(function(a){ if(tous && a.c!=="S"){ var tg=a.f+(a.m && a.m!=="Tous de la famille" && a.m!=="—" ? " · "+a.m : " · toute la famille"); if(tg!==dern){ html+='<div class="sous">'+esc(tg)+'</div>'; dern=tg; } } html+='<div class="li"><span class="nom">'+esc(a.a)+'<span class="nv">'+(NIV[a.n]||"")+'</span>'+noteDe(a)+'</span>'+cellule(a)+'</div>'; });
    if(aut.length){
      html+='<div class="sous">60 s\'en occupe seul · '+aut.length+'</div>';
      aut.forEach(function(a){ html+='<div class="li l60"><span class="nom">'+esc(a.a)+'</span>'+cellule(a)+'</div>'; });
    }
    var nx=visibles[ib+1];
    html+='<div class="suite"><button data-suivant="'+(nx?nx.k:"")+'">'+(nx?'Bloc suivant : '+esc(nx.t):'Terminer et fermer')+
      '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="'+(nx?'M9 6l6 6-6 6':'M5 12l5 5 9-10')+'"/></svg></button></div>';
    html+='</div></section>';
  });
  $("liste").innerHTML = bandeau + (html || '<div class="empty">Aucune action.</div>');
}

/* Interactions */
$("liste").addEventListener("click",function(e){
  var b=e.target.closest(".bloc-btn");
  if(b){ ouvrir(etat.ouvert===b.dataset.k ? null : b.dataset.k); return; }
  var sv=e.target.closest("[data-suivant]");
  if(sv){ ouvrir(sv.dataset.suivant || null); if(!sv.dataset.suivant) window.scrollTo({top:0,behavior:"smooth"}); return; }
  var x=e.target.closest(".choix"); if(!x || x.disabled) return;
  var qui=x.dataset.qui, liste=activites();
  if(x.dataset.bloc){
    var k=x.dataset.bloc, libres=liste.filter(function(a){ return blocDe(a)===k && regle(a)==="libre"; });
    var tous=libres.every(function(a){ return choixDe(a)[qui]; });
    libres.forEach(function(a){
      var c=Object.assign({}, choixDe(a)); c[qui]=!tous;
      if(!c.moi && !c.cab) c[qui==="moi"?"cab":"moi"]=true;
      etat.resp[a.id]=c;
    });
  } else {
    var a=liste.filter(function(z){return z.id===x.dataset.id;})[0]; if(a) basculer(a,qui);
  }
  var y=window.scrollY; dessiner(); window.scrollTo(0,y);
});
$("resTot").addEventListener("click",function(e){ if(e.target.closest("[data-tout]")){ etat.tout=!etat.tout; etat.ouvert=null; dessiner(); } });
function ouvrir(k){
  if(etat.ouvert) etat.vus[etat.ouvert]=true;
  etat.ouvert=k; if(k) etat.vus[k]=true;
  dessiner();
  if(k){ var s=$("s-"+k); if(s) s.scrollIntoView({behavior:"smooth",block:"start"}); }
}
function hauteurBarre(){ document.documentElement.style.setProperty("--topH", document.querySelector(".top").offsetHeight+"px"); }
window.addEventListener("resize",hauteurBarre);
function aide(){ var b=$("bulle"), o=b.hidden; b.hidden=!o; $("btn60").setAttribute("aria-expanded",o); }
$("btn60").addEventListener("click",aide); $("btnAide").addEventListener("click",aide);
$("lang").addEventListener("change",function(e){ if(e.target.value!=="FR") montrer("La version anglaise et espagnole arrive bientôt. Le contenu reste en français pour l'instant."); e.target.value="FR"; });
var minuteur; function montrer(t){ var x=$("toast"); x.textContent=t; x.hidden=false; clearTimeout(minuteur); minuteur=setTimeout(function(){x.hidden=true;},4200); }
function choix(){
  return { profil:etat.profil, metier:etat.metier, cabinet:etat.cabinet,
    activites: activites().map(function(a){ var c=choixDe(a), s=statut(a);
      return { id:a.id, bloc:blocDe(a), activite:a.a, statut:s, moi: c?c.moi:false, cabinet: c?c.cab:false, partagee: s==="par" }; }) };
}
$("btnSave").addEventListener("click",function(){
  if(etat.lecture) return;
  var p=choix(), envoye=JSON.stringify(etat.resp); document.dispatchEvent(new CustomEvent("qfq:enregistrer",{detail:p}));
  if(!etat.urlEnregistrer || !window.fetch){ etat.sauve=envoye; dessiner(); montrer("C'est enregistré : "+p.activites.length+" actions réparties. Vous pourrez changer d'avis en tout temps."); return; }
  /* ERP : enregistré dans les paramètres de la compagnie ; « Enregistré » seulement quand le serveur l'a confirmé. */
  $("btnSave").disabled=true;
  fetch(etat.urlEnregistrer,{method:"POST",headers:{"Content-Type":"application/json"},credentials:"same-origin",body:JSON.stringify(p)})
    .then(function(r){ if(!r.ok) throw 0; etat.sauve=envoye; dessiner(); montrer("C'est enregistré : "+p.activites.length+" actions réparties. Vous pourrez changer d'avis en tout temps."); })
    .catch(function(){ dessiner(); montrer("L'enregistrement n'a pas pu être envoyé. Réessayez dans un instant."); });
});window.QuiFaitQuoi = { choix: choix };

lireContexte(); hauteurBarre(); dessiner();
