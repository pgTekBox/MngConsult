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
        .listview-list-head {
            display: grid;
            grid-template-columns: 110px minmax(220px, 1fr) 400px  70px 100px;
            gap: 14px;
            padding: 14px 16px;
            font-weight: 800;
            font-size: 13px;
            color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky;
            top: 0;
            z-index: 0;
            box-sizing: border-box;
        }

        .listview-row {
            display: grid;
            grid-template-columns: 110px minmax(220px, 1fr) 400px  70px 100px;
            gap: 14px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .field-date,
        .field-reference,
        .field-compte,
        .field-statut,
        .field-montant {
            white-space: nowrap;
        }

        .field-description {
            min-width: 0;
            word-break: break-word;
        }

        .field-montant {
            text-align: right;
            font-weight: 800;
        }

        .montant-negatif {
            color: #dc2626;
        }

        .montant-positif {
            color: #16a34a;
        }

        .badge-statut {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 30px;
            padding: 0 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
            border: 1px solid #dbeafe;
            background: #eff6ff;
            color: #1d4ed8;
        }

            .badge-statut.regle {
                border-color: #bbf7d0;
                background: #f0fdf4;
                color: #15803d;
            }

            .badge-statut.enattente {
                border-color: #fde68a;
                background: #fffbeb;
                color: #b45309;
            }

            .badge-statut.ignore {
                border-color: #e5e7eb;
                background: #f8fafc;
                color: #475569;
            }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
                   <button type="button" class="btn btnAddRow" onclick="openPlaidFromPage(); return false;"><asp:Literal ID="litConnectBtn" runat="server" /></button>
    
    <%--<button type="button"
      class ="btn btn-icon btn-icon-plaid" 
    onclick="openPlaidFromPage();"
    title="Connecter banque">Test Plaid 
</button>--%>


    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static" >

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
                <div class="page-sub"><asp:Literal ID="litPageSub" runat="server" /></div>
            </div>

            <div class="searchbox">
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server"
                        CssClass="input txttbsearch"
                        placeholder="" />

                    <asp:Button ID="btnSearch" runat="server"
                        CssClass="btn btn-icon btn-icon-search"
                        Text="" />

                    <asp:Button ID="btnClear"  runat="server"
                        CssClass="btn btn-icon btn-icon-clear"
                        Text=""
                        ToolTip=""
                        CausesValidation="false" />

                <%-- <button type="button"
      class ="btn btn-icon btn-icon-plaid"
    onclick="openPlaidFromPage()"
    title="Connecter banque">
</button>--%>
                </div>
            </div>
        </div>

        <div class="full-grid">
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
                                <div style="text-align: right;"><asp:Literal ID="litColAmount" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            <div class="field-date">
                                <%# FormatDateOnly(Eval("DateMouvement")) %>
                            </div>

                            <div class="field-description">
                                <%# Eval("Description") %>
                            </div>

                            <div class="field-reference">
                                <%# Eval("FullName") %>
                               
                            </div>

                             
                            <div class="field-statut">
                                <span class='<%# GetStatutCss(Eval("Statut")) %>'>
                                    <%# LocalizeStatut(Eval("Statut")) %>
                                </span>
                            </div>

                            <div class='<%# "field-montant " & GetMontantCss(Eval("Montant")) %>'>
                                <%# FormatMontant(Eval("Montant")) %>
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            <asp:Literal ID="litEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

    </telerik:RadAjaxPanel>
      <%-- =====================================================
       JAVASCRIPT
  ===================================================== --%>
  <telerik:RadCodeBlock ID="rcbReleveJs" runat="server">
  <script type="text/javascript">

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
