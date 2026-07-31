<%@ Page Title="" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfFermetureAnnee.aspx.vb"
    Inherits="MngConsul.wbfFermetureAnnee" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="TitleContent" runat="server"><%= L("pageTitle") %></asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .closure-page { max-width: 1100px; margin: 0 auto; padding: 12px; }
        .closure-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .closure-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 20px; }

        .closure-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .closure-card h3 { margin: 0 0 12px 0; font-size: 16px; color: #0f172a; }

        .closure-toolbar {
            display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
        }

        /* Aperçu financier */
        .preview-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 8px 24px;
            font-size: 14px;
        }
        .preview-grid .lbl { color: #64748b; }
        .preview-grid .val { font-weight: 600; color: #0f172a; text-align: right; }
        .preview-grid .val.positive { color: #16a34a; }
        .preview-grid .val.negative { color: #dc2626; }

        /* Liste des problèmes */
        .problem-row {
            display: flex; gap: 10px; align-items: flex-start;
            padding: 10px 12px; border-left: 3px solid #94a3b8;
            background: #f8fafc; border-radius: 4px; margin-bottom: 8px;
        }
        .problem-row.bloquant  { border-color: #dc2626; background: #fef2f2; }
        .problem-row.warning   { border-color: #f59e0b; background: #fffbeb; }
        .problem-row.info      { border-color: #0ea5e9; background: #f0f9ff; }
        .problem-badge {
            font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 999px;
            color: #fff; flex-shrink: 0; margin-top: 2px;
        }
        .problem-badge.bloquant { background: #dc2626; }
        .problem-badge.warning  { background: #f59e0b; }
        .problem-badge.info     { background: #0ea5e9; }
        .problem-text .titre { font-weight: 600; color: #0f172a; }
        .problem-text .detail { color: #475569; font-size: 13px; margin-top: 2px; }
        .problem-nb {
            margin-left: auto; font-weight: 700; color: #0f172a;
            background: #fff; padding: 2px 10px; border-radius: 999px;
            border: 1px solid #cbd5e1; font-size: 12px;
        }

        /* Tableau preview écritures */
        .preview-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .preview-table th, .preview-table td {
            padding: 6px 10px; border-bottom: 1px solid #e2e8f0; text-align: left;
        }
        .preview-table th { background: #f1f5f9; color: #475569; font-weight: 600; }
        .preview-table td.num { text-align: right; font-variant-numeric: tabular-nums; }

        /* Action bar */
        .action-bar {
            display: flex; gap: 12px; justify-content: flex-end;
            padding-top: 16px; border-top: 1px solid #e2e8f0; margin-top: 16px;
        }
        .status-pill {
            display: inline-block; padding: 4px 12px; border-radius: 999px;
            font-size: 12px; font-weight: 600; margin-left: 8px;
        }
        .status-pill.ok       { background: #dcfce7; color: #166534; }
        .status-pill.warning  { background: #fef3c7; color: #92400e; }
        .status-pill.bloque   { background: #fee2e2; color: #991b1b; }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="ddlExercice">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phPreview" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnVerifier">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phPreview" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnFermer">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phPreview" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                    <telerik:AjaxUpdatedControl ControlID="ddlExercice" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="closure-page">

        <h2><asp:Literal ID="litH2Title" runat="server" /></h2>
        <div class="subtitle">
            <asp:Literal ID="litSubtitle" runat="server" />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="closure-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- Étape 1 : sélection de l'exercice -->
        <div class="closure-card">
            <h3><asp:Literal ID="litH3Step1" runat="server" /></h3>
            <div class="closure-toolbar">
                <asp:Literal ID="litLblExercice" runat="server" />
                <telerik:RadComboBox ID="ddlExercice" runat="server" Width="180px"
                    AutoPostBack="true" Skin="Bootstrap"
                    OnSelectedIndexChanged="ddlExercice_SelectedIndexChanged" />

                <telerik:RadButton ID="btnVerifier" runat="server" Text="Vérifier" Skin="Bootstrap"
                    OnClick="btnVerifier_Click" Icon-PrimaryIconCssClass="rbRefresh" />
            </div>
        </div>

        <!-- Étape 2 : aperçu et confirmation -->
        <asp:PlaceHolder ID="phPreview" runat="server" Visible="false">

            <!-- Aperçu financier -->
            <div class="closure-card">
                <h3>
                    <asp:Literal ID="litH3Apercu" runat="server" />
                    <asp:Literal ID="litStatutPill" runat="server" />
                </h3>
                <div class="preview-grid">
                    <div class="lbl"><asp:Literal ID="litLblRevenus" runat="server" /></div>
                    <div class="val positive"><asp:Literal ID="litRevenus" runat="server" /></div>

                    <div class="lbl"><asp:Literal ID="litLblDepenses" runat="server" /></div>
                    <div class="val negative"><asp:Literal ID="litDepenses" runat="server" /></div>

                    <div class="lbl"><strong><asp:Literal ID="litLblBeneficeNet" runat="server" /></strong></div>
                    <div class="val"><asp:Literal ID="litBeneficeNet" runat="server" /></div>

                    <div class="lbl"><asp:Literal ID="litLblCompteBNR" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litCompteBNR" runat="server" /></div>

                    <div class="lbl"><asp:Literal ID="litLblBNRAvant" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litBNRAvant" runat="server" /></div>

                    <div class="lbl"><strong><asp:Literal ID="litLblBNRApres" runat="server" /></strong></div>
                    <div class="val"><asp:Literal ID="litBNRApres" runat="server" /></div>

                    <div class="lbl"><asp:Literal ID="litLblCompteBNE" runat="server" /></div>
                    <div class="val">
                        <asp:Literal ID="litCompteBNE" runat="server" /> /
                        <asp:Literal ID="litJournal" runat="server" />
                    </div>
                </div>
            </div>

            <!-- Problèmes détectés -->
            <asp:PlaceHolder ID="phProblemes" runat="server" Visible="false">
                <div class="closure-card">
                    <h3><asp:Literal ID="litH3Problemes" runat="server" /></h3>
                    <asp:Repeater ID="rpProblemes" runat="server">
                        <ItemTemplate>
                            <div class='problem-row <%# Eval("Severite").ToString().ToLower() %>'>
                                <span class='problem-badge <%# Eval("Severite").ToString().ToLower() %>'>
                                    <%# Eval("Severite") %>
                                </span>
                                <div class="problem-text">
                                    <div class="titre"><%# Eval("Titre") %></div>
                                    <div class="detail"><%# Eval("Detail") %></div>
                                </div>
                                <%# If(Convert.IsDBNull(Eval("Nombre")) OrElse Eval("Nombre") Is Nothing,
                                       "",
                                       String.Format("<div class='problem-nb'>{0}</div>", Eval("Nombre"))) %>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>
            </asp:PlaceHolder>

            <!-- Détail des écritures qui seront créées -->
            <asp:PlaceHolder ID="phEcritures" runat="server" Visible="false">
                <div class="closure-card">
                    <h3><asp:Literal ID="litH3Ecritures" runat="server" /></h3>
                    <table class="preview-table">
                        <thead>
                            <tr>
                                <th><asp:Literal ID="litThCompte" runat="server" /></th>
                                <th><asp:Literal ID="litThNom" runat="server" /></th>
                                <th><asp:Literal ID="litThType" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litThTotD" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litThTotC" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litThDebitClot" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litThCreditClot" runat="server" /></th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpEcritures" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><strong><%# Eval("Compte") %></strong></td>
                                        <td><%# Eval("Nom") %></td>
                                        <td><%# Eval("TypeBilan") %></td>
                                        <td class="num"><%# Eval("TotDebit", "{0:N2}") %></td>
                                        <td class="num"><%# Eval("TotCredit", "{0:N2}") %></td>
                                        <td class="num"><%# IIf(Convert.ToDecimal(Eval("DebitClotureCompte")) > 0, String.Format("{0:N2}", Eval("DebitClotureCompte")), "") %></td>
                                        <td class="num"><%# IIf(Convert.ToDecimal(Eval("CreditClotureCompte")) > 0, String.Format("{0:N2}", Eval("CreditClotureCompte")), "") %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </asp:PlaceHolder>

            <!-- Action bar -->
            <div class="closure-card">
                <div class="action-bar">
                    <asp:Literal ID="litFermeHint" runat="server" />
                    <telerik:RadButton ID="btnFermer" runat="server" Text="Confirmer la fermeture" Skin="Bootstrap"
                        OnClick="btnFermer_Click" CssClass="btn-danger"
                        Icon-PrimaryIconCssClass="rbLock"
                        OnClientClicking="confirmCloture" />
                </div>
            </div>

        </asp:PlaceHolder>

    </div>

    <telerik:RadCodeBlock ID="rcbFermetureJs" runat="server">
    <script type="text/javascript">
        function confirmCloture(sender, args) {
            var msg = "<%= L("jsConfirm1") %>\n\n"
                + "<%= L("jsConfirm2") %>\n\n"
                + "<%= L("jsConfirm3") %>";
            args.set_cancel(!confirm(msg));
        }
    </script>
    </telerik:RadCodeBlock>

</asp:Content>
