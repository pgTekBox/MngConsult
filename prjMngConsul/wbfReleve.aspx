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
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: 130px minmax(0, 2.2fr) minmax(0, 1.3fr) 130px 150px }
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
                            <div><%# StatutPill(Eval("Statut")) %></div>
                            <div class='<%# "c-montant " & GetMontantCss(Eval("Montant")) %>'><%# FormatMontant(Eval("Montant")) %></div>
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
      <%-- =====================================================
       JAVASCRIPT
  ===================================================== --%>
  <telerik:RadCodeBlock ID="rcbReleveJs" runat="server">
  <script type="text/javascript">
        // Un indicateur ou une puce de filtre : « groupe|valeur » dans le champ caché,
        // puis le bouton caché renvoie au serveur (btnChip_Click) par le RadAjaxPanel.
        function fcChip(g, v) {
            document.getElementById("hfChip").value = g + "|" + v;
            document.getElementById("btnChip").click();
        }


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
