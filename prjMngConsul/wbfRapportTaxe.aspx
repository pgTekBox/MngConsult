<%@ Page Title="" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfRapportTaxe.aspx.vb"
    Inherits="MngConsul.wbfRapportTaxe" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server"><%= L("pageTitle") %></asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .tax-page { max-width: 1100px; margin: 0 auto; padding: 12px; }
        .tax-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .tax-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .tax-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .tax-card h3 { margin: 0 0 12px 0; font-size: 16px; color: #0f172a; }

        .tax-toolbar {
            display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
        }

        /* Cartes TPS / TVQ */
        .tax-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 16px;
        }
        .tax-block {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 14px 16px;
        }
        .tax-block h4 {
            margin: 0 0 10px 0; font-size: 14px; color: #475569;
            border-bottom: 1px solid #e2e8f0; padding-bottom: 6px;
            text-transform: uppercase; letter-spacing: 0.5px;
        }
        .tax-line {
            display: flex; justify-content: space-between; padding: 4px 0;
            font-size: 14px; color: #0f172a;
        }
        .tax-line .lbl { color: #64748b; }
        .tax-line .val { font-weight: 500; font-variant-numeric: tabular-nums; }
        .tax-line.minus .val { color: #dc2626; }
        .tax-line.total {
            border-top: 1px solid #cbd5e1; padding-top: 8px; margin-top: 4px;
            font-weight: 600; font-size: 15px;
        }
        .tax-line.total .val { color: #0f172a; }

        /* Total à remettre */
        .total-remise {
            background: #fef3c7; border: 1px solid #fbbf24;
            border-radius: 8px; padding: 16px 20px;
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 16px;
        }
        .total-remise .lbl { font-size: 15px; color: #92400e; font-weight: 600; }
        .total-remise .val {
            font-size: 22px; font-weight: 700; color: #92400e;
            font-variant-numeric: tabular-nums;
        }

        /* Pill statut */
        .status-pill {
            display: inline-block; padding: 4px 12px; border-radius: 999px;
            font-size: 12px; font-weight: 600; margin-left: 8px;
            vertical-align: middle;
        }
        .status-pill.brouillon { background: #e0e7ff; color: #3730a3; }
        .status-pill.finalise  { background: #dbeafe; color: #1e40af; }
        .status-pill.paye      { background: #dcfce7; color: #166534; }

        /* Tableau de détail */
        .detail-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .detail-table th, .detail-table td {
            padding: 6px 10px; border-bottom: 1px solid #e2e8f0; text-align: left;
        }
        .detail-table th { background: #f1f5f9; color: #475569; font-weight: 600; }
        .detail-table td.num { text-align: right; font-variant-numeric: tabular-nums; }
        .detail-table .cat-tps-vte { color: #16a34a; }
        .detail-table .cat-tps-ach { color: #dc2626; }
        .detail-table .cat-tvq-vte { color: #16a34a; }
        .detail-table .cat-tvq-ach { color: #dc2626; }

        /* Action bar */
        .action-bar {
            display: flex; gap: 12px; justify-content: flex-end;
            padding-top: 16px; border-top: 1px solid #e2e8f0; margin-top: 16px;
        }

        /* Période button group */
        .period-nav { display: flex; gap: 6px; align-items: center; }
        .period-label {
            padding: 6px 16px; background: #f1f5f9; border-radius: 6px;
            font-weight: 600; color: #0f172a; min-width: 200px; text-align: center;
        }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnPrev">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phReport" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="lblPeriode" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnNext">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phReport" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="lblPeriode" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnRecalcul">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phReport" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnRemettre">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phReport" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="tax-page">

        <h2><asp:Literal ID="litH2Title" runat="server" /></h2>
        <div class="subtitle">
            <asp:Literal ID="litSubtitle" runat="server" /> <asp:Literal ID="litFreqInfo" runat="server" />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="tax-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- Navigation période -->
        <div class="tax-card">
            <div class="tax-toolbar">
                <div class="period-nav">
                    <telerik:RadButton ID="btnPrev" runat="server" Text="‹ Précédent"
                        Skin="Bootstrap" OnClick="btnPrev_Click" />
                    <asp:Label ID="lblPeriode" runat="server" CssClass="period-label" Text="Période" />
                    <telerik:RadButton ID="btnNext" runat="server" Text="Suivant ›"
                        Skin="Bootstrap" OnClick="btnNext_Click" />
                </div>

                <telerik:RadButton ID="btnRecalcul" runat="server" Text="Recalculer"
                    Skin="Bootstrap" OnClick="btnRecalcul_Click"
                    Icon-PrimaryIconCssClass="rbRefresh" />
            </div>
        </div>

        <asp:PlaceHolder ID="phReport" runat="server">

            <!-- Bloc TPS / TVQ -->
            <div class="tax-card">
                <h3>
                    <asp:Literal ID="litDetailTitre" runat="server" />
                    <asp:Literal ID="litStatutPill" runat="server" />
                </h3>

                <div class="tax-grid">
                    <!-- TPS -->
                    <div class="tax-block">
                        <h4><asp:Literal ID="litTPSTitre" runat="server" /></h4>
                        <div class="tax-line">
                            <span class="lbl"><asp:Literal ID="litTPSPercueLbl" runat="server" /></span>
                            <span class="val"><asp:Literal ID="litTPSPercue" runat="server" /></span>
                        </div>
                        <div class="tax-line minus">
                            <span class="lbl"><asp:Literal ID="litTPSPayeeLbl" runat="server" /></span>
                            <span class="val">(<asp:Literal ID="litTPSPayee" runat="server" />)</span>
                        </div>
                        <div class="tax-line total">
                            <span><asp:Literal ID="litTPSNetteLbl" runat="server" /></span>
                            <span class="val"><asp:Literal ID="litTPSNette" runat="server" /></span>
                        </div>
                    </div>

                    <!-- TVQ -->
                    <div class="tax-block">
                        <h4><asp:Literal ID="litTVQTitre" runat="server" /></h4>
                        <div class="tax-line">
                            <span class="lbl"><asp:Literal ID="litTVQPercueLbl" runat="server" /></span>
                            <span class="val"><asp:Literal ID="litTVQPercue" runat="server" /></span>
                        </div>
                        <div class="tax-line minus">
                            <span class="lbl"><asp:Literal ID="litTVQPayeeLbl" runat="server" /></span>
                            <span class="val">(<asp:Literal ID="litTVQPayee" runat="server" />)</span>
                        </div>
                        <div class="tax-line total">
                            <span><asp:Literal ID="litTVQNetteLbl" runat="server" /></span>
                            <span class="val"><asp:Literal ID="litTVQNette" runat="server" /></span>
                        </div>
                    </div>
                </div>

                <!-- Total à remettre -->
                <div class="total-remise">
                    <span class="lbl"><asp:Literal ID="litTotalLbl" runat="server" /></span>
                    <span class="val"><asp:Literal ID="litTotal" runat="server" /></span>
                </div>

                <!-- Date de paiement (si payé) -->
                <asp:Panel ID="pnlPaye" runat="server" Visible="false"
                    style="background:#f0fdf4;border:1px solid #86efac;border-radius:8px;padding:12px 16px;">
                    <strong><asp:Literal ID="litRemiseFaiteLbl" runat="server" /> <asp:Literal ID="litDatePaiement" runat="server" /></strong>
                    <asp:Literal ID="litRefSepLbl" runat="server" /> <asp:Literal ID="litReference" runat="server" />
                </asp:Panel>
            </div>

            <!-- Détail des écritures -->
            <asp:PlaceHolder ID="phDetail" runat="server" Visible="false">
                <div class="tax-card">
                    <h3><asp:Literal ID="litDetailEcrituresTitre" runat="server" /></h3>
                    <table class="detail-table">
                        <thead>
                            <tr>
                                <th><asp:Literal ID="litColDate" runat="server" /></th>
                                <th><asp:Literal ID="litColPiece" runat="server" /></th>
                                <th><asp:Literal ID="litColLibelle" runat="server" /></th>
                                <th><asp:Literal ID="litColCompte" runat="server" /></th>
                                <th><asp:Literal ID="litColCategorie" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litColDebit" runat="server" /></th>
                                <th class="num"><asp:Literal ID="litColCredit" runat="server" /></th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpDetail" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Eval("DateEcriture", "{0:yyyy-MM-dd}") %></td>
                                        <td><%# Eval("NumeroPiece") %></td>
                                        <td><%# Eval("LibelleLigne") %></td>
                                        <td><strong><%# Eval("Compte") %></strong> <%# Eval("NomCompte") %></td>
                                        <td><%# Eval("Categorie") %></td>
                                        <td class="num"><%# IIf(Convert.ToDecimal(Eval("MontantDebit")) > 0, String.Format("{0:N2}", Eval("MontantDebit")), "") %></td>
                                        <td class="num"><%# IIf(Convert.ToDecimal(Eval("MontantCredit")) > 0, String.Format("{0:N2}", Eval("MontantCredit")), "") %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </asp:PlaceHolder>

            <!-- Action bar -->
            <div class="tax-card">
                <div class="action-bar">
                    <telerik:RadButton ID="btnRemettre" runat="server"
                        Text="Marquer comme remis" Skin="Bootstrap"
                        OnClick="btnRemettre_Click"
                        Icon-PrimaryIconCssClass="rbCheck"
                        OnClientClicking="confirmRemise" />
                </div>
            </div>

        </asp:PlaceHolder>

    </div>

    <!-- Modale de confirmation de remise -->
    <telerik:RadWindow ID="winRemise"  runat="server" Title="Confirmer la remise"
        Width="450" Height="280" Modal="true" Behaviors="Close" VisibleStatusbar="false"
        Skin="Bootstrap" AutoSizeBehaviors="Default" ClientIDMode="Static">
        <ContentTemplate>
            <div style="padding:16px;">
                <p><asp:Literal ID="litWinIntro" runat="server" /></p>
                <ul style="font-size:13px;color:#475569;">
                    <li><asp:Literal ID="litWinLi1" runat="server" /></li>
                    <li><asp:Literal ID="litWinLi2" runat="server" /></li>
                </ul>
                <table style="width:100%;margin-top:12px;">
                    <tr>
                        <td style="width:130px;padding:6px 0;"><asp:Literal ID="litWinDateLbl" runat="server" /></td>
                        <td><telerik:RadDatePicker ID="dpDatePaiement" runat="server" Skin="Bootstrap" Width="150px" /></td>
                    </tr>
                    <tr>
                        <td style="padding:6px 0;"><asp:Literal ID="litWinRefLbl" runat="server" /></td>
                        <td><telerik:RadTextBox ID="txtReference" runat="server" Skin="Bootstrap" Width="250px"
                                EmptyMessage="Numéro de chèque, confirmation, ..." /></td>
                    </tr>
                </table>
                <div style="margin-top:16px;text-align:right;">
                    <telerik:RadButton ID="btnConfirmerRemise" runat="server" Text="Confirmer" Skin="Bootstrap"
                        OnClick="btnConfirmerRemise_Click" />
                    <telerik:RadButton ID="btnAnnulerRemise" runat="server" Text="Annuler" Skin="Bootstrap"
                        AutoPostBack="false" OnClientClicked="closeRemiseDialog" />
                </div>
            </div>
        </ContentTemplate>
    </telerik:RadWindow>

    <script type="text/javascript">
        function confirmRemise(sender, args) {
            args.set_cancel(true);
            var win = $find('winRemise');
            win.show();
        }
        function closeRemiseDialog(sender, args) {
            var win = $find('winRemise');
            win.close();
        }
    </script>

</asp:Content>
