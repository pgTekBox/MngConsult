<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfBeneficesNonRepartis.aspx.vb" Inherits="MngConsul.wbfBeneficesNonRepartis" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Bénéfices non répartis — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* ═══════════════════════════════════════
           TOOLBAR
        ═══════════════════════════════════════ */
        .report-toolbar {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px; flex-wrap: wrap; padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke); background: rgba(255,255,255,.75);
        }

        .report-title { font-weight: 900; font-size: 18px; }
        .report-sub { color: var(--mc-muted); font-size: 13px; margin-top: 4px; }

        .report-actions {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
        }

        .filter-period {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
            padding: 10px 16px; border-bottom: 1px solid var(--mc-stroke); font-size: 13px;
        }

        .filter-period label { font-weight: 700; color: var(--mc-muted); font-size: 12px; }

        .filter-period .riTextBox {
            padding: 8px 10px !important; border-radius: 10px !important;
            border: 1px solid var(--mc-stroke) !important; font-size: 13px; width: 130px !important;
        }

        /* ═══════════════════════════════════════
           RAPPORT
        ═══════════════════════════════════════ */
        .report-body { padding: 20px; max-width: 700px; margin: 0 auto; }

        .report-header {
            text-align: center; margin-bottom: 28px; padding-bottom: 16px;
            border-bottom: 2px solid #0f172a;
        }

        .report-header h1 {
            font-size: 22px; font-weight: 900; margin: 0 0 4px; letter-spacing: -.02em;
        }

        .report-header .company-name {
            font-size: 16px; font-weight: 700; color: #334155; margin-bottom: 2px;
        }

        .report-header .report-date { font-size: 12px; color: #64748b; }

        /* ── Tableau ── */
        .bnr-table {
            width: 100%; border-collapse: collapse; font-size: 14px;
        }

        .bnr-table td { padding: 10px 16px; vertical-align: top; }

        /* Ligne d'ouverture */
        .bnr-open td {
            font-weight: 800; font-size: 15px; padding: 14px 16px;
            background: linear-gradient(135deg, #1e293b, #334155); color: #fff;
        }

        .bnr-open .bnr-amount { font-size: 17px; font-weight: 900; }

        /* Ligne normale */
        .bnr-line td {
            border-bottom: 1px solid #f1f5f9; font-size: 14px;
        }

        .bnr-line:hover td { background: #f8fafc; }

        .bnr-line .item-label { padding-left: 24px; }

        .bnr-amount {
            text-align: right;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 600; width: 160px; white-space: nowrap;
        }

        /* Sous-ligne (détail) */
        .bnr-detail td {
            border-bottom: 1px solid #f8fafc; font-size: 13px; color: #64748b;
        }

        .bnr-detail .item-label { padding-left: 48px; }
        .bnr-detail .bnr-amount { font-weight: 500; color: #64748b; }

        /* Ligne d'addition (bénéfice net, etc.) */
        .bnr-add td {
            font-weight: 700; font-size: 14px;
            border-bottom: 1px solid #e2e8f0;
            color: #15803d;
        }

        .bnr-add .item-label { padding-left: 24px; }
        .bnr-add .bnr-amount { color: #15803d; font-weight: 700; }

        /* Ligne de soustraction (dividendes, retraits) */
        .bnr-sub td {
            font-weight: 700; font-size: 14px;
            border-bottom: 1px solid #e2e8f0;
            color: #dc2626;
        }

        .bnr-sub .item-label { padding-left: 24px; }
        .bnr-sub .bnr-amount { color: #dc2626; font-weight: 700; }

        /* Sous-total intermédiaire */
        .bnr-subtotal td {
            font-weight: 800; font-size: 14px; padding: 10px 16px;
            border-top: 1px solid #cbd5e1; border-bottom: 1px solid #cbd5e1;
            background: #f8fafc; color: #0f172a;
        }

        .bnr-subtotal .bnr-amount { font-weight: 800; font-size: 15px; }

        /* Séparateur */
        .bnr-spacer td { padding: 6px; border: none; }

        /* Ajustements */
        .bnr-adj-header td {
            font-weight: 700; color: #334155; background: #f1f5f9;
            font-size: 13px; padding: 8px 16px;
            border-bottom: 1px solid #e2e8f0;
        }

        /* Ligne de clôture */
        .bnr-close td {
            font-weight: 900; font-size: 16px; padding: 16px;
            background: linear-gradient(135deg, #1e293b, #334155); color: #fff;
        }

        .bnr-close .bnr-amount { font-size: 20px; font-weight: 900; }

        /* Vérification */
        .bnr-check td {
            font-weight: 700; font-size: 12px; padding: 10px 16px;
            text-align: center; border-top: 3px double #0f172a;
        }

        .bnr-check-ok { color: #15803d; background: #f0fdf4; }
        .bnr-check-err { color: #dc2626; background: #fef2f2; }

        /* Couleurs montants */
        .amt-positive { color: #15803d; }
        .amt-negative { color: #dc2626; }
        .amt-zero { color: #94a3b8; }

        /* ═══════════════════════════════════════
           IMPRESSION
        ═══════════════════════════════════════ */
        @media print {
            .mc-app > *:not(.mc-shell),
            .mc-sidebar, .report-toolbar, .report-actions,
            .filter-period, .fab-add, .app-header, .topbar, .sidebar {
                display: none !important;
            }

            .mc-shell { display: block !important; padding: 0 !important; }

            .mc-maincol, .mc-card, .mc-mainwrap {
                background: #fff !important; border: none !important;
                box-shadow: none !important; border-radius: 0 !important;
                overflow: visible !important;
            }

            body {
                background: #fff !important; color: #000 !important;
                font-size: 11px !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .report-body { padding: 0 !important; max-width: 100%; }
            .report-header { border-bottom-color: #000 !important; }

            .bnr-open td, .bnr-close td {
                background: #1e293b !important; color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bnr-adj-header td, .bnr-subtotal td {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bnr-table td { padding: 6px 12px; }

            @page { size: letter portrait; margin: 1.5cm; }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Toolbar --%>
    <div class="report-toolbar">
        <div>
            <div class="report-title">État des bénéfices non répartis</div>
            <div class="report-sub"><asp:Label ID="lblInfo" runat="server" /></div>
        </div>
        <div class="report-actions">
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <%-- Période --%>
    <div class="filter-period">
        <label>Exercice du :</label>
        <telerik:RadDatePicker ID="dpDateDebut" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <label>au :</label>
        <telerik:RadDatePicker ID="dpDateFin" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <asp:Button ID="btnGenerate" runat="server" CssClass="btn" Text="Générer" />
    </div>

    <div class="report-body">

        <%-- En-tête --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>État des bénéfices non répartis</h1>
            <div class="report-date">
                Pour l'exercice terminé le <asp:Label ID="lblPeriodeFin" runat="server" />
            </div>
        </div>

        <%-- Contenu --%>
        <asp:Literal ID="litReport" runat="server" />

    </div>

</asp:Content>
