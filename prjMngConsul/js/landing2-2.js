
/* CORTEX — « votre journée » : démonstration de la communication Cortex ↔ client par Le 60. Données fictives. */
window.CxDay=(function(){
  var ORDER=['probleme','urgent','action','question','info','regle','travail','pause'];
  var D={
    ta:{who:'Marie',todo:[
        {lv:'urgent',t:'Remise TPS/TVQ due dans 2 jours',c:'1 842,16 $ calculés et prêts. Rien ne part sans vous.',b:[['Déclencher le paiement','main','Paiement de la TPS/TVQ déclenché.']]},
        {lv:'question',t:'Esso, 68,40 $ : affaires ou personnel ?',c:'Premier plein de ce mois-ci. Votre réponse vaudra pour les suivants.',b:[['Affaires','','Esso → déplacements d\'affaires. Règle créée.'],['Personnel','','Esso → personnel. Règle créée.']]},
        {lv:'action',t:'2 reçus à confirmer',c:'Bureau en Gros 42,18 $ · Adobe 29,99 $',b:[['Tout confirmer','main','2 reçus confirmés et classés.']]}],
      stakes:[['Revenus de l\'année','27 400 $','Seuil TPS/TVQ de 30 000 $ en vue','warn'],['TPS/TVQ mise de côté','1 842 $','Montant de la remise couvert','ok'],['Liquidités fin du mois','4 310 $','Après remise et abonnements','']],
      done:['36 pièces lues et classées ce matin','Facture n° 1042 payée par Ferme Duval — rapprochée','Rendez-vous de 14 h : facture préparée']},
    c0:{who:'Luc',todo:[
        {lv:'question',t:'Virement de 1 200 $ vers votre compte personnel',c:'Dividende, salaire ou remboursement de dépenses ? Le choix fiscal vous revient.',b:[['Dividende','','Classé en dividende ; relevé préparé pour la fin d\'année.'],['Salaire','','Classé en salaire ; retenues calculées.'],['Remboursement','','Classé en remboursement de dépenses.']]},
        {lv:'question',t:'Nouveau fournisseur « Tech Pro »',c:'Facture de 689,85 $. Quelle catégorie ?',b:[['Logiciels','','Tech Pro → logiciels. Règle créée.'],['Matériel informatique','','Tech Pro → matériel ; amortissement calculé.']]},
        {lv:'info',t:'Votre rapport mensuel est prêt',c:'Bénéfice de septembre : 6 240 $ (+ 12 %).',b:[['Vu','main','Rapport de septembre consulté.']]}],
      stakes:[['Acompte provisionnel du 15 déc.','2 100 $','Déjà réservé','ok'],['Compte de l\'actionnaire','3 800 $','La société vous doit ce montant',''],['Fin d\'exercice','dans 68 jours','Livres à jour à 97 %','ok']],
      done:['Relevés bancaires de septembre rapprochés : aucun écart','14 factures fournisseurs classées','TPS/TVQ du trimestre calculées']},
    c4:{who:'Nadia',todo:[
        {lv:'probleme',t:'Feuille de temps manquante',c:'Julie, semaine du 15 septembre. La paie part jeudi.',b:[['Relancer Julie','main','Rappel envoyé à Julie sur son application.']]},
        {lv:'urgent',t:'Paie de jeudi prête : 6 480 $',c:'4 employés. Fonds suffisants au compte.',b:[['Déclencher la paie','main','Paie déclenchée ; talons envoyés aux employés.']]},
        {lv:'question',t:'Julie a fait 44 h : les 4 h en plus ?',c:'Votre politique deviendra la règle pour l\'équipe.',b:[['Payées à 1,5×','','Heures supplémentaires payées. Règle créée.'],['En banque de temps','','Heures ajoutées à sa banque. Règle créée.']]}],
      stakes:[['DAS dues le 15 octobre','2 214 $','Montant calculé, à déclencher','warn'],['Chantier Tremblay','71 %','du budget de main-d\'œuvre utilisé',''],['Liquidités après la paie','11 930 $','Suffisantes pour octobre','ok']],
      done:['52 pièces lues et classées cette semaine','Heures de 3 employés transférées dans la paie','Facture du chantier Gagnon envoyée']}
  };
  var st={p:'ta',todo:[],done:[],fresh:[]};
  var MSG={probleme:'Un problème à régler maintenant.',urgent:'Une échéance arrive très bientôt.',action:'Une action à poser, sans urgence.',question:'Cortex a besoin de votre décision.',info:'Une information pour vous.',regle:'Tout est en ordre. Bonne journée !'};
  function $(id){return document.getElementById(id);}
  function sv(x,n){return window.Av?window.Av.svg(x,n):'';}
  function reset(p){st.p=p||st.p;var d=D[st.p];st.todo=d.todo.slice();st.done=d.done.slice();st.fresh=[];}
  function top(){var lv='regle';st.todo.forEach(function(i){if(ORDER.indexOf(i.lv)<ORDER.indexOf(lv))lv=i.lv;});return lv;}
  function render(pop){
    if(!$('cx-todo'))return;
    var d=D[st.p],lv=top(),n=st.todo.length;
    var f=$('cx-face');f.innerHTML=sv(lv==='regle'?'regle':lv,84);if(pop){f.classList.remove('pop');void f.offsetWidth;f.classList.add('pop');}
    $('cx-hi').textContent=n?'Bonjour '+d.who+'.':'Merci, '+d.who+' !';
    $('cx-sum').textContent=n?(n+(n>1?' actions':' action')+' aujourd\'hui. '+MSG[lv]):MSG.regle;
    document.querySelectorAll('.cx-ladder li').forEach(function(li){li.classList.toggle('on',li.dataset.lv===lv);});
    var ul=$('cx-todo');ul.innerHTML='';
    if(!n) ul.innerHTML='<li class="cx-empty">Rien d\'autre à faire aujourd\'hui. Cortex continue en coulisse.</li>';
    st.todo.slice().sort(function(a,b){return ORDER.indexOf(a.lv)-ORDER.indexOf(b.lv);}).forEach(function(it){
      var li=document.createElement('li');li.className='cx-item';li.dataset.lv=it.lv;
      li.innerHTML='<span>'+sv(it.lv,28)+'</span><div><p class="tt"></p><p class="ct"></p><div class="bt"></div></div>';
      li.querySelector('.tt').textContent=it.t;li.querySelector('.ct').textContent=it.c;
      it.b.forEach(function(b){var bt=document.createElement('button');bt.type='button';bt.textContent=b[0];if(b[1])bt.className=b[1];
        bt.addEventListener('click',function(){st.todo=st.todo.filter(function(x){return x!==it;});st.fresh.unshift(b[2]);render(true);});
        li.querySelector('.bt').appendChild(bt);});
      ul.appendChild(li);
    });
    $('cx-stakes').innerHTML=d.stakes.map(function(s){return '<li class="cx-stake"><span>'+s[0]+'<small>'+s[2]+'</small></span><b class="'+s[3]+'">'+s[1]+'</b></li>';}).join('');
    $('cx-done').innerHTML=st.fresh.map(function(t){return '<li class="new">'+sv('regle',20)+'<span>'+t+'</span></li>';}).join('')+st.done.map(function(t){return '<li>'+sv('travail',20)+'<span>'+t+'</span></li>';}).join('');
    document.querySelectorAll('[data-cxp]').forEach(function(b){b.setAttribute('aria-pressed',String(b.dataset.cxp===st.p));});
  }
  function set(p){if(!D[p]||p===st.p&&st.todo.length)return render();reset(p);render(true);}
  function mount(){
    if(!$('cortex'))return;
    if(!st.todo.length&&!st.fresh.length)reset(st.p);
    document.querySelectorAll('[data-cxp]').forEach(function(b){b.addEventListener('click',function(){reset(b.dataset.cxp);render(true);});});
    $('cx-reset').addEventListener('click',function(){reset();render(true);});
    render(false);
  }
  return {mount:mount,set:set};
})();
