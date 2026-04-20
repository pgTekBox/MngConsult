<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfEtatResultats.aspx.vb" Inherits="MngConsul.wbfEtatResultats" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    État des résultats — MngConsul
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

        .filter-period .RadPicker,
        .filter-period .RadPicker_Metro {
            display: inline-block;
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
        .er-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        .er-table td {
            padding: 7px 14px;
            vertical-align: top;
        }

        /* Ligne de section (Revenus, CDV, etc.) */
        .er-section {
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff;
            font-weight: 800;
            font-size: 14px;
        }

        .er-section td {
            padding: 10px 14px;
        }

        /* Ligne de sous-classe */
        .er-sub-header td {
            font-weight: 700;
            color: #334155;
            background: #f1f5f9;
            font-size: 13px;
            padding: 6px 14px 6px 28px;
            border-bottom: 1px solid #e2e8f0;
        }

        /* Ligne de compte normal */
        .er-line td {
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
        }

        .er-line:hover td { background: #f8fafc; }

        .er-line .account-name { padding-left: 44px; }

        .er-line .account-num {
            font-family: 'Consolas', 'Courier New', monospace;
            color: #64748b;
            font-size: 12px;
            width: 70px;
            padding-left: 44px;
        }

        .er-amount {
            text-align: right;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 600;
            width: 140px;
            white-space: nowrap;
        }

        /* Sous-total de sous-classe */
        .er-sub-total td {
            font-weight: 700;
            font-size: 13px;
            padding: 6px 14px 6px 28px;
            border-top: 1px solid #cbd5e1;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
        }

        .er-sub-total .er-amount {
            font-weight: 800;
        }

        /* Total de section */
        .er-total td {
            font-weight: 800;
            font-size: 14px;
            padding: 10px 14px;
            border-top: 2px solid #334155;
            border-bottom: 2px solid #334155;
            background: #f8fafc;
            color: #0f172a;
        }

        .er-total .er-amount {
            font-weight: 900;
            font-size: 15px;
        }

        /* Ligne de calcul intermédiaire (bénéfice brut, BAII, etc.) */
        .er-calc td {
            font-weight: 800;
            font-size: 14px;
            padding: 12px 14px;
            background: linear-gradient(135deg, rgba(37,99,235,.06), rgba(6,182,212,.04));
            border-top: 1px solid rgba(37,99,235,.15);
            border-bottom: 1px solid rgba(37,99,235,.15);
            color: #1e40af;
        }

        .er-calc .er-amount {
            font-weight: 900;
            font-size: 15px;
            color: #1e40af;
        }

        /* Ligne de résultat net */
        .er-net td {
            font-weight: 900;
            font-size: 16px;
            padding: 14px;
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff;
        }

        .er-net .er-amount {
            font-size: 18px;
            font-weight: 900;
        }

        /* Positif / Négatif */
        .amt-positive { color: #15803d; }
        .amt-negative { color: #dc2626; }
        .amt-zero { color: #94a3b8; }

        /* Ligne vide (espaceur) */
        .er-spacer td {
            padding: 6px;
            border: none;
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

            .mc-shell {
                display: block !important;
                padding: 0 !important;
            }

            .mc-maincol,
            .mc-card,
            .mc-mainwrap {
                background: #fff !important;
                border: none !important;
                box-shadow: none !important;
                border-radius: 0 !important;
                overflow: visible !important;
            }

            body {
                background: #fff !important;
                color: #000 !important;
                font-size: 11px !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .report-body { padding: 0 !important; }
            .report-header { border-bottom-color: #000 !important; }

            .er-section {
                background: #1e293b !important;
                color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .er-net {
                background: #1e293b !important;
                color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .er-sub-header td {
                background: #f1f5f9 !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .er-calc td {
                background: #eff6ff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .er-table td { padding: 4px 10px; }

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
            <div class="report-title">État des résultats</div>
            <div class="report-sub"><asp:Label ID="lblInfo" runat="server" /></div>
        </div>
        <div class="report-actions">
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <%-- Filtres de période --%>
    <div class="filter-period">
        <label>Du :</label>
        <telerik:RadDatePicker ID="dpDateDebut" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <label>Au :</label>
        <telerik:RadDatePicker ID="dpDateFin" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <asp:Button ID="btnGenerate" runat="server" CssClass="btn" Text="Générer" />
    </div>

    <div class="report-body">

        <%-- En-tête du rapport --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>État des résultats</h1>
            <div class="report-date">
                Période du <asp:Label ID="lblPeriodeDebut" runat="server" /> au <asp:Label ID="lblPeriodeFin" runat="server" />
            </div>
        </div>

        <%-- Contenu généré dynamiquement --%>
        <asp:Literal ID="litReport" runat="server" />

    </div>

</asp:Content>
