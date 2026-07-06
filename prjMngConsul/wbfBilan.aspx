<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfBilan.aspx.vb" Inherits="MngConsul.wbfBilan" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Bilan — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* ═══════════════════════════════════════
           TOOLBAR
        ═══════════════════════════════════════ */
        .report-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .report-title { font-weight: 900; font-size: 18px; }
        .report-sub { color: var(--mc-muted); font-size: 13px; margin-top: 4px; }

        .report-actions {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }

        .filter-period {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
            padding: 10px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            font-size: 13px;
        }

        .filter-period label {
            font-weight: 700;
            color: var(--mc-muted);
            font-size: 12px;
        }

        .filter-period .riTextBox {
            padding: 8px 10px !important;
            border-radius: 10px !important;
            border: 1px solid var(--mc-stroke) !important;
            font-size: 13px;
            width: 130px !important;
        }

        /* ═══════════════════════════════════════
           RAPPORT
        ═══════════════════════════════════════ */
        .report-body { padding: 20px; }

        .report-header {
            text-align: center;
            margin-bottom: 28px;
            padding-bottom: 16px;
            border-bottom: 2px solid #0f172a;
        }

        .report-header h1 {
            font-size: 22px; font-weight: 900; margin: 0 0 4px;
            letter-spacing: -.02em;
        }

        .report-header .company-name {
            font-size: 16px; font-weight: 700; color: #334155; margin-bottom: 2px;
        }

        .report-header .report-date {
            font-size: 12px; color: #64748b;
        }

        /* ── Tableau principal ── */
        .bi-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        .bi-table td { padding: 7px 14px; vertical-align: top; }

        /* Section principale (Actif, Passif, Capitaux propres) */
        .bi-section {
            font-weight: 800;
            font-size: 15px;
        }

        .bi-section td {
            padding: 14px 14px 6px;
            border-bottom: 2px solid #0f172a;
            color: #0f172a;
        }

        /* Classe (Actif CT, Actif LT, etc.) */
        .bi-classe {
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff;
            font-weight: 800;
            font-size: 14px;
        }

        .bi-classe td { padding: 10px 14px; }

        .bi-classe .plage {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            opacity: .7;
        }

        /* Sous-classe */
        .bi-sub-header td {
            font-weight: 700;
            color: #334155;
            background: #f1f5f9;
            font-size: 13px;
            padding: 6px 14px 6px 28px;
            border-bottom: 1px solid #e2e8f0;
        }

        /* Ligne de compte */
        .bi-line td {
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
        }

        .bi-line:hover td { background: #f8fafc; }

        .bi-line .account-name { padding-left: 44px; }

        .bi-line .account-num {
            font-family: 'Consolas', 'Courier New', monospace;
            color: #64748b;
            font-size: 12px;
            width: 70px;
            padding-left: 44px;
        }

        .bi-amount {
            text-align: right;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 600;
            width: 140px;
            white-space: nowrap;
        }

        /* Sous-total de sous-classe */
        .bi-sub-total td {
            font-weight: 700;
            font-size: 13px;
            padding: 6px 14px 6px 28px;
            border-top: 1px solid #cbd5e1;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
        }

        .bi-sub-total .bi-amount { font-weight: 800; }

        /* Total de classe */
        .bi-total td {
            font-weight: 800;
            font-size: 14px;
            padding: 10px 14px;
            border-top: 2px solid #334155;
            border-bottom: 2px solid #334155;
            background: #f8fafc;
            color: #0f172a;
        }

        .bi-total .bi-amount { font-weight: 900; font-size: 15px; }

        /* Grand total (Total Actif, Total Passif + CP) */
        .bi-grand-total td {
            font-weight: 900;
            font-size: 16px;
            padding: 14px;
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff;
        }

        .bi-grand-total .bi-amount { font-size: 18px; font-weight: 900; }

        /* Ligne d'équilibre (vérification) */
        .bi-check td {
            font-weight: 800;
            font-size: 13px;
            padding: 10px 14px;
            text-align: center;
            border-top: 3px double #0f172a;
        }

        .bi-check-ok { color: #15803d; background: #f0fdf4; }
        .bi-check-err { color: #dc2626; background: #fef2f2; }

        /* Positif / Négatif */
        .amt-positive { color: #15803d; }
        .amt-negative { color: #dc2626; }
        .amt-zero { color: #94a3b8; }

        /* Espaceur */
        .bi-spacer td { padding: 8px; border: none; }

        /* Séparateur entre Actif et Passif */
        .bi-divider td {
            padding: 16px 0;
            border: none;
        }

        .bi-divider hr {
            border: none;
            border-top: 3px double #cbd5e1;
            margin: 0;
        }

        /* ═══════════════════════════════════════
           IMPRESSION
        ═══════════════════════════════════════ */
        @media print {

            .mc-app > *:not(.mc-shell),
            .mc-sidebar,
            .report-toolbar,
            .report-actions,
            .filter-period,
            .fab-add,
            .app-header,
            .topbar,
            .sidebar {
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

            .report-body { padding: 0 !important; }
            .report-header { border-bottom-color: #000 !important; }

            .bi-classe {
                background: #1e293b !important; color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bi-grand-total td {
                background: #1e293b !important; color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bi-sub-header td {
                background: #f1f5f9 !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bi-table td { padding: 4px 10px; }

            @page {
                size: letter portrait;
                margin: 1.5cm;
            }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Toolbar --%>
    <div class="report-toolbar">
        <div>
            <div class="report-title">Bilan</div>
            <div class="report-sub"><asp:Label ID="lblInfo" runat="server" /></div>
        </div>
        <div class="report-actions">
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <%-- Date du bilan --%>
    <div class="filter-period">
        <label>En date du :</label>
        <telerik:RadDatePicker ID="dpDateBilan" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <asp:Button ID="btnGenerate" runat="server" CssClass="btn" Text="Générer" />
    </div>

    <div class="report-body">

        <%-- En-tête --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>Bilan</h1>
            <div class="report-date">
                Au <asp:Label ID="lblDateBilan" runat="server" />
            </div>
        </div>

        <%-- Contenu --%>
        <asp:Literal ID="litReport" runat="server" />

    </div>

</asp:Content>
