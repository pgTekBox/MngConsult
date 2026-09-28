
/*
  ANNUAIRE DES SPÉCIALISTES — aperçu autonome.
  Données fictives en mémoire ; disponibilités déterministes (FNV-1a).
  Brancher plus tard : listerPros / plages / creer / deplacer / annuler → API serveur.
  Les réservations d'essai sont gardées dans le stockage local (cet appareil seulement).
*/
window.Annuaire=(function(){
  var HORIZON=42, LEAD_MIN=120, KEY='60s-rdv';
  var IND=[['sante','Santé'],['travaux','Travaux et rénovation'],['beaute','Beauté et bien-être'],['pro','Services professionnels'],['auto','Automobile'],['animaux','Animaux'],['cours','Cours et formation']];
  var INDL={}; IND.forEach(function(i){INDL[i[0]]=i[1];});
  var CITY={'Montréal':[45.508,-73.587],'Laval':[45.570,-73.720],'Longueuil':[45.531,-73.518],'Québec':[46.813,-71.225],'Lévis':[46.790,-71.180],'Gatineau':[45.477,-75.701],'Sherbrooke':[45.404,-71.893],'Trois-Rivières':[46.343,-72.543],'Saguenay':[48.428,-71.068],'Saint-Jérôme':[45.780,-74.003],'Granby':[45.400,-72.733],'Drummondville':[45.883,-72.484],'Rimouski':[48.449,-68.524],'Ottawa':[45.421,-75.697],'Toronto':[43.653,-79.383],'London':[42.984,-81.246],'Sudbury':[46.492,-80.993],'Winnipeg':[49.895,-97.138],'Regina':[50.445,-104.618],'Saskatoon':[52.157,-106.670],'Calgary':[51.045,-114.057],'Edmonton':[53.546,-113.494],'Vancouver':[49.283,-123.121],'Victoria':[48.428,-123.365],'Halifax':[44.649,-63.575],'Moncton':[46.088,-64.778],'Charlottetown':[46.238,-63.131],"St. John's":[47.561,-52.713],'Whitehorse':[60.721,-135.057],'Yellowknife':[62.454,-114.372],'Iqaluit':[63.748,-68.517]};
  var FSA=[[/^H7/,'Laval'],[/^H/,'Montréal'],[/^J4[B-Z]/,'Longueuil'],[/^J[89]/,'Gatineau'],[/^J1/,'Sherbrooke'],[/^(J7[YZ]|J5L)/,'Saint-Jérôme'],[/^J2[GHJ]/,'Granby'],[/^J2[ABCE]/,'Drummondville'],[/^G[123]/,'Québec'],[/^(G6[V-Z]|G7A)/,'Lévis'],[/^G7/,'Saguenay'],[/^(G8[T-Z]|G9[ABC])/,'Trois-Rivières'],[/^G5[LMN]/,'Rimouski'],[/^K[12]/,'Ottawa'],[/^T[56]/,'Edmonton'],[/^V[89]/,'Victoria'],[/^S7/,'Saskatoon'],[/^X0A/,'Iqaluit'],[/^X1/,'Yellowknife']];
  var FSA_REGION={A:"St. John's",B:'Halifax',C:'Charlottetown',E:'Moncton',G:'Québec',H:'Montréal',J:'Montréal',K:'Ottawa',L:'Toronto',M:'Toronto',N:'London',P:'Sudbury',R:'Winnipeg',S:'Regina',T:'Calgary',V:'Vancouver',X:'Yellowknife',Y:'Whitehorse'};
  function S(id,nom,ent,spec,ind,ville,quartier,tel,lieu,langues,jours,debut,fin,dens,annul,services){
    return {id:id,nom:nom,ent:ent,spec:spec,ind:ind,ville:ville,quartier:quartier,tel:tel,lieu:lieu,langues:langues,jours:jours,debut:debut,fin:fin,dens:dens,annul:annul,
      services:services.map(function(s,i){return {id:id+'-'+i,nom:s[0],duree:s[1],prix:s[2]};})};
  }
  var W=[1,2,3,4,5], W6=[1,2,3,4,5,6], T6=[2,3,4,5,6];
  var PROS=[
    S('p01','Émilie Roy','Clinique Physio Plateau','Physiothérapeute','sante','Montréal','Plateau-Mont-Royal','514 555-0101','En clinique',['FR','EN'],W,8,19,52,24,[['Évaluation initiale',60,110],['Traitement de suivi',30,75]]),
    S('p28','Julie Gagnon','Massothérapie Équilibre','Massothérapeute','sante','Montréal','Rosemont','514 555-0128','En clinique',['FR','EN'],W6,9,20,50,24,[['Massage suédois',60,95],['Massage thérapeutique',90,130]]),
    S('p02','Jérôme Côté','Ostéo Limoilou','Ostéopathe','sante','Québec','Limoilou','418 555-0102','En clinique',['FR'],T6,9,18,48,24,[['Consultation',60,105],['Suivi',30,70]]),
    S('p03','Karine Bouchard','Massothérapie Rive-Sud','Massothérapeute','sante','Longueuil','Vieux-Longueuil','450 555-0103','En clinique',['FR','EN'],W6,9,20,45,24,[['Massage suédois 60 min',60,95],['Massage suédois 90 min',90,130]]),
    S('p04','Sophie Lefebvre','Chiro Laval-des-Rapides','Chiropraticienne','sante','Laval','Laval-des-Rapides','450 555-0104','En clinique',['FR','EN'],W,8,18,55,24,[['Premier examen',60,85],['Ajustement',30,60]]),
    S('p05','Amélie Nguyen','Nutrition Plein Sens','Nutritionniste-diététiste','sante','Sherbrooke','Fleurimont','819 555-0105','En cabinet ou en vidéo',['FR','EN'],W,9,17,50,48,[['Première rencontre',60,120],['Suivi',30,70]]),
    S('p06','Hugo Pelletier','Optométrie Centre-ville','Optométriste','sante','Gatineau','Hull','819 555-0106','En clinique',['FR','EN'],W6,9,17,45,24,[['Examen de la vue',30,null],['Ajustement de lunettes',30,0]]),
    S('p07','Isabelle Gauthier','Clinique dentaire des Forges','Dentiste','sante','Trois-Rivières','Centre-ville','819 555-0107','En clinique',['FR'],W,8,17,38,48,[['Examen et nettoyage',60,null],['Consultation',30,null]]),
    S('p08','Maxime Girard','Kinésiologie Mouvement','Kinésiologue','sante','Lévis','Desjardins','418 555-0108','En studio',['FR'],W6,7,19,50,12,[['Évaluation',60,90],['Séance d\'entraînement',60,75]]),
    S('p09','Luc Tremblay','Plomberie Tremblay et fils','Maître plombier','travaux','Laval','Chomedey','450 555-0109','À domicile (rayon de 25 km)',['FR','EN'],W,7,16,40,24,[['Estimation à domicile',60,0],['Réparation, première heure',60,115]]),
    S('p10','Nadia Morin','Électricité Voltaire','Maître électricienne','travaux','Montréal','Rosemont','514 555-0110','À domicile',['FR','EN'],W,7,16,42,24,[['Estimation',30,0],['Diagnostic',60,125]]),
    S('p11','Samuel Ouellet','Peinture Couleur Nord','Peintre en bâtiment','travaux','Saint-Jérôme','Centre','450 555-0111','À domicile',['FR'],W6,8,17,45,24,[['Estimation',60,0]]),
    S('p12','Patrice Lavoie','Ébénisterie Boréale','Ébéniste','travaux','Saguenay','Chicoutimi','418 555-0112','À l\'atelier ou à domicile',['FR'],W,8,16,40,24,[['Consultation à l\'atelier',60,0],['Prise de mesures à domicile',60,75]]),
    S('p13','Marc-André Beaulieu','Toitures Beaulieu','Couvreur','travaux','Québec','Charlesbourg','418 555-0113','À domicile',['FR'],W,7,16,35,48,[['Estimation',30,0],['Inspection de toiture',60,150]]),
    S('p14','Catherine Dion','Paysagement Les Cèdres','Paysagiste','travaux','Granby','Centre','450 555-0114','À domicile',['FR','EN'],W6,8,17,45,24,[['Visite-conseil',60,80]]),
    S('p15','Olivier Fortin','Réno Drummond','Entrepreneur général','travaux','Drummondville','Saint-Charles','819 555-0115','À domicile',['FR'],W,7,17,38,24,[['Estimation de projet',60,0]]),
    S('p16','Valérie Poirier','Salon Mèche Rebelle','Coiffeuse','beaute','Montréal','Villeray','514 555-0116','En salon',['FR','EN','ES'],T6,9,20,40,12,[['Coupe',30,45],['Coupe et couleur',120,140]]),
    S('p17','Sarah Bergeron','Esthétique Lumina','Esthéticienne','beaute','Québec','Saint-Roch','418 555-0117','En institut',['FR'],T6,10,19,45,24,[['Soin du visage',60,90],['Épilation sourcils',30,25]]),
    S('p18','Antoine Caron','Barbier du Vieux-Longueuil','Barbier','beaute','Longueuil','Vieux-Longueuil','450 555-0118','En salon',['FR','EN'],T6,9,19,50,4,[['Coupe',30,35],['Coupe et barbe',60,55]]),
    S('p19','Hélène Martel','Martel Notaire','Notaire','pro','Sherbrooke','Centre-ville','819 555-0119','Au bureau ou en vidéo',['FR','EN'],W,9,17,45,24,[['Première consultation',30,0],['Rencontre testament et mandat',60,null]]),
    S('p20','Julien Paquette','Studio Clic','Photographe','pro','Gatineau','Aylmer','819 555-0120','En studio',['FR','EN'],[2,3,4,5,6,0],10,18,40,48,[['Séance portrait',60,175],['Photo de profil professionnelle',30,95]]),
    S('p21','Stéphane Leclerc','Garage Mécanique du Fleuve','Mécanicien','auto','Rimouski','Saint-Germain','418 555-0121','Au garage',['FR'],W6,8,17,45,4,[['Changement d\'huile',30,79],['Inspection complète',60,99],['Pose de pneus',60,80]]),
    S('p22','Kevin Lapointe','Esthétique Auto Brillance','Esthétique automobile','auto','Laval','Sainte-Rose','450 555-0122','À l\'atelier',['FR','EN'],W6,8,18,45,24,[['Lavage intérieur et extérieur',120,180],['Lavage extérieur',60,70]]),
    S('p23','Mélanie Simard','Toilettage Pattes de velours','Toiletteuse','animaux','Lévis','Saint-Nicolas','418 555-0123','En salon',['FR'],T6,8,17,45,24,[['Toilettage petit chien',90,75],['Bain et brossage',60,50]]),
    S('p25','Geneviève Lachance','Lachance CPA inc.','Cabinet comptable certifié 60secondes · CPA','pro','Montréal','Ahuntsic','514 555-0125','Au bureau ou en vidéo',['FR','EN'],W,8,17,45,24,[['Rencontre découverte',30,0],['Transfert vers 60secondes et soldes d\'ouverture',60,150],['Revue de fin d\'exercice',60,null]]),
    S('p26','Philippe Gagnon','Gagnon Bérubé comptables','Cabinet comptable certifié 60secondes · CPA','pro','Québec','Sainte-Foy','418 555-0126','Au bureau ou en vidéo',['FR'],W,8,17,40,24,[['Rencontre découverte',30,0],['Tenue de livres et révision mensuelle',60,null]]),
    S('p27','Marie-Ève Tanguay','Tanguay Comptabilité','Cabinet comptable certifié 60secondes','pro','Sherbrooke','Jacques-Cartier','819 555-0127','En vidéo',['FR','EN'],W,9,16,45,24,[['Rencontre découverte',30,0],['Démarrage : taxes et paie',60,120]]),
    S('p24','Gabriel Dubois','École de musique Allegro','Professeur de piano','cours','Trois-Rivières','Cap-de-la-Madeleine','819 555-0124','Au studio ou en vidéo',['FR','EN'],[1,2,3,4,6],13,21,40,24,[['Cours d\'essai',30,0],['Cours de piano',60,60]])
  ];
  var BYID={}; PROS.forEach(function(p){BYID[p.id]=p;p.tel=p.tel.replace(' ','\u00a0');});

  var bookings=load();
  var st={q:'',ville:'',cp:'',rad:'25',ind:'',soon:false,sort:'next',shown:9};
  var ctx=null, $=function(id){return document.getElementById(id);}, deb=null;

  // --- outils
  function load(){try{var v=JSON.parse(localStorage.getItem(KEY));return Array.isArray(v)?v:[];}catch(e){return [];}}
  function save(){try{localStorage.setItem(KEY,JSON.stringify(bookings));}catch(e){}}
  function fnv(s){var h=0x811c9dc5;for(var i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}h^=h>>>16;h=Math.imul(h,0x85ebca6b);h^=h>>>13;return h>>>0;}
  function norm(s){return String(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();}
  function esc(s){return String(s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];});}
  function pad(n){return (n<10?'0':'')+n;}
  function dkey(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate());}
  function fromKey(k){var a=k.split('-');return new Date(+a[0],+a[1]-1,+a[2]);}
  function today(){var d=new Date();d.setHours(0,0,0,0);return d;}
  function addDays(d,n){var x=new Date(d);x.setDate(x.getDate()+n);return x;}
  function hm(m){var h=Math.floor(m/60),r=m%60;return h+' h'+(r?' '+pad(r):'');}
  function dayShort(d){return d.toLocaleDateString('fr-CA',{weekday:'short',day:'numeric',month:'short'});}
  function dayLong(d){var s=d.toLocaleDateString('fr-CA',{weekday:'long',day:'numeric',month:'long'});return s.charAt(0).toUpperCase()+s.slice(1);}
  function when(k,m){return dayLong(fromKey(k))+', '+hm(m);}
  function startOf(b){var d=fromKey(b.date);d.setMinutes(b.start);return d;}
  function price(p){return p===null?'Tarif au rendez-vous':p===0?'Gratuit':p.toFixed(2).replace('.',',').replace(',00','')+'\u00a0$';}
  function initials(p){return p.nom.split(/[\s-]+/).map(function(w){return w.charAt(0);}).slice(0,2).join('');}
  function svcOf(b){var p=BYID[b.pro];return p&&p.services.filter(function(s){return s.id===b.svc;})[0];}
  function upcoming(){var now=Date.now();return bookings.filter(function(b){return b.statut==='confirmée'&&startOf(b).getTime()>now;});}

  // --- disponibilités
  function plages(p,svc,d,exclude){
    var k=dkey(d);
    if(p.jours.indexOf(d.getDay())<0) return [];
    if(fnv(p.id+'|off|'+k)%100<10) return [];            // congé ponctuel
    var free={},m,a=p.debut*60,z=p.fin*60;
    for(m=a;m<z;m+=30) free[m]=fnv(p.id+'|'+k+'|'+m)%100<p.dens;
    bookings.forEach(function(b){
      if(b.pro!==p.id||b.date!==k||b.statut!=='confirmée'||b.code===exclude) return;
      var s=svcOf(b),e=b.start+(s?s.duree:30);
      for(var x=b.start;x<e;x+=30) free[x]=false;
    });
    var min=Date.now()+delai(p)*60000, out=[];
    for(m=a;m+svc.duree<=z;m+=30){
      var ok=true;for(var x=m;x<m+svc.duree;x+=30) if(!free[x]){ok=false;break;}
      if(ok){var t=new Date(d);t.setMinutes(m);if(t.getTime()>=min) out.push(m);}
    }
    return out;
  }
  function delai(p){return [LEAD_MIN,LEAD_MIN,240,720,1440][fnv(p.id+'|lead')%5];}
  function prochaine(p){
    var t=today(),svc=p.services[0];
    for(var i=0;i<HORIZON;i++){var d=addDays(t,i),s=plages(p,svc,d);if(s.length) return {d:d,m:s[0],i:i};}
    return null;
  }

  // --- géographie
  function geo(cp){
    var c=cp.toUpperCase().replace(/\s+/g,'');
    if(!c) return {none:true};
    if(!/^[A-Z]\d[A-Z](\d[A-Z]\d)?$/.test(c)) return {bad:true};
    for(var i=0;i<FSA.length;i++) if(FSA[i][0].test(c)) return {ville:FSA[i][1],pos:CITY[FSA[i][1]]};
    var r=FSA_REGION[c.charAt(0)];
    return r?{ville:r,pos:CITY[r],approx:true}:{out:true};
  }
  function posPro(p){var c=CITY[p.ville],j=fnv(p.id);return [c[0]+((j%100)-50)/1400,c[1]+(((j>>>8)%100)-50)/1000];}
  function km(a,b){var R=6371,r=Math.PI/180,dl=(b[0]-a[0])*r,dg=(b[1]-a[1])*r,x=Math.sin(dl/2)*Math.sin(dl/2)+Math.cos(a[0]*r)*Math.cos(b[0]*r)*Math.sin(dg/2)*Math.sin(dg/2);return 2*R*Math.asin(Math.sqrt(x));}

  // --- recherche
  function chercher(){
    var words=norm(st.q).split(' ').filter(Boolean), g=geo(st.cp), rad=+st.rad, out=[];
    PROS.forEach(function(p){
      if(st.ind&&p.ind!==st.ind) return;
      if(st.ville&&p.ville!==st.ville) return;
      var hay=norm([p.nom,p.ent,p.spec,INDL[p.ind],p.ville,p.quartier].concat(p.services.map(function(s){return s.nom;})).join(' '));
      for(var i=0;i<words.length;i++) if(hay.indexOf(words[i])<0) return;
      var dist=g.pos?km(g.pos,posPro(p)):null;
      if(dist!==null&&rad&&dist>rad) return;
      var nx=prochaine(p);
      if(st.soon&&!(nx&&nx.i<7)) return;
      out.push({p:p,dist:dist,nx:nx});
    });
    var key=function(r){return r.nx?r.nx.d.getTime()+r.nx.m*60000:Infinity;};
    out.sort(function(a,b){
      if(st.sort==='dist'&&a.dist!==null) return a.dist-b.dist||key(a)-key(b);
      if(st.sort==='nom') return a.p.ent.localeCompare(b.p.ent,'fr');
      return key(a)-key(b)||a.p.ent.localeCompare(b.p.ent,'fr');
    });
    return {rows:out,g:g};
  }
  function renderResults(){
    var r=chercher(),box=$('an-results'),msg=$('an-cp-msg'),g=r.g;
    msg.textContent=g.bad?'Format attendu : A1A ou A1A 1A1.':g.out?'Code postal non reconnu : vérifiez la première lettre.':g.approx?'Code postal reconnu par région seulement : distances calculées depuis '+g.ville+'.':g.ville?'Distances calculées depuis le secteur de '+g.ville+'.':'';
    var n=r.rows.length;
    $('an-status').textContent=n===0?'Aucun spécialiste ne correspond.':n+(n>1?' spécialistes trouvés':' spécialiste trouvé');
    if(!n){box.innerHTML='<p class="an-empty">Aucun résultat. Essayez un autre mot, une autre industrie ou un rayon plus grand.</p>';return;}
    box.innerHTML=r.rows.slice(0,st.shown).map(function(x){
      var p=x.p,nx=x.nx;
      return '<article class="an-card"><div class="an-who"><span class="an-av" aria-hidden="true">'+esc(initials(p))+'</span><div><h3>'+esc(p.ent)+'</h3><p class="sp">'+esc(p.nom)+' · '+esc(p.spec)+'</p></div></div>'+
        '<div class="an-meta"><span><span aria-hidden="true">📍 </span>'+esc(p.ville)+' · '+esc(p.quartier)+(x.dist!==null?' · <strong>'+(x.dist<1?'moins de 1':Math.round(x.dist))+'&nbsp;km</strong>':'')+'</span><span>'+esc(p.lieu)+'</span><span>'+esc(INDL[p.ind])+' · '+p.langues.join(' · ')+'</span></div>'+
        (nx?'<p class="an-next"><b>Prochaine plage</b>'+esc(dayShort(nx.d))+', '+hm(nx.m)+'</p>':'<p class="an-next none"><b>Aucune plage</b>Complet pour les 6 prochaines semaines</p>')+
        '<button type="button" class="btn btn-primary" data-an-open="'+p.id+'"'+(nx?'':' disabled')+'>Voir les plages et réserver</button></article>';
    }).join('')+(n>st.shown?'<button type="button" class="btn btn-ghost an-more" id="an-more">Afficher '+Math.min(9,n-st.shown)+' de plus ('+(n-st.shown)+' restants)</button>':'');
    box.querySelectorAll('[data-an-open]').forEach(function(b){b.addEventListener('click',function(){ouvrir(b.dataset.anOpen);});});
    var more=$('an-more'); if(more) more.addEventListener('click',function(){st.shown+=9;renderResults();});
  }
  function badge(){var n=upcoming().length,b=$('an-count');if(!b)return;b.hidden=!n;b.textContent=n;}

  // --- fenêtre de réservation
  function dlgOpen(){var f=$('an-find');if(!f)return;if(!f.open){f.dataset.from='direct';if(f.showModal)f.showModal();else f.setAttribute('open','');document.documentElement.style.overflow='hidden';}else if($('an-dlg').hidden)f.dataset.from='search';$('an-full').hidden=true;$('an-dlg').hidden=false;$('an-x-t').textContent=f.dataset.from==='search'?'Retour aux résultats':'Rechercher un professionnel';}
  function toSearch(){var f=$('an-find');$('an-dlg').hidden=true;$('an-full').hidden=false;ctx=null;f.dataset.from='search';f.scrollTop=0;var q=$('an-q');if(q)q.focus({preventScroll:true});}
  function dlgClose(){var f=$('an-find');if(f.dataset.from==='direct'){if(f.close&&f.open)f.close();else f.removeAttribute('open');}else toSearch();}
  function header(p,title,sub){
    $('an-dlg-av').textContent=p?initials(p):'';$('an-dlg-av').hidden=!p;
    $('an-dlg-h').textContent=title;$('an-dlg-sub').textContent=sub||'';
  }
  function body(html,focusSel){
    var b=$('an-body');b.innerHTML=html;$('an-find').scrollTop=0;
    var f=b.querySelector(focusSel||'h4');if(f){if(f.tagName==='H4')f.tabIndex=-1;f.focus({preventScroll:true});}
  }
  function stepper(n){
    var L=['Service','Plage','Coordonnées','Confirmation'];
    return '<p class="an-stepper" aria-label="Étape '+n+' sur 4">'+L.map(function(l,i){return '<span class="'+(i+1<=n?'on':'')+'">'+(i+1<n?'✓ ':(i+1)+' · ')+l+'</span>';}).join('')+'</p>';
  }
  function sub(p){return p.nom+' · '+p.spec+' · '+p.ville;}
  function policy(p){return 'Changement ou annulation en ligne sans frais jusqu\'à '+p.annul+'\u00a0h avant le rendez-vous. Ensuite : '+p.tel+'.';}

  function ouvrir(id){
    var p=BYID[id]; ctx={mode:'book',p:p,svc:null,week:0,day:null,m:null};
    header(p,p.ent,sub(p)); dlgOpen();
    if(p.services.length===1){ctx.svc=p.services[0];return etapePlage();}
    etapeService();
  }
  function etapeService(){
    var p=ctx.p;
    body(stepper(1)+'<h4>Quel service&nbsp;?</h4><div class="an-svc" role="radiogroup" aria-label="Services">'+p.services.map(function(s,i){
      var on=ctx.svc?ctx.svc.id===s.id:i===0;
      return '<label><input type="radio" name="an-svc" value="'+s.id+'"'+(on?' checked':'')+'><span>'+esc(s.nom)+'<span class="d">'+(s.duree>=60?(s.duree/60)+'\u00a0h'+(s.duree%60?' 30':''):s.duree+'\u00a0min')+' · '+esc(p.lieu)+'</span></span><span class="p">'+price(s.prix)+'</span></label>';
    }).join('')+'</div><p class="an-policy">'+esc(policy(p))+' Aucun paiement en ligne : vous réglez directement le professionnel.</p><div class="an-actions"><button type="button" class="btn btn-primary" id="an-go">Voir les plages libres</button></div>');
    $('an-go').addEventListener('click',function(){
      var r=document.querySelector('input[name="an-svc"]:checked');
      ctx.svc=p.services.filter(function(s){return s.id===r.value;})[0]; ctx.week=0; ctx.day=null; etapePlage();
    });
  }
  function etapePlage(){
    var p=ctx.p,svc=ctx.svc,t=today(),ws=addDays(t,ctx.week*7),days=[],i,first=null;
    for(i=0;i<7;i++){var d=addDays(ws,i),s=plages(p,svc,d,ctx.mode==='move'?ctx.code:null);days.push({d:d,s:s});if(s.length&&first===null)first=i;}
    if(ctx.day===null||!days[ctx.day]||!days[ctx.day].s.length) ctx.day=first;
    var maxW=Math.floor((HORIZON-1)/7), moving=ctx.mode==='move', cur=moving?ctx.old:null;
    var head=moving?'<h4>Choisir une nouvelle plage</h4><div class="an-recap" style="margin-bottom:14px"><span>Rendez-vous actuel · '+esc(svc.nom)+'</span><b>'+esc(when(cur.date,cur.start))+'</b></div>'
      :stepper(2)+'<h4>'+esc(svc.nom)+' · choisissez une plage</h4>';
    var html=head+'<div class="an-weeknav"><button type="button" id="an-prev" aria-label="Semaine précédente"'+(ctx.week?'':' disabled')+'>‹</button><span aria-live="polite">Du '+esc(dayShort(days[0].d))+' au '+esc(dayShort(days[6].d))+'</span><button type="button" id="an-next" aria-label="Semaine suivante"'+(ctx.week<maxW?'':' disabled')+'>›</button></div>';
    html+='<div class="an-days" role="group" aria-label="Jours">'+days.map(function(x,i){
      var n=x.s.length,lbl=dayLong(x.d)+(n?', '+n+' plage'+(n>1?'s':'')+' libre'+(n>1?'s':''):', aucune plage');
      return '<button type="button" class="an-day" data-i="'+i+'" aria-pressed="'+(i===ctx.day)+'" aria-label="'+esc(lbl)+'"'+(n?'':' disabled')+'><span class="w">'+esc(x.d.toLocaleDateString('fr-CA',{weekday:'short'}).replace('.',''))+'</span><span class="d">'+x.d.getDate()+'</span><span class="c">'+(n?n:'—')+'</span></button>';
    }).join('')+'</div>';
    if(ctx.day===null) html+='<p class="an-warn">Aucune plage libre cette semaine. Passez à la semaine suivante.</p>';
    else{
      var dd=days[ctx.day],ck=dkey(dd.d);
      html+='<div class="an-slots" role="group" aria-label="Plages du '+esc(dayLong(dd.d))+'"><p class="lbl">'+esc(dayLong(dd.d))+'</p>'+dd.s.map(function(m){
        if(moving&&cur.date===ck&&cur.start===m) return '<span class="an-slot cur" title="Plage actuelle">'+hm(m)+'<span class="sr"> (plage actuelle)</span></span>';
        return '<button type="button" class="an-slot" data-m="'+m+'" aria-label="'+esc(dayLong(dd.d)+', '+hm(m)+' à '+hm(m+svc.duree))+'">'+hm(m)+'</button>';
      }).join('')+'</div>';
    }
    html+='<div class="an-actions">'+(moving?'<button type="button" class="btn btn-ghost" id="an-back">Garder mon rendez-vous</button>':(ctx.p.services.length>1?'<button type="button" class="btn btn-ghost" id="an-back">‹ Changer de service</button>':''))+'</div>';
    body(html);
    $('an-prev').addEventListener('click',function(){ctx.week--;ctx.day=null;etapePlage();});
    $('an-next').addEventListener('click',function(){ctx.week++;ctx.day=null;etapePlage();});
    $('an-body').querySelectorAll('.an-day').forEach(function(b){b.addEventListener('click',function(){ctx.day=+b.dataset.i;etapePlage();var s=$('an-body').querySelector('.an-slot');if(s)s.focus();});});
    $('an-body').querySelectorAll('.an-slot').forEach(function(b){b.addEventListener('click',function(){
      ctx.date=dkey(days[ctx.day].d); ctx.m=+b.dataset.m;
      if(moving) etapeDeplacer(); else etapeInfo();
    });});
    var back=$('an-back'); if(back) back.addEventListener('click',function(){ if(moving) gerer(ctx.code); else etapeService(); });
  }
  function etapeInfo(){
    var p=ctx.p,svc=ctx.svc,sante=p.ind==='sante',v=ctx.form||{};
    body(stepper(3)+'<h4>Vos coordonnées</h4><div class="an-recap"><span>'+esc(svc.nom)+' · '+price(svc.prix)+'</span><b>'+esc(when(ctx.date,ctx.m))+'</b><span>'+esc(p.ent)+' · '+esc(p.lieu)+'</span></div>'+
      '<form id="an-info" novalidate><div class="row2"><div class="field"><label for="an-nom">Nom et prénom *</label><input id="an-nom" autocomplete="name" required value="'+esc(v.nom||'')+'"></div>'+
      '<div class="field"><label for="an-mail">Courriel *</label><input id="an-mail" type="email" autocomplete="email" required value="'+esc(v.mail||'')+'"></div></div>'+
      '<div class="row2"><div class="field"><label for="an-tel">Téléphone (facultatif)</label><input id="an-tel" type="tel" autocomplete="tel" value="'+esc(v.tel||'')+'" placeholder="514 555-0000"></div>'+
      '<div class="field"><label for="an-rap">Rappel la veille</label><select id="an-rap"><option value="courriel">Par courriel</option><option value="texto">Par texto</option><option value="aucun">Aucun rappel</option></select></div></div>'+
      (sante?'<p class="notice">N\'indiquez aucun renseignement sur votre santé : le motif de la consultation se discute directement avec le professionnel.</p>'
        :'<div class="field"><label for="an-note">Précisions pour le professionnel (facultatif)</label><textarea id="an-note" maxlength="300" placeholder="ex. : fuite sous l\'évier, accès par la ruelle">'+esc(v.note||'')+'</textarea></div>')+
      '<label class="consent" for="an-ok"><input id="an-ok" type="checkbox" required><span>J\'accepte que ces renseignements soient transmis à '+esc(p.ent)+' pour la gestion de ce rendez-vous (confirmation, rappel, changement ou annulation), et à aucune autre fin<sup class="n"><a href="#note-15" aria-label="Note 15">15</a></sup>. *</span></label>'+
      '<p class="an-warn" id="an-err" role="alert" hidden></p>'+
      '<div class="an-actions"><button type="submit" class="btn btn-gold">Confirmer la réservation</button><button type="button" class="btn btn-ghost" id="an-back">‹ Autre plage</button></div></form>');
    if(v.rap) $('an-rap').value=v.rap;
    $('an-back').addEventListener('click',function(){ctx.form=lire();etapePlage();});
    $('an-info').addEventListener('submit',function(e){
      e.preventDefault(); var f=lire(), err=$('an-err');
      function stop(t,el){err.textContent=t;err.hidden=false;document.querySelectorAll('#an-info [aria-invalid]').forEach(function(x){x.removeAttribute('aria-invalid');});if(el){el.setAttribute('aria-invalid','true');el.focus();}}
      if(!f.nom) return stop('Indiquez votre nom.',$('an-nom'));
      if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(f.mail)) return stop('Entrez un courriel valide : la confirmation et le lien de gestion y sont envoyés.',$('an-mail'));
      if(f.rap==='texto'&&f.tel.replace(/\D/g,'').length<10) return stop('Pour un rappel par texto, indiquez un numéro à 10 chiffres.',$('an-tel'));
      if(!$('an-ok').checked) return stop('Cochez le consentement : sans lui, le professionnel ne peut pas recevoir votre réservation.',$('an-ok'));
      // la plage est-elle toujours libre ?
      if(plages(p,svc,fromKey(ctx.date)).indexOf(ctx.m)<0){ctx.form=f;return stop('Cette plage vient d\'être prise. Choisissez-en une autre.');}
      var b={code:code(),pro:p.id,svc:svc.id,date:ctx.date,start:ctx.m,nom:f.nom,mail:f.mail,tel:f.tel,rappel:f.rap,note:sante?'':f.note,statut:'confirmée',cree:new Date().toISOString()};
      bookings.push(b); save(); ctx.form=null; badge(); renderResults(); confirmation(b,'new');
    });
    function lire(){return {nom:$('an-nom').value.trim(),mail:$('an-mail').value.trim(),tel:$('an-tel').value.trim(),rap:$('an-rap').value,note:$('an-note')?$('an-note').value.trim():''};}
  }
  function code(){var A='ABCDEFGHJKLMNPQRSTUVWXYZ23456789',c;do{c='RDV-';for(var i=0;i<5;i++)c+=A.charAt(Math.floor(Math.random()*A.length));}while(bookings.some(function(b){return b.code===c;}));return c;}
  function confirmation(b,kind){
    var p=BYID[b.pro],s=svcOf(b);
    header(p,p.ent,sub(p));
    var t={new:'Rendez-vous confirmé',moved:'Rendez-vous déplacé',found:'Votre rendez-vous'}[kind];
    body((kind==='new'?stepper(4):'')+'<h4>'+t+'</h4><p class="an-code">'+b.code+'</p>'+
      '<div class="an-recap" style="margin-top:10px"><b>'+esc(when(b.date,b.start))+' à '+hm(b.start+s.duree)+'</b><span>'+esc(s.nom)+' · '+price(s.prix)+'</span><span>'+esc(p.ent)+' · '+esc(p.quartier)+', '+esc(p.ville)+' · '+esc(p.lieu)+'</span>'+'<span>Téléphone du professionnel : '+esc(p.tel)+'</span>'+'</div>'+
      (kind==='found'?'':'<p class="an-ok">Confirmation et lien « Gérer mon rendez-vous » envoyés à <strong>'+esc(b.mail)+'</strong>'+(b.rappel!=='aucun'?' ; rappel par '+b.rappel+' la veille':'')+'. <em>Aperçu : aucun envoi réel ; ce rendez-vous est gardé sur cet appareil.</em></p>')+
      '<p class="an-policy">'+esc(policy(p))+'</p>'+
      '<div class="an-actions"><button type="button" class="btn btn-ghost" id="an-mv">Changer de plage</button><button type="button" class="btn btn-danger" id="an-cx">Annuler le rendez-vous</button><button type="button" class="btn btn-primary" id="an-done">Terminé</button></div>');
    $('an-mv').addEventListener('click',function(){deplacer(b.code);});
    $('an-cx').addEventListener('click',function(){annuler(b.code);});
    $('an-done').addEventListener('click',dlgClose);
  }
  function modifiable(b){var p=BYID[b.pro];return startOf(b).getTime()-Date.now()>=p.annul*3600000;}
  function tropTard(b){var p=BYID[b.pro];return '<p class="an-warn">Le délai de '+p.annul+'\u00a0h fixé par '+esc(p.ent)+' est dépassé : pour changer ou annuler, appelez au '+esc(p.tel)+'.</p>';}
  function deplacer(c){
    var b=find(c);if(!b)return;var p=BYID[b.pro];
    header(p,p.ent,sub(p));dlgOpen();
    if(!modifiable(b)) return body('<h4>Changer de plage</h4>'+tropTard(b)+'<div class="an-actions"><button type="button" class="btn btn-ghost" id="an-back">‹ Retour</button></div>'),$('an-back').addEventListener('click',function(){gerer(c);});
    ctx={mode:'move',p:p,svc:svcOf(b),code:c,old:b,week:Math.max(0,Math.floor((fromKey(b.date)-today())/864e5/7)),day:null};
    etapePlage();
  }
  function etapeDeplacer(){
    var b=ctx.old;
    body('<h4>Confirmer le changement</h4><div class="an-recap"><span>'+esc(ctx.svc.nom)+'</span><span class="old">'+esc(when(b.date,b.start))+'</span><b>'+esc(when(ctx.date,ctx.m))+'</b></div><p class="an-policy">L\'ancienne plage est libérée dès la confirmation. '+esc(ctx.p.ent)+' est avisé.</p><div class="an-actions"><button type="button" class="btn btn-gold" id="an-yes">Confirmer la nouvelle plage</button><button type="button" class="btn btn-ghost" id="an-back">‹ Autre plage</button></div>');
    $('an-back').addEventListener('click',etapePlage);
    $('an-yes').addEventListener('click',function(){
      if(plages(ctx.p,ctx.svc,fromKey(ctx.date),b.code).indexOf(ctx.m)<0) return etapePlage();
      b.date=ctx.date;b.start=ctx.m;b.modifie=new Date().toISOString();save();renderResults();badge();confirmation(b,'moved');
    });
  }
  function annuler(c){
    var b=find(c);if(!b)return;var p=BYID[b.pro],s=svcOf(b);
    header(p,p.ent,sub(p));dlgOpen();
    if(!modifiable(b)) return body('<h4>Annuler le rendez-vous</h4>'+tropTard(b)+'<div class="an-actions"><button type="button" class="btn btn-ghost" id="an-back">‹ Retour</button></div>'),$('an-back').addEventListener('click',function(){gerer(c);});
    body('<h4>Annuler ce rendez-vous&nbsp;?</h4><div class="an-recap"><b>'+esc(when(b.date,b.start))+'</b><span>'+esc(s.nom)+' · '+esc(p.ent)+'</span><span>Code '+b.code+'</span></div><p class="an-policy">La plage redevient libre pour d\'autres personnes. Annulation sans frais : vous êtes dans le délai de '+p.annul+'\u00a0h.</p><div class="an-actions"><button type="button" class="btn btn-danger" id="an-yes">Oui, annuler</button><button type="button" class="btn btn-ghost" id="an-back">Garder mon rendez-vous</button></div>');
    $('an-back').addEventListener('click',function(){gerer(c);});
    $('an-yes').addEventListener('click',function(){
      b.statut='annulée';b.annule=new Date().toISOString();save();renderResults();badge();
      body('<h4>Rendez-vous annulé</h4><p class="an-ok">Le rendez-vous '+b.code+' du '+esc(when(b.date,b.start))+' est annulé. '+esc(p.ent)+' est avisé et la plage est libérée. Un courriel de confirmation est envoyé à '+esc(b.mail)+' <em>(aperçu : aucun envoi)</em>.</p><div class="an-actions"><button type="button" class="btn btn-primary" id="an-re">Reprendre un rendez-vous</button><button type="button" class="btn btn-ghost" id="an-list">Mes rendez-vous</button></div>');
      $('an-re').addEventListener('click',function(){ouvrir(p.id);});
      $('an-list').addEventListener('click',function(){gerer();});
    });
  }
  function find(c){c=String(c||'').toUpperCase().replace(/\s/g,'');if(c&&c.indexOf('RDV-')!==0)c='RDV-'+c;return bookings.filter(function(b){return b.code===c;})[0];}
  function gerer(focusCode){
    header(null,'Mes rendez-vous','Changer de plage ou annuler');dlgOpen();
    var now=Date.now(),list=bookings.filter(function(b){return startOf(b).getTime()>now-864e5;}).sort(function(a,b){return startOf(a)-startOf(b);});
    var html='<h4>Réservés sur cet appareil</h4>';
    html+=list.length?'<div class="an-list">'+list.map(function(b){
      var p=BYID[b.pro],s=svcOf(b),x=b.statut!=='confirmée',passe=startOf(b).getTime()<now;
      return '<div class="an-bk'+(x||passe?' x':'')+'" id="bk-'+b.code+'"><div class="top2"><strong>'+esc(when(b.date,b.start))+'</strong><span class="chip '+(x?'ask':'ok')+'">'+(x?'Annulé':passe?'Passé':'Confirmé')+' · '+b.code+'</span></div><span>'+esc(s.nom)+' · '+esc(p.ent)+', '+esc(p.ville)+'</span>'+
        (x||passe?'':'<div class="an-actions"><button type="button" class="btn btn-ghost" data-mv="'+b.code+'">Changer de plage</button><button type="button" class="btn btn-danger" data-cx="'+b.code+'">Annuler</button></div>')+'</div>';
    }).join('')+'</div>':'<p class="an-policy" style="margin-top:0">Aucun rendez-vous réservé depuis cet appareil.</p>';
    html+='<form class="an-find" id="an-find" novalidate><h4 style="font-size:15.5px;margin-bottom:0">Réservé ailleurs&nbsp;?</h4><p class="an-policy" style="margin-top:4px">Utilisez le lien du courriel de confirmation, ou entrez le code et le courriel de la réservation.</p><div class="row2"><div class="field"><label for="an-fc">Code</label><input id="an-fc" placeholder="RDV-7K2QX" autocomplete="off"></div><div class="field"><label for="an-fm">Courriel</label><input id="an-fm" type="email" autocomplete="email"></div></div><p class="an-warn" id="an-ferr" role="alert" hidden></p><div class="an-actions"><button type="submit" class="btn btn-primary">Retrouver</button></div></form>';
    body(html);
    $('an-body').querySelectorAll('[data-mv]').forEach(function(b){b.addEventListener('click',function(){deplacer(b.dataset.mv);});});
    $('an-body').querySelectorAll('[data-cx]').forEach(function(b){b.addEventListener('click',function(){annuler(b.dataset.cx);});});
    $('an-find').addEventListener('submit',function(e){
      e.preventDefault();var b=find($('an-fc').value),m=$('an-fm').value.trim().toLowerCase(),err=$('an-ferr');
      if(!b||b.mail.toLowerCase()!==m){err.textContent='Aucune réservation ne correspond à ce code et à ce courriel.';err.hidden=false;return;}
      if(b.statut!=='confirmée'){err.textContent='Ce rendez-vous a déjà été annulé.';err.hidden=false;return;}
      confirmation(b,'found');
    });
    if(focusCode){var el=$('bk-'+focusCode);if(el)el.scrollIntoView({block:'nearest'});}
  }

  // --- montage (rappelé à chaque changement de langue, car #app est reconstruit)
  function mount(){
    if(!$('specialistes')) return;
    var city=$('an-city');
    Object.keys(CITY).sort(function(a,b){return a.localeCompare(b,'fr');}).forEach(function(c){var o=document.createElement('option');o.value=c;o.textContent=c;city.appendChild(o);});
    $('an-ind').innerHTML=[['','Toutes']].concat(IND).map(function(i){return '<button type="button" class="an-chip" data-ind="'+i[0]+'" aria-pressed="'+(st.ind===i[0])+'">'+esc(i[1])+'</button>';}).join('');
    $('an-q').value=st.q;city.value=st.ville;$('an-cp').value=st.cp;$('an-rad').value=st.rad;$('an-soon').checked=st.soon;$('an-sort').value=st.sort;
    function upd(){st.shown=9;renderResults();}
    $('an-q').addEventListener('input',function(){st.q=this.value;clearTimeout(deb);deb=setTimeout(upd,150);});
    $('an-cp').addEventListener('input',function(){st.cp=this.value;if(norm(st.cp).length>=3&&st.sort==='next'){st.sort='dist';$('an-sort').value='dist';}clearTimeout(deb);deb=setTimeout(upd,200);});
    city.addEventListener('change',function(){st.ville=this.value;upd();});
    $('an-rad').addEventListener('change',function(){st.rad=this.value;upd();});
    $('an-soon').addEventListener('change',function(){st.soon=this.checked;upd();});
    $('an-sort').addEventListener('change',function(){st.sort=this.value;upd();});
    $('an-ind').querySelectorAll('.an-chip').forEach(function(b){b.addEventListener('click',function(){
      st.ind=b.dataset.ind;$('an-ind').querySelectorAll('.an-chip').forEach(function(x){x.setAttribute('aria-pressed',String(x===b));});upd();
    });});
    $('an-form').addEventListener('submit',function(e){e.preventDefault();upd();});
    $('an-manage').addEventListener('click',function(){gerer();});
    var fd=$('an-find');
    $('an-x').addEventListener('click',toSearch);
    fd.addEventListener('cancel',function(e){if(!$('an-dlg').hidden){e.preventDefault();toSearch();}});
    fd.addEventListener('close',function(){ctx=null;$('an-dlg').hidden=true;$('an-full').hidden=false;fd.dataset.from='search';});
    renderResults();badge();
  }
  return {mount:mount};
})();
