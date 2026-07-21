<%@ Page  Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomersInvoices.aspx.vb" Inherits="MngConsul.wbfCustomersInvoices" %>

<%@ Register Src="~/Controls/PdfViewer.ascx" TagPrefix="uc1" TagName="PdfViewer" %>

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

        /* Courriel (billing) affiché sous l'adresse dans la colonne Client */
        .cust-email {
            font-size: 12px;
            color: #64748b;
            margin-top: 2px;
            word-break: break-all;
        }

        /* Icône Envoyer par courriel (enveloppe) */
        .btn-icon-email {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%230891b2' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='4' width='20' height='16' rx='2'/%3E%3Cpath d='m22 7-10 6L2 7'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Icône Encaisser / lien de paiement Square (bleu Square) */
        .btn-icon-collect {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23006aff' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71'/%3E%3Cpath d='M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71'/%3E%3C/svg%3E") !important;
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

        .field-customer {
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


      .field-dejarecu{
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


        /* =========================
         TABLETTE — 769px à 1024px
      ========================= */
        @media  (max-width: 1024px) {

            .listview-list-head,
            .listview-row {
                grid-template-columns: 60px 100px 1fr 80px  80px  90px 70px;
                gap: 12px;
                padding: 12px 14px;
            }
        }

        /* =========================
          MOBILE LARGE — 481px à 768px  grands smartphones en portrait
      ========================= */
        @media  (max-width: 768px) {


            .listview-list-head {
                display: none;
            }

            .listview-row {
                grid-template-columns: 1fr auto;
                grid-template-rows: auto auto;
                gap: 2px 2px;
                padding: 2px;
            }

            /* Wrappers redeviennent flex */
            .field-row1 {
                grid-column: 1;
                grid-row: 1;
                display: flex;
                align-items: center;
                gap: 2px;
                flex-wrap: nowrap;
            }

            .field-row2 {
                grid-column: 1;
                grid-row: 2;
                display: flex;
                align-items: center;
                gap: 2px;
            }

            /* Ligne 1 */
            .field-number {
                font-size: 13px;
                font-weight: 700;
                color: #64748b;
                white-space: nowrap;
            }

            .field-date {
                font-size: 13px;
                color: #64748b;
                white-space: nowrap;
               margin-left: auto;
        margin-right: auto;
            }

            .field-total {
                font-weight: 800;
                font-size: 14px;
                color: #0f172a;
                margin-left: auto; /* ← pousse le total à droite */
                white-space: nowrap;
            }



            /* Ligne 2 */
            .field-customer {
                font-weight: 700;
                font-size: 15px;
                color: #0f172a;
            }

            .field-etat {
                font-size: 12px;
                color: #64748b;
                margin-left: auto;
            }


            /* Actions — colonne droite sur 2 lignes */
            .listview-actions {
                grid-column: 2;
                grid-row: 1 / -1;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                gap: 6px;
            }
        }

            /* =========================
             PETIT MOBILE — max 480px
             ========================= */
            @media (max-width: 480px) {


                .listview-list-head {
                    display: none;
                }

              
            .listview-row {
                grid-template-columns: 1fr auto;
                grid-template-rows: auto auto;
                gap: 2px 2px;
                padding: 2px;
            }

            /* Wrappers redeviennent flex */
            .field-row1 {
                grid-column: 1;
                grid-row: 1;
                display: flex;
                align-items: center;
                gap: 2px;
                flex-wrap: nowrap;
            }

            .field-row2 {
                grid-column: 1;
                grid-row: 2;
                display: flex;
                align-items: center;
                gap: 2px;
            }


                .field-number {
                    font-size: 12px;
                    font-weight: 700;
                    color: #64748b;
                    white-space: nowrap;
                }

                .field-date {
                    font-size: 12px;
                    color: #64748b;
                    white-space: nowrap;
                    margin-left: auto;
        margin-right: auto;
                }

                .field-total {
                    font-weight: 800;
                    font-size: 13px;
                    margin-left: auto;
                    white-space: nowrap;
                }

               

                .field-customer {
                    font-weight: 700;
                    font-size: 14px;
                }

                .field-etat {
                    font-size: 12px;
                    color: #64748b;
                    margin-left: auto;
                }

              

                .listview-actions {
      grid-column: 2;
      grid-row: 1 / -1;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      gap: 6px;
  }
                      

            }
       
    </style>

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <%-- Le RadWindowManager (radalert/radconfirm) DOIT rester HORS du RadAjaxPanel :
         sinon chaque rebind AJAX le re-rend et laisse un fond modal orphelin qui
         bloque les clics (l'envoi « fonctionne une fois puis plus »). --%>
    <telerik:RadWindowManager ID="rwmCustomersInvoices" runat="server" EnableShadow="true"></telerik:RadWindowManager>
    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <asp:HiddenField ID="hfInvoiceDirty" runat="server" ClientIDMode="Static" Value="0" />

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
            </div>
            <div class="searchbox">
                <asp:Button ID="btnAddCustomerInvoice" runat="server"
                    CssClass="btn btnAddRow"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;"
                />
                <asp:Button ID="btnImportSquare" runat="server"
                    CssClass="btn btnAddRow"
                    CausesValidation="false" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvClientsFactures" runat="server"
                    Skin="Metro"
                    AllowPaging="False"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div class="colh-numero"><asp:Literal ID="litColNum" runat="server" /></div>
                                <div class="colh-date"><asp:Literal ID="litColDate" runat="server" /></div>
                                <div class="colh-customer"><asp:Literal ID="litColCustomer" runat="server" /></div>
                                <div class="colh-statutpaiement"><asp:Literal ID="litColStatutPaiement" runat="server" /></div>
                                 <div class="colh-resteapayer"><asp:Literal ID="litColResteAPayer" runat="server" /></div>
                                 <div class="colh-dejarecu"><asp:Literal ID="litColDejaRecu" runat="server" /></div>



                                <div class="colh-total"><asp:Literal ID="litColTotal" runat="server" /></div>
                                <div class="colh-etat"><asp:Literal ID="litColEtat" runat="server" /></div>



                                <div class="colh-action"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
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
                                <span class="field-customer"><%# Eval("Name") %></span>
                                <span class="field-statutpaiement"><%# Eval("StatutPaiement") %></span>
                                <span class="field-resteapayer"><%# Eval("ResteAPayer") %></span>
                                <span class="field-dejarecu"><%# Eval("DejaRecu") %></span>
                                <span class="field-etat"><%# Eval("Status") %></span>
                            </div>

                            <div class="listview-actions">

                                <asp:Button ID="Button1" runat="server"
                                    CssClass="field-encaissement btn btn-icon btn-icon-receipt"
                                    Text=""
                                    ToolTip='<%# L("tipCashIn") %>'
                                    CausesValidation="false"
                                    OnClientClick ='<%# "openRadWindowParam(" & Eval("PartyId") & ",""&PartyId=" & Eval("PartyId") & "&sens=ENCAISSEMENT "" ,""rwEncaissement"", ""wbfReceiptEditPopup.aspx"", L_EDIT_CASHIN, L_ADD_CASHIN);    return false;" %>'
                                />

                                <%-- Bouton "Encaisser" : genere un lien de paiement Square (page hebergee) --%>
                                <asp:Button ID="btnSquarePay" runat="server"
                                    CssClass="btn btn-icon btn-icon-collect"
                                    Text=""
                                    ToolTip='<%# L("tipSquarePay") %>'
                                    CausesValidation="false"
                                    Visible='<%# CanCollect(Eval("StatutPaiement")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Amount=" & FormatAmountForUrl(Eval("ResteAPayer")) & """ ,""rwSquarePay"", ""wbfCustomerPaymentLink.aspx"", L_SQUARE, L_SQUARE);    return false;" %>' />

                                <asp:Button ID="btnSendEmail" runat="server"
                                    CssClass="btn btn-icon btn-icon-email"
                                    Text=""
                                    ToolTip='<%# L("tipSendEmail") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "openSendEmailDialog(" & Eval("Id") & "); return false;" %>' />

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip='<%# L("tipEdit") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwInvoice"", ""wbfInvoiceEdit.aspx"", L_EDIT_INVOICE, L_ADD_INVOICE);    return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip='<%# L("tipDelete") %>'
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




    </telerik:RadAjaxPanel>

    <%-- FAB mobile — titre posé par JS (pas de bloc de code inline : cMain est verrouillé par RadAjaxPanel) --%>
    <button class="fab-add" onclick="openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;">+</button>

    <telerik:RadWindow ID="rwInvoice" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Title="Ajouter / Modifier une Facture"
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
     Title="Ajouter / Modifier unencaissement"
      OnClientPageLoad="rwInvoice_PageLoad"
  OnClientBeforeClose="rwInvoice_BeforeClose"
  OnClientClose="rwInvoice_OnInvoiceClose"
     ClientIDMode="Static" >
 </telerik:RadWindow>

    <%-- Modal : lien de paiement Square (encaissement facture client) --%>
    <telerik:RadWindow ID="rwSquarePay" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move"
        DestroyOnClose="true"
        Width="620"
        Height="560"
        Title="Encaisser (Square)"
        OnClientClose="rwInvoice_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>




    <script src="js/RadWindows.js"></script>

    <%-- RadCodeBlock OBLIGATOIRE : RadAjaxPanel verrouille le Content parent (cMain),
         donc aucun bloc de code inline ne doit être enfant direct de cMain (cf. mémoire i18n). --%>
    <telerik:RadCodeBlock ID="rcbLang" runat="server">
        <script type="text/javascript">
            // Titres localisés des fenêtres modales (RadWindow)
            var L_EDIT_INVOICE = "<%= L("winEditInvoice") %>";
            var L_ADD_INVOICE = "<%= L("winAddInvoice") %>";
            var L_EDIT_CASHIN = "<%= L("winEditCashIn") %>";
            var L_ADD_CASHIN = "<%= L("winAddCashIn") %>";
            var L_SQUARE = "<%= L("winSquare") %>";
            var L_ADD_INVOICE_TIP = "<%= L("addInvoice") %>";
            // Titre du FAB défini ici (pas de bloc de code inline dans le bouton)
            (function () {
                function setFab() { var f = document.querySelector(".fab-add"); if (f) f.title = L_ADD_INVOICE_TIP; }
                document.addEventListener("DOMContentLoaded", setFab);
                if (window.Sys && Sys.Application) { Sys.Application.add_load(setFab); }
            })();
        </script>
    </telerik:RadCodeBlock>

    <script type="text/javascript">
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
            var oWnd = $find("rwInvoice");
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
                "⚠️ Vous avez des modifications non sauvegardées.<br/>Voulez-vous vraiment fermer ?",
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
                "Confirmation"
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
    <%-- Dialogue : envoyer la facture par courriel (avec ou sans lien de paiement Square) --%>
    <div id="sendEmailOverlay" style="display:none; position:fixed; inset:0; z-index:10000;
         background:rgba(15,23,42,.55); align-items:center; justify-content:center;">
        <div style="background:#fff; border-radius:16px; box-shadow:0 20px 60px rgba(0,0,0,.3);
             width:92vw; max-width:460px; padding:24px; box-sizing:border-box;">
            <div style="font-weight:800; font-size:16px; color:#0f172a; margin-bottom:8px;">
                <asp:Literal ID="litDlgTitle" runat="server" />
            </div>
            <div style="color:#475569; font-size:14px; line-height:1.5; margin-bottom:22px;">
                <asp:Literal ID="litDlgQuestion" runat="server" />
            </div>
            <div style="display:flex; gap:10px; flex-wrap:wrap; justify-content:flex-end;">
                <button type="button" onclick="closeSendEmailDialog()"
                    style="padding:10px 16px; border:1px solid #cbd5e1; background:#fff; color:#475569;
                           border-radius:10px; font-weight:700; cursor:pointer;"><asp:Literal ID="litDlgCancel" runat="server" /></button>
                <button type="button" onclick="doSendEmail(0)"
                    style="padding:10px 16px; border:1px solid #2563eb; background:#fff; color:#2563eb;
                           border-radius:10px; font-weight:700; cursor:pointer;"><asp:Literal ID="litDlgWithout" runat="server" /></button>
                <button type="button" onclick="doSendEmail(1)"
                    style="padding:10px 16px; border:1px solid #16a34a; background:#16a34a; color:#fff;
                           border-radius:10px; font-weight:700; cursor:pointer;"><asp:Literal ID="litDlgWith" runat="server" /></button>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        var _sendEmailInvoiceId = 0;
        function openSendEmailDialog(id) {
            _sendEmailInvoiceId = id;
            document.getElementById("sendEmailOverlay").style.display = "flex";
        }
        function closeSendEmailDialog() {
            document.getElementById("sendEmailOverlay").style.display = "none";
        }
        function doSendEmail(includeSquare) {
            closeSendEmailDialog();
            var mgr = $find("RAP1");
            if (mgr) { mgr.ajaxRequest("sendmail|" + _sendEmailInvoiceId + "|" + includeSquare); }
        }
        // Fermer en cliquant le fond sombre
        document.getElementById("sendEmailOverlay").addEventListener("click", function (e) {
            if (e.target === this) closeSendEmailDialog();
        });
    </script>

    <uc1:PdfViewer runat="server" id="PdfViewer" />

</asp:Content>
