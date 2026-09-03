<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true" Async="true"
    CodeBehind="wbfCustomerEdit.aspx.vb" Inherits="MngConsul.wbfCustomerEdit" %>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("pageTitle") %></title>
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
        /* Réserve la place de la barre de défilement en permanence : quand la
           fenêtre modale « Édition adresse » s'ouvre, la barre de la page ne
           disparaît plus, donc la grille (et ses boutons) ne se décale plus. */
        html { scrollbar-gutter: stable; }

        body {
            font-family: var(--font);
            color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%),
                        var(--bg);
        }

        /* =============================================
           LAYOUT WRAP
        ============================================= */
        .wrap {
            max-width: 1100px;
            margin: 20px auto;
            padding: 0 16px 28px;
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
        .mono  { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }

        /* =============================================
           RADLISTVIEW ADRESSES — structure de base
        ============================================= */

        /* Conteneur général liste */
        .addr-list {
            border: 1px solid var(--line);
            border-radius: 14px;
            overflow-y: auto;              /* la liste ENTIÈRE défile (entête + lignes)  */
            overflow-x: hidden;
            scrollbar-gutter: stable;      /* réserve la barre : pas de décalage des colonnes */
            max-height: 340px;
            margin: 0 16px 16px;
        }

        /* Entête colonnes — desktop. Sticky DANS le conteneur scrollable : ainsi la
           barre de défilement rétrécit entête ET lignes de la même façon, et la
           colonne Actions reste alignée avec les boutons (fix : décalage après rebind). */
        .addr-list-head {
            display: grid;
            grid-template-columns: 120px 1fr 80px;
            gap: 12px;
            padding: 10px 16px;
            font-size: 12px;
            font-weight: 800;
            color: var(--muted);
            background: #f8fafc;
            border-bottom: 1px solid var(--line);
            box-sizing: border-box;
            position: sticky;
            top: 0;
            z-index: 1;
        }

        /* Le défilement est délégué à .addr-list (entête sticky). */
        .addr-list-body {
            min-height: 0;
        }

        /* Ligne adresse */
        .addr-row {
            display: grid;
            grid-template-columns: 120px 1fr 80px;
            gap: 12px;
            align-items: center;
            padding: 12px 16px;
            border-bottom: 1px solid #f1f5f9;
            background: #fff;
            box-sizing: border-box;
            transition: background .12s;
        }
        .addr-row:last-child { border-bottom: none; }
        .addr-row:hover      { background: #fafcff; }

        /* Badge type adresse */
        .addr-type-badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 800;
            background: var(--primary-weak);
            color: var(--primary);
            border: 1px solid rgba(37,99,235,.18);
            white-space: nowrap;
        }

        /* Adresse texte */
        .addr-text {
            font-size: 14px;
            font-weight: 600;
            color: var(--text);
            line-height: 1.4;
        }

        /* Actions dans la ligne */
        .addr-actions {
            display: flex;
            gap: 6px;
            justify-content: flex-end;
            align-items: center;
        }

        /* État vide */
        .addr-empty {
            padding: 24px;
            text-align: center;
            color: var(--muted);
            font-size: 14px;
        }

        /* Icônes boutons */
        .btn-icon {
            width: 36px; height: 36px; min-width: 0; padding: 0;
            display: inline-flex; align-items: center; justify-content: center;
            flex-shrink: 0;
            border-radius: 10px !important;
            border: 1px solid var(--line) !important;
            background: #fff !important;
            cursor: pointer;
        }
        .btn-icon:hover { background: #f1f5f9 !important; }

        .btn-icon-edit {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%232563eb' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7'/%3E%3Cpath d='M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 16px 16px !important;
        }

        .btn-icon-delete {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23ef4444' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='3 6 5 6 21 6'/%3E%3Cpath d='M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6'/%3E%3Cpath d='M10 11v6'/%3E%3Cpath d='M14 11v6'/%3E%3Cpath d='M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 16px 16px !important;
        }

        /* Interface DESKTOP uniquement (pas de version mobile/tablette) :
           layout fixe en 3 colonnes, aucune media query responsive. */

        /* =============================================
           SCAN / REMPLISSAGE AUTOMATIQUE
        ============================================= */
        /* Carte client : laisse le panneau scan déborder (overlay) et prime
           sur les cartes suivantes (z-index) — sinon .card { overflow:hidden } le rognerait. */
        .card-client { overflow: visible; position: relative; z-index: 5; }

        /* Boîte scan : pastille compacte dans l'entête ; panneau flottant à l'ouverture */
        .scan-box {
            position: relative;
            flex: 0 0 auto;
            width: 300px; max-width: 100%;
            border: 1px solid var(--line);
            border-radius: 10px;
            background: #f8fafc;
            padding: 6px 10px;
        }
        .scan-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; cursor: pointer; }
        .scan-box .scan-title { font-weight: 800; font-size: 13px; }
        .scan-box .scan-hint  { font-size: 11px; color: var(--muted); margin: 0 0 8px; }

        /* Chevron expand / collapse */
        .scan-toggle {
            flex: 0 0 auto;
            width: 24px; height: 24px; padding: 0;
            border: none; background: transparent;
            color: #64748b; cursor: pointer; border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
        }
        .scan-toggle:hover { background: #e2e8f0; color: #334155; }
        .scan-toggle .chev { font-size: 13px; line-height: 1; transition: transform .18s ease; }
        .scan-box.collapsed .scan-toggle .chev { transform: rotate(-90deg); }

        /* Panneau flottant : s'ouvre PAR-DESSUS tous les autres éléments */
        .scan-body {
            position: absolute;
            top: calc(100% + 6px);
            right: 0;
            width: 360px; max-width: 86vw;
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 12px;
            box-shadow: 0 18px 44px rgba(2,6,23,.20);
            padding: 12px;
            z-index: 100;
        }
        .scan-box.collapsed .scan-body { display: none; }

        .dropzone {
            position: relative;
            border: 2px dashed #cbd5e1;
            border-radius: 10px;
            background: #fff;
            padding: 10px;              /* était 18px */
            text-align: center;
            cursor: pointer;
            transition: border-color .15s, background .15s;
        }
        .dropzone:hover { border-color: var(--primary); background: #eff6ff; }
        .dropzone.drag  { border-color: #1d4ed8; background: rgba(59,130,246,.10); }
        .dropzone .dz-ico  { font-size: 18px; line-height: 1; }
        .dropzone .dz-text { font-size: 12px; color: #475569; font-weight: 600; margin-top: 4px; }
        .dropzone .dz-file { font-size: 12px; color: var(--primary); font-weight: 700; margin-top: 4px; min-height: 14px; word-break: break-all; }
        .dropzone .dz-input { position: absolute; width: 1px; height: 1px; opacity: 0; overflow: hidden; }

        .scan-row { display: flex; gap: 10px; align-items: center; margin-top: 8px; flex-wrap: wrap; }

        .scan-msg {
            margin-top: 8px;
            padding: 8px 12px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 700;
            border: 1px solid var(--line);
            background: #fff;
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

                <%-- Rafraîchit le RadListView des adresses après enregistrement --%>
                <telerik:AjaxSetting AjaxControlID="btnNewAddress">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rlvAddr" />
                        <telerik:AjaxUpdatedControl ControlID="pnlAddrEditor" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <telerik:AjaxSetting AjaxControlID="rlvAddr">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rlvAddr" />
                        <telerik:AjaxUpdatedControl ControlID="pnlMsg" />
                        <telerik:AjaxUpdatedControl ControlID="pnlAddrEditor" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <telerik:AjaxSetting AjaxControlID="btnAddrRefresh">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rlvAddr" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <%-- Cascade Pays → Province : recharge la liste des provinces/états du pays choisi --%>
                <telerik:AjaxSetting AjaxControlID="rddlPays">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rddlProvince" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

            </AjaxSettings>
        </telerik:RadAjaxManager>

        <div class="wrap">

            <%-- ===== ENTÊTE PAGE ===== --%>
            <div class="top">
                <div>
                    <div class="title"><asp:Literal ID="litEditTitle" runat="server" /></div>
                </div>
                <div class="bar">
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn"
                        onclick="closeWin();"></asp:HyperLink>
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <%-- ===== MESSAGE ===== --%>
            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <%-- ===== CARD : INFORMATIONS CLIENT ===== --%>
            <div class="card card-client">
                <div class="cardHead">
                    <div>
                        <div class="h"><asp:Literal ID="litCustomerInfo" runat="server" /></div>
                        <div class="grid4" style="margin-top:6px;">
                            <div class="small"><asp:Literal ID="litOriginLbl" runat="server" /> :
                                <telerik:RadLabel runat="server" ID="tlblOrigine"></telerik:RadLabel>
                            </div>
                            <div class="small"><asp:Literal ID="litCreatedLbl" runat="server" /> :
                                <telerik:RadLabel runat="server" ID="tlblCreated"></telerik:RadLabel>
                            </div>
                        </div>
                    </div>

                    <%-- Scan de document : compact dans l'entête ; le panneau s'ouvre en overlay --%>
                    <div id="scanBox" class="scan-box collapsed">
                        <div class="scan-head" onclick="toggleScanBox(); return false;">
                            <div class="scan-title"><asp:Literal ID="litScanTitle" runat="server" /></div>
                            <button type="button" id="btnScanToggle" runat="server" class="scan-toggle"
                                title="" aria-label="">
                                <span class="chev" aria-hidden="true">&#9662;</span>
                            </button>
                        </div>
                        <div class="scan-body">
                            <div class="scan-hint"><asp:Literal ID="litScanHint" runat="server" /></div>

                            <div id="dropZone" class="dropzone">
                                <div class="dz-ico" aria-hidden="true">⬆️</div>
                                <div class="dz-text"><asp:Literal ID="litDropZone" runat="server" /></div>
                                <div class="dz-file" id="dzFile"></div>
                                <asp:FileUpload ID="fileDoc" runat="server" ClientIDMode="Static"
                                    accept=".pdf,.png,.jpg,.jpeg,image/*,application/pdf" CssClass="dz-input" />
                            </div>

                            <div class="scan-row">
                                <asp:Button ID="btnExtract" runat="server" CssClass="btn primary"
                                    CausesValidation="false" Text="Analyser le document" />
                            </div>

                            <asp:Panel ID="pnlUpload" runat="server" Visible="false" CssClass="scan-msg">
                                <asp:Literal ID="litUpload" runat="server" />
                            </asp:Panel>
                        </div>
                    </div>
                </div>

                <div class="cardBody">
                    <div class="grid3">
                        <div class="field">
                            <label><asp:Literal ID="litLblName" runat="server" /></label>
                            <telerik:RadTextBox ID="txtName" Width="300px" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" MaxLength="500" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblDisplayName" runat="server" /></label>
                            <telerik:RadTextBox ID="txtDisplayName" Width="300px" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" MaxLength="500" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblType" runat="server" /></label>
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlPartyType"
                                runat="server" DefaultMessage="Sélectionner…"
                                DropDownHeight="110px" Skin="Metro" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblWebsite" runat="server" /></label>
                            <telerik:RadTextBox ID="txtWebsite" Width="300px" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" MaxLength="200" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblTPS" runat="server" /></label>
                            <telerik:RadTextBox ID="txtNoTPS" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" MaxLength="20" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblTVQ" runat="server" /></label>
                            <telerik:RadTextBox ID="txtNoTVQ" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" MaxLength="20" />
                        </div>
                        <div class="field">
                            <label><asp:Literal ID="litLblTermDays" runat="server" /></label>
                            <telerik:RadNumericTextBox ID="numTermDays" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" Width="100px"
                                MinValue="0" MaxValue="365" Value="0">
                                <NumberFormat DecimalDigits="0" GroupSeparator="" />
                            </telerik:RadNumericTextBox>
                        </div>
                    </div>

                    <div class="grid1" style="margin-top:12px;">
                        <div class="field">
                            <label><asp:Literal ID="litLblNote" runat="server" /></label>
                            <telerik:RadTextBox ID="txtNote" Width="100%" runat="server"
                                RenderMode="Lightweight" CssClass="rtbLike" TextMode="MultiLine" />
                        </div>
                    </div>
                </div>
            </div>

            <%-- ===== CARD : ADRESSES (RadListView remplace RadGrid) ===== --%>
            <div class="card">
                <div class="cardHead">
                    <div class="h"><asp:Literal ID="litAddresses" runat="server" /></div>
                    <div class="right">
                        <asp:Button ID="btnNewAddress" runat="server"
                            Text="+ Ajouter une adresse"
                            CssClass="btn primary" />
                    </div>
                </div>

                <%-- -------------------------------------------------------
                     RadListView : rlvAddr
                     DataKeyNames = "Id"  (même clé que l'ancien rgAddr)
                     Les CommandName "EditAddress" et "DeleteAddress" sont
                     identiques à ceux utilisés dans le code-behind existant.
                ------------------------------------------------------- --%>
                <telerik:RadListView ID="rlvAddr" runat="server"
                    Skin="Metro"
                    DataKeyNames="Id"
                    AllowPaging="false"
                    ItemPlaceholderID="addrPlaceholder"
                    ClientIDMode="Static">

                    <%-- LAYOUT TEMPLATE : contient le squelette de la liste --%>
                    <LayoutTemplate>
                        <div class="addr-list">

                            <%-- Entête colonnes (masqué sur mobile via CSS) --%>
                            <div class="addr-list-head">
                                <div><asp:Literal ID="litAddrColType" runat="server" /></div>
                                <div><asp:Literal ID="litAddrColAddress" runat="server" /></div>
                                <div style="text-align:right;"><asp:Literal ID="litAddrColActions" runat="server" /></div>
                            </div>

                            <%-- Corps : les items seront injectés ici --%>
                            <div class="addr-list-body">
                                <asp:PlaceHolder ID="addrPlaceholder" runat="server" />
                            </div>

                        </div>
                    </LayoutTemplate>

                    <%-- ITEM TEMPLATE : une ligne / carte par adresse --%>
                    <ItemTemplate>
                        <div class="addr-row">

                            <%-- Colonne 1 : Badge de type --%>
                            <div>
                                <span class="addr-type-badge">
                                    <%# Eval("Typename") %>
                                </span>
                            </div>

                            <%-- Colonne 2 : Adresse complète --%>
                            <div class="addr-text">
                                <%# Eval("Address") %>
                            </div>

                            <%-- Colonne 3 : Actions Modifier / Supprimer --%>
                            <div class="addr-actions">
                                <asp:Button ID="btnAddrEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip='<%# L("edit") %>'
                                    CausesValidation="false"
                                    CommandName="EditAddress"
                                    CommandArgument='<%# Eval("Id") %>' />

                                <asp:Button ID="btnAddrDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip='<%# L("delete") %>'
                                    CausesValidation="false"
                                    CommandName="DeleteAddress"
                                    CommandArgument='<%# Eval("Id") %>' />
                            </div>

                        </div>
                    </ItemTemplate>

                    <%-- EMPTY TEMPLATE : affiché quand aucune adresse --%>
                    <EmptyDataTemplate>
                        <div class="addr-empty">
                            <asp:Literal ID="litAddrEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

                <%-- ===== ÉDITEUR D'ADRESSE (RadWindow inchangé) ===== --%>
                <telerik:RadWindowManager ID="rwm1" runat="server" EnableShadow="true" />

                <telerik:RadWindow ID="rwAddr" runat="server"
                    Modal="true"
                    VisibleOnPageLoad="false"
                    Behaviors="Close,Move"
                    DestroyOnClose="false"
                    Width="820px"
                    Height="520px"
                    Title="Édition adresse"
                    OnClientClose="rwAddr_OnClientClose">
                    <ContentTemplate>

                        <asp:Panel ID="pnlAddrEditor" runat="server">
                            <asp:HiddenField ID="hfAddrId" runat="server" />

                            <div style="padding:14px;">
                                <div class="grid">

                                    <div class="field">
                                        <label><asp:Literal ID="litAddrType" runat="server" /></label>
                                        <telerik:RadDropDownList RenderMode="Lightweight"
                                            ID="rddlAddressType" runat="server"
                                            DefaultMessage="Sélectionner…" DropDownHeight="110px" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litAddrName" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtAddressName" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="200" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litAddr1" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtA1" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="500" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litAddr2" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtA2" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="500" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litCity" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtCity" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="50" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litProvince" runat="server" /></label>
                                        <telerik:RadDropDownList RenderMode="Lightweight"
                                            ID="rddlProvince" runat="server"
                                            DefaultMessage="Sélectionner…" DropDownHeight="110px" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litCountry" runat="server" /></label>
                                        <telerik:RadDropDownList RenderMode="Lightweight"
                                            ID="rddlPays" runat="server"
                                            AutoPostBack="true" OnSelectedIndexChanged="rddlPays_SelectedIndexChanged"
                                            DefaultMessage="Sélectionner…" DropDownHeight="110px" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litPostal" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtPostal" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="20" />
                                    </div>

                                    <div class="field">
                                        <label><asp:Literal ID="litAddrEmail" runat="server" /></label>
                                        <telerik:RadTextBox ID="txtAddrEmail" runat="server"
                                            RenderMode="Lightweight" CssClass="rtbLike" MaxLength="200" />
                                    </div>

                                </div>

                                <div class="field" style="margin-top:12px;">
                                    <label><asp:Literal ID="litAddrNote" runat="server" /></label>
                                    <telerik:RadTextBox ID="txtAddressNote" runat="server"
                                        RenderMode="Lightweight" CssClass="rtbLike" />
                                </div>

                                <div style="display:flex;justify-content:flex-end;gap:10px;
                                            margin-top:14px;flex-wrap:wrap;">
                                    <asp:Button ID="btnAddrSave" runat="server"
                                        Text="Enregistrer" CssClass="btn primary" />
                                    <asp:Button ID="btnAddrCancel" runat="server"
                                        Text="Annuler" CssClass="btn"
                                        CausesValidation="false"
                                        OnClientClick="closeAddrWindow(false); return false;" />
                                </div>
                            </div>

                        </asp:Panel>
                    </ContentTemplate>
                </telerik:RadWindow>

            </div><%-- /card adresses --%>

        </div><%-- /wrap --%>

        <%-- Bouton caché pour rebind après fermeture de la fenêtre adresse --%>
        <asp:Button ID="btnAddrRefresh" ClientIDMode="Static" runat="server"
            Style="display:none" />

        <%-- =====================================================
             JAVASCRIPT
        ===================================================== --%>
        <script type="text/javascript">

            /* Replie / déplie la boîte « Remplissage automatique par document »
               (l'entête reste visible, le chevron pivote). */
            function toggleScanBox() {
                var box = document.getElementById('scanBox');
                if (box) box.classList.toggle('collapsed');
            }

            /* Ferme la fenêtre adresse et signale si on a sauvegardé */
            function closeAddrWindow(saved) {
                var wnd = $find("rwAddr");
                wnd.close({ saved: saved === true });
            }

            /* Après fermeture de la fenêtre adresse : rebind si sauvegarde */
            function rwAddr_OnClientClose(sender, args) {
                var a = args.get_argument();
                if (a && a.saved) {
                    __doPostBack("btnAddrRefresh", "");
                }
            }

            /* Récupère la référence à la RadWindow parente (mode popup) */
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            /* Ferme la fenêtre courante (retour liste clients) */
            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
            }

        </script>

        <%-- Glisser-déposer d'un document dans la zone de scan.
             Le fichier déposé est injecté dans le <input type=file> (DataTransfer),
             puis le postback « Analyser » le traite comme une sélection classique. --%>
        <script type="text/javascript">
            (function () {
                function initDrop() {
                    var dz = document.getElementById('dropZone'),
                        inp = document.getElementById('fileDoc'),
                        lbl = document.getElementById('dzFile');
                    if (!dz || !inp) return;
                    if (dz.dataset.wired === '1') return;
                    dz.dataset.wired = '1';

                    function showName() { if (lbl) lbl.textContent = (inp.files && inp.files.length) ? inp.files[0].name : ''; }
                    dz.addEventListener('click', function () { inp.click(); });
                    inp.addEventListener('change', showName);

                    ['dragenter', 'dragover'].forEach(function (t) {
                        dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.add('drag'); });
                    });
                    ['dragleave', 'dragend', 'drop'].forEach(function (t) {
                        dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.remove('drag'); });
                    });
                    dz.addEventListener('drop', function (e) {
                        var files = e.dataTransfer && e.dataTransfer.files;
                        if (!files || !files.length) return;
                        try { var dt = new DataTransfer(); dt.items.add(files[0]); inp.files = dt.files; } catch (ex) { }
                        showName();
                    });
                }
                if (document.readyState !== 'loading') initDrop();
                else document.addEventListener('DOMContentLoaded', initDrop);
                if (window.Sys && Sys.Application) { Sys.Application.add_load(initDrop); }
            })();
        </script>

    </form>
</body>
</html>
