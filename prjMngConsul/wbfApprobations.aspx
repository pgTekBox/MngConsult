<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApprobations.aspx.vb" Inherits="MngConsul.wbfApprobations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Tâches à approuver — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .appro-page {
            max-width: 1100px;
            margin: 0 auto;
            padding: 16px;
        }

        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }

        .page-title {
            font-size: 22px;
            font-weight: 800;
            color: #0f172a;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .page-lead {
            color: #64748b;
            font-size: 13px;
            margin: 0 0 18px;
            max-width: 720px;
        }

        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
            margin-bottom: 18px;
        }

        .stat-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 14px 16px;
        }

            .stat-card.amber { border-color: #fcd34d; background: #fffbeb; }
            .stat-card.red { border-color: #fecaca; background: #fef2f2; }

        .stat-label {
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .03em;
            color: #64748b;
        }

        .stat-value {
            font-size: 26px;
            font-weight: 800;
            color: #0f172a;
            margin-top: 4px;
        }

        .filter-bar {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }

            .filter-bar select {
                padding: 8px 10px;
                border: 1px solid #cbd5e1;
                border-radius: 8px;
                font-size: 13px;
                background: #fff;
            }

        .alert {
            padding: 12px 14px;
            border-radius: 10px;
            margin-bottom: 14px;
            font-size: 13px;
            font-weight: 600;
        }

            .alert.success { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
            .alert.error { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }

        .appro-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .appro-card {
            display: flex;
            gap: 18px;
            justify-content: space-between;
            align-items: flex-start;
            background: #fff;
            border: 1px solid #e2e8f0;
            border-left: 4px solid #f59e0b;
            border-radius: 12px;
            padding: 14px 16px;
        }

            .appro-card.late { border-left-color: #dc2626; background: #fffafa; }
            .appro-card.done { border-left-color: #10b981; }
            .appro-card.refused { border-left-color: #94a3b8; opacity: .75; }

        .appro-info { flex: 1 1 auto; min-width: 0; }

        .appro-job {
            font-size: 15px;
            font-weight: 800;
            color: #0f172a;
        }

        .appro-desc {
            font-size: 13px;
            color: #475569;
            margin-top: 3px;
        }

        .appro-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 6px 14px;
            margin-top: 8px;
            font-size: 12px;
            color: #64748b;
        }

            .appro-meta strong { color: #0f172a; }

        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 800;
            letter-spacing: .02em;
        }

        .badge-type { background: #eff6ff; color: #1d4ed8; }
        .badge-late { background: #fee2e2; color: #b91c1c; }
        .badge-ok { background: #ecfdf5; color: #047857; }
        .badge-no { background: #f1f5f9; color: #475569; }

        .appro-actions {
            display: flex;
            flex-direction: column;
            gap: 8px;
            align-items: stretch;
            min-width: 230px;
        }

            .appro-actions input[type=text] {
                padding: 7px 9px;
                border: 1px solid #cbd5e1;
                border-radius: 8px;
                font-size: 12px;
            }

        .btn-appro, .btn-refus {
            padding: 8px 12px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            border: 1px solid transparent;
        }

        .btn-appro { background: #ecfdf5; color: #047857; border-color: #a7f3d0; }
        .btn-refus { background: #fef2f2; color: #b91c1c; border-color: #fecaca; }

        .empty-state {
            background: #fff;
            border: 1px dashed #cbd5e1;
            border-radius: 12px;
            padding: 28px;
            text-align: center;
            color: #64748b;
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="appro-page">

        <div class="page-header">
            <h1 class="page-title">📥 <asp:Literal ID="litTitle" runat="server" /></h1>
        </div>

        <p class="page-lead">
            <asp:Literal ID="litLead" runat="server" />
        </p>

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

        <div class="stats-row">
            <div class="stat-card amber">
                <div class="stat-label"><asp:Literal ID="litStatWaitLabel" runat="server" /></div>
                <div class="stat-value"><asp:Literal ID="litStatWait" runat="server" Text="0" /></div>
            </div>
            <div class="stat-card red">
                <div class="stat-label"><asp:Literal ID="litStatLateLabel" runat="server" /></div>
                <div class="stat-value"><asp:Literal ID="litStatLate" runat="server" Text="0" /></div>
            </div>
        </div>

        <div class="filter-bar">
            <asp:DropDownList ID="ddlEtat" runat="server" AutoPostBack="true" CausesValidation="false" />
            <asp:Button ID="btnRefresh" runat="server" CssClass="btn-appro" CausesValidation="false" />
        </div>

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
