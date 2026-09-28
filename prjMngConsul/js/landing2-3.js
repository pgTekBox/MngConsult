
/*
  LE 60 — avatar de 60secondes et assistant de discussion (réponses générales).
  Dessin repris de « 60sec-AI-avatars-v5 » : le 6 et le 0 sont les yeux ; la couleur dit la situation.
  Aperçu : base de connaissances locale, aucune donnée transmise. À brancher plus tard sur Cortex.
*/
window.Av=(function(){
  var C={
    sarcelle:['#C8F7F1','#3DDCCB','#06524C'],
    violet:['#E4DAFF','#A78BFA','#34188A','#5B4BC4'],
    bleu:['#D2E9FF','#5AAEFF','#0B3F80','#2F6FD6'],
    vert:['#CFF7DF','#4ADE80','#0B5229','#1E9E5A'],
    rouge:['#FFC2C2','#FF5E5E','#7A0E0E','#C62E2E'],
    orange:['#FFE0B8','#FFA033','#6E3300','#E36B12'],
    jaune:['#FFF6C2','#FFDD33','#524000','#D9A300'],
    gris:['#EEF2F6','#B8C4D1','#2E3B48']
  };
  var X={ // expression : couleur, œil droit, bouche, pastille
    principal:{c:'sarcelle',eye:'blink',mouth:'M99 166 q29 16 58 0'},
    bonjour:{c:'sarcelle',eye:'happy',mouth:'M97 164 q31 24 62 0'},
    travail:{c:'sarcelle',eye:'spin',mouth:'M106 168 q22 6 44 0'},
    merci:{c:'sarcelle',eye:'heart',mouth:'M98 164 q30 22 60 0'},
    info:{c:'bleu',eye:'blink',mouth:'M103 166 q25 12 50 0',bdg:'i'},
    question:{c:'violet',eye:'ask',mouth:'M108 170 q20 6 40 -6',bdg:'?'},
    regle:{c:'vert',eye:'happy',mouth:'M97 164 q31 24 62 0',bdg:'ok'},
    probleme:{c:'rouge',eye:'blink',brow:'M144 74 l30 -9',mouth:'M103 178 q25 -14 50 0',bdg:'x'},
    urgent:{c:'orange',eye:'blink',brow:'M176 66 l-30 8',mouth:'M108 170 q20 0 40 0',bdg:'clock'},
    action:{c:'jaune',eye:'blink',brow:'M145 72 l30 -6',mouth:'M102 166 q26 12 52 0',bdg:'arrow'},
    pause:{c:'gris',eye:'closed',mouth:'M108 168 q20 4 40 0'}
  };
  var n=0;
  function svg(expr,size,label){
    var e=X[expr]||X.principal,c=C[e.c],k=c[2],id='avg'+(n++);
    var eye={
      blink:'<ellipse class="av-blink" cx="160" cy="110" rx="15" ry="25" fill="none" stroke="'+k+'" stroke-width="12"/>',
      happy:'<path d="M142 116 q18 -24 36 0" fill="none" stroke="'+k+'" stroke-width="12" stroke-linecap="round"/>',
      spin:'<ellipse class="av-spin" cx="160" cy="110" rx="21" ry="21" fill="none" stroke="'+k+'" stroke-width="12" stroke-dasharray="88 44" stroke-linecap="round"/>',
      heart:'<path d="M160 130 C136 114 142 92 153 92 C157 92 160 96 160 99 C160 96 163 92 167 92 C178 92 184 114 160 130 Z" fill="'+k+'"/>',
      closed:'<path d="M142 110 q18 10 36 0" fill="none" stroke="'+k+'" stroke-width="12" stroke-linecap="round"/>',
      ask:'<ellipse cx="162" cy="106" rx="15" ry="25" fill="none" stroke="'+k+'" stroke-width="12" transform="rotate(12 160 110)"/><path d="M148 68 q16 -9 30 0" fill="none" stroke="'+k+'" stroke-width="9" stroke-linecap="round"/>'
    }[e.eye];
    if(e.brow) eye+='<path d="'+e.brow+'" stroke="'+k+'" stroke-width="9" stroke-linecap="round"/>';
    var b='';
    if(e.bdg==='x') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><path d="M216 33.5 l17 17 M233 33.5 l-17 17" stroke="#fff" stroke-width="6" stroke-linecap="round"/>';
    if(e.bdg==='clock') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><circle cx="224.5" cy="42" r="11" fill="none" stroke="#fff" stroke-width="4.5"/><path d="M224.5 35.5 v7 l5 3" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>';
    if(e.bdg==='arrow') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><path d="M214 42 h19 M226 34.5 l7.5 7.5 l-7.5 7.5" fill="none" stroke="#fff" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round"/>';
    if(e.bdg==='?') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><text x="224.5" y="52" fill="#fff" font-family="Arial,Helvetica,sans-serif" font-size="27" font-weight="700" text-anchor="middle">?</text>';
    if(e.bdg==='i') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><rect x="221.5" y="39" width="6" height="16" rx="3" fill="#fff"/><circle cx="224.5" cy="31.5" r="3.8" fill="#fff"/>';
    if(e.bdg==='ok') b='<circle cx="224.5" cy="42" r="23" fill="'+c[3]+'" stroke="#fff" stroke-width="4"/><path d="M214 42 l7.5 7.5 l13 -15" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>';
    return '<svg class="av-inline" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="'+size+'" height="'+size+'" overflow="visible" '+(label?'role="img" aria-label="'+label+'"':'aria-hidden="true"')+'>'+
      '<defs><radialGradient id="'+id+'" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="'+c[0]+'"/><stop offset="1" stop-color="'+c[1]+'"/></radialGradient></defs>'+
      '<circle cx="128" cy="128" r="104" fill="url(#'+id+')"/><ellipse cx="96" cy="62" rx="44" ry="20" fill="#fff" opacity=".45" transform="rotate(-20 96 62)"/>'+
      '<circle cx="128" cy="128" r="102" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="3"/>'+
      '<circle cx="96" cy="120" r="16" fill="none" stroke="'+k+'" stroke-width="12"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="'+k+'" stroke-width="12" stroke-linecap="round"/>'+
      eye+'<path d="'+e.mouth+'" fill="none" stroke="'+k+'" stroke-width="10" stroke-linecap="round"/>'+b+'</svg>';
  }

  // --- base de connaissances (réponses générales ; renvois vers la page)
  var L=function(h,t){return '<a href="'+h+'" data-go>'+t+'</a>';};
  var KB=[
    {k:['hola','buenos','good','morning','hey','buenas','bonjour','salut','allo','hello','bonsoir','hi'],x:'bonjour',a:['Bonjour ! Posez-moi votre question sur 60secondes : prix, fonctions, transfert de vos données, sécurité, lancement…']},
    {k:['thanks','thank','great','perfect','gracias','perfecto','genial','merci','parfait','super','genial','excellent','cool'],x:'merci',a:['Avec plaisir ! Autre chose ?']},
    {k:['price','prices','pricing','cost','costs','how','much','plan','plans','subscription','precio','precios','costo','cuanto','cuesta','plan','suscripcion','prix','cout','coute','combien','tarif','forfait','abonnement','cher','mensualite'],x:'info',a:['Trois forfaits, les quatorze fonctions dans chacun : <b>79,99 $</b> par mois pour le travailleur autonome, <b>99,99 $</b> pour la société sans employé et <b>149,99 $</b> pour la société avec employés (4 employés inclus, puis 2 $ par employé). Prix avant TPS et TVQ.','Détails : '+L('#prix','les forfaits')+' · '+L('#note-2','note 2')+'.']},
    {k:['profile','which','choose','incorporated','selfemployed','freelancer','corporation','company','perfil','elegir','cual','empresa','autonomo','sociedad','profil','choisir','lequel','incorpore','incorporee','autonome','travailleur','societe','compagnie'],x:'principal',a:['Trois profils : <b>travailleur autonome</b> (vous facturez à votre nom), <b>société sans employé</b> (incorporé et seul) et <b>société avec employés</b> (de 1 à 49). Votre dossier suit votre entreprise si elle change de profil.','Comparez-les ici : '+L('#profils','trouver mon profil')+'.']},
    {k:['feature','features','function','functions','include','includes','payroll','invoicing','inventory','quote','funcion','funciones','incluye','nomina','facturacion','inventario','fonction','fonctions','inclus','inclut','module','faire','offre','inventaire','soumission','facturation','paie','horaire','poincon'],x:'principal',a:['Quatorze fonctions intégrées dans une seule base : Cortex, comptabilité et facturation, soumissions, inventaire, reçus, conciliation, paie, gestion des employés, horaires et poinçon, application mobile, agenda, courriel et texto, préparation des paiements et lien avec votre comptable.','Voir '+L('#fonctions','les quatorze fonctions')+'.']},
    {k:['ai','artificial','automated','automation','automatic','inteligencia','automatizado','automatica','cortex','ia','intelligence','artificielle','automatique','automatise','automatisee','robot','classe','classement'],x:'principal',a:['Cortex lit les factures et reçus qui arrivent dans la boîte de courriel de votre entreprise, les classe, fait les calculs et passe l\'écriture. Quand un cas est ambigu, il vous pose la question une seule fois ; votre réponse devient une règle.','Voir '+L('#cortex','Cortex')+' · '+L('#note-6','note 6')+'.']},
    {k:['transfer','migrate','import','switch','move','transferencia','migrar','importar','cambiar','transfert','transferer','migrer','migration','importer','quickbooks','sage','acomba','odoo','xero','commencee','cours','changer'],x:'info',a:['Votre année est en cours ? Nous transférons vos données — paie, clients, factures, reçus, fournisseurs — depuis QuickBooks, Sage, Acomba, Odoo et autres, sans frais. Vous le faites vous-même avec un agent IA, avec votre comptable ou avec un cabinet certifié 60secondes.','Voir '+L('#transfert','le transfert')+' · '+L('#note-14','note 14')+'.']},
    {k:['data','hosting','hosted','security','secure','privacy','law','server','encryption','datos','seguridad','privacidad','alojamiento','ley','donnee','donnees','heberge','hebergees','hebergement','securite','securitaire','loi','confidentialite','serveur','chiffrement','prive','vie'],x:'info',a:['Vos données sont hébergées et traitées au Québec et au Canada, chiffrées en transit et au repos, jamais vendues. Le modèle d\'IA qui aide Cortex est fourni par un tiers et exploité au Canada, selon les engagements de ce fournisseur ; il ne reçoit que des extraits minimisés, non conservés.','Voir '+L('#doc-confidentialite','la politique de confidentialité')+' · '+L('#note-5','note 5')+'.']},
    {k:['replace','accountant','need','reemplaza','contador','necesito','remplace','remplacer','cpa','besoin'],x:'principal',a:['Non, 60secondes ne remplace pas votre comptable : il fait la tenue et les calculs ; votre comptable garde la révision, le conseil et les déclarations. Vous pouvez l\'inviter dans votre dossier.','Voir '+L('#note-10','note 10')+'.']},
    {k:['firm','firms','accounting','bookkeeper','portal','fees','certified','firma','contable','contables','certificada','cabinet','partenaire','portail','commission','honoraires','bureau','comptable','comptables'],x:'principal',a:['Vous cherchez un comptable ? Invitez le vôtre, ou choisissez un cabinet certifié 60secondes dans l\'annuaire et réservez une rencontre. Dans les deux cas, il se connecte à votre dossier selon les permissions que vous fixez.','Vous êtes un cabinet ? La certification est sans frais ; aucune commission, vos honoraires restent les vôtres. Voir '+L('#cabinets','les cabinets certifiés')+'.']},
    {k:['payment','payments','pay','supplier','suppliers','money','pago','pagos','pagar','proveedor','proveedores','dinero','paiement','payer','paye','fournisseur','fournisseurs','virement','fonds','argent','interac'],x:'info',a:['60secondes calcule et prépare vos paiements. Vous déclenchez chaque paiement, ou vous autorisez votre cabinet comptable à le faire en votre nom. L\'exécution relèvera de 60sec-Paiement, société distincte, une fois ses autorisations obtenues.','Voir '+L('#note-4','note 4')+'.']},
    {k:['launch','when','available','start','signup','sign','register','trial','lanzamiento','cuando','disponible','registro','empezar','lancement','quand','disponible','date','ouverture','essai','inscrire','inscription','commencer','acces'],x:'info',a:['Lancement le 1<sup>er</sup> janvier 2027. L\'accès anticipé est ouvert : réservez votre place, sans paiement ni engagement.',L('#membres','Réserver mon accès')+' · '+L('#note-3','note 3')+'.']},
    {k:['language','languages','french','spanish','idioma','idiomas','ingles','frances','langue','langues','anglais','english','espagnol','espanol','francais','traduction'],x:'principal',a:['La plateforme travaille dans la langue de chacun : français, anglais ou espagnol, au choix de chaque utilisateur, sur le même dossier. Les pièces sont lues quelle que soit leur langue.']},
    {k:['appointment','appointments','book','booking','specialist','directory','cita','citas','reservar','especialista','rendez','rdv','reserver','reservation','specialiste','annuaire','trouver','pro'],x:'principal',a:['Vous cherchez un professionnel ? L\'annuaire permet de chercher par métier, ville ou code postal, puis de réserver, déplacer ou annuler en ligne, gratuitement.','Vous êtes entrepreneur ? Avec la fonction Agenda et rendez-vous, vos propres clients réservent avec vous en ligne, 24 heures sur 24. '+L('#specialistes','Voir comment')+'.']},
    {k:['employees','staff','size','large','empleados','tamano','grande','employes','50','grande','grosse','taille','maximum'],x:'info',a:['Le forfait Société avec employés couvre de 1 à 49 employés (4 inclus, puis 2 $ par employé et par mois). Les entreprises de 50 employés et plus ne sont pas desservies.','Voir '+L('#note-8','note 8')+'.']},
    {k:['phone','mobile','movil','celular','aplicacion','telefono','mobile','application','app','telephone','cellulaire','iphone','android'],x:'principal',a:['L\'application mobile vous permet de photographier vos reçus, et à vos employés de poinçonner, voir leur horaire et leurs talons de paie. Même compte, même base.','Voir '+L('#fonctions','les fonctions')+'.']},
    {k:['human','person','talk','contact','email','call','humano','persona','hablar','contacto','correo','llamar','humain','personne','parler','contact','contacter','joindre','courriel','appeler','agent','conseiller'],x:'info',a:['Pour parler à une personne, écrivez à <b>info@60secondes.ca</b> (cabinets comptables : <b>certifies@60secondes.ca</b>). Nous répondons en français, en anglais ou en espagnol.']}
  ];
  var CHIPS=['Combien ça coûte ?','Quel profil pour moi ?','Transférer mes données','Où sont mes données ?','Ça remplace mon comptable ?','Quand est le lancement ?'];
  function norm(s){return String(s||'').normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase().replace(/[^a-z0-9 ]+/g,' ');}
  function answer(q){
    var w=norm(q).split(/\s+/).filter(Boolean),best=null,score=0;
    KB.forEach(function(e){var s=0;w.forEach(function(x){if(e.k.some(function(k){return x===k||(k.length>4&&x.indexOf(k)===0);}))s++;});if(s>score){score=s;best=e;}});
    if(!best) return {x:'question',q:true,a:['Je ne suis pas certain de bien comprendre. Pouvez-vous reformuler ? Je réponds aux questions générales : prix, profils, fonctions, transfert de données, sécurité, lancement, cabinets, rendez-vous.','Pour une question précise sur votre situation, écrivez à <b>info@60secondes.ca</b>.']};
    return best;
  }

  // --- interface
  var $=function(id){return document.getElementById(id);},started=false,open=false;
  function scroll(){var l=$('chat-log');l.scrollTop=l.scrollHeight;}
  function setFace(x){$('chat-face').innerHTML=svg(x,40);}
  function bot(r){
    var d=document.createElement('div');d.className='msg-b'+(r.q?' q':'');
    d.innerHTML='<span>'+svg(r.x,30)+'</span><div class="bub">'+r.a.map(function(p){return '<p>'+p+'</p>';}).join('')+'</div>';
    $('chat-log').appendChild(d);
    d.querySelectorAll('[data-go]').forEach(function(a){a.addEventListener('click',function(){
      var h=a.getAttribute('href').slice(1),el=document.getElementById(h),dt=el&&(el.tagName==='DETAILS'?el:el.closest('details'));if(dt)dt.open=true;
      if(window.matchMedia('(max-width:520px)').matches) toggle(false);
    });});
    setFace(r.x==='merci'||r.x==='bonjour'?r.x:r.x==='question'?'question':'principal');scroll();
  }
  function chips(list){
    var d=document.createElement('div');d.className='chips-row';
    list.forEach(function(t){var b=document.createElement('button');b.type='button';b.textContent=t;b.addEventListener('click',function(){ask(t);d.remove();});d.appendChild(b);});
    $('chat-log').appendChild(d);scroll();
  }
  function ask(q){
    q=q.trim();if(!q)return;
    var u=document.createElement('div');u.className='msg-u';u.textContent=q;$('chat-log').appendChild(u);
    var t=document.createElement('div');t.className='msg-b';t.innerHTML='<span>'+svg('travail',30)+'</span><div class="bub typing" aria-label="Le 60 écrit"><span></span><span></span><span></span></div>';
    $('chat-log').appendChild(t);setFace('travail');scroll();
    setTimeout(function(){t.remove();var r=answer(q);bot(r);if(r.q)chips(CHIPS.slice(0,4));},550);
  }
  function toggle(v){
    open=v===undefined?!open:v;
    $('chat').hidden=!open;$('chat-fab').setAttribute('aria-expanded',String(open));
    $('chat-tease').hidden=true;
    if(open){
      if(!started){started=true;bot({x:'bonjour',a:['Bonjour ! Je suis <b>Le 60</b>, l\'assistant de 60secondes. Je réponds aux questions générales sur la plateforme.','Que voulez-vous savoir ?']});chips(CHIPS);}
      setTimeout(function(){$('chat-in').focus();},30);
    } else $('chat-fab').focus();
  }
  function early(){var h=document.querySelector('section.hero'),l=document.querySelector('.chat-launch');if(!h||!l)return;l.classList.toggle('early',h.getBoundingClientRect().bottom>80);}
  window.addEventListener('scroll',early,{passive:true});window.addEventListener('resize',early);setTimeout(early,0);
  function mount(){
    $('chat-fab').innerHTML=svg('principal',52,'Ouvrir la discussion avec Le 60, l\'assistant de 60secondes');
    $('chat-fab').addEventListener('click',function(){toggle();});
    $('chat-x').addEventListener('click',function(){toggle(false);});
    $('chat-tease-x').addEventListener('click',function(){$('chat-tease').hidden=true;});
    $('chat-f').addEventListener('submit',function(e){e.preventDefault();var i=$('chat-in');ask(i.value);i.value='';});
    document.addEventListener('keydown',function(e){if(e.key==='Escape'&&open)toggle(false);});
    setFace('principal');
  }
  // petits avatars dans la page (rebâtis à chaque changement de langue)
  function decorate(){document.querySelectorAll('[data-av]').forEach(function(s){s.innerHTML=svg(s.dataset.av,+(s.dataset.size||28));});}
  return {svg:svg,mount:mount,decorate:decorate,open:function(){toggle(true);}};
})();
