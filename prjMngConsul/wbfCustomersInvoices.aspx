<%@ Page  Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomersInvoices.aspx.vb" Inherits="MngConsul.wbfCustomersInvoices" %>

<%@ Register Src="~/Controls/PdfViewer.ascx" TagPrefix="uc1" TagName="PdfViewer" %>

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
            grid-template-columns: 70px 110px 1fr 90px 100px 80px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
        }
        

        .listview-actions {
            flex-wrap: nowrap;
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

        .field-total {
            grid-column: 5;
            grid-row: 1;
        }

        .listview-actions {
            grid-column: 6;
            grid-row: 1;
        }


        /* =========================
         TABLETTE — 769px à 1024px
      ========================= */
        @media  (max-width: 1024px) {

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
    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">
    <telerik:RadWindowManager ID="rwmCustomersInvoices" runat="server" EnableShadow="true"></telerik:RadWindowManager>



        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Client</div>
            </div>
            <div class="searchbox">
                <asp:Button ID="btnAddCustomerInvoice" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Facture"
                    CausesValidation="false"
                    OnClientClick="openCustomerInvoiceWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text=""CausesValidation="false" />
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
                                <div class="colh-numero">#</div>
                                <div class="colh-date">Date</div>
                                <div class="colh-customer">Client</div>

                                <div class="colh-etat">État</div>
                                <div class="colh-total">Total</div>
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
                                <span class="field-customer"><%# Eval("Name") %></span>
                                <span class="field-etat"><%# Eval("Status") %></span>
                            </div>

                            <div class="listview-actions">

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip="Modifier"
                                    CausesValidation="false"
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwInvoice"", ""wbfInvoiceEdit.aspx"", ""Modifier une facture"", ""Ajouter une facture""); return false;" %>' />
                                   
                                <asp:Button ID="Button1" runat="server"
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
        <button class="fab-add" onclick="openCustomerWindow(0); return false;" title="Ajouter un client">+</button>




    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwInvoice" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Title="Ajouter / Modifier une Facture"
        OnClientClose="rwCustomer_OnInvoiceClose"
        ClientIDMode="Static" >
    </telerik:RadWindow>


    <script src="js/RadWindows.js"></script>

    <script type="text/javascript">
       

        function rwCustomer_OnInvoiceClose(sender, args) {

            var ajaxManager = $find("RAP1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }


        }

    </script>
    <uc1:PdfViewer runat="server" id="PdfViewer" />

</asp:Content>
