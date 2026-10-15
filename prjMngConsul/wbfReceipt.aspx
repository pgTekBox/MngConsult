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
    .fc-recherche { display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 0 6px 0 14px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff }
    .fc-recherche:focus-within { border-color: #1B4F9C; box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .fc-recherche svg { flex: none }
    .fc-recherche input[type=text] { border: 0 !important; outline: none; flex: 1 1 auto; min-width: 0; background: transparent !important; color: #0E1F3D; font: inherit; font-size: 15px; padding: 0 !important; box-shadow: none !important; width: auto !important; border-radius: 0 }
    .fc-recherche .btn-icon { width: 34px; height: 34px; border: 0; background-color: transparent !important; border-radius: 50% }
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
    /* Les colonnes des reçus : fichier, fournisseur, lecture IA, résultat, comptabilisation, statut, action. */
    .fc-liste .listview-list { min-width: 1080px }
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: minmax(220px, 1.5fr) minmax(200px, 1.2fr) 130px 130px 170px 110px 70px; align-items: start }
    .fc-liste .listview-row .btn { min-height: 34px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 13px; font-family: inherit; cursor: pointer }
    .fc-liste .listview-row .btn:hover { background: #F2F5F9 }
    .fc-liste .listview-row .btn:disabled { background: #F2F5F9 !important; color: #AEBBCD !important; border-color: #E3E9F1 !important; cursor: not-allowed !important }
    .fc-liste .receipt-file a, .fc-liste .receipt-supplier a { color: #1B4F9C !important; font-weight: 700 }
    .fc-liste .receipt-status { font-size: 14px; font-weight: 700; color: #44536E }
        



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
            color: #0E1F3D;
            min-width: 0;
            word-break: break-word;
        }

        .receipt-status {
            font-weight: 700;
            color: #44536E;
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

        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
        </div>

        <%-- Les trois indicateurs : à lire par l'IA, lus par l'IA, reçus ce mois. --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <section class="fc-filtres">
            <asp:Panel ID="pnlRecherche" runat="server" CssClass="fc-recherche" DefaultButton="btnSearch">
                <svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#44536E" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
            </asp:Panel>
        </section>

        <div class="fc-liste full-grid">
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
                                <div><asp:Literal ID="litColFichier" runat="server" /></div>
                                <div><asp:Literal ID="litColFournisseur" runat="server" /></div>
                                <div><asp:Literal ID="litColIA" runat="server" /></div>
                                <div><asp:Literal ID="litColResultat" runat="server" /></div>
                                <div><asp:Literal ID="litColCompta" runat="server" /></div>
                                <div><asp:Literal ID="litColStatut" runat="server" /></div>
                                <div class="adroite"><asp:Literal ID="litColAction" runat="server" /></div>
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
                                    Text='<%# Server.HtmlDecode(Convert.ToString(Eval("SourceFileName"))) %>' />
                                <asp:Literal ID="litHtmlOp" runat="server"
                                    Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(Convert.ToString(Eval("Optimized"))) %>' />
                            </div>

                            <div class="receipt-supplier">
                                <asp:Literal ID="litinfo" runat="server"
                                    Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(Convert.ToString(Eval("SupplierInfo"))) %>' />
                            </div>

                            <div class="receipt-process">
                                <asp:Button ID="btnProcess"
                                    runat="server"
                                    Text='<%# L("btnIA") %>'
                                    CssClass="btn"
                                    Enabled='<%# Eval("CanProcessAI") %>'
                                    CommandName="Process"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </div>

                            <div class="receipt-json">
                                <asp:Button ID="btnVoirJSON"
                                    runat="server"
                                    Text='<%# L("btnVoir") %>'
                                    Visible='<%# Eval("CanViewJSON") %>'
                                    CssClass="btn"
                                    CommandName="VoirJSON"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </div>

                            <div class="receipt-process-json">
                                <asp:Button ID="btnProcessJSON"
                                    runat="server"
                                    Text='<%# L("btnCompta") %>'
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
                        <div class="receipt-empty"><asp:Literal ID="litEmpty" runat="server" /></div>
                    </EmptyDataTemplate>
                </telerik:RadListView>

                <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>



            </div>
        </div>



    </telerik:RadAjaxPanel>


    <uc1:jsonViewer runat="server" id="jsonViewer" />

     


</asp:Content>
