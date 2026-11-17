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

    // ─────────────────────────────────────────────────────────────────────
    // Confirmations — remplacent confirm() natif.
    //   appConfirm(message, options) → Promise<bool>
    //       options : { titre, ok, annuler, danger }  (libellés selon <html lang>)
    //   appConfirmClic(element, message) → pour un OnClientClick / onclick :
    //       if (!appConfirmClic(this, 'Supprimer ?')) { return false; }
    //       Le 1er clic est annulé et la boîte s'ouvre ; sur « Confirmer », le
    //       même élément est recliqué et passe (postback, lien, bouton submit).
    //   appConfirmRad(sender, args, message) → pour un OnClientClicking Telerik :
    //       function (s, e) { appConfirmRad(s, e, 'Supprimer cette ligne ?'); }
    // ─────────────────────────────────────────────────────────────────────
    function libelles() {
        var l = (document.documentElement.lang || '').toLowerCase();
        if (l.indexOf('en') === 0) return { titre: 'Confirmation', ok: 'Confirm', annuler: 'Cancel' };
        if (l.indexOf('es') === 0) return { titre: 'Confirmación', ok: 'Confirmar', annuler: 'Cancelar' };
        return { titre: 'Confirmation', ok: 'Confirmer', annuler: 'Annuler' };
    }

    var confFile = [], confEnCours = null;

    function construireConfirm() {
        if (document.getElementById('mcConfOverlay')) return;
        var o = document.createElement('div');
        o.id = 'mcConfOverlay';
        o.style.cssText = 'display:none;position:fixed;inset:0;z-index:1000000;background:rgba(15,23,42,.55);' +
                          'align-items:center;justify-content:center;font-family:inherit';
        o.innerHTML =
            '<div role="alertdialog" aria-modal="true" aria-labelledby="mcConfTitre" aria-describedby="mcConfTexte" ' +
            'style="background:#fff;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.3);width:92vw;max-width:480px;padding:24px;box-sizing:border-box">' +
            '<div id="mcConfTitre" style="font-weight:800;font-size:16px;color:#0E1F3D;margin-bottom:10px"></div>' +
            '<div id="mcConfTexte" style="color:#44536E;font-size:14px;line-height:1.5;margin-bottom:22px;white-space:pre-wrap"></div>' +
            '<div style="display:flex;justify-content:flex-end;gap:8px">' +
            '<button type="button" id="mcConfNon" style="padding:10px 18px;border:1px solid #D5DDE8;background:#fff;color:#143A73;' +
            'border-radius:10px;font-weight:700;cursor:pointer"></button>' +
            '<button type="button" id="mcConfOui" style="padding:10px 18px;border:1px solid #1B4F9C;background:#1B4F9C;color:#fff;' +
            'border-radius:10px;font-weight:700;cursor:pointer"></button></div></div>';
        document.body.appendChild(o);
        o.addEventListener('click', function (e) { if (e.target === o) repondre(false); });
        document.getElementById('mcConfNon').addEventListener('click', function () { repondre(false); });
        document.getElementById('mcConfOui').addEventListener('click', function () { repondre(true); });
        document.addEventListener('keydown', function (e) {
            if (!confEnCours) return;
            if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); repondre(false); }
        }, true);
    }

    function montrer(q) {
        construireConfirm();
        var lib = libelles(), opt = q.options || {};
        document.getElementById('mcConfTitre').textContent = opt.titre || lib.titre;
        document.getElementById('mcConfTexte').textContent = q.message == null ? '' : String(q.message);
        document.getElementById('mcConfNon').textContent = opt.annuler || lib.annuler;
        var oui = document.getElementById('mcConfOui');
        oui.textContent = opt.ok || lib.ok;
        oui.style.background = opt.danger ? '#A3261C' : '#1B4F9C';
        oui.style.borderColor = opt.danger ? '#A3261C' : '#1B4F9C';
        confEnCours = q;
        document.getElementById('mcConfOverlay').style.display = 'flex';
        oui.focus();
    }

    function repondre(ok) {
        var q = confEnCours; confEnCours = null;
        var o = document.getElementById('mcConfOverlay'); if (o) o.style.display = 'none';
        if (q) { try { q.resoudre(ok); } catch (e) { } }
        if (confFile.length) montrer(confFile.shift());
    }

    window.appConfirm = function (message, options) {
        return new Promise(function (resoudre) {
            var q = { message: message, options: options, resoudre: resoudre };
            var go = function () { if (confEnCours) confFile.push(q); else montrer(q); };
            if (document.body) go(); else document.addEventListener('DOMContentLoaded', go);
        });
    };

    window.appConfirmClic = function (el, message, options) {
        if (el && el.__appConfOk) { el.__appConfOk = false; return true; }
        window.appConfirm(message, options).then(function (ok) {
            if (ok && el) { el.__appConfOk = true; el.click(); }
        });
        return false;
    };

    window.appConfirmRad = function (sender, args, message, options) {
        if (sender && sender.__appConfOk) { sender.__appConfOk = false; return; }
        if (args && args.set_cancel) args.set_cancel(true);
        window.appConfirm(message, options).then(function (ok) {
            if (ok && sender) { sender.__appConfOk = true; sender.click(); }
        });
    };

    // ─────────────────────────────────────────────────────────────────────
    // Lecture seule (T395) : zone d'un dossier en « Accès restreint ».
    // appLectureSeule(texte) pose un bandeau en haut de la page et grise les
    // boutons de modification (repérés par leur libellé / titre), y compris
    // après les mises à jour Ajax. Le vrai verrou est côté serveur (clsData).
    // ─────────────────────────────────────────────────────────────────────
    var MOTS_MODIF = /(enregistr|sauvegard|supprim|retirer|nouveau|nouvelle|ajout|cr[ée]er|comptabilis|payer|r[ée]gler|import|envoyer|factur|approuv|refuser|valider|modifier|^lier|d[ée]lier|cl[ôo]tur|rouvrir|inscrire|associer|save|delete|remove|\bnew\b|\badd\b|create|post\b|\bpay\b|send|invoice|approve|reject|\bedit\b|guardar|eliminar|nuev|agregar|crear|pagar|importar|enviar|facturar|aprobar|modificar|^\+)/i;
    var lsTexte = null;

    function libelleDe(el) {
        return ((el.value || '') + ' ' + (el.textContent || '') + ' ' + (el.getAttribute('title') || '') + ' ' + (el.getAttribute('aria-label') || '')).trim();
    }
    // Masqués (pas seulement grisés) en accès restreint : les encaissements /
    // décaissements et les synchronisations demandent l'accès complet.
    var MOTS_CACHER = /(square|synchro|\bsync|plaid|quickbooks|apideck|encaiss|d[ée]caiss|cash.?in|cobro|rwEncaissement|ReceiptEditPopup|PaymentLink|lien de paiement|payment link|enlace de pago|paiement d[ée]j[àa] re[çc]u|payment received|pago recibido)/i;
    function signatureDe(el) {
        return libelleDe(el) + ' ' + (el.id || '') + ' ' + (el.className && el.className.baseVal === undefined ? el.className : '') + ' ' +
               (el.getAttribute('onclick') || '') + ' ' + (el.getAttribute('href') || '');
    }
    function griser() {
        var sel = 'button, input[type=submit], input[type=button], input[type=image], a[href^="javascript:__doPostBack"], a[onclick], .rbButton, .RadButton';
        Array.prototype.forEach.call(document.querySelectorAll(sel), function (el) {
            if (el.closest('#mcMsgOverlay, #mcConfOverlay, #appLectureSeule, nav, .nav-group, header, #iaPanneau')) return;
            if (el.__lsVu) return;
            el.__lsVu = true;
            if (el.hasAttribute('data-lecture')) return;   // consultation : toujours permise
            if (MOTS_CACHER.test(signatureDe(el))) { el.style.display = 'none'; el.setAttribute('aria-hidden', 'true'); return; }
            var lib = libelleDe(el);
            if (!lib || !MOTS_MODIF.test(lib)) return;
            el.setAttribute('disabled', 'disabled');
            el.setAttribute('aria-disabled', 'true');
            el.style.opacity = '.45';
            el.style.pointerEvents = 'none';
            el.style.cursor = 'not-allowed';
        });
        // Liens vers les pages réservées à l'accès complet : masqués aussi
        Array.prototype.forEach.call(document.querySelectorAll('a[href]'), function (a) {
            if (a.__lsLien || a.closest('nav, .nav-group, header')) return;
            a.__lsLien = true;
            if (/(PlaidAccounts|wbfEncaissements|wbfSupplierPayment|wbfCustomerPaymentLink|wbfScheduleAutoPay|wbfReceiptEdit)/i.test(a.getAttribute('href') || '')) a.style.display = 'none';
        });
    }
    window.appLectureSeule = function (texte) {
        lsTexte = texte || 'Lecture seule';
        var go = function () {
            if (!document.getElementById('appLectureSeule')) {
                var b = document.createElement('div');
                b.id = 'appLectureSeule';
                b.setAttribute('role', 'status');
                b.style.cssText = 'position:sticky;top:0;z-index:9000;margin:0 0 12px;padding:10px 16px;border-radius:12px;' +
                                  'background:#FBF1DC;color:#7A5200;font-weight:700;font-size:13.5px;display:flex;gap:10px;align-items:center';
                b.innerHTML = '<span aria-hidden="true">🔒</span><span></span>';
                b.lastChild.textContent = lsTexte;
                var cible = document.querySelector('main, .main-content, #MainContent, form') || document.body;
                cible.insertBefore(b, cible.firstChild);
            }
            griser();
            // Après chaque mise à jour Ajax (RadAjax / UpdatePanel) : regriser
            try { if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) Sys.WebForms.PageRequestManager.getInstance().add_endRequest(griser); } catch (e) { }
            var t = null;
            new MutationObserver(function () { clearTimeout(t); t = setTimeout(griser, 150); })
                .observe(document.body, { childList: true, subtree: true });
        };
        if (document.body) go(); else document.addEventListener('DOMContentLoaded', go);
    };
})();
