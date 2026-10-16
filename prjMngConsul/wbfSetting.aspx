<%@ Page Title="" Language="vb" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"  CodeBehind="wbfSetting.aspx.vb" Inherits="MngConsul.wbfSetting" %>


<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .page-head{
            display:flex; align-items:center; justify-content:space-between;
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
        .field label{
            display:block;
            font-size:12px;
            color:var(--mc-muted);
            margin-bottom:6px;
        }
        .field-shortname{
            display:inline-block;
            font-weight:700;
            color:#1B4F9C;
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

        .logo-box{
            display:flex; align-items:center; gap:18px;
            padding:14px; margin-bottom:16px;
            border:1px solid var(--mc-stroke); border-radius:12px;
            background:rgba(2,6,23,.02);
        }
        .logo-preview{
            width:84px; height:84px; flex:0 0 84px;
            border:1px solid var(--mc-stroke); border-radius:12px;
            background:#fff; display:flex; align-items:center; justify-content:center; overflow:hidden;
        }
        .logo-preview img{ max-width:100%; max-height:100%; object-fit:contain; }
        .logo-preview .ph{ color:var(--mc-muted); font-size:11px; text-align:center; padding:4px; }
        .logo-info{ flex:1 1 auto; min-width:0; }
        .logo-info label{ display:block; font-size:13px; font-weight:700; margin-bottom:6px; }

        /* Rangée logo + scan côte à côte */
        .logo-row{ display:flex; gap:16px; flex-wrap:wrap; align-items:stretch; margin-bottom:16px; }
        .logo-row > .logo-box{ flex:1 1 320px; margin-bottom:0; }
        .scan-box{
            flex:1 1 320px; display:flex; flex-direction:column;
            padding:14px; border:1px solid var(--mc-stroke); border-radius:12px;
            background:rgba(37,99,235,.04);
        }
        .scan-box .scan-title{ font-weight:800; font-size:13px; margin-bottom:2px; }
        .scan-box .scan-hint{ font-size:12px; color:var(--mc-muted); margin-bottom:10px; }
        .dropzone{
            position:relative; border:2px dashed #cbd5e1; border-radius:12px;
            background:#fff; padding:16px; text-align:center; cursor:pointer;
            transition:border-color .15s, background .15s;
        }
        .dropzone:hover{ border-color:#1B4F9C; background:#E3EBF7; }
        .dropzone.drag{ border-color:#143A73; background:rgba(59,130,246,.10); }
        .dropzone .dz-ico{ font-size:22px; line-height:1; }
        .dropzone .dz-text{ font-size:12px; color:#44536E; font-weight:600; margin-top:6px; }
        .dropzone .dz-file{ font-size:12px; color:#1B4F9C; font-weight:700; margin-top:6px; min-height:14px; word-break:break-all; }
        .dropzone .dz-input{ position:absolute; width:1px; height:1px; opacity:0; overflow:hidden; }
        .scan-actions{ margin-top:10px; }
        .scan-msg{ margin-top:10px; padding:8px 10px; border-radius:8px; font-size:12px; font-weight:700; border:1px solid var(--mc-stroke); background:#fff; }

        /* Progression du profil + identité admin + boutons — même ligne d'en-tête */
        .head-right{ display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
        .profile-progress{ background:#fff; border:1px solid var(--mc-stroke); border-radius:12px; padding:8px 12px; min-width:190px; }
        .pp-head{ display:flex; justify-content:space-between; align-items:center; gap:14px; margin-bottom:6px; }
        .pp-label{ font-size:12px; font-weight:800; }
        .pp-pct{ font-size:12px; font-weight:800; color:#1B4F9C; }
        .pp-track{ height:8px; background:#eef2f7; border-radius:999px; overflow:hidden; }
        .pp-fill{ height:100%; background:linear-gradient(90deg,#1B4F9C,#06b6d4); border-radius:999px; transition:width .3s ease; }
        .admin-id{ display:flex; align-items:center; gap:10px; background:#fff; border:1px solid var(--mc-stroke); border-radius:12px; padding:8px 12px; }
        .admin-avatar{ width:38px; height:38px; flex:0 0 38px; border-radius:10px; background:#E3EBF7; color:#1B4F9C; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:14px; }
        .admin-info{ flex:0 1 auto; min-width:0; max-width:230px; }
        .admin-name{ font-size:14px; font-weight:800; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
        .admin-meta{ font-size:12px; color:var(--mc-muted); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
        .admin-role{ font-size:11px; font-weight:800; text-transform:uppercase; letter-spacing:.05em; padding:4px 10px; border-radius:999px; background:rgba(37,99,235,.10); color:#1B4F9C; border:1px solid rgba(37,99,235,.20); white-space:nowrap; }

        /* Vérification du courriel d'entreprise (MAIL_FROM_EMAIL) */
        .mail-verify-row{
            display:flex; align-items:center; gap:10px;
            flex-wrap:wrap; margin-top:8px;
        }
        .mail-badge{
            display:inline-flex; align-items:center; gap:6px;
            padding:5px 10px; border-radius:999px;
            font-size:12px; font-weight:700;
        }
        .mail-badge.ok{ background:rgba(22,163,74,.10); color:#166534; border:1px solid rgba(22,163,74,.20); }
        .mail-badge.pending{ background:rgba(245,158,11,.12); color:#92400e; border:1px solid rgba(245,158,11,.25); }
        .mail-badge.no{ background:rgba(220,38,38,.10); color:#991b1b; border:1px solid rgba(220,38,38,.20); }
        /* ── La signature du gabarit « Portail du client » : le titre pose sur le fond,
           Recharger / Enregistrer en pastilles, la progression et l'identité en cartes,
           puis les onglets dans la carte principale. ── */
        .fc-tete{ display:flex; flex-wrap:wrap; align-items:flex-end; gap:12px; margin-bottom:16px; }
        .fc-tete .txt{ flex:1 1 260px; }
        .fc-rubrique{ font-size:14px; font-weight:800; color:#1B4F9C; text-transform:uppercase; letter-spacing:.06em; }
        .fc-tete h1{ margin:2px 0 0; font-size:30px; font-weight:800; line-height:1.15; color:#0E1F3D; }
        .fc-tete p{ margin:4px 0 0; font-size:17px; color:#44536E; }
        .fc-tete .actions .RadButton{ border-radius:999px !important; min-height:44px !important; height:auto !important; padding:0 18px !important; border:1px solid #AEBBCD !important; background:#fff !important; color:#0E1F3D !important; font-weight:700 !important; font-family:inherit !important; box-shadow:none !important; }
        .fc-tete .actions .RadButton .rbText{ color:inherit !important; font-weight:inherit !important; }
        .fc-tete .actions .RadButton.primary{ border-color:#1B4F9C !important; background:#1B4F9C !important; color:#fff !important; font-weight:800 !important; padding:0 20px !important; }
        .fc-tete .actions .RadButton.primary:hover{ background:#143A73 !important; }
        .fc-kpis{ display:grid; grid-template-columns:minmax(220px, 1fr) minmax(300px, 2fr); gap:12px; margin-bottom:16px; }
        .fc-kpi{ padding:14px 16px; border-radius:22px; background:#fff; display:flex; flex-direction:column; gap:4px; color:#0E1F3D; }
        .fc-kpi .lab{ display:flex; align-items:center; gap:8px; font-weight:700; color:#44536E; font-size:14px; }
        .fc-kpi .lab i{ width:10px; height:10px; border-radius:50%; flex:none; }
        .fc-kpi .val{ font-size:24px; font-weight:800; line-height:1.15; }
        .fc-kpi .pp-track{ margin-top:6px; }
        .pp-fill{ background:#1B4F9C; }
        .fc-kpi.admin-id{ flex-direction:row; align-items:center; gap:12px; border:0; padding:14px 16px; }
        .admin-avatar{ width:44px; height:44px; flex:0 0 44px; border-radius:50%; background:#1B4F9C; color:#fff; font-size:15px; }
        .admin-info{ max-width:none; flex:1 1 auto; }
        .admin-name{ font-size:16px; }
        .admin-meta{ font-size:14px; }
        .admin-role{ border:0; background:#E3EBF7; color:#143A73; font-size:12px; }
        .wrap{ padding:0; }
        .card{ border:0; border-radius:24px; box-shadow:none; }
        .card-b{ padding:18px 20px; }
        .field label{ font-size:13px; font-weight:800; color:#5B6B86; }
        .logo-box, .scan-box{ border:0; border-radius:18px; background:#F2F5F9; }
        .logo-preview{ border-radius:14px; border-color:#D5DDE8; }
        .dropzone{ border-radius:14px; border-color:#AEBBCD; }
        .scan-msg{ border:0; border-radius:14px; background:#F2F5F9; }
        .status-ok{ border:0; background:#E3F3EA; color:#0F5A3A; font-weight:700; }
        .status-err{ border:0; background:#FDECEA; color:#A3261C; font-weight:700; }
        .empty-state{ font-size:14px; font-weight:700; }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre,
         le sous-titre ; à droite, Recharger et Enregistrer en pastilles (et le message d'état). --%>
    <div class="fc-tete">
        <div class="txt">
            <div class="fc-rubrique"><%= L("rubrique") %></div>
            <h1><%= L("pageTitleShort") %></h1>
            <p><%= L("pageSub") %></p>
        </div>
        <div class="actions">
            <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
                <asp:Literal ID="litStatus" runat="server" />
            </asp:PlaceHolder>
            <telerik:RadButton ID="btnReload" runat="server" Text="Recharger" CssClass="btn"
                AutoPostBack="true" OnClick="btnReload_Click" />
            <telerik:RadButton ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary"
                AutoPostBack="true" OnClick="btnSave_Click" />
        </div>
    </div>

    <%-- Deux cartes : la progression du profil et l'identité de l'administrateur. --%>
    <div class="fc-kpis">
        <div class="fc-kpi">
            <span class="lab"><i style="background:#1B4F9C"></i><%= L("profileLabel") %></span>
            <span class="val"><%= ProfilePct %>&nbsp;%</span>
            <div class="pp-track"><div class="pp-fill" style="width:<%= ProfilePct %>%;"></div></div>
        </div>
        <div class="fc-kpi admin-id">
            <div class="admin-avatar"><%= AdminInitials %></div>
            <div class="admin-info">
                <div class="admin-name"><%= AdminName %></div>
                <div class="admin-meta"><%= AdminMeta %></div>
            </div>
            <span class="admin-role"><%= AdminRole %></span>
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
                        <telerik:RadTab Text="Facture" />
                        <telerik:RadTab Text="Traitement" />
                        <telerik:RadTab Text="Comptabilité" />
                        <telerik:RadTab Text="Bancaire" />
                        <telerik:RadTab Text="Comptable" />
                    </Tabs>
                </telerik:RadTabStrip>

                <telerik:RadMultiPage ID="mpSettings" runat="server" SelectedIndex="0">

                    <!-- ENTREPRISE -->
                    <telerik:RadPageView ID="pvCompany" runat="server">

                        <div class="logo-row">
                            <div class="logo-box">
                                <div class="logo-preview">
                                    <asp:Image ID="imgLogo" runat="server" Visible="false" />
                                    <asp:Panel ID="pnlNoLogo" runat="server" CssClass="ph"><%= L("logoNone") %></asp:Panel>
                                </div>
                                <div class="logo-info">
                                    <label><%= L("logoLabel") %></label>
                                    <asp:FileUpload ID="fuLogo" runat="server" accept="image/png,image/jpeg,image/svg+xml" />
                                    <div class="hint"><%= L("logoHint") %></div>
                                    <asp:CheckBox ID="chkRemoveLogo" runat="server" Text="" />
                                    <span style="font-size:12px;color:var(--mc-muted);"><%= L("logoRemove") %></span>
                                </div>
                            </div>

                            <%-- Scan de document : remplit automatiquement les champs Entreprise/Taxes vides --%>
                            <div class="scan-box">
                                <div class="scan-title"><%= L("scanTitle") %></div>
                                <div class="scan-hint"><%= L("scanHint") %></div>
                                <div id="dropZone" class="dropzone">
                                    <div class="dz-ico" aria-hidden="true">⬆️</div>
                                    <div class="dz-text"><%= L("scanDrop") %></div>
                                    <div class="dz-file" id="dzFile"></div>
                                    <asp:FileUpload ID="fileDocScan" runat="server" ClientIDMode="Static"
                                        accept=".pdf,.png,.jpg,.jpeg,image/*,application/pdf" CssClass="dz-input" />
                                </div>
                                <div class="scan-actions">
                                    <asp:Button ID="btnScanExtract" runat="server" CssClass="btn btn-primary"
                                        CausesValidation="false" Text="Analyser le document" />
                                </div>
                                <asp:Panel ID="pnlScanMsg" runat="server" Visible="false" CssClass="scan-msg">
                                    <asp:Literal ID="litScanMsg" runat="server" />
                                </asp:Panel>
                            </div>
                        </div>

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
                            <%= L("emptyTab") %>
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
                            <%= L("emptyTab") %>
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
                            <%= L("emptyTab") %>
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
                            <%= L("emptyTab") %>
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- TRAITEMENT -->
                    <telerik:RadPageView ID="pvTraitement" runat="server">
                        <asp:Repeater ID="rpTraitement" runat="server" OnItemDataBound="rp_ItemDataBound">
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
                        <asp:Panel ID="pnlEmptyTraitement" runat="server" Visible="false" CssClass="empty-state">
                            <%= L("emptyTab") %>
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- COMPTABILITÉ -->
                    <telerik:RadPageView ID="pvAccounting" runat="server">
                        <div style="margin-bottom:12px; color:var(--mc-muted); font-size:13px;">
                            <%= L("introAccounting") %>
                        </div>
                        <asp:Repeater ID="rpComptabilite" runat="server" OnItemDataBound="rp_ItemDataBound">
                            <HeaderTemplate><div class="form-grid"></HeaderTemplate>
                            <ItemTemplate>
                                <div class='<%# GetFieldCssClass(Container.DataItem) %>'>
                                    <asp:HiddenField ID="hidParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                                    <asp:HiddenField ID="hidParamType" runat="server" Value='<%# Eval("ParamType") %>' />
                                    <asp:HiddenField ID="hidShortName" runat="server" Value='<%# Eval("ShortName") %>' />
                                    <label>
                                        <strong style="color:#1B4F9C;"><%# Eval("ShortName") %></strong> —
                                        <%# Eval("Name") %>
                                    </label>
                                    <asp:PlaceHolder ID="phControl" runat="server" />
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlEmptyComptabilite" runat="server" Visible="false" CssClass="empty-state">
                            <%= L("emptyTab") %>
                        </asp:Panel>
                    </telerik:RadPageView>

                    <!-- BANCAIRE -->
                    <telerik:RadPageView ID="pvBancaire" runat="server">
                        <div style="margin-bottom:12px; color:var(--mc-muted); font-size:13px;">
                            <%= L("introBank") %>
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
                    <!-- BANCAIRE -->
                    <telerik:RadPageView ID="pvComptable" runat="server">
                        <div style="margin-bottom:12px; color:var(--mc-muted); font-size:13px;">
                            <%= L("introAccountant") %>
                        </div>
                        <asp:Repeater ID="rpComptable" runat="server" OnItemDataBound="rp_ItemDataBound">
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
                        <asp:Panel ID="pnlEmptyComptable" runat="server" Visible="false" CssClass="empty-state">
                            <%= L("emptyTab") %>
                        </asp:Panel>
                    </telerik:RadPageView>

                </telerik:RadMultiPage>

            </div>
        </div>
    </div>

    <%-- Glisser-déposer d'un document dans la zone de scan (Entreprise) --%>
    <script type="text/javascript">
        (function () {
            function initDrop() {
                var dz = document.getElementById('dropZone'),
                    inp = document.getElementById('fileDocScan'),
                    lbl = document.getElementById('dzFile');
                if (!dz || !inp) return;
                if (dz.dataset.wired === '1') return;
                dz.dataset.wired = '1';

                function showName() { if (lbl) lbl.textContent = (inp.files && inp.files.length) ? inp.files[0].name : ''; }
                dz.addEventListener('click', function () { inp.click(); });
                inp.addEventListener('change', showName);
                ['dragenter', 'dragover'].forEach(function (t) {
                    dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.add('drag'); });
                });
                ['dragleave', 'dragend', 'drop'].forEach(function (t) {
                    dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.remove('drag'); });
                });
                dz.addEventListener('drop', function (e) {
                    var files = e.dataTransfer && e.dataTransfer.files;
                    if (!files || !files.length) return;
                    try { var dt = new DataTransfer(); dt.items.add(files[0]); inp.files = dt.files; } catch (ex) { }
                    showName();
                });
            }
            if (document.readyState !== 'loading') initDrop();
            else document.addEventListener('DOMContentLoaded', initDrop);
            if (window.Sys && Sys.Application) { Sys.Application.add_load(initDrop); }
        })();
    </script>

</asp:Content>
