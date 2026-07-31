<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.master"
    CodeBehind="wbfReceipt.aspx.vb" Async="true" MaintainScrollPositionOnPostback="true" Inherits="MngConsul.wbfReceipt" %>

<%@ Register Src="~/Controls/jsonViewer.ascx" TagPrefix="uc1" TagName="jsonViewer" %>


<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Reçus — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>

    <style>
           .listview-list-head {
       display: grid;
       grid-template-columns:minmax(230px, 1.5fr) minmax(220px, 1.2fr) 130px 120px 150px 140px 120px ;
       gap: 12px;
       padding: 14px 16px;
       font-weight: 800;
       font-size: 13px;
       color: #0f172a;
       background: #f8fafc;
       border-bottom: 1px solid var(--mc-stroke);
       position: sticky;
       top: 0;
       z-index: 5;
   }

   .listview-row {
       display: grid;
       grid-template-columns: minmax(230px, 1.5fr) minmax(220px, 1.2fr) 130px 120px 150px 140px 120px    ;
       gap: 12px;
       align-items: start;
       padding: 14px 16px;
       border-bottom: 1px solid #eef2f7;
       background: #fff;
   }
        


        /* Petites touches pour harmoniser avec le thème du Site.master */
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

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .grid-wrap {
            padding: 16px;
        }

        .full-grid {
            height: calc(100vh - 220px);
        }

        .grid .btn,
        .RadGrid .btn,
        .RadGrid input[type=submit],
        .RadGrid input[type=button] {
            border-radius: 10px !important;
        }


            /* ===== ÉTAT DISABLED PRO ===== */
            .btn:disabled,
            .btn[disabled],
            .RadGrid .btn:disabled,
            .RadGrid input[type=submit]:disabled,
            .RadGrid input[type=button]:disabled {
                background: #e5e7eb !important; /* gris doux */
                color: #9ca3af !important; /* texte gris */
                border-color: #d1d5db !important;
                cursor: not-allowed !important;
                opacity: .75;
                box-shadow: none !important;
                transform: none !important;
            }

                /* empêche hover */
                .btn:disabled:hover {
                    background: #e5e7eb !important;
                }

        .receipt-shell {
            height: 100%;
            display: flex;
            flex-direction: column;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15,23,42,.06);
            min-height: 0;
        }

        .receipt-scroll {
            flex: 1 1 auto;
            overflow: auto;
            min-height: 0;
        }

        .receipt-list {
            display: flex;
            flex-direction: column;
            min-width: 1200px;
        }

     

             

        .receipt-actions,
        .receipt-process,
        .receipt-json,
        .receipt-process-json {
            display: flex;
            align-items: flex-start;
            justify-content: flex-start;
        }

        .receipt-file,
        .receipt-supplier,
        .receipt-status {
            color: #0f172a;
            min-width: 0;
            word-break: break-word;
        }

        .receipt-status {
            font-weight: 700;
            color: #475569;
        }

        .receipt-empty {
            padding: 40px 20px;
            text-align: center;
            color: var(--mc-muted);
        }

        .receipt-pager {
            flex: 0 0 auto;
            padding: 12px 16px 16px 16px;
            border-top: 1px solid var(--mc-stroke);
            background: #fff;
        }

        /* boutons dans listview */
        .receipt-row .btn,
        .receipt-row input[type=submit],
        .receipt-row input[type=button] {
            border-radius: 10px !important;
        }

            /* disabled */
            .receipt-row .btn:disabled,
            .receipt-row .btn[disabled],
            .receipt-row input[type=submit]:disabled,
            .receipt-row input[type=button]:disabled {
                background: #e5e7eb !important;
                color: #9ca3af !important;
                border-color: #d1d5db !important;
                cursor: not-allowed !important;
                opacity: .75;
                box-shadow: none !important;
                transform: none !important;
            }

                .receipt-row .btn:disabled:hover {
                    background: #e5e7eb !important;
                }

    </style>



</asp:Content>
<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">


    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmCustomers" runat="server" EnableShadow="true"></telerik:RadWindowManager>




    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Reçus</div>

            </div>

            <div class="searchbox">
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input  txttbsearch" placeholder="Rechercher (fournisseur, fichier, statut…)" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server"
                    CssClass="btn btn-icon btn-icon-clear"
                    Text=""
                    ToolTip="Effacer"
                    CausesValidation="false" />
            </div>
        </div>


        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="RadReceipt" runat="server"
                    DataKeyNames="imageGUID"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false"
                    AllowPaging="false"
                    ClientIDMode="Static">
                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div>Fichier</div>
                                <div>Fournisseur</div>
                                <div>Optimize and AI</div>
                                <div>Voir JSON</div>
                                <div>Process to Database</div>
                                <div>Statut</div>
                                <div>Action</div>
                            </div>
                        
                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                         <div class="listview-row">
                           

                            <div class="receipt-file">
                                <asp:Literal ID="litHtml" runat="server"
                                    Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(CStr(Eval("SourceFileName"))) %>' />
                                <asp:Literal ID="litHtmlOp" runat="server"
                                    Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(CStr(Eval("Optimized"))) %>' />
                            </div>

                            <div class="receipt-supplier">
                                <asp:Literal ID="litinfo" runat="server"
                                    Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(CStr(Eval("SupplierInfo"))) %>' />
                            </div>

                            <div class="receipt-process">
                                <asp:Button ID="btnProcess"
                                    runat="server"
                                    Text="Process AI"
                                    CssClass="btn"
                                    Enabled='<%# Eval("CanProcessAI") %>'
                                    CommandName="Process"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </div>

                            <div class="receipt-json">
                                <asp:Button ID="btnVoirJSON"
                                    runat="server"
                                    Text="Voir JSON"
                                    Visible='<%# Eval("CanViewJSON") %>'
                                    CssClass="btn"
                                    CommandName="VoirJSON"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </div>

                            <div class="receipt-process-json">
                                <asp:Button ID="btnProcessJSON"
                                    runat="server"
                                    Text="Process JSON"
                                    CssClass="btn"
                                    Visible='<%# Eval("CanViewJSON") %>'
                                    CommandName="ProcessJSON"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </div>

                            <div class="receipt-status">
                                <%# Eval("ProcessingStatus") %>
                            </div>
                              <div class="listview-actions">
     <asp:Button ID="btnDelete"
         runat="server"
         Text=""
          CssClass="btn btn-icon btn-icon-delete"
         CommandName="DeleteR"
         CommandArgument='<%# Eval("imageGUID") %>' />
 </div>



                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="receipt-empty">
                            Aucun reçu trouvé.
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>



            </div>
        </div>



    </telerik:RadAjaxPanel>


    <uc1:jsonViewer runat="server" id="jsonViewer" />

     


</asp:Content>
