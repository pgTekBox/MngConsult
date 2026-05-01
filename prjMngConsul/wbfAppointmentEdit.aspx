<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfAppointmentEdit.aspx.vb" Inherits="MngConsul.wbfAppointmentEdit" %>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Rendez-vous — Edit</title>
    <style>
        /* =============================================
           VARIABLES & BASE
        ============================================= */
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb;
            --card: #fff;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --primary: #2563eb;
            --primary-weak: #eff6ff;
            --danger: #dc2626;
            --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08);
            --radius: 16px;
        }

        html, body { height: 100%; margin: 0; }

        body {
            font-family: var(--font);
            color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%),
                        var(--bg);
        }

        /* =============================================
           LAYOUT WRAP — pleine largeur dans la RadWindow 1300px
        ============================================= */
        .wrap {
            max-width: 1260px;
            margin: 16px auto;
            padding: 0 16px 20px;
        }

        .top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }

        .title  { font-size: 22px; font-weight: 900; letter-spacing: -.02em; }
        .sub    { font-size: 13px; color: var(--muted); margin-top: 3px; }
        .bar    { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }

        /* =============================================
           CARD
        ============================================= */
        .card {
            background: var(--card);
            border: 1px solid rgba(226,232,240,.9);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 14px;
        }

        .cardHead {
            padding: 14px 16px;
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .cardHead .h { font-weight: 900; }
        .cardBody { padding: 16px; }

        /* =============================================
           GRILLES DE FORMULAIRE
        ============================================= */
        .grid  { display: grid; grid-template-columns: 1fr 1fr;         gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr;             gap: 12px; }
        .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr;     gap: 12px; }
        .grid4 { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; }

        @media (max-width: 800px) {
            .grid, .grid3, .grid4 { grid-template-columns: 1fr; }
        }

        /* =============================================
           CHAMPS
        ============================================= */
        .field label {
            display: block;
            font-size: 12px;
            color: #334155;
            margin-bottom: 6px;
            font-weight: 700;
        }

        .field input,
        .field textarea {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            outline: none;
            background: #fff;
            box-sizing: border-box;
            font-family: var(--font);
        }

        .field input:focus,
        .field textarea:focus {
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        /* RadTextBox */
        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox,
        .field .rtbLike input.riTextBox {
            width: 100% !important;
            box-sizing: border-box;
            padding: 10px 12px !important;
            border: 1px solid var(--line) !important;
            border-radius: 12px !important;
            outline: none;
            background: #fff !important;
            font-family: var(--font);
            color: var(--text);
        }
        .field .rtbLike .riTextBox:focus,
        .field .rtbLike input.riTextBox:focus,
        .field .rtbLike .riFocused .riTextBox {
            border-color: rgba(37,99,235,.5) !important;
            box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }

        /* RadDropDownList */
        .field .RadDropDownList,
        .field .RadDropDownList_Metro { width: 100%; display: block; }

        .field .RadDropDownList_Metro .rddlInner {
            width: 100%;
            height: 33px;
            padding: 10px 40px 10px 12px !important;
            border-radius: 12px !important;
            background: #fff !important;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            box-shadow: none !important;
        }
        .field .RadDropDownList_Metro .rddlFakeInput {
            flex: 1; min-width: 0; overflow: hidden;
            text-overflow: ellipsis; white-space: nowrap;
            color: var(--text); line-height: 20px;
        }
        .field .RadDropDownList_Metro .rddlSelect {
            width: 36px; margin-left: auto;
            display: flex; align-items: center; justify-content: center;
            background: transparent !important; border: 0 !important;
        }
        .field .RadDropDownList_Metro .rddlInner.rddlFocused,
        .field .RadDropDownList_Metro .rddlInner.rddlExpanded {
            border-color: #2563eb !important;
            box-shadow: 0 0 0 3px rgba(37,99,235,.15) !important;
        }
        .RadDropDownList_Metro .rddlSelect .p-icon::before { font-size: 25px; }

        /* RadDatePicker / RadTimePicker — même look que les autres champs */
        .field .RadPicker { width: 100% !important; }
        .field .RadPicker .rcTable { width: 100% !important; }
        .field .RadInput .riTextBox,
        .field .RadInput input.riTextBox {
            padding: 10px 12px !important;
            border: 1px solid var(--line) !important;
            border-radius: 12px !important;
            background: #fff !important;
            font-family: var(--font);
            color: var(--text);
            box-sizing: border-box;
        }

        /* =============================================
           CHECKBOX
        ============================================= */
        .check {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
            color: var(--text);
            margin-top: 24px;
        }

        /* =============================================
           BOUTONS
        ============================================= */
        .btn {
            cursor: pointer;
            border: 1px solid var(--line);
            border-radius: 12px !important;
            padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: var(--text);
            font-weight: 800;
            font-family: var(--font);
        }
        .btn.primary {
            border-color: rgba(37,99,235,.4);
            background: rgba(37,99,235,.08);
            color: #1d4ed8;
        }
        .btn.danger {
            border-color: rgba(220,38,38,.35);
            background: rgba(220,38,38,.08);
            color: var(--danger);
        }
        .btn:disabled { opacity: .6; cursor: not-allowed; }

        /* =============================================
           MESSAGES
        ============================================= */
        .msg {
            margin: 0; padding: 10px 12px;
            border-radius: 12px; font-weight: 700;
            font-size: 13px; border: 1px solid var(--line);
            background: #fff;
        }
        .msg.ok  { border-color: rgba(22,163,74,.35);  background: rgba(22,163,74,.08);  color: var(--ok);     }
        .msg.bad { border-color: rgba(220,38,38,.35);  background: rgba(220,38,38,.08);  color: var(--danger); }

        .right { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .small { font-size: 12px; color: var(--muted); }
        .hint  { font-size: 11px; color: var(--muted); margin-top: 4px; }

        /* =============================================
           RESPONSIVE
        ============================================= */
        @media (max-width: 768px) {
            .wrap { margin: 10px auto; padding: 0 10px 16px; }
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <%-- ===== TELERIK GLOBAL ===== --%>
        <telerik:RadScriptManager
            ID="RadScriptManager1"
            runat="server"
            EnablePartialRendering="true"
            AsyncPostBackTimeout="300" />

        <telerik:RadAjaxManager ID="ram1" runat="server">
            <AjaxSettings>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <%-- Hidden : map JSON  Id-de-type → DurationMinutes --%>
        <asp:HiddenField ID="hfTypeDurations" runat="server" ClientIDMode="Static" />

        <div class="wrap">

            <%-- ===== ENTÊTE PAGE ===== --%>
            <div class="top">
                <div>
                    <div class="title">
                        <asp:Literal ID="litTitle" runat="server" Text="Nouveau rendez-vous" />
                    </div>
                    <div class="sub">Remplissez les informations du rendez-vous.</div>
                </div>
                <div class="bar">
                    <asp:Button ID="btnDelete" runat="server" Text="Supprimer"
                        CssClass="btn danger" Visible="false"
                        OnClientClick="return confirm('Supprimer ce rendez-vous ?');" />
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn"
                        onclick="closeWin();">← Annuler</asp:HyperLink>
                    <asp:Button ID="btnInvoice" runat="server" Text="Facturer"
                        CssClass="btn"
                        ToolTip="Sauvegarder le rendez-vous et créer une facture" />
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <%-- ===== MESSAGE ===== --%>
            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <asp:HiddenField ID="hfId" runat="server" Value="0" />

            <%-- ===== CARD : INFORMATIONS GÉNÉRALES ===== --%>
            <div class="card">
                <div class="cardHead">
                    <div class="h">Informations</div>
                </div>

                <div class="cardBody">

                    <%-- Ligne 1 : Titre seul --%>
                    <div class="grid1">
                        <div class="field">
                            <label>Titre *</label>
                            <telerik:RadTextBox ID="txtTitle" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>

                    <%-- Ligne 2 : Client / Employé / Statut --%>
                    <div class="grid3" style="margin-top:12px;">
                        <div class="field">
                            <label>Client</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlCustomer"
                                runat="server" DefaultMessage="Sélectionner…"
                                DropDownHeight="200px" Skin="Metro" />
                        </div>
                        <div class="field">
                            <label>Employé / Ressource</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlEmployee"
                                runat="server" DefaultMessage="Sélectionner…"
                                DropDownHeight="200px" Skin="Metro" />
                        </div>
                        <div class="field">
                            <label>Statut</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlStatus"
                                runat="server" DropDownHeight="200px" Skin="Metro">
                                <Items>
                                    <telerik:DropDownListItem Value="Planifié" Text="Planifié" />
                                    <telerik:DropDownListItem Value="Confirmé" Text="Confirmé" />
                                    <telerik:DropDownListItem Value="Terminé"  Text="Terminé" />
                                    <telerik:DropDownListItem Value="Annulé"   Text="Annulé" />
                                    <telerik:DropDownListItem Value="NoShow"   Text="No-show" />
                                </Items>
                            </telerik:RadDropDownList>
                        </div>
                    </div>

                </div>
            </div>

            <%-- ===== CARD : DATES ET TYPE ===== --%>
            <div class="card">
                <div class="cardHead">
                    <div class="h">Date et durée</div>
                </div>

                <div class="cardBody">

                    <%-- Ligne 1 : Type / Date début / Heure début --%>
                    <div class="grid3">
                        <div class="field">
                            <label>Type</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlType"
                                runat="server" DefaultMessage="Sélectionner…"
                                DropDownHeight="200px" Skin="Metro" OnClientSelectedIndexChanged="aeOnTypeChanged">
                            
                            </telerik:RadDropDownList>
                            <div class="hint">La durée du type ajustera automatiquement la date de fin.</div>
                        </div>
                        <div class="field">
                            <label>Date de début *</label>
                            <telerik:RadDatePicker ID="rdpStart" runat="server"
                                RenderMode="Lightweight" Skin="Metro" Width="100%">
                                <DateInput DateFormat="yyyy-MM-dd" DisplayDateFormat="yyyy-MM-dd" />
                                <ClientEvents OnDateSelected="aeOnStartChanged" />
                            </telerik:RadDatePicker>
                        </div>
                        <div class="field">
                            <label>Heure de début *</label>
                            <telerik:RadTimePicker ID="rtpStart" runat="server"
                                RenderMode="Lightweight" Skin="Metro" Width="100%">
                                <DateInput DateFormat="HH:mm" DisplayDateFormat="HH:mm" />
                                <TimeView Interval="00:30:00" StartTime="07:00:00" EndTime="20:00:00" />
                                <ClientEvents OnDateSelected="aeOnStartChanged" />
                            </telerik:RadTimePicker>
                        </div>
                    </div>

                    <%-- Ligne 2 : Toute la journée / Date fin / Heure fin --%>
                    <div class="grid3" style="margin-top:12px;">
                        <div class="field">
                            <label>&nbsp;</label>
                            <label class="check">
                                <asp:CheckBox ID="cbAllDay" runat="server" />
                                <span>Toute la journée</span>
                            </label>
                        </div>
                        <div class="field">
                            <label>Date de fin *</label>
                            <telerik:RadDatePicker ID="rdpEnd" runat="server"
                                RenderMode="Lightweight" Skin="Metro" Width="100%">
                                <DateInput DateFormat="yyyy-MM-dd" DisplayDateFormat="yyyy-MM-dd" />
                            </telerik:RadDatePicker>
                        </div>
                        <div class="field">
                            <label>Heure de fin *</label>
                            <telerik:RadTimePicker ID="rtpEnd" runat="server"
                                RenderMode="Lightweight" Skin="Metro" Width="100%">
                                <DateInput DateFormat="HH:mm" DisplayDateFormat="HH:mm" />
                                <TimeView Interval="00:30:00" StartTime="07:00:00" EndTime="20:00:00" />
                            </telerik:RadTimePicker>
                        </div>
                    </div>

                </div>
            </div>

            <%-- ===== CARD : OPTIONS ===== --%>
            <div class="card">
                <div class="cardHead">
                    <div class="h">Options</div>
                </div>

                <div class="cardBody">

                    <div class="grid3">
                        <div class="field">
                            <label>Lieu</label>
                            <telerik:RadTextBox ID="txtLocation" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Récurrence</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlRecurrence"
                                runat="server" DropDownHeight="200px" Skin="Metro">
                                <Items>
                                    <telerik:DropDownListItem Value="" Text="Aucune" />
                                    <telerik:DropDownListItem Value="FREQ=DAILY;INTERVAL=1"   Text="Tous les jours" />
                                    <telerik:DropDownListItem Value="FREQ=WEEKLY;INTERVAL=1"  Text="Toutes les semaines" />
                                    <telerik:DropDownListItem Value="FREQ=WEEKLY;INTERVAL=2"  Text="Toutes les 2 semaines" />
                                    <telerik:DropDownListItem Value="FREQ=MONTHLY;INTERVAL=1" Text="Tous les mois" />
                                    <telerik:DropDownListItem Value="FREQ=YEARLY;INTERVAL=1"  Text="Tous les ans" />
                                </Items>
                            </telerik:RadDropDownList>
                        </div>
                        <div class="field">
                            <label>Rappel</label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlReminder"
                                runat="server" DropDownHeight="200px" Skin="Metro">
                                <Items>
                                    <telerik:DropDownListItem Value=""    Text="Aucun" />
                                    <telerik:DropDownListItem Value="5"   Text="5 minutes avant" />
                                    <telerik:DropDownListItem Value="15"  Text="15 minutes avant" />
                                    <telerik:DropDownListItem Value="30"  Text="30 minutes avant" />
                                    <telerik:DropDownListItem Value="60"  Text="1 heure avant" />
                                    <telerik:DropDownListItem Value="1440" Text="1 jour avant" />
                                </Items>
                            </telerik:RadDropDownList>
                        </div>
                    </div>

                    <div class="grid1" style="margin-top:12px;">
                        <div class="field">
                            <label>Description</label>
                            <telerik:RadTextBox ID="txtDescription" Width="100%" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike"
                                TextMode="MultiLine" Rows="4" />
                        </div>
                    </div>

                </div>
            </div>

        </div><%-- /wrap --%>


        <%-- =====================================================
             JAVASCRIPT
        ===================================================== --%>
        <script type="text/javascript">

            // ============================================================
            // Récupère les vrais ClientID (auto-générés par ASP.NET)
            // ============================================================
            var AE_IDS = {
                rdpStart: '<%= rdpStart.ClientID %>',
                rtpStart: '<%= rtpStart.ClientID %>',
                rdpEnd:   '<%= rdpEnd.ClientID %>',
                rtpEnd:   '<%= rtpEnd.ClientID %>',
                rddlType: '<%= rddlType.ClientID %>',
                hfTypeDurations: '<%= hfTypeDurations.ClientID %>'
            };

            // ============================================================
            // Map des durées par type
            // ============================================================
            var AE_TYPE_DURATIONS = {};
            try {
                var raw = document.getElementById(AE_IDS.hfTypeDurations).value || '{}';
                AE_TYPE_DURATIONS = JSON.parse(raw);
            } catch (e) {
                AE_TYPE_DURATIONS = {};
            }

            // ============================================================
            // État
            // ============================================================
            var AE_lastStart = null;   // valeur de Début avant le changement
            var AE_busy = false;       // évite les boucles

            // ============================================================
            // Helpers
            // ============================================================
            function aeGetDateTime(dpId, tpId) {
                var dp = $find(dpId);
                var tp = $find(tpId);
                if (!dp || !tp) return null;
                var d = dp.get_selectedDate();
                var t = tp.get_selectedDate();
                if (!d) return null;
                return new Date(
                    d.getFullYear(), d.getMonth(), d.getDate(),
                    t ? t.getHours() : 0,
                    t ? t.getMinutes() : 0,
                    0, 0
                );
            }

            function aeSetDateTime(dpId, tpId, dt) {
                var dp = $find(dpId);
                var tp = $find(tpId);
                if (!dp || !tp || !dt) return;
                dp.set_selectedDate(new Date(dt.getFullYear(), dt.getMonth(), dt.getDate()));
                tp.set_selectedDate(new Date(1980, 0, 1, dt.getHours(), dt.getMinutes(), 0));
            }

            // ============================================================
            // Handler appelé par RadDatePicker / RadTimePicker (Début)
            //   ClientEvents OnDateSelected="aeOnStartChanged"
            // ============================================================
            function aeOnStartChanged(sender, args) {
                if (AE_busy) return;

                // Différé : laisse Telerik finir d'appliquer ses changements
                setTimeout(function () {
                    AE_busy = true;
                    try {
                        var newStart = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                        if (!newStart) return;

                        var oldEnd = aeGetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd);

                        if (AE_lastStart && oldEnd) {
                            // Décale la fin du même delta → la durée est préservée
                            var delta = newStart.getTime() - AE_lastStart.getTime();
                            var newEnd = new Date(oldEnd.getTime() + delta);
                            aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd, newEnd);
                        } else if (oldEnd && oldEnd <= newStart) {
                            aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd,
                                new Date(newStart.getTime() + 60 * 60000));
                        }

                        AE_lastStart = newStart;
                    } finally {
                        AE_busy = false;
                    }
                }, 50);
            }

            // ============================================================
            // Handler appelé par RadDropDownList (Type)
            //   ClientEvents OnSelectedIndexChanged="aeOnTypeChanged"
            // ============================================================
            function aeOnTypeChanged(sender, args) {
                if (AE_busy) return;

                var item = sender.get_selectedItem();
                if (!item) return;

                var typeId = item.get_value();
                var durMin = parseInt(AE_TYPE_DURATIONS[typeId], 10);
                if (!durMin || durMin <= 0) return;

                var startDt = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                if (!startDt) return;

                AE_busy = true;
                try {
                    var newEnd = new Date(startDt.getTime() + durMin * 60000);
                    aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd, newEnd);
                } finally {
                    AE_busy = false;
                }
            }

            // ============================================================
            // Mémoriser la valeur initiale du Début pour le calcul du delta
            // ============================================================
            function aeInitLastStart() {
                AE_lastStart = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
            }

            if (typeof Sys !== 'undefined' && Sys.Application) {
                Sys.Application.add_load(aeInitLastStart);
            } else {
                document.addEventListener('DOMContentLoaded', aeInitLastStart);
            }

            // ============================================================
            // Fenêtre parente
            // ============================================================
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
                return false;
            }

        </script>

    </form>
</body>
</html>
