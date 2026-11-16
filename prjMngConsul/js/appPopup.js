/*
 * appPopup.js — jamais d'alert() natif dans l'ERP.
 *
 * - showAppMessage(texte, titre, aLaFermeture) : la boîte de message maison
 *   (même allure que celle de Site.Master). Si la page a déjà la sienne
 *   (Site.Master), c'est elle qui sert ; sinon (pages autonomes, fenêtres
 *   RadWindow) la boîte est construite ici à la première utilisation.
 * - window.alert est redirigé vers showAppMessage : un alert() oublié ou
 *   ajouté plus tard s'affiche quand même dans la boîte maison.
 *
 * Le texte est posé par textContent (jamais interprété comme du HTML).
 * La boîte ne bloque pas le script : ce qui doit attendre la fermeture
 * (rechargement, fermeture de fenêtre…) passe par aLaFermeture.
 */
(function () {
    'use strict';
    var alertNatif = window.alert;
    var rappel = null, file = [];

    function construire() {
        if (document.getElementById('mcMsgOverlay')) return;
        var o = document.createElement('div');
        o.id = 'mcMsgOverlay';
        o.style.cssText = 'display:none;position:fixed;inset:0;z-index:999999;background:rgba(15,23,42,.55);' +
                          'align-items:center;justify-content:center;font-family:inherit';
        o.addEventListener('click', function (e) { if (e.target === o) window.closeAppMessage(); });
        o.innerHTML =
            '<div id="mcMsgBox" role="alertdialog" aria-modal="true" aria-labelledby="mcMsgTitle" aria-describedby="mcMsgText" ' +
            'style="background:#fff;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.3);width:92vw;max-width:460px;padding:24px;box-sizing:border-box">' +
            '<div id="mcMsgTitle" style="font-weight:800;font-size:16px;color:#0E1F3D;margin:-24px -24px 10px;padding:14px 24px 10px;border-radius:16px 16px 0 0"></div>' +
            '<div id="mcMsgText" style="color:#44536E;font-size:14px;line-height:1.5;margin-bottom:22px;white-space:pre-wrap"></div>' +
            '<div style="display:flex;justify-content:flex-end">' +
            '<button type="button" id="mcMsgOk" style="padding:10px 18px;border:1px solid #1B4F9C;background:#1B4F9C;color:#fff;' +
            'border-radius:10px;font-weight:700;cursor:pointer">OK</button></div></div>';
        document.body.appendChild(o);
        document.getElementById('mcMsgOk').addEventListener('click', function () { window.closeAppMessage(); });
        document.addEventListener('keydown', function (e) { if (e.key === 'Escape') window.closeAppMessage(); });
    }

    // La boîte autonome — seulement si la page n'en a pas déjà une (Site.Master
    // définit la sienne plus loin et la remplace alors).
    if (typeof window.showAppMessage !== 'function') {
        window.showAppMessage = function (texte, titre, aLaFermeture) {
            construire();
            // Un message qui arrive pendant qu'un autre est affiché attend son tour
            if (document.getElementById('mcMsgOverlay').style.display === 'flex') { file.push([texte, titre, aLaFermeture]); return; }
            document.getElementById('mcMsgText').textContent = texte == null ? '' : String(texte);
            document.getElementById('mcMsgTitle').textContent = titre || 'Information';
            rappel = typeof aLaFermeture === 'function' ? aLaFermeture : null;
            document.getElementById('mcMsgOverlay').style.display = 'flex';
            var b = document.getElementById('mcMsgOk'); if (b) b.focus();
        };
        window.closeAppMessage = function () {
            var o = document.getElementById('mcMsgOverlay');
            if (o) o.style.display = 'none';
            var f = rappel; rappel = null;
            if (f) { try { f(); } catch (e) { } }
            if (file.length) { var s = file.shift(); window.showAppMessage(s[0], s[1], s[2]); }
        };
    }

    // alert() → la boîte maison (attend que la page soit prête au besoin)
    window.alert = function (message) {
        var texte = message == null ? '' : String(message);
        var afficher = function () {
            if (typeof window.showAppMessage === 'function') window.showAppMessage(texte);
            else alertNatif(texte);
        };
        if (document.body) afficher();
        else document.addEventListener('DOMContentLoaded', afficher);
    };
})();
