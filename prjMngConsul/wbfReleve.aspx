<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
      CodeBehind="wbfReleve.aspx.vb"
    Inherits="MngConsul.wbfReleve"  Async="true"  %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Relevé bancaire — MngConsul
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

        @media (max-width: 1024px) {
            .listview-list-head,
            .listview-row {
                grid-template-columns: 100px minmax(180px, 1.6fr) 110px 120px 95px 90px;
                gap: 10px;
                padding: 12px 14px;
            }
        }

        @media (max-width: 768px) {
            .listview-list-head {
                display: none;
            }

            .listview-row {
                grid-template-columns: 1fr;
                gap: 8px;
                padding: 14px;
            }

            .field-date {
                order: 1;
                font-weight: 800;
            }

            .field-description {
                order: 2;
            }

            .field-reference {
                order: 3;
                color: var(--mc-muted);
                font-size: 13px;
            }

                .field-reference::before {
                    content: "Référence : ";
                    font-weight: 800;
                    color: #0f172a;
                }

            .field-compte {
                order: 4;
                color: var(--mc-muted);
                font-size: 13px;
            }

                .field-compte::before {
                    content: "Compte : ";
                    font-weight: 800;
                    color: #0f172a;
                }

            .field-statut {
                order: 5;
            }

            .field-montant {
                order: 6;
                text-align: left;
                font-size: 16px;
            }
        }

        @media (max-width: 480px) {
            .listview-row {
                padding: 12px;
            }

            .page-title {
                font-size: 17px;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
                   <button type="button" onclick="openPlaidFromPage()">Test Plaid</button>
    
    <%--<button type="button"
      class ="btn btn-icon btn-icon-plaid" 
    onclick="openPlaidFromPage();"
    title="Connecter banque">Test Plaid 
</button>--%>


    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static" >

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Relevé bancaire</div>
                <div class="page-sub">Consultation des mouvements bancaires</div>
            </div>

            <div class="searchbox">
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server"
                        CssClass="input txttbsearch"
                        placeholder="Rechercher (description, référence, compte, statut…)" />

                    <asp:Button ID="btnSearch" runat="server"
                        CssClass="btn btn-icon btn-icon-search"
                        Text="" />

                    <asp:Button ID="btnClear"  runat="server"
                        CssClass="btn btn-icon btn-icon-clear"
                        Text=""
                        ToolTip="Effacer"
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
                                <div>Date</div>
                                <div>Description</div>
                                <div>Référence</div>
                               
                                <div>Statut</div>
                                <div style="text-align: right;">Montant</div>
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
                                    <%# Eval("Statut") %>
                                </span>
                            </div>

                            <div class='<%# "field-montant " & GetMontantCss(Eval("Montant")) %>'>
                                <%# FormatMontant(Eval("Montant")) %>
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucun mouvement bancaire trouvé.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

    </telerik:RadAjaxPanel>
      <%-- =====================================================
       JAVASCRIPT
  ===================================================== --%>
  <script type="text/javascript">
      async function openPlaidFromPage() {
          try {
              
              const res = await fetch('/PlaidCreateLinkToken', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: '{}'
              });

               
              const data = await res.json();
              console.log(res);
              if (!data.success) {
                  alert(data.message || 'Erreur lors de la création du link token.');
                  return;
              }
               
              const handler = Plaid.create({
                  token: data.link_token,

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

                      if (!exData.success) {
                          alert(exData.message || 'Erreur lors de l’échange du token.');
                          return;
                      }

                      alert('Compte bancaire connecté avec succès.');

                      // recharge la page pour revoir les lignes importées
                      window.location.reload();
                  },

                  onExit: function (err, metadata) {
                      if (err) {
                          console.log('Plaid Exit Error:', err);
                      }
                  }
              });

              handler.open();

          } catch (e) {
              console.error(e);
              alert('Erreur Plaid.');
          }
      }

       

      </script>

</asp:Content>
