<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliersInvoices.aspx.vb" Inherits="MngConsul.wbfSuppliersInvoices" %>

<%@ Register Src="~/Controls/PdfViewer.ascx" TagPrefix="uc1" TagName="PdfViewer" %>
<%@ Register Src="~/Controls/jsonViewer.ascx" TagPrefix="uc2" TagName="jsonViewer" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
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
            .field-supplier {
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

               

                .field-supplier {
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
    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">
    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true"></telerik:RadWindowManager>

        <asp:HiddenField ID="hfInvoiceDirty" runat="server" ClientIDMode="Static" Value="0" />

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Fournisseur</div>
            </div>
            <div class="searchbox">
                <asp:Button ID="btnAddSupplierInvoice" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Facture"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwSupplierInvoices', 'wbfSupplierInvoinceEdit.aspx', 'Modifier une facture', 'Ajouter une facture'); return false;" 
                />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
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
                                <div class="colh-numero">#</div>
                                <div class="colh-date">Date</div>
                                <div class="colh-supplier">Fournisseur</div>
                                <div class="colh-statutpaiement">Statut Paiement</div>
                                 <div class="colh-resteapayer">Reste A Payer</div>
                                 <div class="colh-dejapaye">Deja Payé</div>
                                   


                                <div class="colh-total">Total</div>
                                <div class="colh-etat">Etat</div>
                                 
                                
                                <div class="colh-action">Action</div>
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
                                <span class="field-supplier"><%# Eval("Name") %></span>
                                <span class="field-statutpaiement"><%# Eval("StatutPaiement") %></span>
                                <span class="field-resteapayer"><%# Eval("ResteAPayer") %></span>
                                <span class="field-dejapaye"><%# Eval("DejaPaye") %></span>
                                <span class="field-etat"><%# Eval("Status") %></span>
                            </div>

                            <div class="listview-actions">

                                <asp:Button ID="Button1" runat="server"
                                    CssClass="field-encaissement btn btn-icon btn-icon-receipt"
                                    Text=""
                                    ToolTip="Décaissement"
                                    CausesValidation="false"
                                    OnClientClick ='<%# "openRadWindowParam(" & Eval("PartyId") & ",""&PartyId=" & Eval("PartyId") & "&sens=DECAISSEMENT "" ,""rwEncaissement"", ""wbfReceiptEdit.aspx"", ""Modifier un décaissement"", ""Ajouter un décaissement"");    return false;" %>'
                                />

                                <%-- Bouton "Payer avec Stripe" : visible seulement si facture non payée et comptabilisée
                                     IMPORTANT : Amount doit etre formate en InvariantCulture (point decimal)
                                     pour eviter que la virgule FR soit interpretee comme separateur milliers --%>
                                <asp:Button ID="btnPay" runat="server"
                                    CssClass="btn btn-icon btn-icon-pay"
                                    Text=""
                                    ToolTip="Payer avec Stripe (Interac / ACSS / Carte)"
                                    CausesValidation="false"
                                    Visible='<%# CanPay(Eval("StatutPaiement"), Eval("ComptabilisationStatus")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Amount=" & FormatAmountForUrl(Eval("ResteAPayer")) & """ ,""rwSupplierPayment"", ""wbfSupplierPaymentChoice.aspx"", ""Payer le fournisseur"", ""Payer"");    return false;" %>' />

                                <%-- Bouton "Synchroniser paiements Stripe" : ouvre la page sync dans nouvelle fenêtre --%>
                                <asp:Button ID="btnSync" runat="server"
                                    CssClass="btn btn-icon btn-icon-sync"
                                    Text=""
                                    ToolTip="Synchroniser les paiements Stripe (si webhook a échoué)"
                                    CausesValidation="false"
                                    OnClientClick='<%# "window.open(""wbfSupplierPaymentSync.aspx?DocumentId="" + " & Eval("Id") & ", ""_blank"", ""width=800,height=900,scrollbars=yes""); return false;" %>' />

                                <%-- Bouton "Programmer auto-paiement" : visible si facture eligible + autorisation T144 active
                                     existe pour le fournisseur (sera affiche selon AutoPayCanSchedule retourne par s0023) --%>
                                <asp:Button ID="btnAutoPay" runat="server"
                                    CssClass='<%# IIf(IsAutoPayActive(Eval("AutoPay"), Eval("AutoPayStatus")), "btn btn-icon btn-icon-autopay-active", "btn btn-icon btn-icon-autopay") %>'
                                    Text=""
                                    ToolTip='<%# IIf(IsAutoPayActive(Eval("AutoPay"), Eval("AutoPayStatus")), "Auto-paiement programmé - cliquer pour gérer", "Programmer un paiement automatique") %>'
                                    CausesValidation="false"
                                    Visible='<%# CanShowAutoPayButton(Eval("StatutPaiement"), Eval("ComptabilisationStatus"), Eval("HasActiveAuthorization")) %>'
                                    OnClientClick='<%# "openRadWindowParam(" & Eval("Id") & ",""&DocumentId=" & Eval("Id") & "&PartyId=" & Eval("PartyId") & "&Total=" & FormatAmountForUrl(Eval("ResteAPayer")) & """, ""rwScheduleAutoPay"", ""wbfScheduleAutoPay.aspx"", ""Programmer auto-paiement"", ""Programmer"");    return false;" %>' />

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip="Modifier"
                                    CausesValidation="false"
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwSupplierInvoices"", ""wbfSupplierInvoinceEdit.aspx"", ""Modifier une facture"", ""Ajouter une facture"");    return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip="Supprimer"
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CausesValidation="false" />
                            </div>




                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="empty-state">
                            Aucune facture trouvée.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>
                <%-- FAB mobile --%>
        <button class="fab-add" onclick="openRadWindow(0, 'rwSupplierInvoices', 'wbfSupplierInvoinceEdit.aspx', 'Modifier une facture', 'Ajouter une facture'); return false;" title="Ajouter une facture">+</button>




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
    <uc1:PdfViewer runat="server" id="PdfViewer" />
    <uc2:jsonViewer runat="server" id="jsonViewer" />

</asp:Content>
