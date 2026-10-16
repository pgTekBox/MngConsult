<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliersInvoices.aspx.vb" Inherits="MngConsul.wbfSuppliersInvoices" %>

<%@ Register Src="~/Controls/PdfViewer.ascx" TagPrefix="uc1" TagName="PdfViewer" %>
<%@ Register Src="~/Controls/jsonViewer.ascx" TagPrefix="uc2" TagName="jsonViewer" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <script src="js/viewport.js?v=<%=DateTime.Now.Ticks %>"></script>

    <style>

    /* ── Ventes › Factures clients : la signature du gabarit « Portail du client ».
       Le titre pose sur le fond de la page (FondDePage), puis quatre indicateurs
       cliquables, la carte « recherche et filtres », et la carte de la liste. ── */
    .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
    .fc-tete .txt { flex: 1 1 260px }
    .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
    .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
    .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
    .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px }
    .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
    .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 }
    .fc-btn.primaire, input.fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
    .fc-btn.primaire:hover, input.fc-btn.primaire:hover { background: #143A73 }

    .fc-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 16px }
    .fc-kpi { padding: 14px 16px; border-radius: 22px; text-align: left; display: flex; flex-direction: column; gap: 2px; border: 2px solid transparent; background: #fff; color: #0E1F3D; cursor: pointer; font-family: inherit }
    .fc-kpi:hover { border-color: #D5DDE8 }
    .fc-kpi.on { border-color: #1B4F9C }
    .fc-kpi .lab { display: flex; align-items: center; gap: 8px; font-weight: 700; color: #44536E; font-size: 14px }
    .fc-kpi .lab i { width: 10px; height: 10px; border-radius: 50%; flex: none }
    .fc-kpi .val { font-size: 24px; font-weight: 800; line-height: 1.15 }
    .fc-kpi .sub { font-size: 14px; color: #44536E }

    .fc-filtres { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px }
    .fc-recherche { display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 0 6px 0 14px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; width: 100%; max-width: 520px; box-sizing: border-box }
    .fc-recherche:focus-within { border-color: #1B4F9C; box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .fc-recherche svg { flex: none }
    .fc-recherche input[type=text] { border: 0 !important; outline: none; flex: 1 1 auto; min-width: 0; background: transparent !important; color: #0E1F3D; font: inherit; font-size: 15px; padding: 0 !important; box-shadow: none !important; width: auto !important; border-radius: 0; max-width: none !important }
    .fc-recherche .btn-icon { width: 34px; height: 34px; border: 0; background-color: transparent !important; border-radius: 50% }
    .fc-recherche .btn-icon-search { margin-left: auto }
    .fc-recherche .btn-icon:hover { background-color: #F2F5F9 !important }
    .fc-groupes { display: flex; flex-wrap: wrap; gap: 10px 24px; align-items: flex-end }
    .fc-groupe { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 800; color: #5B6B86 }
    .fc-chips { display: flex; flex-wrap: wrap; gap: 6px }
    .fc-chip { display: inline-flex; align-items: center; gap: 6px; min-height: 36px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 13px; font-family: inherit; cursor: pointer }
    .fc-chip i { width: 8px; height: 8px; border-radius: 50%; flex: none }
    .fc-chip b { font-weight: 700; color: #5B6B86 }
    .fc-chip:hover { background: #F2F5F9 }
    .fc-chip.on { background: #0E1F3D; border-color: #0E1F3D; color: #fff }
    .fc-chip.on b { color: #AEBBCD }

    /* La liste : une carte blanche ; en-tête gris-bleu sans fond, lignes à filet doux. */
    .fc-liste.full-grid { height: auto; min-height: 0 }
    .fc-liste .list-shell { height: auto; padding: 6px 12px 12px; border-radius: 24px; background: #fff }
    .fc-liste .list-shell > * { flex: none; display: block }
    .fc-liste .listview-list-body { overflow: visible }
    .fc-liste .listview-list-head, .fc-liste .listview-row {
        display: grid; grid-template-columns: 96px 118px minmax(0, 2fr) 120px 112px 104px 132px 210px;
        gap: 10px; align-items: center; padding: 10px 6px; box-sizing: border-box;
    }
    .fc-liste .listview-list-head { position: static; background: transparent; border: 0; font-size: 14px; font-weight: 800; color: #5B6B86; z-index: auto }
    .fc-liste .listview-row { border: 0; border-top: 1px solid #E3E9F1; background: #fff; font-size: 15px }
    .fc-liste .listview-row:hover { background: #FAFCFF }
    .fc-liste .sort-link, .fc-liste .sort-link:hover, .fc-liste .sort-link:visited { color: inherit; text-decoration: none; cursor: pointer; font-weight: inherit }
    .fc-liste .sort-link:hover { text-decoration: underline }
    .fc-liste .adroite { text-align: right }
    .fc-liste .c-num { white-space: nowrap }
    .fc-liste .lien { font-weight: 800 }
    .fc-liste .c-ech { display: flex; flex-direction: column; line-height: 1.3 }
    .fc-liste .c-ech b { font-weight: 700 }
    .fc-liste .c-ech span { font-size: 13px; color: #44536E }
    .fc-liste .c-client { min-width: 0 }
    .fc-liste .c-client > div:first-child { font-weight: 800 }
    .fc-liste .cust-email { font-size: 13px; color: #44536E; margin-top: 0 }
    .fc-pay { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800; white-space: nowrap }
    .fc-liste .c-reste { text-align: right; font-weight: 800 }
    .fc-liste .c-reste.retard { color: #A3261C }
    .fc-liste .c-reste span { display: block; font-size: 12px; font-weight: 600; color: #44536E }
    .fc-liste .c-total { text-align: right; font-weight: 700 }
    .fc-etat { display: inline-flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 700 }
    .fc-etat svg { flex: none }
    .fc-liste .listview-actions { display: flex; justify-content: flex-end; gap: 4px; flex-wrap: nowrap }
    .fc-liste .listview-actions .btn-icon { width: 40px; height: 40px; border: 0; border-radius: 10px; background-color: transparent !important; background-size: 22px 22px !important }
    .fc-liste .listview-actions .btn-icon:hover { background-color: #F2F5F9 !important }
    .fc-liste .listview-actions .btn-icon-invoice-send { background-size: 26px 26px !important }
    .fc-liste .empty-state { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .fc-pied { padding: 12px 6px 0; color: #44536E; font-size: 14px }
    .fc-liste .listview-list { min-width: 1100px }
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: 90px 112px minmax(170px, 2fr) 104px 104px 100px 124px 256px }

        /* Icône PDF (cohérent avec les autres btn-icon-*) */
        .btn-icon-pdf {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23dc2626' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z'/%3E%3Cpolyline points='14 2 14 8 20 8'/%3E%3Cline x1='9' y1='13' x2='15' y2='13'/%3E%3Cline x1='9' y1='17' x2='15' y2='17'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 16px 16px !important;
        }

        /* Icône Payer (carte de crédit verte) */
        .btn-icon-pay {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2310b981' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='5' width='20' height='14' rx='2'/%3E%3Cpath d='M2 10h20'/%3E%3Cpath d='M7 15h4'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Icône DreamPaiement EFT (virement bancaire, sarcelle) */
        .btn-icon-dream {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%230d9488' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cline x1='3' y1='21' x2='21' y2='21'/%3E%3Cline x1='5' y1='21' x2='5' y2='10'/%3E%3Cline x1='19' y1='21' x2='19' y2='10'/%3E%3Cline x1='9' y1='21' x2='9' y2='10'/%3E%3Cline x1='15' y1='21' x2='15' y2='10'/%3E%3Cpolygon points='12 2 21 8 3 8'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Icône Interac e-Transfer (enveloppe/envoi, rouge Interac) */
        .btn-icon-interac {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23e4002b' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='4' width='20' height='16' rx='2'/%3E%3Cpath d='M22 6l-10 7L2 6'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Icône Sync Stripe (rotation orange) */
        .btn-icon-sync {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23f59e0b' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='23 4 23 10 17 10'/%3E%3Cpolyline points='1 20 1 14 7 14'/%3E%3Cpath d='M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Icône Programmer auto-paiement (robot/calendrier violet) */
        .btn-icon-autopay {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%237c3aed' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='4' width='18' height='18' rx='2'/%3E%3Cline x1='16' y1='2' x2='16' y2='6'/%3E%3Cline x1='8' y1='2' x2='8' y2='6'/%3E%3Cline x1='3' y1='10' x2='21' y2='10'/%3E%3Cpath d='M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01M16 18h.01'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }
        /* Icône AutoPay programmé (vert plein) */
        .btn-icon-autopay-active {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2310b981' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='4' width='18' height='18' rx='2'/%3E%3Cpolyline points='9 14 11 16 15 12'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

    </style>

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">
    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true"></telerik:RadWindowManager>

        <asp:HiddenField ID="hfInvoiceDirty" runat="server" ClientIDMode="Static" Value="0" />

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
             le titre, le sous-titre, et à droite le bouton en pastille. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div class="btns">
                <asp:Button ID="btnAddSupplierInvoice" runat="server"
                    CssClass="fc-btn primaire"  ClientIDMode="Static"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwSupplierInvoices', 'wbfSupplierInvoinceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;"
                />
            </div>
        </div>

        <%-- Les quatre indicateurs : un clic pose son filtre sur la liste, un second
             clic l'enlève (litKpis est rendu par ChargerIndicateurs). --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <%-- Un indicateur ou une puce de filtre cliqué : fcChip() pose « groupe|valeur »
             dans hfChip et clique le bouton caché, qui renvoie au serveur (btnChip_Click). --%>
        <asp:HiddenField ID="hfChip" runat="server" ClientIDMode="Static" />
        <asp:Button ID="btnChip" runat="server" ClientIDMode="Static" CausesValidation="false" Text="" style="display:none" />

        <section class="fc-filtres">
            <asp:Panel ID="pnlRecherche" runat="server" CssClass="fc-recherche" DefaultButton="btnSearch">
                <svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#44536E" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>
                <asp:TextBox ID="tbSearch"  ClientIDMode="Static" runat="server" CssClass="input txttbsearch" />
                <asp:Button ID="btnSearch"  ClientIDMode="Static" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear"  ClientIDMode="Static" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
            </asp:Panel>
            <div class="fc-groupes"><asp:Literal ID="litChips" runat="server" /></div>
        </section>

        <div class="fc-liste full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rgFournisseursFactures" runat="server"
                    Skin="Metro"
                    AllowPaging="False"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <%-- Toutes les colonnes sont triables, sauf « Action ». --%>
                            <div class="listview-list-head">
                                <div><asp:LinkButton ID="lnkSortNum" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="NumeroSort" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortDue" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="DueDate" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortSupplier" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="NameSort" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortPay" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="StatutPaiement" CausesValidation="false" /></div>
                                <div class="adroite"><asp:LinkButton ID="lnkSortReste" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="ResteAPayer" CausesValidation="false" /></div>
                                <div class="adroite"><asp:LinkButton ID="lnkSortTotal" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="Total" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortEtat" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="Status" CausesValidation="false" /></div>
                                <div class="adroite"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder"  ClientIDMode="Static" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <%-- Numéro (lien vers le reçu s'il y en a un), échéance avec la date de
                                 facture dessous, fournisseur et adresse, paiement en pastille (en retard
                                 si l'échéance est passée), reste (avec le payé), total, état, puis les actions. --%>
                            <div class="c-num"><%# Eval("DocumentNumber") %></div>
                            <div class="c-ech"><%# EcheanceCell(Eval("DueDate"), Eval("DocumentDate")) %></div>
                            <div class="c-client"><%# Eval("Name") %></div>
                            <div><%# PayPill(Eval("StatutPaiement"), Eval("DueDate"), Eval("ComptabilisationStatus")) %></div>
                            <div class='<%# ResteClass(Eval("StatutPaiement"), Eval("DueDate"), Eval("ComptabilisationStatus")) %>'><%# ResteCell(Eval("ResteAPayer"), Eval("DejaPaye")) %></div>
                            <div class="c-total"><%# Eval("Total", "{0:C2}") %></div>
                            <div><%# EtatCell(Eval("Status"), Eval("ComptabilisationStatus")) %></div>

                            <div class="listview-actions">

                                <asp:Button ID="Button1" runat="server"
                                    CssClass="field-encaissement btn btn-icon btn-icon-receipt"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("tipDecaiss") %>'
                                    CausesValidation="false"
                                    OnClientClick ='<%# "openRadWindowParam(" & Eval("PartyId") & ",""&PartyId=" & Eval("PartyId") & "&sens=DECAISSEMENT "" ,""rwEncaissement"", ""wbfReceiptEditPopup.aspx"", L_EDIT_DECAISS, L_ADD_DECAISS);    return false;" %>'
                                />

                                <%-- Bouton "Payer avec Stripe" : visible seulement si facture non payée et comptabilisée
                                     IMPORTANT : Amount doit etre formate en InvariantCulture (point decimal)
                                     pour eviter que la virgule FR soit interpretee comme separateur milliers --%>
                                <asp:Button ID="btnPay" runat="server"
                                    CssClass="btn btn-icon btn-icon-pay"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("tipPay") %>'
                                    CausesValidation="false"
                                    Visible='<%# CanPay(Eval("StatutPaiement"), Eval("ComptabilisationStatus")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Amount=" & FormatAmountForUrl(Eval("ResteAPayer")) & """ ,""rwSupplierPayment"", ""wbfSupplierPaymentChoice.aspx"", L_PAY_SUPPLIER, L_PAY);    return false;" %>' />

                                <%-- Les boutons « Payer via DreamPaiement (EFT) » et « Payer via
                                     Interac e-Transfer » ont ete retires de la grille sur demande.
                                     Les pages wbfSupplierPaymentDream.aspx / wbfSupplierPaymentInterac.aspx
                                     et leurs RadWindow restent en place. --%>

                                <%-- Bouton "Synchroniser paiements Stripe" : ouvre la page sync dans nouvelle fenêtre --%>
                                <asp:Button ID="btnSync" runat="server"
                                    CssClass="btn btn-icon btn-icon-sync"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("tipSync") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "window.open(""wbfSupplierPaymentSync.aspx?DocumentId="" + " & Eval("Id") & ", ""_blank"", ""width=800,height=900,scrollbars=yes""); return false;" %>' />

                                <%-- Bouton "Programmer auto-paiement" : visible si facture eligible + autorisation T144 active
                                     existe pour le fournisseur (sera affiche selon AutoPayCanSchedule retourne par s0023) --%>
                                <asp:Button ID="btnAutoPay" runat="server"
                                    CssClass='<%# IIf(IsAutoPayActive(Eval("AutoPay"), Eval("AutoPayStatus")), "btn btn-icon btn-icon-autopay-active", "btn btn-icon btn-icon-autopay") %>'
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# IIf(IsAutoPayActive(Eval("AutoPay"), Eval("AutoPayStatus")), L("tipAutoPayActive"), L("tipAutoPaySched")) %>'
                                    CausesValidation="false"
                                    Visible='<%# CanShowAutoPayButton(Eval("StatutPaiement"), Eval("ComptabilisationStatus"), Eval("HasActiveAuthorization")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Total=" & FormatAmountForUrl(Eval("ResteAPayer")) & """, ""rwScheduleAutoPay"", ""wbfScheduleAutoPay.aspx"", L_SCHED_AUTOPAY, L_SCHEDULE);    return false;" %>' />

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("edit") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwSupplierInvoices"", ""wbfSupplierInvoinceEdit.aspx"", L_EDIT_INVOICE, L_ADD_INVOICE);    return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("delete") %>'
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CausesValidation="false" />
                            </div>




                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="empty-state">
                            <asp:Literal ID="litEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

                <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>

            </div>
        </div>
                <%-- FAB mobile --%>
        <button id="fabAdd" runat="server" type="button"  ClientIDMode="Static" class="fab-add" onclick="openRadWindow(0, 'rwSupplierInvoices', 'wbfSupplierInvoinceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;" title="">+</button>




    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwSupplierInvoices" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Title="Ajouter / Modifier une Facture Fournisseur"
        OnClientPageLoad="rwInvoice_PageLoad"
        OnClientBeforeClose="rwInvoice_BeforeClose"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>


     <telerik:RadWindow ID="rwEncaissement" runat="server"
     Modal="true"
     VisibleOnPageLoad="false"
     Behaviors="Close,Move,Resize"
     DestroyOnClose="true"
     Title="Ajouter / Modifier un décaissement"
      OnClientPageLoad="rwInvoice_PageLoad"
  OnClientBeforeClose="rwInvoice_BeforeClose"
  OnClientClose="rwInvoice_OnInvoiceClose"
     ClientIDMode="Static" >
 </telerik:RadWindow>

    <%-- Modal de choix de méthode de paiement (Interac / ACSS / Carte) --%>
    <telerik:RadWindow ID="rwSupplierPayment" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move"
        DestroyOnClose="true"
        Width="720"
        Height="780"
        Title="Payer le fournisseur"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>

    <%-- Modal de paiement DreamPaiement EFT --%>
    <telerik:RadWindow ID="rwDreamPayment" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move"
        DestroyOnClose="true"
        Width="720"
        Height="780"
        Title="Payer via DreamPaiement (EFT)"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>

    <%-- Modal de paiement Interac e-Transfer --%>
    <telerik:RadWindow ID="rwInteracPayment" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move"
        DestroyOnClose="true"
        Width="720"
        Height="720"
        Title="Payer via Interac e-Transfer"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>

    <%-- Modal "Programmer auto-paiement" --%>
    <telerik:RadWindow ID="rwScheduleAutoPay" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move"
        DestroyOnClose="true"
        Width="640"
        Height="580"
        Title="Programmer paiement automatique"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>




    <script src="js/RadWindows.js"></script>

    <telerik:RadCodeBlock ID="rcbInvoicesJs" runat="server">
    <script type="text/javascript">
        // Un indicateur ou une puce de filtre : « groupe|valeur » dans le champ caché,
        // puis le bouton caché renvoie au serveur (btnChip_Click) par le RadAjaxPanel.
        function fcChip(g, v) {
            document.getElementById("hfChip").value = g + "|" + v;
            document.getElementById("btnChip").click();
        }


        // Libelles localises (fr/en/es). Les blocs de rendu serveur ci-dessous DOIVENT
        // rester dans le RadCodeBlock englobant : sinon ils verrouillent le conteneur
        // MainContent, et le RadAjaxPanel (RadAjaxControl) echoue a s'envelopper
        // (MoveUpdatePanel -> AddAt). Variables referencees par les OnClientClick de la grille.
        var L_ADD_INVOICE = "<%= L("addInvoiceWin") %>";
        var L_EDIT_INVOICE = "<%= L("editInvoiceWin") %>";
        var L_ADD_DECAISS = "<%= L("addDecaissWin") %>";
        var L_EDIT_DECAISS = "<%= L("editDecaissWin") %>";
        var L_PAY_SUPPLIER = "<%= L("payWin") %>";
        var L_PAY = "<%= L("pay") %>";
        var L_SCHED_AUTOPAY = "<%= L("schedAutoPayWin") %>";
        var L_SCHEDULE = "<%= L("schedule") %>";
        var L_DREAM_TITLE = "<%= L("winDreamTitle") %>";
        var L_INTERAC_TITLE = "<%= L("winInteracTitle") %>";
        var L_CONFIRM_UNSAVED = "<%= L("confirmUnsaved") %>";
        var L_CONFIRM_TITLE = "<%= L("confirmTitle") %>";

        function setInvoiceDirty() {

            document.getElementById("hfInvoiceDirty").value = "1";
        }

        function setInvoiceClean() {
            document.getElementById("hfInvoiceDirty").value = "0";
        }

        function isInvoiceDirty() {
            return document.getElementById("hfInvoiceDirty").value === "1";
        }


        function rwInvoice_PageLoad(sender, args) {
            wireDirtyTracking(); // iframe prête ✔
        }
        function wireDirtyTracking() {
            var oWnd = $find("rwSupplierInvoices");
            console.log(oWnd);
            if (!oWnd) return;

            var iframe = oWnd.get_contentFrame();
            console.log(iframe);
            if (!iframe || !iframe.contentWindow || !iframe.contentWindow.document) return;

            var doc = iframe.contentWindow.document;

            var inputs = doc.querySelectorAll("input, textarea, select");

            inputs.forEach(function (el) {
                if (el.type === "hidden") return;

                el.addEventListener("change", setInvoiceDirty);
                el.addEventListener("input", setInvoiceDirty);
            });
        }


        function rwInvoice_BeforeClose(sender, args) {

            if (!isInvoiceDirty()) return;

            // 🔴 On bloque la fermeture tout de suite
            args.set_cancel(true);

            // Telerik confirm (asynchrone)
            radconfirm(
                L_CONFIRM_UNSAVED,
                function (arg) {

                    if (arg) {
                        // utilisateur confirme → on ferme manuellement
                        setInvoiceClean(); // optionnel
                        sender.close();
                    }

                    // sinon → on ne fait rien (reste ouvert)
                },
                350, // largeur
                180, // hauteur
                null,
                L_CONFIRM_TITLE
            );
        }


        function rwInvoice_OnInvoiceClose(sender, args) {
            setInvoiceClean();
            var ajaxManager = $find("RAP1");
            if (ajaxManager) {

                ajaxManager.ajaxRequest("refreshgrid");
            }


        }






    </script>
    </telerik:RadCodeBlock>
    <uc1:PdfViewer runat="server" id="PdfViewer" />
    <uc2:jsonViewer runat="server" id="jsonViewer" />

</asp:Content>
