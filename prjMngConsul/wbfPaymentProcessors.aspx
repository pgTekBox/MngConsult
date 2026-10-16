<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfPaymentProcessors.aspx.vb" Inherits="MngConsul.wbfPaymentProcessors" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litTitle" runat="server" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pp-wrap { max-width: 820px; margin: 0 auto; padding: 8px 4px 40px; }
        .pp-head h1 { font-size: 22px; font-weight: 800; color: #0E1F3D; margin: 0 0 4px; }
        .pp-head p { color: #44536E; font-size: 14px; margin: 0 0 20px; }

        .pp-msg { padding: 12px 16px; border-radius: 12px; font-weight: 700; font-size: 14px;
                  margin-bottom: 18px; }
        .pp-msg.ok  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .pp-msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; }

        .pp-card { background: #fff; border: 1px solid var(--mc-stroke, #D5DDE8); border-radius: 16px;
                   padding: 20px 22px; box-shadow: 0 1px 2px rgba(15,23,42,.04); margin-bottom: 16px; }
        .pp-card-head { display: flex; align-items: center; justify-content: space-between; gap: 12px;
                        margin-bottom: 14px; }
        .pp-logo { display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 800;
                   color: #0E1F3D; }
        .pp-logo .pp-mark { width: 34px; height: 34px; border-radius: 9px; background: #0E1F3D; color:#fff;
                   display: inline-flex; align-items: center; justify-content: center; font-size: 16px; }

        .pp-badge { display: inline-flex; align-items: center; gap: 7px; padding: 5px 12px; border-radius: 999px;
                    font-size: 12px; font-weight: 800; }
        .pp-badge.on  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .pp-badge.off { background: #f1f5f9; border: 1px solid #D5DDE8; color: #44536E; }
        .pp-badge .dot { width: 8px; height: 8px; border-radius: 50%; }
        .pp-badge.on .dot  { background: #10b981; box-shadow: 0 0 0 3px rgba(16,185,129,.2); }
        .pp-badge.off .dot { background: #94a3b8; }

        .pp-detail { display: grid; grid-template-columns: 160px 1fr; gap: 8px 14px; font-size: 13px;
                     color: #334155; margin: 6px 0 18px; }
        .pp-detail .k { color: #44536E; font-weight: 700; }
        .pp-detail .v { color: #0E1F3D; word-break: break-all; }

        .pp-actions { display: flex; gap: 10px; flex-wrap: wrap; }
        .pp-note { color: #44536E; font-size: 13px; margin: 4px 0 16px; }

        .pp-btn { padding: 10px 18px; border-radius: 10px; font-weight: 700; font-size: 14px; cursor: pointer;
                  border: 1px solid transparent; }
        .pp-btn-primary { background: #1B4F9C; color: #fff; border-color: #1B4F9C; }
        .pp-btn-primary:hover { background: #143A73; }
        .pp-btn-ghost { background: #fff; color: #1B4F9C; border-color: #bfdbfe; }
        .pp-btn-danger { background: #fff; color: #b91c1c; border-color: #fecaca; }
        .pp-btn-danger:hover { background: #fef2f2; }

        .pp-soon { opacity: .65; }
        /* ── La signature du gabarit « Portail du client » : le titre pose sur le fond,
           les trois cartes (Square, Plaid, Stripe) arrondies, côte à côte sur grand écran. ── */
        .pp-wrap { max-width: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(auto-fit, minmax(380px, 1fr)); gap: 16px; align-items: start; }
        .pp-wrap > .fc-tete, .pp-wrap > .pp-msg { grid-column: 1 / -1; }
        .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin: 0; }
        .fc-tete .txt { flex: 1 1 260px; }
        .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em; }
        .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D; }
        .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E; }
        .pp-msg { border: 0; border-radius: 16px; margin: 0; }
        .pp-msg.ok { background: #E3F3EA; color: #0F5A3A; }
        .pp-msg.err { background: #FDECEA; color: #A3261C; }
        .pp-card { border: 0; border-radius: 24px; box-shadow: none; padding: 20px 22px; margin: 0; }
        .pp-logo { font-size: 19px; }
        .pp-logo .pp-mark { width: 40px; height: 40px; border-radius: 12px; }
        .pp-badge { border: 0; font-size: 13px; }
        .pp-badge.on { background: #E3F3EA; color: #0F5A3A; }
        .pp-badge.on .dot { background: #43B47A; box-shadow: none; }
        .pp-badge.off { background: #F2F5F9; color: #5B6B86; }
        .pp-detail { font-size: 14px; }
        .pp-note { font-size: 14px; }
        .pp-btn { min-height: 44px; padding: 0 18px; border-radius: 999px; font-family: inherit; }
        .pp-btn-primary { font-weight: 800; padding: 0 20px; }
        .pp-btn-ghost { border-color: #AEBBCD; color: #0E1F3D; }
        .pp-btn-ghost:hover { background: #F2F5F9; }
        .pp-btn-danger { border-color: #F1B9B4; color: #A3261C; }
        .pp-btn-danger:hover { background: #FDECEA; }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pp-wrap">
        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre, le sous-titre. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litHead" runat="server" /></h1>
                <p><asp:Literal ID="litSub" runat="server" /></p>
            </div>
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
