/* Prix des forfaits de la page d'accueil.
   Le serveur (LandingPage.aspx.vb) lit les forfaits dans T021Plan (Sec60Admin › Forfaits), remplace
   dans la page française les prix écrits (79,99 / 99,99 / 149,99) et pose window.FORFAITS60.
   Ce module sert aux scripts : prix pour le calculateur (Prix60.v), mise à jour des textes écrits
   dans les scripts (Prix60.fwd) et, pour la traduction, retour au texte d'origine (Prix60.back) afin
   que le dictionnaire EN/ES retrouve ses phrases malgré le nouveau prix. */
window.Prix60=(function(){
  var K=['ta','c0','c4'];
  var O={ta:79.99,c0:99.99,c4:149.99};   // prix écrits dans la page et dans le dictionnaire
  var V={};K.forEach(function(k){var x=window.FORFAITS60&&Number(window.FORFAITS60[k]);V[k]=x>0?x:O[k];});
  function fr(n){return n.toFixed(2).replace('.',',');}
  function en(n){return n.toFixed(2);}
  function esc(s){return s.replace(/[.]/g,'\.');}
  function table(m){var ks=Object.keys(m);
    if(!ks.length)return function(s){return s;};
    var rx=new RegExp('(^|[^\d.,])('+ks.map(esc).join('|')+')(?!\d)','g');
    return function(s){return typeof s!=='string'?s:s.replace(rx,function(a,p,x){return p+m[x];});};}
  var fw={},bk={};
  K.forEach(function(k){if(V[k]!==O[k]){fw[fr(O[k])]=fr(V[k]);fw[en(O[k])]=en(V[k]);bk[fr(V[k])]=fr(O[k]);bk[en(V[k])]=en(O[k]);}});
  // Le retour n'est sûr que si les prix de la base sont tous différents (sinon on ne sait pas lequel était lequel).
  var distinct=K.every(function(k,i){return K.every(function(j,n){return n===i||V[k]!==V[j];});});
  var changed=Object.keys(fw).length>0;
  return {v:V,changed:changed,fwd:table(fw),back:changed&&distinct?table(bk):function(s){return s;}};
})();
