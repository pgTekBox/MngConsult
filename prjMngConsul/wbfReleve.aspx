<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
      CodeBehind="wbfReleve.aspx.vb"
    Inherits="MngConsul.wbfReleve"  Async="true"  %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>
    <script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>
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
    /* Les colonnes : date, description, compte, état, montant. */
    .fc-liste .listview-list { min-width: 900px }
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: 110px minmax(0, 2.2fr) minmax(0, 1fr) minmax(140px, 1fr) 115px 115px 180px }
    /* Période et conciliation (T368) */
    .cb-ligne { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 14px }
    .cb-lab { font-size: 13px; font-weight: 800; color: #5B6B86; text-transform: uppercase; letter-spacing: .04em }
    .cb-date { display: inline-flex; align-items: center; gap: 6px; font-weight: 700; color: #44536E; font-size: 14px }
    .cb-champ { min-height: 40px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; color: #0E1F3D; font: inherit; font-size: 14px }
    .cb-carte { padding: 18px 20px; border-radius: 24px; background: #fff; margin-bottom: 16px; color: #0E1F3D }
    .cb-tete { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 14px; margin-bottom: 12px }
    .cb-tete h2 { margin: 0; font-size: 20px; font-weight: 800 }
    /* Repliable : l'en-tête (titre, période, état, écart) reste ; le corps se cache. */
    .cb-ecart-mini { margin-left: auto; font-weight: 800; font-size: 15px; white-space: nowrap }
    .cb-ecart-mini.zero { color: #0F5A3A } .cb-ecart-mini.non { color: #A3261C }
    /* Le bouton est fixé dans le coin supérieur droit de la boîte ; l'en-tête lui laisse la place. */
    .cb-carte { position: relative }
    .cb-carte .cb-tete { padding-right: 52px }
    .cb-bascule { position: absolute; top: 16px; right: 18px; width: 36px; height: 36px; flex: none; display: inline-flex; align-items: center; justify-content: center; border: 1px solid #AEBBCD; border-radius: 50%; background: #fff; color: #0E1F3D; cursor: pointer }
    .cb-bascule:hover { background: #F2F5F9 }
    .cb-bascule svg { transition: transform .15s }
    .cb-carte.replie .cb-bascule svg { transform: rotate(-90deg) }
    .cb-carte.replie .cb-corps { display: none }
    .cb-carte.replie .cb-tete { margin-bottom: 0 }
    .cb-carte .cb-tete { cursor: default }
    .cb-tete .sous { color: #44536E; font-size: 14px }
    .cb-etat { display: inline-block; padding: 4px 12px; border-radius: 999px; font-size: 13px; font-weight: 800 }
    .cb-etat.ok { background: #E3F3EA; color: #0F5A3A } .cb-etat.ecart { background: #FBF1DC; color: #7A5200 } .cb-etat.close { background: #E8EEF8; color: #1B4F9C }
    .cb-cols { display: grid; grid-template-columns: 1fr 1fr; gap: 16px }
    .cb-col { border: 1px solid #E3E9F1; border-radius: 18px; padding: 12px 14px }
    .cb-col h3 { margin: 0 0 6px; font-size: 13px; font-weight: 800; color: #5B6B86; text-transform: uppercase; letter-spacing: .04em }
    .cb-l { display: flex; justify-content: space-between; gap: 10px; padding: 5px 0; font-size: 14px }
    .cb-l span:first-child { color: #44536E }
    .cb-l b { white-space: nowrap }
    .cb-l.tot { border-top: 1px solid #E3E9F1; margin-top: 4px; padding-top: 8px; font-weight: 800 }
    .cb-l.tot span:first-child { color: #0E1F3D }
    .cb-bas { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 16px; margin-top: 14px; padding: 12px 14px; border-radius: 18px; background: #F2F5F9 }
    .cb-bas .ecart { font-size: 20px; font-weight: 800 }
    .cb-bas .ecart.zero { color: #0F5A3A } .cb-bas .ecart.non { color: #A3261C }
    .cb-bas .note { flex: 1 1 260px; font-size: 13px; color: #44536E }
    .cb-msg { margin-top: 10px; padding: 10px 14px; border-radius: 12px; font-weight: 700 }
    .cb-msg.err { background: #FDECEA; color: #A3261C } .cb-msg.ok { background: #E3F3EA; color: #0F5A3A }
    .cb-listes { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 14px }
    .cb-listes h4 { margin: 0 0 4px; font-size: 13px; font-weight: 800; color: #5B6B86 }
    .cb-it { display: grid; grid-template-columns: 64px minmax(0, 1fr) auto; gap: 8px; padding: 5px 0; border-top: 1px solid #EEF2F7; font-size: 13px }
    .cb-it span:nth-child(2) { overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .cb-it b { white-space: nowrap }
    .cb-vide { font-size: 13px; color: #44536E; padding: 5px 0 }
    .cb-hist { margin-top: 14px }
    .cb-hist h4 { margin: 0 0 4px; font-size: 13px; font-weight: 800; color: #5B6B86 }
    .cb-hist button { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; gap: 12px; width: 100%; padding: 6px 4px; border: 0; border-top: 1px solid #EEF2F7; background: none; font: inherit; font-size: 13px; color: #0E1F3D; text-align: left; cursor: pointer }
    .cb-hist button:hover { background: #FAFCFF }
    /* Rapprochement (T367) : le règlement relié sous l'état, les gestes de la ligne. */
    .rb-lien { display: block; margin-top: 4px; font-size: 12px; color: #44536E; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .rb-actions { display: flex; justify-content: flex-end; gap: 6px }
    .rb-act { min-height: 34px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font: inherit; font-size: 13px; font-weight: 700; cursor: pointer }
    .rb-act:hover { background: #F2F5F9 }
    .rb-act.primaire { border-color: #1B4F9C; background: #1B4F9C; color: #fff }
    .rb-act.primaire:hover { background: #143A73 }
    .rb-act:disabled { opacity: .55; cursor: default }
    /* La fenêtre « Relier » */
    .rb-fond { position: fixed; inset: 0; background: rgba(14,31,61,.45); display: none; align-items: flex-start; justify-content: center; z-index: 10000; padding: 6vh 16px; box-sizing: border-box; overflow: auto }
    .rb-fond.ouvert { display: flex }
    .rb-boite { width: 100%; max-width: 760px; background: #fff; border-radius: 24px; padding: 22px 24px; box-shadow: 0 20px 60px rgba(14,31,61,.3); color: #0E1F3D }
    .rb-boite h2 { margin: 0 0 4px; font-size: 22px; font-weight: 800 }
    .rb-ligne { display: flex; flex-wrap: wrap; gap: 6px 16px; align-items: baseline; padding: 12px 14px; border-radius: 16px; background: #F2F5F9; margin: 10px 0 16px }
    .rb-ligne b { font-size: 16px }
    .rb-ligne .m { margin-left: auto; font-size: 18px; font-weight: 800 }
    .rb-ligne .m.entree { color: #0F5A3A } .rb-ligne .m.sortie { color: #A3261C }
    .rb-boite h3 { margin: 14px 0 6px; font-size: 14px; font-weight: 800; color: #5B6B86; text-transform: uppercase; letter-spacing: .04em }
    .rb-cand { display: grid; grid-template-columns: 90px minmax(0, 1fr) 120px 170px; gap: 10px; align-items: center; padding: 9px 6px; border-top: 1px solid #E3E9F1; font-size: 14px }
    .rb-cand .t { min-width: 0 } .rb-cand .t b { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .rb-cand .t span { font-size: 12px; color: #44536E }
    .rb-cand .mt { text-align: right; font-weight: 800 }
    .rb-cand .go { text-align: right }
    .rb-prob { display: inline-block; margin-left: 6px; padding: 1px 8px; border-radius: 999px; background: #E3F3EA; color: #0F5A3A; font-size: 11px; font-weight: 800; vertical-align: middle }
    .rb-vide { padding: 10px 6px; color: #44536E; border-top: 1px solid #E3E9F1; font-size: 14px }
    .rb-bilan { display: flex; flex-wrap: wrap; gap: 8px 22px; margin: -6px 0 10px; padding: 10px 14px; border: 1px solid #E3E9F1; border-radius: 14px; font-size: 14px; color: #44536E }
    .rb-bilan b { color: #0E1F3D } .rb-bilan .reste b { color: #A3261C } .rb-bilan .ok b { color: #0F5A3A }
    .rb-ok { margin: 4px 0 10px; padding: 9px 14px; border-radius: 12px; background: #E3F3EA; color: #0F5A3A; font-weight: 700; font-size: 14px }
    .rb-cand.trop { opacity: .6 }
    .rb-trop { font-size: 12px; color: #7A5200 }
    .rb-reste { color: #7A5200 !important; font-weight: 700 }
    .rb-inscrire { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(0, 1.4fr) 120px auto; gap: 8px 10px; align-items: end; padding: 10px 0 0; border-top: 1px solid #E3E9F1 }
    .rb-inscrire p { grid-column: 1 / -1; margin: 0; font-size: 13px; color: #44536E }
    .rb-inscrire label { display: flex; flex-direction: column; gap: 4px; font-size: 12px; font-weight: 800; color: #5B6B86; min-width: 0 }
    .rb-inscrire select, .rb-inscrire input { min-height: 36px; padding: 0 10px; border: 1px solid #AEBBCD; border-radius: 10px; font: inherit; font-size: 14px; color: #0E1F3D; background: #fff; min-width: 0 }
    .rb-inscrire .mt input { text-align: right }
    .rb-msg { margin-top: 12px; padding: 10px 14px; border-radius: 12px; background: #FDECEA; color: #A3261C; font-weight: 700; display: none }
    .rb-pied { display: flex; justify-content: flex-end; margin-top: 16px }
    .fc-liste .c-date { white-space: nowrap; font-weight: 700 }
    .fc-liste .c-desc { display: flex; flex-direction: column; min-width: 0 }
    .fc-liste .c-desc b { font-weight: 800; color: #0E1F3D; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .fc-liste .c-desc span { font-size: 13px; color: #44536E; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .fc-liste .c-compte { font-size: 14px; color: #44536E; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .fc-liste .c-montant { text-align: right; font-weight: 800; white-space: nowrap }
    .fc-liste .c-montant.sortie { color: #A3261C }
    .fc-liste .c-montant.entree { color: #0F5A3A }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static" >

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
             le titre, le sous-titre, et à droite les boutons en pastille. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litPageSub" runat="server" /></p>
            </div>
            <div class="btns">
                <a class="fc-btn" href="PlaidAccounts.aspx"><asp:Literal ID="litComptesBtn" runat="server" /></a>
                <button type="button" class="fc-btn primaire" onclick="openPlaidFromPage(); return false;">+ <asp:Literal ID="litConnectBtn" runat="server" /></button>
            </div>
        </div>

        <%-- Les quatre indicateurs : mouvements, à apparier, réglés, ignorés
             (un clic sur les trois derniers pose le filtre, un second l'enlève). --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <%-- Un indicateur cliqué : fcChip() pose « groupe|valeur » dans hfChip et clique
             le bouton caché, qui renvoie au serveur (btnChip_Click). --%>
        <asp:HiddenField ID="hfChip" runat="server" ClientIDMode="Static" />
        <asp:Button ID="btnChip" runat="server" ClientIDMode="Static" CausesValidation="false" Text="" style="display:none" />

        <%-- La période du relevé (date de début et de fin) : elle borne la liste, les
             indicateurs et la conciliation ci-dessous. --%>
        <section class="fc-filtres cb-periode">
            <div class="cb-ligne">
                <span class="cb-lab"><asp:Literal ID="litPeriode" runat="server" /></span>
                <asp:DropDownList ID="ddlCompte" runat="server" CssClass="cb-champ" Visible="false" />
                <label class="cb-date"><asp:Literal ID="litDu" runat="server" /> <asp:TextBox ID="tbDu" runat="server" TextMode="Date" CssClass="cb-champ" /></label>
                <label class="cb-date"><asp:Literal ID="litAu" runat="server" /> <asp:TextBox ID="tbAu" runat="server" TextMode="Date" CssClass="cb-champ" /></label>
                <asp:Button ID="btnPeriode" runat="server" CssClass="fc-btn primaire" CausesValidation="false" />
                <span class="fc-chips"><asp:Literal ID="litPeriodeChips" runat="server" /></span>
            </div>
        </section>

        <%-- La conciliation de la période : relevé ↔ livres, écart, clôture, historique. --%>
        <asp:Literal ID="litConcil" runat="server" />

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

                <telerik:RadListView ID="rlvReleve" runat="server"
                    Skin="Metro"
                    DataKeyNames="Id"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div><asp:Literal ID="litColDate" runat="server" /></div>
                                <div><asp:Literal ID="litColDesc" runat="server" /></div>
                                <div><asp:Literal ID="litColRef" runat="server" /></div>
                                <div><asp:Literal ID="litColStatus" runat="server" /></div>
                                <div class="adroite"><asp:Literal ID="litColAmount" runat="server" /></div>
                                <div class="adroite"><asp:Literal ID="litColEntrees" runat="server" /></div>
                                <div></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            <%-- La date, la description et sa référence, le compte, l'état en pastille, le montant. --%>
                            <div class="c-date"><%# FormatDateOnly(Eval("DateMouvement")) %></div>
                            <div class="c-desc"><%# DescCell(Eval("Description"), Eval("Reference")) %></div>
                            <div class="c-compte"><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></div>
                            <div style="min-width:0"><%# StatutCell(Eval("Statut"), Eval("ReglementInfo"), Eval("Montant"), Eval("Relie")) %></div>
                            <div class="c-montant sortie"><%# MontantSortie(Eval("Montant")) %></div>
                            <div class="c-montant entree"><%# MontantEntree(Eval("Montant")) %></div>
                            <div class="rb-actions"><%# ActionsCell(Eval("Id"), Eval("Statut"), Eval("NbLiens"), Eval("Montant"), Eval("Relie")) %></div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            <asp:Literal ID="litEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

                <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>

            </div>
        </div>

    </telerik:RadAjaxPanel>

    <%-- La fenêtre « Relier » (hors du RadAjaxPanel) : remplie par rbRelier()
         à partir de ReleveRapprochement.ashx (action « candidats »). --%>
    <div id="rbFond" class="rb-fond" onclick="if (event.target === this) rbFermer();">
        <div class="rb-boite" role="dialog" aria-modal="true" aria-labelledby="rbTitre">
            <h2 id="rbTitre"></h2>
            <div id="rbCorps"></div>
            <div id="rbMsg" class="rb-msg"></div>
            <div class="rb-pied"><button type="button" class="rb-act" id="rbFermerBtn" onclick="rbFermer()"></button></div>
        </div>
    </div>

      <%-- =====================================================
       JAVASCRIPT
  ===================================================== --%>
  <telerik:RadCodeBlock ID="rcbReleveJs" runat="server">
  <script type="text/javascript">
        // Un indicateur ou une puce de filtre : « groupe|valeur » dans le champ caché,
        // puis le bouton caché renvoie au serveur (btnChip_Click) par le RadAjaxPanel.
        // La boîte « Conciliation bancaire » se replie et se déplie ; le choix est
        // retenu dans ce navigateur et réappliqué après chaque rechargement Ajax.
        var CB_CLE = 'releve.conciliation.repliee';
        function cbAppliquer() {
            var carte = document.querySelector('.cb-carte'); if (!carte) return;
            var replie = false;
            try { replie = localStorage.getItem(CB_CLE) === '1'; } catch (e) { }
            if (carte.querySelector('.cb-msg')) replie = false;   // un message à lire : on montre
            carte.classList.toggle('replie', replie);
            var b = carte.querySelector('.cb-bascule');
            if (b) { b.setAttribute('aria-expanded', replie ? 'false' : 'true'); b.title = b.getAttribute(replie ? 'data-deplier' : 'data-replier'); }
        }
        function cbBascule() {
            var carte = document.querySelector('.cb-carte'); if (!carte) return;
            var replie = !carte.classList.contains('replie');
            try { localStorage.setItem(CB_CLE, replie ? '1' : '0'); } catch (e) { }
            var msg = carte.querySelector('.cb-msg'); if (msg) msg.remove();
            cbAppliquer();
        }
        if (window.Sys && Sys.Application) { Sys.Application.add_load(cbAppliquer); }
        else { document.addEventListener('DOMContentLoaded', cbAppliquer); }

        function fcChip(g, v) {
            document.getElementById("hfChip").value = g + "|" + v;
            document.getElementById("btnChip").click();
        }


      // ── Rapprochement (T367) : Relier / Délier / Ignorer une ligne du relevé ──
      var RB = <%= LibellesRelier() %>;
      var rbLigneId = 0;

      function rbEsc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
      function rbMontant(n) { return Number(n || 0).toLocaleString('fr-CA', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' $'; }
      function rbJour(d) {
          if (!d) return '';
          var p = d.split('-'); var dt = new Date(+p[0], +p[1] - 1, +p[2]);
          return dt.toLocaleDateString(document.documentElement.lang || 'fr-CA', { day: 'numeric', month: 'short' });
      }
      async function rbAppel(corps) {
          var r = await fetch('ReleveRapprochement.ashx', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(corps), credentials: 'same-origin' });
          var d = null;
          try { d = await r.json(); } catch (e) { }
          if (!d) d = { ok: false, erreur: RB.mErreur + ' ' + r.status };
          return d;
      }
      function rbMessage(t) { var m = document.getElementById('rbMsg'); m.textContent = t || ''; m.style.display = t ? 'block' : 'none'; }
      function rbRafraichir() { fcChip('refresh', '1'); }
      // La fenêtre reste ouverte tant qu'il reste un montant à relier ; la liste se
      // recharge à la fermeture si quelque chose a changé.
      var rbChange = false;
      function rbFermer() {
          document.getElementById('rbFond').classList.remove('ouvert'); rbLigneId = 0;
          if (rbChange) { rbChange = false; rbRafraichir(); }
      }

      async function rbRelier(id, message) {
          rbLigneId = id;
          document.getElementById('rbTitre').textContent = RB.mTitre;
          document.getElementById('rbFermerBtn').textContent = RB.mFermer;
          if (!document.getElementById('rbFond').classList.contains('ouvert'))
              document.getElementById('rbCorps').innerHTML = '<div class="rb-vide">' + rbEsc(RB.mChargement) + '</div>';
          rbMessage('');
          document.getElementById('rbFond').classList.add('ouvert');

          var d = await rbAppel({ action: 'candidats', id: id });
          if (!d.ok) { document.getElementById('rbCorps').innerHTML = ''; rbMessage(d.erreur); return; }

          var l = d.ligne, h = '', reste = l.reste;
          h += '<div class="rb-ligne"><span>' + rbEsc(rbJour(l.date)) + '</span><b>' + rbEsc(l.description) + '</b>' +
               '<span class="m ' + (l.entree ? 'entree' : 'sortie') + '">' + rbEsc(l.entree ? RB.mDepot : RB.mSortie) + ' ' + rbMontant(Math.abs(l.montant)) + '</span></div>';

          // Le compte : montant de la ligne, déjà relié, reste à relier
          h += '<div class="rb-bilan"><span>' + rbEsc(RB.mLigneMontant) + ' <b>' + rbMontant(Math.abs(l.montant)) + '</b></span>' +
               '<span>' + rbEsc(RB.mDejaRelie) + ' <b>' + rbMontant(l.relie) + '</b></span>' +
               '<span class="' + (reste > 0.005 ? 'reste' : 'ok') + '">' + rbEsc(RB.mResteARelier) + ' <b>' + rbMontant(reste) + '</b></span></div>';
          if (message) h += '<div class="rb-ok">' + rbEsc(message) + '</div>';

          if (d.liens.length) {
              h += '<h3>' + rbEsc(RB.mDejaRelie) + '</h3>';
              d.liens.forEach(function (x) {
                  h += '<div class="rb-cand"><span>' + rbEsc(x.genre === 'REG' ? (l.entree ? '↘' : '↗') : '✎') + '</span>' +
                       '<span class="t"><b>' + rbEsc(x.libelle || '—') + '</b><span>' + rbEsc(x.detail) + '</span></span>' +
                       '<span class="mt">' + rbMontant(x.montant) + '</span>' +
                       '<span class="go">' + (l.verrouillee ? '' : '<button type="button" class="rb-act" onclick="rbRetirer(' + x.id + ', this)">' + rbEsc(RB.mRetirer) + '</button>') + '</span></div>';
              });
          }

          if (l.verrouillee) { h += '<div class="rb-vide">' + rbEsc(RB.mVerrou) + '</div>'; document.getElementById('rbCorps').innerHTML = h; return; }
          if (reste <= 0.005) { h += '<div class="rb-ok">' + rbEsc(RB.mToutRelie) + '</div>'; document.getElementById('rbCorps').innerHTML = h; return; }

          h += '<h3>' + rbEsc(RB.mRegs) + '</h3>';
          if (!d.reglements.length) h += '<div class="rb-vide">' + rbEsc(RB.mRegsVide) + '</div>';
          d.reglements.forEach(function (r) {
              var sous = [r.numeros, r.type, r.reference].filter(function (x) { return x; }).join(' · ');
              h += '<div class="rb-cand' + (r.possible ? '' : ' trop') + '"><span>' + rbEsc(rbJour(r.date)) + '</span>' +
                   '<span class="t"><b>' + rbEsc(r.tiers || '—') + (r.probable ? '<span class="rb-prob">' + rbEsc(RB.mProbable) + '</span>' : '') + '</b><span>' + rbEsc(sous) + '</span></span>' +
                   '<span class="mt">' + rbMontant(r.montant) + '</span>' +
                   '<span class="go">' + (r.possible
                        ? '<button type="button" class="rb-act' + (r.probable ? ' primaire' : '') + '" onclick="rbLier(' + r.id + ', this)">' + rbEsc(RB.mRelier) + '</button>'
                        : '<span class="rb-trop">' + rbEsc(RB.mTropGrand) + '</span>') + '</span></div>';
          });

          h += '<h3>' + rbEsc(l.entree ? RB.mFactsCli : RB.mFactsFour) + '</h3>';
          if (!d.factures.length) h += '<div class="rb-vide">' + rbEsc(RB.mFactsVide) + '</div>';
          d.factures.forEach(function (f) {
              var part = Math.min(f.reste, reste);
              h += '<div class="rb-cand"><span>' + rbEsc(f.numero) + '</span>' +
                   '<span class="t"><b>' + rbEsc(f.tiers || '—') + (f.probable ? '<span class="rb-prob">' + rbEsc(RB.mProbable) + '</span>' : '') + '</b><span>' + rbEsc(RB.mEchue + ' ' + rbJour(f.echeance) + ' · ' + RB.mReste + ' ' + rbMontant(f.reste)) + '</span></span>' +
                   '<span class="mt">' + rbMontant(part) + '</span>' +
                   '<span class="go"><button type="button" class="rb-act' + (f.probable ? ' primaire' : '') + '" onclick="rbRegler(' + f.id + ', this)">' + rbEsc(l.entree ? RB.mEncaisser : RB.mPayer) + '</button></span></div>';
          });

          // Inscrire le reste aux livres sur un compte choisi
          var opts = '<option value="">' + rbEsc(RB.mChoisirCompte) + '</option>';
          d.comptes.forEach(function (c) {
              opts += '<option value="' + c.id + '"' + (c.suggere ? ' selected' : '') + '>' + rbEsc(c.compte + ' ' + c.nom + (c.suggere ? ' — ' + RB.mSuggere : '')) + '</option>';
          });
          h += '<h3>' + rbEsc(RB.mInscrire) + '</h3>' +
               '<div class="rb-inscrire"><p>' + rbEsc(RB.mInscrireAide) + '</p>' +
               '<label>' + rbEsc(RB.mCompte) + '<select id="rbCompte">' + opts + '</select></label>' +
               '<label>' + rbEsc(RB.mLibelle) + '<input type="text" id="rbLibelle" maxlength="250" value="' + rbEsc(l.description) + '" /></label>' +
               '<label class="mt">' + rbEsc(RB.mMontant) + '<input type="number" id="rbMontantIns" step="0.01" min="0.01" max="' + reste.toFixed(2) + '" value="' + reste.toFixed(2) + '" /></label>' +
               '<button type="button" class="rb-act primaire" onclick="rbInscrire(this)">' + rbEsc(RB.mInscrireBtn) + '</button></div>';

          document.getElementById('rbCorps').innerHTML = h;
      }

      function rbOccupe(btn, oui) { document.querySelectorAll('#rbCorps button').forEach(function (b) { b.disabled = oui; }); }

      // Après chaque geste : la fenêtre se recharge ; elle se ferme quand tout est relié.
      async function rbApres(d, btn, message) {
          if (!d.ok) { rbOccupe(btn, false); rbMessage(d.erreur); return; }
          rbChange = true;
          if (d.reste !== undefined && d.reste <= 0.005) { rbFermer(); return; }
          await rbRelier(rbLigneId, message);
      }

      async function rbLier(reglementId, btn) {
          rbOccupe(btn, true); rbMessage('');
          await rbApres(await rbAppel({ action: 'lier', id: rbLigneId, reglementId: reglementId }), btn);
      }

      async function rbRegler(docId, btn) {
          rbOccupe(btn, true); rbMessage('');
          var d = await rbAppel({ action: 'regler', id: rbLigneId, docId: docId });
          var msg = d.ok && d.resteFacture > 0.005 ? RB.mRegleOk.replace('{0}', rbMontant(d.montant)) + ' — ' + RB.mPartiel.replace('{0}', rbMontant(d.resteFacture)) : '';
          if (d.ok && d.reste <= 0.005 && msg) alert(msg);
          await rbApres(d, btn, msg);
      }

      async function rbInscrire(btn) {
          var compte = document.getElementById('rbCompte').value;
          var montant = parseFloat(document.getElementById('rbMontantIns').value);
          var max = parseFloat(document.getElementById('rbMontantIns').max);
          if (!compte) { rbMessage(RB.mChoisirCompte); return; }
          if (!(montant > 0) || montant > max + 0.005) { rbMessage(RB.mDepasse); return; }
          rbOccupe(btn, true); rbMessage('');
          await rbApres(await rbAppel({ action: 'inscrire', id: rbLigneId, compteId: +compte, montant: montant.toFixed(2),
                                         libelle: document.getElementById('rbLibelle').value }), btn);
      }

      async function rbRetirer(lienId, btn) {
          if (!confirm(RB.mConfRetirer)) return;
          rbOccupe(btn, true); rbMessage('');
          var d = await rbAppel({ action: 'retirer', lienId: lienId });
          if (!d.ok) { rbOccupe(btn, false); rbMessage(d.erreur); return; }
          rbChange = true;
          await rbRelier(rbLigneId);
      }

      async function rbAction(action, id) {
          if (action === 'delier' && !confirm(RB.mConfDelier)) return;
          var corps = { action: action === 'retablir' ? 'ignorer' : action, id: id };
          if (action === 'ignorer') corps.ignorer = true;
          if (action === 'retablir') corps.ignorer = false;
          var d = await rbAppel(corps);
          if (!d.ok) { alert(d.erreur); return; }
          rbRafraichir();
      }
      document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && rbLigneId) rbFermer(); });

      var L_EXCHANGE_ERROR  = "<%= L("jsExchangeError") %>";
      var L_CONNECTED       = "<%= L("jsConnected") %>";
      var L_LINKTOKEN_ERROR = "<%= L("jsLinkTokenError") %>";
      var L_PLAID_ERROR     = "<%= L("jsPlaidError") %>";

      // Construit le handler Plaid Link. receivedRedirectUri n'est fourni que lors
      // de la REPRISE après un retour OAuth (banques OAuth : RBC, TD, etc.).
      function createPlaidHandler(linkToken, receivedRedirectUri) {
          var config = {
              token: linkToken,

              onSuccess: async function (public_token, metadata) {
                  const ex = await fetch('ExchangeToken', {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify({
                          public_token: public_token,
                          institution_name: metadata.institution ? metadata.institution.name : '',
                          accounts: metadata.accounts || []
                      })
                  });

                  const exData = await ex.json();
                  try { localStorage.removeItem('plaid_link_token'); } catch (e) { }

                  if (!exData.success) {
                      alert(exData.message || L_EXCHANGE_ERROR);
                      return;
                  }

                  alert(L_CONNECTED);
                  window.location.reload();
              },

              onExit: function (err, metadata) {
                  try { localStorage.removeItem('plaid_link_token'); } catch (e) { }
                  if (err) { console.log('Plaid Exit Error:', err); }
              }
          };

          // Reprise OAuth : indique à Plaid l'URL de retour complète.
          if (receivedRedirectUri) { config.receivedRedirectUri = receivedRedirectUri; }

          return Plaid.create(config);
      }

      async function openPlaidFromPage() {
          try {
              const res = await fetch('/PlaidCreateLinkToken', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: '{}'
              });

              const data = await res.json();
              if (!data.success) {
                  alert(data.message || L_LINKTOKEN_ERROR);
                  return;
              }

              // Le link_token doit survivre à la redirection OAuth (depart vers la
              // banque, puis retour sur cette page) : on le garde en localStorage.
              try { localStorage.setItem('plaid_link_token', data.link_token); } catch (e) { }

              const handler = createPlaidHandler(data.link_token, null);
              handler.open();

          } catch (e) {
              console.error(e);
              alert(L_PLAID_ERROR);
          }
      }

      // Reprise automatique après retour OAuth : Plaid redirige vers le redirect_uri
      // en ajoutant ?oauth_state_id=... On rouvre alors Plaid Link avec le meme
      // link_token (localStorage) et l'URL de retour complete.
      (function resumePlaidOAuth() {
          try {
              if (window.location.search.indexOf('oauth_state_id=') === -1) return;

              var linkToken = null;
              try { linkToken = localStorage.getItem('plaid_link_token'); } catch (e) { }
              if (!linkToken) return;

              function go() {
                  if (typeof Plaid === 'undefined') { setTimeout(go, 100); return; }
                  var handler = createPlaidHandler(linkToken, window.location.href);
                  handler.open();
              }
              if (document.readyState === 'complete') { go(); }
              else { window.addEventListener('load', go); }
          } catch (e) { console.error(e); }
      })();

      </script>
  </telerik:RadCodeBlock>

</asp:Content>
