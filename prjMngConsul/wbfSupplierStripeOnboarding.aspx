<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfSupplierStripeOnboarding.aspx.vb" Inherits="MngConsul.wbfSupplierStripeOnboarding" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("pageTitle") %></title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc; --slate-200: #e2e8f0;
            --slate-500: #64748b; --slate-700: #334155; --slate-800: #1e293b;
            --blue-600: #2563eb; --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444; --amber-500: #f59e0b;
            --purple-500: #635BFF;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: #f6f7fb;
            padding: 24px;
        }

        .layout { max-width: 680px; margin: 0 auto; }

        .card {
            background: #fff;
            border-radius: 18px;
            box-shadow: 0 8px 24px rgba(15,23,42,.08);
            padding: 28px 32px;
            margin-bottom: 16px;
        }

        .header {
            text-align: center;
            margin-bottom: 24px;
        }
        .stripe-logo {
            color: var(--purple-500);
            margin-bottom: 12px;
        }
        .header h1 {
            font-size: 24px;
            font-weight: 800;
            margin: 0 0 8px 0;
        }
        .header .subtitle {
            color: var(--slate-500);
            font-size: 14px;
            margin: 0;
        }

        .supplier-info {
            background: var(--slate-50);
            border-radius: 12px;
            padding: 16px 18px;
            margin-bottom: 24px;
        }
        .supplier-info h3 {
            font-size: 11px;
            font-weight: 800;
            color: var(--slate-500);
            text-transform: uppercase;
            letter-spacing: .1em;
            margin: 0 0 8px 0;
        }
        .supplier-info .name {
            font-size: 18px;
            font-weight: 800;
            color: var(--slate-800);
            margin: 0 0 4px 0;
        }
        .supplier-info .email {
            font-size: 13px;
            color: var(--slate-600);
        }

        .status-box {
            border-radius: 12px;
            padding: 16px 18px;
            margin-bottom: 16px;
            font-size: 14px;
        }
        .status-box.not-configured {
            background: rgba(245,158,11,.08);
            border: 1px solid rgba(245,158,11,.3);
            color: #92400e;
        }
        .status-box.pending {
            background: rgba(59,130,246,.08);
            border: 1px solid rgba(59,130,246,.3);
            color: var(--blue-600);
        }
        .status-box.active {
            background: rgba(16,185,129,.08);
            border: 1px solid rgba(16,185,129,.3);
            color: var(--green-600);
        }
        .status-box.restricted {
            background: rgba(239,68,68,.08);
            border: 1px solid rgba(239,68,68,.3);
            color: var(--red-500);
        }

        .status-title {
            font-weight: 800;
            margin-bottom: 4px;
        }

        ul.features {
            list-style: none;
            padding: 0;
            margin: 16px 0;
        }
        ul.features li {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            padding: 6px 0;
            font-size: 14px;
            color: var(--slate-700);
        }
        ul.features svg {
            color: var(--green-500);
            margin-top: 2px;
            flex-shrink: 0;
        }

        .actions {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            flex-wrap: wrap;
        }

        .btn {
            flex: 1;
            min-width: 200px;
            padding: 13px 24px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 800;
            font-family: var(--font);
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            transition: transform .12s, box-shadow .12s;
            border: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        .btn:hover { transform: translateY(-1px); }

        .btn-primary {
            background: linear-gradient(135deg, var(--purple-500), #4F46E5);
            color: white;
        }
        .btn-primary:hover { box-shadow: 0 12px 24px rgba(99,91,255,.3); }

        .btn-secondary {
            background: var(--slate-50);
            color: var(--slate-700);
            border: 1px solid var(--slate-200);
        }
        .btn-secondary:hover { background: #fff; box-shadow: 0 4px 12px rgba(15,23,42,.06); }

        .acct-id {
            background: var(--slate-50);
            border-radius: 8px;
            padding: 8px 12px;
            font-family: monospace;
            font-size: 11px;
            color: var(--slate-500);
            margin-top: 10px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="layout">

            <div class="card">

                <div class="header">
                    <div class="stripe-logo">
                        <svg width="48" height="24" viewBox="0 0 60 25" fill="currentColor">
                            <path d="M59.5,14.1c0-4.2-2-7.5-5.9-7.5s-6.3,3.3-6.3,7.4c0,4.9,2.8,7.4,6.8,7.4c2,0,3.5-0.4,4.6-1.1v-3.3c-1.1,0.6-2.4,0.9-4.1,0.9c-1.6,0-3-0.6-3.2-2.5h8.1C59.5,15.3,59.5,14.5,59.5,14.1z M51.3,12.6c0-1.8,1.1-2.6,2.1-2.6c1,0,2,0.8,2,2.6H51.3z M40.8,6.6c-1.6,0-2.7,0.8-3.2,1.3l-0.2-1H33.7v18.9l4.2-0.9l0-4.6c0.6,0.5,1.6,1.1,3.1,1.1c3.1,0,5.9-2.5,5.9-7.5C46.9,9.3,44,6.6,40.8,6.6z M39.8,17.6c-1,0-1.7-0.4-2-0.8l0-6.4c0.4-0.5,1-0.8,2-0.8c1.6,0,2.7,1.8,2.7,4C42.6,15.9,41.5,17.6,39.8,17.6z M32.1,5.6L27.9,6.5v3.4l4.2-0.9V5.6z M27.9,6.9h4.2v14.3h-4.2V6.9z M23.4,8l-0.3-1.2h-3.6v14.4h4.1v-9.7c1-1.3,2.6-1,3.1-0.9V6.8C26.3,6.6,24.4,6.2,23.4,8z M14.9,3.2l-4.1,0.9V18c0,2.5,1.9,4.3,4.3,4.3c1.3,0,2.3-0.2,2.9-0.5v-3.3c-0.5,0.2-3.1,1-3.1-1.5v-5.7h3.1V7.4h-3.1V3.2z M4.2,11c0-0.6,0.5-0.9,1.4-0.9c1.2,0,2.8,0.4,4.1,1.1V7.3c-1.4-0.6-2.7-0.8-4.1-0.8c-3.3,0-5.6,1.8-5.6,4.7c0,4.6,6.3,3.9,6.3,5.9c0,0.8-0.7,1-1.5,1c-1.3,0-3-0.5-4.4-1.2v4c1.5,0.6,3,0.9,4.4,0.9c3.4,0,5.8-1.7,5.8-4.7C10.6,12.2,4.2,13,4.2,11z"/>
                        </svg>
                    </div>
                    <h1><%= L("hTitle") %></h1>
                    <p class="subtitle"><%= L("subtitle") %></p>
                </div>

                <div class="supplier-info">
                    <h3><%= L("supplierLabel") %></h3>
                    <div class="name"><asp:Literal ID="litSupplierName" runat="server" /></div>
                    <div class="email"><asp:Literal ID="litSupplierEmail" runat="server" /></div>
                </div>

                <!-- État : pas encore configuré -->
                <asp:Panel ID="pnlStatusNew" runat="server" Visible="false" CssClass="status-box not-configured">
                    <div class="status-title"><%= L("stNewTitle") %></div>
                    <%= L("stNewBody") %>
                </asp:Panel>

                <!-- État : onboarding en cours -->
                <asp:Panel ID="pnlStatusPending" runat="server" Visible="false" CssClass="status-box pending">
                    <div class="status-title"><%= L("stPendTitle") %></div>
                    <%= L("stPendBody") %>
                    <div class="acct-id"><asp:Literal ID="litAcctIdPending" runat="server" /></div>
                </asp:Panel>

                <!-- État : actif -->
                <asp:Panel ID="pnlStatusActive" runat="server" Visible="false" CssClass="status-box active">
                    <div class="status-title"><%= L("stActiveTitle") %></div>
                    <%= L("stActiveBody") %>
                    <div class="acct-id"><asp:Literal ID="litAcctIdActive" runat="server" /></div>
                </asp:Panel>

                <!-- État : restreint / erreur -->
                <asp:Panel ID="pnlStatusRestricted" runat="server" Visible="false" CssClass="status-box restricted">
                    <div class="status-title"><%= L("stRestrTitle") %></div>
                    <asp:Literal ID="litRestrictedMessage" runat="server" />
                </asp:Panel>

                <ul class="features">
                    <li>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        <%= L("feat1") %>
                    </li>
                    <li>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        <%= L("feat2") %>
                    </li>
                    <li>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        <%= L("feat3") %>
                    </li>
                    <li>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        <%= L("feat4") %>
                    </li>
                </ul>

                <%-- Choix du mode d'inscription : direct ou par courriel --%>
                <asp:Panel ID="pnlModeChoice" runat="server" Visible="false">

                    <h3 style="font-size: 13px; font-weight: 800; color: var(--slate-700); text-transform: uppercase; letter-spacing: .08em; margin: 24px 0 12px 0;">
                        <%= L("modeChoiceTitle") %>
                    </h3>

                    <div style="display: grid; grid-template-columns: 1fr; gap: 12px; margin-bottom: 16px;">

                        <%-- Mode A : direct (utilisateur remplit pour le fournisseur) --%>
                        <div style="background: #fff; border: 2px solid var(--slate-200); border-radius: 12px; padding: 16px 18px;">
                            <div style="font-weight: 800; font-size: 14px; margin-bottom: 4px;">
                                <%= L("modeATitle") %>
                            </div>
                            <div style="font-size: 12px; color: var(--slate-500); margin-bottom: 10px;">
                                <%= L("modeADesc") %>
                            </div>
                            <asp:Button ID="btnStartOnboarding" runat="server"
                                Text="Configurer maintenant →"
                                CssClass="btn btn-primary"
                                Style="width:100%;"
                                CausesValidation="false" />
                        </div>

                        <%-- Mode B : invitation par courriel --%>
                        <div style="background: #fff; border: 2px solid var(--slate-200); border-radius: 12px; padding: 16px 18px;">
                            <div style="font-weight: 800; font-size: 14px; margin-bottom: 4px;">
                                <%= L("modeBTitle") %>
                            </div>
                            <div style="font-size: 12px; color: var(--slate-500); margin-bottom: 10px;">
                                <%= L("modeBDesc") %>
                                <strong><%= L("modeBRecommended") %></strong>.
                            </div>

                            <div style="margin-bottom: 10px;">
                                <label style="display:block; font-size: 11px; font-weight: 700; color: var(--slate-700); margin-bottom: 4px;">
                                    <%= L("lblSupplierEmail") %>
                                </label>
                                <asp:TextBox ID="tbInvitationEmail" runat="server"
                                    Style="width:100%; padding: 10px 12px; border: 2px solid var(--slate-200); border-radius: 8px; font-size: 13px;"
                                    placeholder="compta@fournisseur.com" />
                            </div>

                            <asp:Button ID="btnSendInvitation" runat="server"
                                Text="Envoyer l'invitation par courriel ✉️"
                                CssClass="btn btn-primary"
                                Style="width:100%;"
                                CausesValidation="false" />
                        </div>
                    </div>

                </asp:Panel>

                <asp:Panel ID="pnlInvitationSent" runat="server" Visible="false"
                    CssClass="status-box active"
                    Style="margin-top: 16px;">
                    <div class="status-title"><%= L("invSentTitle") %></div>
                    <%= L("invSentPre") %> <strong><asp:Literal ID="litInvitationEmailSent" runat="server" /></strong>
                    <%= L("invSentPost") %>
                </asp:Panel>

                <div class="actions">
                    <asp:Button ID="btnResumeOnboarding" runat="server"
                        Text="Reprendre l'inscription →"
                        CssClass="btn btn-primary"
                        CausesValidation="false"
                        Visible="false" />
                    <asp:Button ID="btnResendInvitation" runat="server"
                        Text="Renvoyer l'invitation ✉️"
                        CssClass="btn btn-primary"
                        CausesValidation="false"
                        Visible="false" />
                    <asp:HyperLink ID="lnkBack" runat="server"
                        NavigateUrl="~/wbfSuppliers.aspx"
                        CssClass="btn btn-secondary">
                    </asp:HyperLink>
                </div>

            </div>

        </div>

    </form>
</body>
</html>
