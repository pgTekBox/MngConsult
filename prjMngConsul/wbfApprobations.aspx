<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApprobations.aspx.vb" Inherits="MngConsul.wbfApprobations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Tâches à approuver — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* ── Tâches à approuver : la signature du gabarit « Portail du client ». Le titre pose sur
           le fond, Rafraîchir à droite, deux indicateurs, la carte du filtre, puis les cartes. ── */
        .appro-page { max-width: none; margin: 0; padding: 0 }
        .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
        .fc-tete .txt { flex: 1 1 260px }
        .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
        .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
        .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E; max-width: 820px }
        .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px }
        .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
        .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 }
        .fc-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 16px }
        .fc-kpi { padding: 14px 16px; border-radius: 22px; display: flex; flex-direction: column; gap: 2px; background: #fff; color: #0E1F3D }
        .fc-kpi .lab { display: flex; align-items: center; gap: 8px; font-weight: 700; color: #44536E; font-size: 14px }
        .fc-kpi .lab i { width: 10px; height: 10px; border-radius: 50%; flex: none }
        .fc-kpi .val { font-size: 24px; font-weight: 800; line-height: 1.15 }
        .fc-kpi .sub { font-size: 14px; color: #44536E }
        .fc-filtres { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-wrap: wrap; gap: 10px 24px; align-items: flex-end; margin-bottom: 16px }
        .fc-groupe { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 800; color: #5B6B86 }
        .fc-groupe select { min-height: 44px; min-width: 240px; padding: 0 14px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; font: inherit; font-size: 14px; font-weight: 700; color: #0E1F3D }
        .alert { padding: 12px 16px; border-radius: 16px; margin-bottom: 14px; font-size: 14px; font-weight: 700 }
        .alert.success { background: #E3F3EA; color: #0F5A3A }
        .alert.error { background: #FDECEA; color: #A3261C }
        .appro-list { display: flex; flex-direction: column; gap: 12px }
        .appro-card { display: flex; gap: 18px; justify-content: space-between; align-items: flex-start; background: #fff; border: 0; border-left: 5px solid #E3B341; border-radius: 20px; padding: 16px 18px }
        .appro-card.late { border-left-color: #A3261C }
        .appro-card.done { border-left-color: #43B47A }
        .appro-card.refused { border-left-color: #AEBBCD; opacity: .75 }
        .appro-info { flex: 1 1 auto; min-width: 0 }
        .appro-job { font-size: 16px; font-weight: 800; color: #0E1F3D; display: flex; flex-wrap: wrap; align-items: center; gap: 8px }
        .appro-desc { font-size: 14px; color: #44536E; margin-top: 3px }
        .appro-meta { display: flex; flex-wrap: wrap; gap: 6px 14px; margin-top: 8px; font-size: 13px; color: #44536E }
        .appro-meta strong { color: #0E1F3D }
        .badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800 }
        .badge-type { background: #E3EBF7; color: #143A73 }
        .badge-late { background: #FDECEA; color: #A3261C }
        .badge-ok { background: #E3F3EA; color: #0F5A3A }
        .badge-no { background: #F2F5F9; color: #5B6B86 }
        .appro-actions { display: flex; flex-direction: column; gap: 8px; align-items: stretch; min-width: 240px }
        .appro-actions input[type=text] { min-height: 40px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 12px; font: inherit; font-size: 13px }
        .btn-appro, .btn-refus { min-height: 40px; padding: 0 14px; border-radius: 999px; font-size: 14px; font-weight: 800; font-family: inherit; cursor: pointer; border: 1px solid transparent }
        .btn-appro { background: #1B4F9C; color: #fff; border-color: #1B4F9C }
        .btn-appro:hover { background: #143A73 }
        .btn-refus { background: #fff; color: #A3261C; border-color: #F1B9B4 }
        .btn-refus:hover { background: #FDECEA }
        .empty-state { background: #fff; border: 0; border-radius: 24px; padding: 28px; text-align: center; color: #44536E; font-weight: 700 }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="appro-page">

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre,
             le texte d'introduction ; à droite, Rafraîchir en pastille. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litTitle" runat="server" /></h1>
                <p><asp:Literal ID="litLead" runat="server" /></p>
            </div>
            <div class="btns">
                <asp:Button ID="btnRefresh" runat="server" CssClass="fc-btn" CausesValidation="false" />
            </div>
        </div>

        <asp:Panel ID="pnlAlert" runat="server" Visible="false">
            <div class="alert success">
                <asp:Literal ID="litAlert" runat="server" />
            </div>
        </asp:Panel>

        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert error">
                <asp:Literal ID="litError" runat="server" />
            </div>
        </asp:Panel>

        <%-- Les deux indicateurs : à approuver, échéance dépassée. --%>
        <div class="fc-kpis">
            <div class="fc-kpi">
                <span class="lab"><i style="background:#E3B341"></i><asp:Literal ID="litStatWaitLabel" runat="server" /></span>
                <span class="val"><asp:Literal ID="litStatWait" runat="server" Text="0" /></span>
                <span class="sub"><asp:Literal ID="litStatWaitSub" runat="server" /></span>
            </div>
            <div class="fc-kpi">
                <span class="lab"><i style="background:#A3261C"></i><asp:Literal ID="litStatLateLabel" runat="server" /></span>
                <span class="val"><asp:Literal ID="litStatLate" runat="server" Text="0" /></span>
                <span class="sub"><asp:Literal ID="litStatLateSub" runat="server" /></span>
            </div>
        </div>

        <%-- Le filtre d'état, dans sa carte. --%>
        <section class="fc-filtres">
            <div class="fc-groupe"><asp:Literal ID="litEtatLbl" runat="server" /><asp:DropDownList ID="ddlEtat" runat="server" AutoPostBack="true" CausesValidation="false" /></div>
        </section>

        <asp:Repeater ID="rptApprobations" runat="server">
            <HeaderTemplate>
                <div class="appro-list">
            </HeaderTemplate>
            <ItemTemplate>
                <div class='appro-card <%# CardCss(Eval("Approbation"), Eval("EnRetard")) %>'>
                    <div class="appro-info">
                        <div class="appro-job">
                            <%# Server.HtmlEncode(Txt(Eval("JobNom"))) %>
                            <span class="badge badge-type"><%# Server.HtmlEncode(Txt(Eval("HandlerType"))) %></span>
                            <%# EtatBadge(Eval("Approbation"), Eval("EnRetard")) %>
                        </div>
                        <div class="appro-desc"><%# Server.HtmlEncode(Txt(Eval("JobDescription"))) %></div>
                        <div class="appro-meta">
                            <span><%# LblPrevue %> <strong><%# Eval("DateExecutionPrevue", "{0:yyyy-MM-dd HH:mm}") %></strong></span>
                            <span><%# LblCode %> : <strong><%# Server.HtmlEncode(Txt(Eval("JobCode"))) %></strong></span>
                            <%# MetaSiRempli(LblCategorie, Eval("Categorie")) %>
                            <%# MetaSiRempli(LblBeneficiaire, Eval("Beneficiaire")) %>
                            <%# MetaMontant(LblMontant, Eval("Montant")) %>
                            <%# MetaSiRempli(LblNotes, Eval("Notes")) %>
                            <%# MetaDecision(Eval("Approbation"), Eval("ApprouveParEmail"), Eval("ApprouveLe"), Eval("MotifDecision")) %>
                        </div>
                    </div>
                    <asp:Panel runat="server" CssClass="appro-actions"
                        Visible='<%# Convert.ToString(Eval("Approbation")) = "A_APPROUVER" %>'>
                        <asp:TextBox runat="server" ID="txtMotif" MaxLength="500" />
                        <asp:Button runat="server" CssClass="btn-appro"
                            Text='<%# LblApprouver %>'
                            CommandName="Approuver"
                            CommandArgument='<%# Eval("PlannedId") %>'
                            CausesValidation="false"
                            OnClientClick='<%# ConfirmJs(LblConfirmApprouver) %>' />
                        <asp:Button runat="server" CssClass="btn-refus"
                            Text='<%# LblRefuser %>'
                            CommandName="Refuser"
                            CommandArgument='<%# Eval("PlannedId") %>'
                            CausesValidation="false"
                            OnClientClick='<%# ConfirmJs(LblConfirmRefuser) %>' />
                    </asp:Panel>
                </div>
            </ItemTemplate>
            <FooterTemplate>
                </div>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
            <p><asp:Literal ID="litEmpty" runat="server" /></p>
            <small><asp:Literal ID="litEmptyHint" runat="server" /></small>
        </asp:Panel>

    </div>
</asp:Content>
