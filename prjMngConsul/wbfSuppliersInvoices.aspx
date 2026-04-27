<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliersInvoices.aspx.vb" Inherits="MngConsul.wbfSuppliersInvoices" %>

<%@ Register Src="~/Controls/jsonViewer.ascx" TagPrefix="uc1" TagName="jsonViewer" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <script src="js/viewport.js"></script>



    <style>
             .listview-list-head {
           grid-template-columns: 70px 110px 1fr 90px 100px 80px;
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
            grid-template-columns: 70px 110px 1fr 90px 100px  100px   100px  100px  80px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
        }

        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .page-title {
            font-weight: 900;
            font-size: 18px;
            line-height: 1.2;
        }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

        .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .full-grid {
            height: calc(100vh - 220px);
            padding: 16px;
            box-sizing: border-box;
        }

        .invoice-shell {
            height: 100%;
            display: flex;
            flex-direction: column;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15,23,42,.06);
            min-height: 0;
        }

        .invoice-scroll {
            flex: 1 1 auto;
            overflow: auto;
            min-height: 0;
        }

        .invoice-list {
            display: flex;
            flex-direction: column;
        }

     
        .invoice-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .invoice-number,
        .invoice-supplier,
        .invoice-status,
        .invoice-date {
            color: #0f172a;
            font-weight: 600;
            min-width: 0;
            word-break: break-word;
        }

        .invoice-total {
            color: #0f172a;
            font-weight: 800;
            text-align: right;
            white-space: nowrap;
        }

        .invoice-empty {
            padding: 40px 20px;
            text-align: center;
            color: var(--mc-muted);
        }

        .invoice-pager {
            flex: 0 0 auto;
            padding: 12px 16px 16px 16px;
            border-top: 1px solid var(--mc-stroke);
            background: #fff;
        }

        .btn.danger {
            border-color: #fecaca !important;
            background: #fff5f5 !important;
            color: #b91c1c !important;
        }

            .btn.danger:hover {
                background: #fee2e2 !important;
            }
 .listview-list-head,
 .listview-row {
     display: grid;
     gap: 16px;
     align-items: center;
     padding: 14px 16px;
     box-sizing: border-box;
 }





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
 .field-total {
         grid-column: 3;
         grid-row: 1;
     }


     .field-customer {
         grid-column: 3;
         grid-row: 1;
     }

     .field-supplier {
         grid-column: 4;
         grid-row: 1;
     }

    
       .field-etat {
      grid-column: 5;
      grid-row: 1;
  }    
       .field-DejaPaye {
    grid-column: 6;
    grid-row: 1;
}

               .field-ResteAPayer {
    grid-column: 7;
    grid-row: 1;
}
    .field-StatutPaiement {
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
        @media (min-width: 769px) and (max-width: 1024px) {

            .listview-list-head,
            .listview-row {
                grid-template-columns: 60px 100px 1fr 80px 90px 70px;
                gap: 12px;
                padding: 12px 14px;
            }
        }

        /* =========================
          MOBILE LARGE — 481px à 768px  grands smartphones en portrait
      ========================= */
        @media (min-width: 481px) and (max-width: 768px) {


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
    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true">    </telerik:RadWindowManager>
      <asp:HiddenField ID="hfInvoiceDirty" runat="server" ClientIDMode="Static" Value="0" />

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Fournisseurs</div>
            </div>
            <div class="searchbox">
                <asp:Button ID="btnAddSupplier" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Supplier"
                    CausesValidation="false"
                    OnClientClick="openSupplierInvoiceWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input  txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">
                <telerik:RadListView ID="rgFournisseursFactures" runat="server"
                    DataKeyNames="Id"
                    ClientIDMode="Static"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">

                                <div>Number</div>
                                <div>Supplier</div>
                                <div style="text-align: right;">Total</div>
                                <div>Status</div>
                                <div>Date</div>
                                <div>Actions</div>
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
                            <div class="field-number"><%# Eval("DocumentNumber") %></div>
                            <div class="field-date"><%# Eval("DocumentDate", "{0:yyyy-MM-dd}") %></div>
                            <div class="field-total"><%# Eval("Total", "{0:C2}") %></div>
                        </div>
                         <%-- Ligne 2 mobile : Nom + État --%>
                         <div class="field-row2">
                            <div class="field-supplier"><%# Eval("Name") %></div>
                            <div class="field-etat"><%# Eval("Status") %></div>

                             <div class="field-DejaPaye"><%# Eval("DejaPaye") %></div>
                                <div class="field-ResteAPayer"><%# Eval("ResteAPayer") %></div>
                                <div class="field-StatutPaiement"><%# Eval("StatutPaiement") %></div>
                          </div>

                            <div class="listview-actions">

                                
                                <asp:Button ID="Button1" runat="server" 
                                    CssClass="field-encaissement btn btn-icon btn-icon-receipt" 
                                    Text=""
                                    ToolTip="Encaissement"
                                    CausesValidation="false"
                                    OnClientClick ='<%# "openRadWindowParam(" & Eval("PartyId") & ",""&PartyId=" & Eval("PartyId") & "&sens=DECAISSEMENT "" ,""rwEncaissement"", ""wbfReceiptEdit.aspx"", ""Modifier unencaissement"", ""Ajouter un encaissement"");    return false;" %>' 
                                />



                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwSupplierInvoices"", ""wbfSupplierInvoinceEdit.aspx"", ""Modifier un fournisseur"", ""Ajouter un fournisseur""); return false;" %>' /> 
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>' />

                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucune facture trouvée.
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>
            </div>


        </div>
               <%-- FAB mobile --%>
       <button class="fab-add" onclick="openRadWindow(0); return false;" title="Ajouter un client">+</button>


    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwSupplierInvoices" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        ClientIDMode="Static"
        Title="Ajouter / Modifier un facture fournisseur"
        OnClientClose="rwSupplierInvoice_OnClientClose"
        OnClientPageLoad="rwSupplierInvoice_PageLoad"
        OnClientBeforeClose  ="rwSupplierInvoice_BeforeClose"
         
 >
 
    </telerik:RadWindow>

        <telerik:RadWindow ID="rwEncaissement" runat="server"
    Modal="true"
    VisibleOnPageLoad="false"
    Behaviors="Close,Move,Resize"
    DestroyOnClose="true"
    Title="Ajouter / Modifier unencaissement"
     OnClientClose="rwSupplierInvoice_OnClientClose"
 OnClientPageLoad="rwSupplierInvoice_PageLoad"
 OnClientBeforeClose  ="rwSupplierInvoice_BeforeClose"
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


        function rwSupplierInvoice_PageLoad(sender, args) {
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




        function rwSupplierInvoice_BeforeClose(sender, args) {

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

        function rwSupplierInvoice_OnClientClose(sender, args) {
            setInvoiceClean();
            var ajaxManager = $find("RAP1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }
        }
    </script>


     <uc1:jsonViewer runat="server" id="jsonViewer" />


</asp:Content>
