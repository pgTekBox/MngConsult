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

  .listview-list-head {
            grid-template-columns: 70px 110px 1fr  90px  90px 100px 90px  90px   190px;
                               
            font-weight: 800;
            font-size: 13px;
            color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky;
            top: 0;
            z-index: 2;
        }

        .listview-row {
            grid-template-columns: 70px 110px 1fr  90px  90px 100px 90px  90px  190px;
                                 
            border-bottom: 1px solid #eef2f7;
            background: #fff;
        }
        

        .listview-actions {
            flex-wrap: nowrap;
        }

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

        .listview-list-head,
        .listview-row {
            display: grid;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            box-sizing: border-box;
        }

       

        /* Desktop — les wrappers mobiles sont invisibles */
        .field-row1,
        .field-row2 {
            display: contents; /* ← les enfants participent directement à la grille */
        }

        .field-number {
            grid-column: 1;
            grid-row: 1;
        }

        .field-date {
            grid-column: 2;
            grid-row: 1;
        }

        .field-supplier {
            grid-column: 3;
            grid-row: 1;
        }

        .field-etat {
            grid-column: 4;
            grid-row: 1;
        }
       .field-resteapayer{
            grid-column: 5;
            grid-row: 1;
        }


      .field-dejapaye{
            grid-column: 6;
            grid-row: 1;
        }
  .field-total {
            grid-column: 7;
            grid-row: 1;
        }

      .field-encaissement{
            grid-column: 8;
            grid-row: 1;
        }
      
          
      


      

        .listview-actions {
            grid-column: 9;
            grid-row: 1;
        }


    </style>

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">
    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true"></telerik:RadWindowManager>

        <asp:HiddenField ID="hfInvoiceDirty" runat="server" ClientIDMode="Static" Value="0" />

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
            </div>
            <div class="searchbox">
                <asp:Button ID="btnAddSupplierInvoice" runat="server"
                    CssClass="btn btnAddRow"  ClientIDMode="Static"
                    Text="Ajouter Facture"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwSupplierInvoices', 'wbfSupplierInvoinceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;"
                />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch"  ClientIDMode="Static" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />
                    <asp:Button ID="btnSearch"  ClientIDMode="Static" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear"  ClientIDMode="Static" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rgFournisseursFactures" runat="server"
                    Skin="Metro"
                    AllowPaging="False"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div class="colh-numero"><asp:Literal ID="litColNum" runat="server" /></div>
                                <div class="colh-date"><asp:Literal ID="litColDate" runat="server" /></div>
                                <div class="colh-supplier"><asp:Literal ID="litColSupplier" runat="server" /></div>
                                <div class="colh-statutpaiement"><asp:Literal ID="litColStatutPaiement" runat="server" /></div>
                                 <div class="colh-resteapayer"><asp:Literal ID="litColResteAPayer" runat="server" /></div>
                                 <div class="colh-dejapaye"><asp:Literal ID="litColDejaPaye" runat="server" /></div>



                                <div class="colh-total"><asp:Literal ID="litColTotal" runat="server" /></div>
                                <div class="colh-etat"><asp:Literal ID="litColEtat" runat="server" /></div>


                                <div class="colh-action"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder"  ClientIDMode="Static" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <%-- Ligne 1 mobile : Numéro + Date + Total --%>
                            <div class="field-row1">
                                <span class="field-number"><%# Eval("DocumentNumber") %></span>
                                <span class="field-date"><%# FormatDateFr(Eval("DocumentDate")) %></span>
                                <span class="field-total"><%# Eval("Total", "{0:C2}") %></span>
                            </div>

                            <%-- Ligne 2 mobile : Nom + État --%>
                            <div class="field-row2">
                                <span class="field-supplier"><%# Eval("Name") %></span>
                                <span class="field-statutpaiement"><%# Eval("StatutPaiement") %></span>
                                <span class="field-resteapayer"><%# Eval("ResteAPayer") %></span>
                                <span class="field-dejapaye"><%# Eval("DejaPaye") %></span>
                                <span class="field-etat"><%# Eval("Status") %></span>
                            </div>

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

                                <%-- Bouton "Payer via DreamPaiement EFT" : mêmes conditions que Stripe (non payée + comptabilisée) ;
                                     ouvre la page DreamPaiement dans un RadWindow (DocumentId / PartyId / Amount) --%>
                                <asp:Button ID="btnDreamPay" runat="server"
                                    CssClass="btn btn-icon btn-icon-dream"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("tipDreamPay") %>'
                                    CausesValidation="false"
                                    Visible='<%# CanPay(Eval("StatutPaiement"), Eval("ComptabilisationStatus")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Amount=" & FormatAmountForUrl(Eval("ResteAPayer")) & """ ,""rwDreamPayment"", ""wbfSupplierPaymentDream.aspx"", L_DREAM_TITLE, L_DREAM_TITLE);    return false;" %>' />

                                <%-- Bouton "Payer via Interac e-Transfer" (rail Interac, basé courriel) --%>
                                <asp:Button ID="btnInteracPay" runat="server"
                                    CssClass="btn btn-icon btn-icon-interac"
                                    Text=""  ClientIDMode="Static"
                                    ToolTip='<%# L("tipInteracPay") %>'
                                    CausesValidation="false"
                                    Visible='<%# CanPay(Eval("StatutPaiement"), Eval("ComptabilisationStatus")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Amount=" & FormatAmountForUrl(Eval("ResteAPayer")) & """ ,""rwInteracPayment"", ""wbfSupplierPaymentInterac.aspx"", L_INTERAC_TITLE, L_INTERAC_TITLE);    return false;" %>' />

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
