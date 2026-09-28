/* Inscriptions : la demande « Réserver ma place » est enregistrée par LandingReservation.ashx (T025LandingReservation) ;
   les inscriptions se consultent dans Sec60Admin › Abonnements › Réservations. Messages trilingues de la page conservés. */
window.Inscriptions=(function(){
  var T={
    fr:{ok:function(n,e){return 'Merci ! Votre inscription est enregistrée (n° '+n+').'+(e?' Vous faites partie des inscrits avant le lancement : nous vous écrirons en priorité dès l\'ouverture, le 1er janvier 2027.':' Nous vous écrirons sous peu.');},
        again:function(n){return 'Votre inscription (n° '+n+') est mise à jour.';},
        ro:"Aperçu : votre inscription n'a pas pu être enregistrée ici (accès en lecture seule à cette page).",
        err:"L'inscription n'a pas pu être enregistrée pour le moment. Réessayez dans un instant.",
        full:"Le registre des inscriptions est plein : communiquez avec nous à info@60secondes.ca.",
        wait:"Enregistrement en cours…"},
    en:{ok:function(n,e){return 'Thank you! Your registration is saved (no. '+n+').'+(e?' You are among those registered before launch: we will contact you first when we open on January 1, 2027.':' We will be in touch shortly.');},
        again:function(n){return 'Your registration (no. '+n+') has been updated.';},
        ro:"Preview: your registration could not be saved here (read-only access to this page).",
        err:"Your registration could not be saved right now. Please try again in a moment.",
        full:"The registration list is full: please contact us at info@60secondes.ca.",
        wait:"Saving…"},
    es:{ok:function(n,e){return '¡Gracias! Su inscripción está registrada (n.º '+n+').'+(e?' Usted forma parte de los inscritos antes del lanzamiento: le escribiremos con prioridad en la apertura, el 1 de enero de 2027.':' Le escribiremos pronto.');},
        again:function(n){return 'Su inscripción (n.º '+n+') se ha actualizado.';},
        ro:"Vista previa: su inscripción no pudo registrarse aquí (acceso de solo lectura a esta página).",
        err:"No se pudo registrar su inscripción por ahora. Inténtelo de nuevo en un momento.",
        full:"El registro de inscripciones está lleno: escríbanos a info@60secondes.ca.",
        wait:"Registrando…"}};
  function L(){var l=(document.documentElement.lang||'fr').slice(0,2);return T[l]||T.fr;}
  async function save(rec){
    var r; try{
      var d=Object.assign({},rec,{languePage:(document.documentElement.lang||'fr-CA'),page:location.href});
      var resp=await fetch('LandingReservation.ashx',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)});
      r=await resp.json();
      if(!resp.ok) return {ok:false,msg:(r&&r.erreur)||L().err};
    }catch(e){ return {ok:false,msg:L().err}; }
    return {ok:true,msg:L().ok(r.numero||('#'+r.id), !!r.avantLancement)};
  }
  return {save:save};
})();
