<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ImportApideck.aspx.vb" Inherits="MngConsul.ImportApideck" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importer depuis QuickBooks — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .apd-page { padding: 16px }

    /* Le chemin du retour : l'écran s'ouvre depuis la page des importations,
       et c'est là qu'on repart une fois l'extraction faite. */
    .retour { display: inline-block; font-size: 13px; font-weight: 600; color: #2563eb; text-decoration: none; margin-bottom: 12px }
    .retour:hover { color: #1d4ed8; text-decoration: underline }

    .apd-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .apd-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .apd-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .apd-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .apd-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 880px; line-height: 1.6 }

    h2.sect { font-size: 15px; font-weight: 800; color: #0f172a; margin: 24px 0 8px }
    h2.sect span { font-size: 12.5px; font-weight: 500; color: #64748b; margin-left: 8px }

    .bloc { border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 16px 18px }

    /* L'état de la liaison */
    .etat { display: flex; align-items: center; gap: 12px; flex-wrap: wrap }
    .pastille { width: 10px; height: 10px; border-radius: 50%; flex: none }
    .pastille.on { background: #10b981 } .pastille.off { background: #ef4444 }
    .pastille.mid { background: #f59e0b }
    .etat .txt { font-size: 13.5px; color: #0f172a; flex: 1; min-width: 260px; line-height: 1.5 }

    .btn {
        display: inline-block; padding: 8px 15px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600; cursor: pointer;
    }
    .btn:hover { background: #f8fafc }
    .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff }
    .btn.primaire:hover { background: #1d4ed8 }

    /* Ce que l'extraction rapatrie : tout, et on le dit en une phrase. */
    .tout { font-size: 13.5px; color: #0f172a; line-height: 1.6; margin: 0 }
    .tout .n { font-weight: 800 }

    .datebloc {
        display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
        margin-top: 14px; padding: 12px 14px; border-radius: 11px;
        background: #f8fafc; border: 1px solid #e2e8f0;
    }

    .datebloc label { font-size: 13px; font-weight: 700; color: #334155 }

    .datechamp {
        padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 9px;
        font-size: 13px; font-family: inherit; background: #fff;
    }

    .datebloc .aide { font-size: 12px; color: #64748b; flex: 1; min-width: 280px; line-height: 1.5 }

    .barre { display: flex; gap: 10px; align-items: center; margin-top: 16px; flex-wrap: wrap }
    .barre .aide { font-size: 12.5px; color: #64748b }

    /* Le compte rendu */
    table.res { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 4px }
    table.res th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; border-bottom: 1px solid #e2e8f0; padding: 7px 8px; font-weight: 700;
    }
    table.res td { border-bottom: 1px solid #f1f5f9; padding: 7px 8px; color: #0f172a }
    table.res td.n { text-align: right; font-variant-numeric: tabular-nums }
    table.res tr.ko td { background: #fef2f2 }
    table.res .ko-txt { color: #b91c1c }
    table.res .vers { color: #047857; font-size: 12px }

    /* Les erreurs d'abord, en rouge ; le détail de ce qui a réussi se déplie. */
    h3.erreurs { font-size: 13.5px; font-weight: 800; color: #b91c1c; margin: 14px 0 4px }
    details.detail { margin-top: 14px }
    details.detail summary { cursor: pointer; font-size: 13px; font-weight: 700; color: #2563eb }
    details.detail summary:hover { color: #1d4ed8 }

    .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 14px 0; line-height: 1.55 }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="apd-page">

    <a class="retour" href="Importations">← Retour aux importations</a>

    <div class="apd-head">
        <div class="ico">🔌</div>
        <div>
            <h1>Importer depuis QuickBooks</h1>
            <div class="sub">Lecture directe, par Apideck — sans export manuel</div>
        </div>
    </div>

    <p class="apd-lede">
        Plutôt que de demander au client d'exporter ses fichiers un à un, on lit sa comptabilité
        là où elle est. Il relie son QuickBooks une seule fois, puis chaque extraction ramène les
        données à jour. <b>Rien ne va en comptabilité</b> : tout se dépose en préparation, et les
        écrans d'import habituels prennent le relais pour décider ce qui est créé.
    </p>

    <asp:Literal ID="litMsg" runat="server" />

    <h2 class="sect">1. La liaison <span>une fois par compagnie</span></h2>
    <div class="bloc">
        <div class="etat">
            <span class="pastille" id="pastille" runat="server"></span>
            <div class="txt"><asp:Literal ID="litEtat" runat="server" /></div>
            <asp:Button ID="btnRelier" runat="server" CssClass="btn primaire" Text="Relier QuickBooks" CausesValidation="false" />
            <asp:Button ID="btnVerifier" runat="server" CssClass="btn" Text="Vérifier la liaison" CausesValidation="false" />
        </div>
    </div>

    <h2 class="sect">2. L'extraction <span>tout est rapatrié, en préparation</span></h2>
    <div class="bloc">
        <%-- Plus rien à cocher : chaque extraction rapatrie tout le catalogue.
             Ce qui a un écran d'import y est versé ; le reste attend en préparation. --%>
        <p class="tout"><asp:Literal ID="litTout" runat="server" /></p>

        <%-- Plusieurs ressources demandent une date : la balance de vérification, le
             grand livre, les taxes, les remises et le pointage. QuickBooks les rend
             pour une période, et un rapport à la mauvaise date ressemble à s'y
             méprendre à un bon. --%>
        <div class="datebloc">
            <label for="<%= txtDateBalance.ClientID %>">Date de bascule</label>
            <asp:TextBox ID="txtDateBalance" runat="server" TextMode="Date" CssClass="datechamp" />
            <asp:DropDownList ID="ddlFrequenceTaxes" runat="server" CssClass="datechamp">
                <asp:ListItem Value="3" Text="Taxes déclarées par trimestre" Selected="True" />
                <asp:ListItem Value="1" Text="Taxes déclarées par mois" />
                <asp:ListItem Value="12" Text="Taxes déclarées par année" />
            </asp:DropDownList>
            <span class="aide">
                La veille du premier jour tenu ici. QuickBooks exige une période : la balance
                de vérification est arrêtée à cette date, les comptes de résultats couvrent
                l'année civile jusqu'à cette date, et le grand livre, les remises et le pointage
                sont lus du 1er janvier à cette date. Les rapports de taxes, eux, sont rapatriés
                une déclaration à la fois — la fréquence est celle que vous produisez.
            </span>
        </div>

        <div class="barre">
            <asp:Button ID="btnImporter" runat="server" CssClass="btn primaire" Text="Importer dans la préparation" CausesValidation="false" />
            <span class="aide">Une extraction complète prend quelques minutes.</span>
        </div>
    </div>

    <asp:Panel ID="pnlResultat" runat="server" Visible="false">
        <h2 class="sect">3. Ce qui est arrivé</h2>
        <div class="bloc"><asp:Literal ID="litResultat" runat="server" /></div>
    </asp:Panel>

</div>

<script type="text/javascript">
    // L'extraction tourne en arrière-plan : on relit son état toutes les trois
    // secondes et on redessine le compte rendu — les erreurs en premier, en
    // rouge ; le détail des réussites replié. Quand elle se termine, on cesse.
    (function () {
        var suivi = document.getElementById('suivi');
        if (!suivi) return;

        var run = suivi.getAttribute('data-run');
        var total = parseInt(suivi.getAttribute('data-total'), 10) || 0;
        var minuterie = null;

        function h(s) {
            return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
                return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
            });
        }

        function nombre(n) { return Number(n || 0).toLocaleString('fr-CA'); }

        function dessiner(e) {
            var fini = e.statut !== 'EN_COURS';
            var demandees = e.demandees || total;
            var ko = e.lignes.filter(function (l) { return !l.reussie; });
            var ok = e.lignes.filter(function (l) { return l.reussie; });
            var html = '';

            if (!fini) {
                html += "<div class='msg info'>Extraction en cours : " + e.lues + " ressource(s) sur " + demandees +
                        " lue(s), " + nombre(e.total) + " enregistrement(s) déposés jusqu'ici. " +
                        "Vous pouvez quitter la page, l'extraction continue.</div>";
            } else {
                var genre = (e.echecs === 0 && e.statut === 'TERMINE') ? 'ok' : 'err';
                html += "<div class='msg " + genre + "'>" + nombre(e.total) + " enregistrement(s) déposés en préparation, sur " +
                        demandees + " ressource(s).";
                if (e.statut === 'ECHEC' || e.statut === 'INTERROMPUE') {
                    html += " L'extraction s'est arrêtée avant la fin" + (e.note ? " — " + h(e.note) : ".");
                } else if (e.echecs > 0) {
                    html += " " + e.echecs + " n'ont pas répondu — le détail est ci-dessous.";
                }
                html += " Rien n'a été écrit en comptabilité : les écrans d'import décident de la suite.</div>";
            }

            if (ko.length) {
                html += "<h3 class='erreurs'>" + ko.length + " ressource(s) en erreur</h3>" +
                        "<table class='res'><tr><th>Ressource</th><th>Erreur</th></tr>";
                ko.forEach(function (l) {
                    html += "<tr class='ko'><td>" + h(l.libelle) + " <span style='color:#94a3b8'>" + h(l.cle) + "</span></td>" +
                            "<td><span class='ko-txt'>" + h(l.erreur) + "</span></td></tr>";
                });
                html += "</table>";
            }

            if (ok.length) {
                html += "<details class='detail'" + (fini ? "" : " open") + "><summary>" +
                        (fini ? "Voir le détail des " : "Déjà rapatriées : ") + ok.length + " ressource(s) rapatriée(s)</summary>" +
                        "<table class='res'><tr><th>Ressource</th><th style='text-align:right'>Enregistrements</th></tr>";
                ok.forEach(function (l) {
                    html += "<tr><td>" + h(l.libelle) + " <span style='color:#94a3b8'>" + h(l.cle) + "</span></td>" +
                            "<td class='n'>" + nombre(l.nb) + "</td></tr>";
                });
                html += "</table></details>";
            }

            suivi.innerHTML = html;
            return fini;
        }

        function relire() {
            fetch('ApideckEtat.ashx?run=' + encodeURIComponent(run) + '&t=' + Date.now(), { cache: 'no-store', credentials: 'same-origin' })
                .then(function (r) { return r.json(); })
                .then(function (e) {
                    if (e.erreur) {
                        suivi.innerHTML = "<div class='msg err'>" + h(e.erreur) + "</div>";
                        clearInterval(minuterie);
                        return;
                    }
                    if (dessiner(e)) clearInterval(minuterie);
                })
                .catch(function () { /* une relecture ratée : la prochaine dira */ });
        }

        relire();
        minuterie = setInterval(relire, 3000);
    })();
</script>
</asp:Content>
