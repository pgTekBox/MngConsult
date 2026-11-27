<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfPaymentSuccess.aspx.vb" Inherits="MngConsul.wbfPaymentSuccess" %>

<%-- Confirmation de paiement, dans le portail (en-tête, menu et sélecteur de langue
     de l'ERP ; ce sélecteur garde le session_id de Stripe). Deux colonnes : à gauche
     le reçu et l'accès au tableau de bord, à droite le détail de l'abonnement. --%>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="css/abo-recap.css?v=2026112601" rel="stylesheet" />
    <style>
        .ps-wrap { padding: 24px; }
        .ps-card {
            max-width: 1100px; margin: 0 auto; background: #fff;
            border: 1px solid #D5DDE8; border-radius: 20px;
            box-shadow: 0 12px 30px rgba(2,6,23,.06); overflow: hidden;
        }
        .ps-head { display: flex; align-items: center; gap: 18px; padding: 24px 28px; border-bottom: 1px solid #E6ECF3; }
        .ps-check {
            flex: 0 0 auto; width: 60px; height: 60px; border-radius: 50%;
            display: inline-flex; align-items: center; justify-content: center; color: #fff;
            background: linear-gradient(135deg, #10b981, #059669);
            box-shadow: 0 10px 22px rgba(16,185,129,.30);
            animation: psPop .5s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        @keyframes psPop { 0% { transform: scale(0); } 100% { transform: scale(1); } }
        .ps-head h1 { font-size: 24px; font-weight: 800; margin: 0 0 4px; color: #0E1F3D; }
        .ps-head p { margin: 0; color: #44536E; font-size: 14px; line-height: 1.5; }

        .ps-cols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 28px; padding: 24px 28px; align-items: start; }

        .ps-receipt { background: #f8fafc; border-radius: 14px; padding: 18px 22px; }
        .ps-receipt h3 { font-size: 11px; font-weight: 800; color: #44536E; text-transform: uppercase; letter-spacing: .1em; margin: 0 0 10px; }
        .ps-row { display: flex; justify-content: space-between; gap: 12px; padding: 7px 0; font-size: 14px; border-top: 1px solid #E9EEF5; }
        .ps-row:first-of-type { border-top: 0; }
        .ps-row .lbl { color: #44536E; }
        .ps-row .val { font-weight: 700; color: #1e293b; text-align: right; overflow-wrap: anywhere; }
        .ps-row.total { border-top: 1px solid #D5DDE8; padding-top: 12px; margin-top: 4px; }
        .ps-row.total .lbl { font-weight: 800; color: #1e293b; }
        .ps-row.total .val { font-size: 18px; font-weight: 900; color: #1B4F9C; }

        .ps-note { margin: 14px 2px 0; font-size: 13px; color: #44536E; line-height: 1.5; }
        .ps-actions { margin-top: 18px; }
        .ps-btn {
            display: inline-flex; align-items: center; gap: 8px; padding: 13px 26px; border-radius: 12px;
            font-size: 14px; font-weight: 800; text-decoration: none; color: #fff;
            background: linear-gradient(135deg, #1B4F9C, #06b6d4);
        }
        .ps-btn:hover { box-shadow: 0 12px 24px rgba(37,99,235,.3); }

        .ps-cols .abo-recap { margin: 0; }
        .ps-cols .abo-inclus ul { columns: 2; column-gap: 16px; }
        .ps-cols .abo-inclus li { break-inside: avoid; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ps-wrap">
        <div class="ps-card">

            <div class="ps-head">
                <div class="ps-check">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <div>
                    <h1><%= L("title") %></h1>
                    <p>
                        <%= L("thanksLine") %>
                        <%= L("subBefore") %><strong><asp:Literal ID="litPlanName" runat="server" /></strong><%= L("subAfter") %>
                    </p>
                </div>
            </div>

            <div class="ps-cols">

                <%-- Gauche : reçu, courriel de Stripe, accès au tableau de bord --%>
                <div>
                    <div class="ps-receipt">
                        <h3><%= L("receiptTitle") %></h3>
                        <div class="ps-row">
                            <span class="lbl"><%= L("txnLabel") %></span>
                            <span class="val" style="font-family: monospace; font-size: 12px;"><asp:Literal ID="litTransactionId" runat="server" /></span>
                        </div>
                        <div class="ps-row">
                            <span class="lbl"><%= L("dateLabel") %></span>
                            <span class="val"><asp:Literal ID="litDate" runat="server" /></span>
                        </div>
                        <div class="ps-row">
                            <span class="lbl"><%= L("cardLabel") %></span>
                            <span class="val"><asp:Literal ID="litCard" runat="server" /></span>
                        </div>
                        <div class="ps-row">
                            <span class="lbl"><%= L("planLabel") %></span>
                            <span class="val"><asp:Literal ID="litPlanName2" runat="server" /></span>
                        </div>
                        <div class="ps-row">
                            <span class="lbl"><%= L("nextBillingLabel") %></span>
                            <span class="val"><asp:Literal ID="litNextBilling" runat="server" /></span>
                        </div>
                        <div class="ps-row total">
                            <span class="lbl"><%= L("amountLabel") %></span>
                            <span class="val"><asp:Literal ID="litAmount" runat="server" /></span>
                        </div>
                    </div>

                    <p class="ps-note"><%= TexteBasPage() %></p>

                    <div class="ps-actions">
                        <asp:HyperLink ID="lnkDashboard" runat="server" NavigateUrl="~/Default.aspx" CssClass="ps-btn" />
                    </div>
                </div>

                <%-- Droite : détail de l'abonnement souscrit (prix, taxes, essai, fonctions incluses) --%>
                <div>
                    <asp:Literal ID="litAbonnement" runat="server" />
                </div>

            </div>
        </div>
    </div>
</asp:Content>
