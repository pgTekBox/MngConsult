<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfPaymentProcessors.aspx.vb" Inherits="MngConsul.wbfPaymentProcessors" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litTitle" runat="server" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pp-wrap { max-width: 820px; margin: 0 auto; padding: 8px 4px 40px; }
        .pp-head h1 { font-size: 22px; font-weight: 800; color: #0f172a; margin: 0 0 4px; }
        .pp-head p { color: #64748b; font-size: 14px; margin: 0 0 20px; }

        .pp-msg { padding: 12px 16px; border-radius: 12px; font-weight: 700; font-size: 14px;
                  margin-bottom: 18px; }
        .pp-msg.ok  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .pp-msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; }

        .pp-card { background: #fff; border: 1px solid var(--mc-stroke, #e2e8f0); border-radius: 16px;
                   padding: 20px 22px; box-shadow: 0 1px 2px rgba(15,23,42,.04); margin-bottom: 16px; }
        .pp-card-head { display: flex; align-items: center; justify-content: space-between; gap: 12px;
                        margin-bottom: 14px; }
        .pp-logo { display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 800;
                   color: #0f172a; }
        .pp-logo .pp-mark { width: 34px; height: 34px; border-radius: 9px; background: #0f172a; color:#fff;
                   display: inline-flex; align-items: center; justify-content: center; font-size: 16px; }

        .pp-badge { display: inline-flex; align-items: center; gap: 7px; padding: 5px 12px; border-radius: 999px;
                    font-size: 12px; font-weight: 800; }
        .pp-badge.on  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .pp-badge.off { background: #f1f5f9; border: 1px solid #e2e8f0; color: #64748b; }
        .pp-badge .dot { width: 8px; height: 8px; border-radius: 50%; }
        .pp-badge.on .dot  { background: #10b981; box-shadow: 0 0 0 3px rgba(16,185,129,.2); }
        .pp-badge.off .dot { background: #94a3b8; }

        .pp-detail { display: grid; grid-template-columns: 160px 1fr; gap: 8px 14px; font-size: 13px;
                     color: #334155; margin: 6px 0 18px; }
        .pp-detail .k { color: #64748b; font-weight: 700; }
        .pp-detail .v { color: #0f172a; word-break: break-all; }

        .pp-actions { display: flex; gap: 10px; flex-wrap: wrap; }
        .pp-note { color: #64748b; font-size: 13px; margin: 4px 0 16px; }

        .pp-btn { padding: 10px 18px; border-radius: 10px; font-weight: 700; font-size: 14px; cursor: pointer;
                  border: 1px solid transparent; }
        .pp-btn-primary { background: #2563eb; color: #fff; border-color: #2563eb; }
        .pp-btn-primary:hover { background: #1d4ed8; }
        .pp-btn-ghost { background: #fff; color: #2563eb; border-color: #bfdbfe; }
        .pp-btn-danger { background: #fff; color: #b91c1c; border-color: #fecaca; }
        .pp-btn-danger:hover { background: #fef2f2; }

        .pp-soon { opacity: .65; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pp-wrap">
        <div class="pp-head">
            <h1><asp:Literal ID="litHead" runat="server" /></h1>
            <p><asp:Literal ID="litSub" runat="server" /></p>
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false" CssClass="pp-msg">
            <asp:Literal ID="litMsg" runat="server" />
        </asp:Panel>

        <%-- Carte Square --%>
        <div class="pp-card">
            <div class="pp-card-head">
                <div class="pp-logo"><span class="pp-mark">■</span> Square</div>
                <asp:Literal ID="litSquareBadge" runat="server" />
            </div>

            <asp:Panel ID="pnlConnected" runat="server" Visible="false">
                <div class="pp-detail">
                    <div class="k"><asp:Literal ID="litLblMerchant" runat="server" /></div>
                    <div class="v"><asp:Literal ID="litMerchant" runat="server" /></div>
                    <div class="k"><asp:Literal ID="litLblLocation" runat="server" /></div>
                    <div class="v"><asp:Literal ID="litLocation" runat="server" /></div>
                    <div class="k"><asp:Literal ID="litLblSince" runat="server" /></div>
                    <div class="v"><asp:Literal ID="litSince" runat="server" /></div>
                </div>
                <div class="pp-actions">
                    <asp:Button ID="btnReconnect" runat="server" CssClass="pp-btn pp-btn-ghost"
                        CausesValidation="false" />
                    <asp:Button ID="btnDisconnect" runat="server" CssClass="pp-btn pp-btn-danger"
                        CausesValidation="false" />
                </div>
            </asp:Panel>

            <asp:Panel ID="pnlDisconnected" runat="server" Visible="false">
                <p class="pp-note"><asp:Literal ID="litSquareIntro" runat="server" /></p>
                <div class="pp-actions">
                    <asp:Button ID="btnConnect" runat="server" CssClass="pp-btn pp-btn-primary"
                        CausesValidation="false" />
                </div>
            </asp:Panel>
        </div>

        <%-- Carte Plaid --%>
        <div class="pp-card">
            <div class="pp-card-head">
                <div class="pp-logo"><span class="pp-mark" style="background:#111827;">P</span> Plaid</div>
                <asp:Literal ID="litPlaidBadge" runat="server" />
            </div>

            <asp:Panel ID="pnlPlaidConnected" runat="server" Visible="false">
                <div class="pp-detail">
                    <div class="k"><asp:Literal ID="litLblPlaidBanks" runat="server" /></div>
                    <div class="v"><asp:Literal ID="litPlaidBanks" runat="server" /></div>
                    <div class="k"><asp:Literal ID="litLblPlaidAccounts" runat="server" /></div>
                    <div class="v"><asp:Literal ID="litPlaidAccounts" runat="server" /></div>
                </div>

                <div class="pp-toggle" style="display:flex; align-items:center; gap:10px; margin:14px 0 4px;">
                    <asp:CheckBox ID="chkAutoImport" runat="server" AutoPostBack="true" />
                </div>
                <p class="pp-note"><asp:Literal ID="litAutoImportHint" runat="server" /></p>

                <div class="pp-actions">
                    <asp:Button ID="btnPlaidManage" runat="server" CssClass="pp-btn pp-btn-ghost"
                        CausesValidation="false" />
                    <asp:Button ID="btnPlaidAdd" runat="server" CssClass="pp-btn pp-btn-primary"
                        CausesValidation="false" />
                </div>
            </asp:Panel>

            <asp:Panel ID="pnlPlaidDisconnected" runat="server" Visible="false">
                <p class="pp-note"><asp:Literal ID="litPlaidIntro" runat="server" /></p>
                <div class="pp-actions">
                    <asp:Button ID="btnPlaidConnect" runat="server" CssClass="pp-btn pp-btn-primary"
                        CausesValidation="false" />
                </div>
            </asp:Panel>
        </div>

        <%-- Autres processeurs (à venir) --%>
        <div class="pp-card pp-soon">
            <div class="pp-card-head">
                <div class="pp-logo"><span class="pp-mark" style="background:#635bff;">S</span> Stripe</div>
                <span class="pp-badge off"><span class="dot"></span><asp:Literal ID="litSoon" runat="server" /></span>
            </div>
            <p class="pp-note"><asp:Literal ID="litStripeNote" runat="server" /></p>
        </div>
    </div>
</asp:Content>
