<%@ Page  Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomersInvoices.aspx.vb" Inherits="MngConsul.wbfCustomersInvoices" %>

<%@ Register Src="~/Controls/PdfViewer.ascx" TagPrefix="uc1" TagName="PdfViewer" %>

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
    .fc-liste .list-shell { height: auto; padding: 6px 12px 12px; border-radius: 24px; background: #fff; overflow-x: auto }
    .fc-liste .listview-list { min-width: 1000px }
    .fc-liste .list-shell > * { flex: none; display: block }
    .fc-liste .listview-list-body { overflow: visible }
    .fc-liste .listview-list-head, .fc-liste .listview-row {
        display: grid; grid-template-columns: 90px 108px minmax(170px, 2fr) 108px 104px 100px 124px 176px;
        gap: 8px; align-items: center; padding: 10px 6px; box-sizing: border-box;
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
            color: #44536E;
            margin-top: 2px;
            word-break: break-all;
        }

        /* Icône unique « Envoyer / Encaisser » : enveloppe + pastille $ (lien de paiement) */
        .btn-icon-invoice-send {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%230891b2' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='4' width='18' height='14' rx='2'/%3E%3Cpath d='m20 6.5-9 5.5-9-5.5'/%3E%3Ccircle cx='18' cy='17.5' r='5.2' fill='%23ffffff' stroke='%2316a34a' stroke-width='1.6'/%3E%3Cpath d='M18 14.6v5.8' stroke='%2316a34a' stroke-width='1.4'/%3E%3Cpath d='M19.5 15.6h-2.1a.95.95 0 0 0 0 1.9h1.2a.95.95 0 0 1 0 1.9h-2.1' stroke='%2316a34a' stroke-width='1.4'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 20px 20px !important;
        }

        /* Indicateurs médias (photos / géolocalisation captées par l'app mobile),
           affichés sous le nom du client. Absents quand il n'y a rien à montrer. */
        .media-badges {
            display: flex;
            gap: 6px;
            margin-top: 4px;
        }

        .media-badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 1px 8px 1px 6px;
            border: 1px solid #cbd5e1;
            border-radius: 999px;
            background: #f8fafc;
            font-size: 11px;
            font-weight: 700;
            color: #44536E;
            cursor: pointer;
            line-height: 18px;
        }

            .media-badge:hover {
                border-color: #1B4F9C;
                color: #1B4F9C;
                background: #E3EBF7;
            }

            .media-badge svg {
                width: 12px;
                height: 12px;
                flex: none;
            }

        /* Visionneuse de photos */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 12px;
        }

        .photo-item {
            display: block;
            border: 1px solid #D5DDE8;
            border-radius: 10px;
            overflow: hidden;
            background: #f8fafc;
            text-decoration: none;
        }

            .photo-item img {
                display: block;
                width: 100%;
                height: 140px;
                object-fit: cover;
                background: #D5DDE8;
            }

        .photo-cap {
            display: block;
            padding: 6px 8px;
            font-size: 11px;
            color: #44536E;
        }

        .photo-geo {
            margin-bottom: 14px;
            padding: 10px 12px;
            border: 1px solid #bbf7d0;
            border-radius: 10px;
            background: #f0fdf4;
            font-size: 12px;
            color: #166534;
        }

            .photo-geo a {
                font-weight: 700;
                color: #15803d;
            }

        /* Options du dialogue « Envoyer / Encaisser » */
        .dlg-opt {
            display: block;
            width: 100%;
            text-align: left;
            padding: 12px 14px;
            margin-bottom: 10px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            background: #fff;
            cursor: pointer;
            font: inherit;
        }

            .dlg-opt:hover {
                border-color: #1B4F9C;
                background: #f8fafc;
            }

            .dlg-opt .dlg-opt-title {
                display: block;
                font-weight: 800;
                font-size: 14px;
                color: #0E1F3D;
            }

            .dlg-opt .dlg-opt-sub {
                display: block;
                font-size: 12px;
                color: #44536E;
                margin-top: 3px;
            }

            .dlg-opt.dlg-opt-pay {
                border-color: #16a34a;
            }

                .dlg-opt.dlg-opt-pay .dlg-opt-title {
                    color: #15803d;
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

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
             le titre, le sous-titre, et à droite les deux boutons en pastille. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div class="btns">
                <asp:Button ID="btnImportSquare" runat="server"
                    CssClass="fc-btn"
                    CausesValidation="false" />
                <asp:Button ID="btnAddCustomerInvoice" runat="server"
                    CssClass="fc-btn primaire"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;"
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
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
            </asp:Panel>
            <div class="fc-groupes"><asp:Literal ID="litChips" runat="server" /></div>
        </section>

        <div class="fc-liste full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvClientsFactures" runat="server"
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
                                <div><asp:LinkButton ID="lnkSortCustomer" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="NameSort" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortPay" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="StatutPaiement" CausesValidation="false" /></div>
                                <div class="adroite"><asp:LinkButton ID="lnkSortReste" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="ResteAPayer" CausesValidation="false" /></div>
                                <div class="adroite"><asp:LinkButton ID="lnkSortTotal" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="Total" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortEtat" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="Status" CausesValidation="false" /></div>
                                <div class="adroite"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <%-- Numéro (lien vers le PDF), échéance avec la date d'émission dessous,
                                 client avec son courriel, paiement en pastille, reste (avec le reçu),
                                 total, état (cadenas si comptabilisée), puis les actions. --%>
                            <div class="c-num"><%# Eval("DocumentNumber") %></div>
                            <div class="c-ech"><%# EcheanceCell(Eval("DueDate"), Eval("DocumentDate")) %></div>
                            <div class="c-client"><%# Eval("Name") %><%# RenderMediaBadges(Eval("Id"), Eval("PhotoCount"), Eval("Latitude"), Eval("Longitude")) %></div>
                            <div><%# PayPill(Eval("StatutPaiement")) %></div>
                            <div class='<%# ResteClass(Eval("StatutPaiement")) %>'><%# ResteCell(Eval("ResteAPayer"), Eval("DejaRecu")) %></div>
                            <div class="c-total"><%# Eval("Total", "{0:C2}") %></div>
                            <div><%# EtatCell(Eval("Status"), Eval("ComptabilisationStatus")) %></div>

                            <div class="listview-actions">

                                <%-- Comptabiliser : uniquement sur un brouillon. C'est ce geste qui
                                     attribue le numéro officiel, la date de facture et l'échéance. --%>
                                <asp:Button ID="btnPost" runat="server"
                                    CssClass="btn btn-icon btn-icon-post"
                                    Text=""
                                    ToolTip='<%# L("tipPost") %>'
                                    Visible='<%# ShowPost(Container.DataItem) %>'
                                    CommandArgument='<%# Eval("Id") %>'
                                    OnClick="btnPost_Click"
                                    OnClientClick='<%# ConfirmPost() %>'
                                    CausesValidation="false" />

                                <asp:Button ID="Button1" runat="server"
                                    CssClass="field-encaissement btn btn-icon btn-icon-receipt"
                                    Text=""
                                    ToolTip='<%# L("tipCashIn") %>'
                                    CausesValidation="false"
                                    Visible='<%# ShowCollect(Container.DataItem) %>'
                                    OnClientClick ='<%# "openRadWindowParam(" & Eval("PartyId") & ",""&PartyId=" & Eval("PartyId") & "&sens=ENCAISSEMENT "" ,""rwEncaissement"", ""wbfReceiptEditPopup.aspx"", L_EDIT_CASHIN, L_ADD_CASHIN);    return false;" %>'
                                />

                                <%-- Bouton unique « Envoyer / Encaisser » : ouvre le dialogue d'actions
                                     (courriel sans lien / courriel avec lien Square / lien à copier). --%>
                                <asp:Button ID="btnInvoiceSend" runat="server"
                                    CssClass="btn btn-icon btn-icon-invoice-send"
                                    Text=""
                                    ToolTip='<%# L("tipInvoiceSend") %>'
                                    CausesValidation="false"
                                    Visible='<%# ShowSend(Container.DataItem) %>'
                                    OnClientClick='<%# "openInvoiceActions(" & FormatIntForJs(Eval("Id")) & "," & FormatIntForJs(Eval("PartyId")) & ",""" & FormatAmountForUrl(Eval("ResteAPayer")) & """," & If(CanCollect(Eval("StatutPaiement")), "1", "0") & "," & FormatIntForJs(Eval("PhotoCount")) & "," & If(HasGeo(Eval("Latitude"), Eval("Longitude")), "1", "0") & "); return false;" %>' />

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

                <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>

            </div>
        </div>

        <%-- Porteur de données des photos. Seul ce bloc, invisible, vit DANS le
             RadAjaxPanel : c'est le serveur qui le remplit au retour de
             ajaxRequest("photos|<id>"). La surimpression visible, elle, est hors
             du panneau (plus bas) — une surimpression re-rendue à chaque aller-retour
             AJAX cesse de fonctionner dès qu'un autre échange a lieu (même piège que
             le RadWindowManager, cf. commentaire en tête de page). showPhotos()
             recopie ce contenu dans la surimpression avant de l'afficher. --%>
        <div id="photoData" style="display:none;">
            <span id="photoDataTitle"><asp:Literal ID="litPhotoTitle" runat="server" /></span>
            <span id="photoDataSubtitle"><asp:Literal ID="litPhotoSubtitle" runat="server" /></span>
            <div id="photoDataBody"><asp:Literal ID="litPhotoBody" runat="server" /></div>
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
            // {0} = nombre de photos, substitué à l'ouverture du dialogue.
            var L_INCL_PHOTOS = "<%= L("inclPhotos") %>";
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
        // Un indicateur ou une puce de filtre : « groupe|valeur » dans le champ caché,
        // puis le bouton caché renvoie au serveur (btnChip_Click) par le RadAjaxPanel.
        function fcChip(g, v) {
            document.getElementById("hfChip").value = g + "|" + v;
            document.getElementById("btnChip").click();
        }


        // Confirmation « Comptabiliser » : radconfirm est ASYNCHRONE, on annule donc
        // le clic tout de suite (return false côté bouton) et c'est la callback qui
        // déclenche le postback si l'utilisateur confirme. Le nom du bouton est
        // capturé avant l'appel : après un rebind AJAX, l'élément peut avoir été
        // remplacé, mais la chaîne, elle, reste valable.
        function confirmPostInvoice(btn, msg, title) {
            var target = btn.name;
            radconfirm(msg,
                function (ok) {
                    if (ok) { __doPostBack(target, ''); }
                },
                420, 190, null, title);
            return false;
        }

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
                "<i class='ic ic-alert' aria-hidden='true'></i> Vous avez des modifications non sauvegardées.<br/>Voulez-vous vraiment fermer ?",
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
    <%-- Dialogue unique « Envoyer / Encaisser » : courriel sans lien, courriel avec lien
         de paiement Square, ou génération du lien seul (à copier / envoyer soi-même). --%>
    <div id="sendEmailOverlay" style="display:none; position:fixed; inset:0; z-index:10000;
         background:rgba(15,23,42,.55); align-items:center; justify-content:center;">
        <div style="background:#fff; border-radius:16px; box-shadow:0 20px 60px rgba(0,0,0,.3);
             width:92vw; max-width:480px; padding:24px; box-sizing:border-box;">
            <div style="font-weight:800; font-size:16px; color:#0E1F3D; margin-bottom:8px;">
                <asp:Literal ID="litDlgTitle" runat="server" />
            </div>
            <div style="color:#44536E; font-size:14px; line-height:1.5; margin-bottom:18px;">
                <asp:Literal ID="litDlgQuestion" runat="server" />
            </div>

            <%-- Médias à joindre. Le bloc entier reste caché quand la facture n'a ni
                 photo ni géolocalisation, et chaque ligne n'apparaît que si la donnée
                 existe (openInvoiceActions reçoit le nombre de photos et la présence
                 de coordonnées depuis la grille). Ne concerne que les deux options
                 d'envoi par courriel : le lien de paiement seul n'envoie rien. --%>
            <div id="mediaOptions" style="display:none; margin-bottom:16px; padding:12px 14px;
                 border:1px solid #D5DDE8; border-radius:12px; background:#f8fafc;">
                <div style="font-size:12px; font-weight:800; color:#44536E; margin-bottom:8px;">
                    <asp:Literal ID="litMediaOptTitle" runat="server" />
                </div>
                <label id="rowInclPhotos" style="display:none; gap:8px; align-items:center;
                       font-size:13px; color:#0E1F3D; margin-bottom:6px; cursor:pointer;">
                    <input type="checkbox" id="chkInclPhotos" />
                    <span id="lblInclPhotos"></span>
                </label>
                <label id="rowInclGeo" style="display:none; gap:8px; align-items:center;
                       font-size:13px; color:#0E1F3D; cursor:pointer;">
                    <input type="checkbox" id="chkInclGeo" />
                    <span><asp:Literal ID="litInclGeo" runat="server" /></span>
                </label>
            </div>

            <button type="button" class="dlg-opt" onclick="doSendEmail(0)">
                <span class="dlg-opt-title"><asp:Literal ID="litDlgWithout" runat="server" /></span>
                <span class="dlg-opt-sub"><asp:Literal ID="litDlgWithoutSub" runat="server" /></span>
           </button>

            <button type="button" id="optSendWithLink" class="dlg-opt dlg-opt-pay" onclick="doSendEmail(1)">
                <span class="dlg-opt-title"><asp:Literal ID="litDlgWith" runat="server" /></span>
                <span class="dlg-opt-sub"><asp:Literal ID="litDlgWithSub" runat="server" /></span>
           </button>

            <button type="button" id="optCopyLink" class="dlg-opt dlg-opt-pay" onclick="doPaymentLink()">
                <span class="dlg-opt-title"><asp:Literal ID="litDlgLink" runat="server" /></span>
                <span class="dlg-opt-sub"><asp:Literal ID="litDlgLinkSub" runat="server" /></span>
           </button>

            <div id="optPaidNote" style="display:none; color:#44536E; font-size:12px; margin:-2px 0 12px;">
                <asp:Literal ID="litDlgPaidNote" runat="server" />
            </div>

            <div style="display:flex; justify-content:flex-end; margin-top:6px;">
                <button type="button" onclick="closeSendEmailDialog()"
                    style="padding:10px 16px; border:1px solid #cbd5e1; background:#fff; color:#44536E;
                           border-radius:10px; font-weight:700; cursor:pointer;"><asp:Literal ID="litDlgCancel" runat="server" /></button>
            </div>
        </div>
    </div>

    <%-- Visionneuse de photos. HORS du RadAjaxPanel, comme le dialogue d'envoi :
         ce noeud ne doit jamais être re-rendu par un aller-retour AJAX. Ses zones
         sont vides au départ et remplies par showPhotos() depuis #photoData.
         z-index au-dessus des fenêtres Telerik (radalert), qui montent très haut. --%>
    <div id="photoOverlay" style="display:none; position:fixed; inset:0; z-index:999999;
         background:rgba(15,23,42,.55); align-items:center; justify-content:center;"
         onclick="if (event.target === this) closePhotos();">
        <div style="background:#fff; border-radius:16px; box-shadow:0 20px 60px rgba(0,0,0,.3);
             width:92vw; max-width:900px; max-height:86vh; overflow:auto; padding:24px; box-sizing:border-box;">
            <div style="display:flex; align-items:baseline; gap:10px; margin-bottom:14px;">
                <div id="photoTitle" style="font-weight:800; font-size:16px; color:#0E1F3D;"></div>
                <div id="photoSubtitle" style="color:#44536E; font-size:13px;"></div>
            </div>

            <div id="photoBody"></div>

            <div style="display:flex; justify-content:flex-end; margin-top:18px;">
                <button type="button" onclick="closePhotos()"
                    style="padding:10px 16px; border:1px solid #cbd5e1; background:#fff; color:#44536E;
                           border-radius:10px; font-weight:700; cursor:pointer;">
                    <asp:Literal ID="litPhotoClose" runat="server" /></button>
            </div>
        </div>
    </div>

    <%-- La boîte de message vit dans Site.Master (showAppMessage / closeAppMessage),
         partagée par toutes les pages. Côté serveur : clsData.ShowMessageBox. --%>

    <script type="text/javascript">
        var _sendEmailInvoiceId = 0;
        var _sendEmailPartyId = 0;
        var _sendEmailAmount = "0";

        // canCollect = 0 quand la facture est déjà payée -> on masque les options de paiement.
        // photoCount / hasGeo viennent de la grille : on n'offre de joindre que ce qui existe.
        function openInvoiceActions(id, partyId, amount, canCollect, photoCount, hasGeo) {
            _sendEmailInvoiceId = id;
            _sendEmailPartyId = partyId;
            _sendEmailAmount = amount;
            var show = (canCollect === 1 || canCollect === "1") ? "" : "none";
            document.getElementById("optSendWithLink").style.display = show;
            document.getElementById("optCopyLink").style.display = show;
            document.getElementById("optPaidNote").style.display = (show === "") ? "none" : "block";

            // Cases décochées à chaque ouverture : joindre des photos au client est
            // une décision explicite, jamais un reste de la facture précédente.
            var nbPhotos = parseInt(photoCount, 10) || 0;
            var geo = (hasGeo === 1 || hasGeo === "1");
            var chkP = document.getElementById("chkInclPhotos");
            var chkG = document.getElementById("chkInclGeo");
            chkP.checked = false;
            chkG.checked = false;
            document.getElementById("lblInclPhotos").textContent =
                L_INCL_PHOTOS.replace("{0}", nbPhotos);
            document.getElementById("rowInclPhotos").style.display = nbPhotos > 0 ? "flex" : "none";
            document.getElementById("rowInclGeo").style.display = geo ? "flex" : "none";
            document.getElementById("mediaOptions").style.display =
                (nbPhotos > 0 || geo) ? "block" : "none";

            document.getElementById("sendEmailOverlay").style.display = "flex";
        }
        function closeSendEmailDialog() {
            document.getElementById("sendEmailOverlay").style.display = "none";
        }
        // Une case cochée mais sur une ligne masquée ne compte pas (la donnée n'existe pas).
        function doSendEmail(includeSquare) {
            var p = mediaChecked("chkInclPhotos", "rowInclPhotos") ? 1 : 0;
            var g = mediaChecked("chkInclGeo", "rowInclGeo") ? 1 : 0;
            closeSendEmailDialog();
            var mgr = $find("RAP1");
            if (mgr) {
                mgr.ajaxRequest("sendmail|" + _sendEmailInvoiceId + "|" + includeSquare +
                                "|" + p + "|" + g);
            }
        }
        function mediaChecked(chkId, rowId) {
            var c = document.getElementById(chkId);
            var r = document.getElementById(rowId);
            return !!(c && c.checked && r && r.style.display !== "none");
        }
        // Lien de paiement seul : ouvre la fenêtre Square (générer / copier / ouvrir).
        function doPaymentLink() {
            closeSendEmailDialog();
            openRadWindowParam(_sendEmailInvoiceId,
                "DocumentId=" + _sendEmailInvoiceId + "&PartyId=" + _sendEmailPartyId + "&Amount=" + _sendEmailAmount,
                "rwSquarePay", "wbfCustomerPaymentLink.aspx", L_SQUARE, L_SQUARE);
        }
        // Fermer en cliquant le fond sombre
        document.getElementById("sendEmailOverlay").addEventListener("click", function (e) {
            if (e.target === this) closeSendEmailDialog();
        });

        // ---- Médias captés par l'app mobile ----
        // Photos : aller-retour serveur (la grille ne connaît que le nombre, pas les
        // identifiants). Le serveur remplit la visionneuse puis appelle showPhotos().
        function openPhotos(id) {
            var mgr = $find("RAP1");
            if (mgr) { mgr.ajaxRequest("photos|" + id); }
        }
        // Recopie le contenu produit par le serveur (#photoData, dans le panneau AJAX)
        // vers la surimpression (hors panneau), puis l'affiche.
        function showPhotos() {
            var o = document.getElementById("photoOverlay");
            if (!o) { return; }
            var pairs = [["photoTitle", "photoDataTitle"],
                         ["photoSubtitle", "photoDataSubtitle"],
                         ["photoBody", "photoDataBody"]];
            for (var i = 0; i < pairs.length; i++) {
                var dst = document.getElementById(pairs[i][0]);
                var src = document.getElementById(pairs[i][1]);
                if (dst) { dst.innerHTML = src ? src.innerHTML : ""; }
            }
            o.style.display = "flex";
        }
        function closePhotos() {
            var o = document.getElementById("photoOverlay");
            if (o) { o.style.display = "none"; }
        }
        // Géolocalisation : purement client, aucun aller-retour.
        function openMap(lat, lng) {
            window.open("https://www.google.com/maps?q=" + lat + "," + lng, "_blank", "noopener");
        }
        // Échap ferme les surimpressions de cette page (celle du master gère la sienne).
        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape") { closePhotos(); closeSendEmailDialog(); }
        });
    </script>

    <uc1:PdfViewer runat="server" id="PdfViewer" />

</asp:Content>
