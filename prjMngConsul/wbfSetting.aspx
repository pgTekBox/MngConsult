<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"  CodeBehind="wbfSetting.aspx.vb" Inherits="MngConsul.wbfSetting" %>


<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paramètres — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .page-head{
            display:flex; align-items:flex-start; justify-content:space-between;
            gap:12px; flex-wrap:wrap;
            padding:14px 16px;
            border-bottom:1px solid var(--mc-stroke);
            background:rgba(255,255,255,.75);
        }
        .page-title{ font-weight:900; font-size:18px; line-height:1.2; }
        .page-sub{ color:var(--mc-muted); font-size:13px; margin-top:4px; }
        .actions{ display:flex; gap:8px; flex-wrap:wrap; align-items:center; }

        .wrap{ padding:16px; }
        .card{
            background:#fff;
            border:1px solid var(--mc-stroke);
            border-radius:14px;
            box-shadow:0 12px 30px rgba(2,6,23,.06);
            overflow:hidden;
        }
        .card-b{ padding:14px; }

        .form-grid{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:12px;
        }
        @media (max-width: 820px){
            .form-grid{ grid-template-columns:1fr; }
        }
        .field label{
            display:block;
            font-size:12px;
            color:var(--mc-muted);
            margin-bottom:6px;
        }
        .field-shortname{
            display:inline-block;
            font-weight:700;
            color:#2563eb;
            font-size:11px;
            margin-left:6px;
            opacity:0.65;
        }
        .field-fullwidth{ grid-column:1/-1; }
        .hint{ color:var(--mc-muted); font-size:12px; margin-top:6px; }

        .status-ok{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px;
            border-radius:999px;
            background:rgba(22,163,74,.10);
            color:#166534;
            border:1px solid rgba(22,163,74,.20);
            font-size:12px;
        }
        .status-err{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px;
            border-radius:999px;
            background:rgba(220,38,38,.10);
            color:#991b1b;
            border:1px solid rgba(220,38,38,.20);
            font-size:12px;
        }

        .RadTabStrip{ margin-bottom:12px; }

        .empty-state{
            padding:24px;
            text-align:center;
            color:var(--mc-muted);
            font-size:13px;
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Paramètres</div>
            <div class="page-sub">Entreprise, taxes, courriels, PDF et comptabilité.</div>
        </div>

        <div class="actions">
            <telerik:RadButton ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary"
                AutoPostBack="true" OnClick="btnSave_Click" />
            <telerik:RadButton ID="btnReload" runat="server" Text="Recharger" CssClass="btn"
                AutoPostBack="true" OnClick="btnReload_Click" />

            <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
                <asp:Literal ID="litStatus" runat="server" />
            </asp:PlaceHolder>
        </div>
    </div>

    <div class="wrap">
        <div class="card">
            <div class="card-b">

                <telerik:RadTabStrip ID="tsSettings" runat="server"
                    MultiPageID="mpSettings"
                    SelectedIndex="0"
                    Skin="Metro"
                    Orientation="HorizontalTop">

                    <Tabs>
                        <telerik:RadTab Text="Entreprise" />
                        <telerik:RadTab Text="Taxes" />
                        <telerik:RadTab Text="Email" />
                        <telerik:RadTab Text="PDF" />
                        <telerik:RadTab Text="Comptabilité" />
                        <telerik:RadTab Text="Bancaire" />
                    </Tabs>
                </telerik:RadTabStrip>

                <telerik:RadMultiPage ID="mpSettings" runat="server" SelectedIndex="0">

                    <!-- ENTREPRISE -->
                    <telerik:RadPageView ID="pvCompany" runat="server">
                        <asp:Repeater ID="rpEntreprise" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <%# Eval("Name") %>
                                        <span class="field-shortname"><%# Eval("ShortName") %></span>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyEntreprise" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre configuré pour cet onglet.
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- TAXES -->
                    <telerik:RadPageView ID="pvTaxes" runat="server">
                        <asp:Repeater ID="rpTaxes" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <%# Eval("Name") %>
                                        <span class="field-shortname"><%# Eval("ShortName") %></span>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyTaxes" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre configuré pour cet onglet.
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- EMAIL -->
                    <telerik:RadPageView ID="pvEmail" runat="server">
                        <asp:Repeater ID="rpEmail" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <%# Eval("Name") %>
                                        <span class="field-shortname"><%# Eval("ShortName") %></span>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyEmail" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre configuré pour cet onglet.
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- PDF -->
                    <telerik:RadPageView ID="pvPdf" runat="server">
                        <asp:Repeater ID="rpPdf" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <%# Eval("Name") %>
                                        <span class="field-shortname"><%# Eval("ShortName") %></span>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyPdf" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre configuré pour cet onglet.
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- COMPTABILITÉ -->
                    <telerik:RadPageView ID="pvAccounting" runat="server">
                        <div style="margin-bottom:12px; color:var(--mc-muted); font-size:13px;">
                            Comptes par défaut utilisés par les modules de comptabilisation automatique.
                        </div>
                        <asp:Repeater ID="rpComptabilite" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <strong style="color:#2563eb;"><%# Eval("ShortName") %></strong> —
                                        <%# Eval("Name") %>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyComptabilite" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre comptable défini.
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- BANCAIRE -->
                    <telerik:RadPageView ID="pvBancaire" runat="server">
                        <div style="margin-bottom:12px; color:var(--mc-muted); font-size:13px;">
                            Comptes bancaires connectés via Plaid. Sélectionnez le compte par défaut
                            utilisé pour les encaissements et décaissements.
                        </div>
                        <asp:Repeater ID="rpBancaire" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <%# Eval("Name") %>
                                        <span class="field-shortname"><%# Eval("ShortName") %></span>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyBancaire" runat="server" Visible="false" CssClass="empty-state">
                            Aucun paramètre bancaire configuré pour cet onglet.
                        </asp:Panel>
                    </telerik:RadPageView>

                </telerik:RadMultiPage>

            </div>
        </div>
    </div>

</asp:Content>
