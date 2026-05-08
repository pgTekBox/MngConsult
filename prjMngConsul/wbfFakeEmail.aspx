<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfFakeEmail.aspx.vb" Inherits="MngConsul.wbfFakeEmail" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>📧 Simulation d'envoi — MngConsul</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc;  --slate-100: #f1f5f9;
            --slate-200: #e2e8f0; --slate-300: #cbd5e1;
            --slate-500: #64748b; --slate-600: #475569;
            --slate-700: #334155; --slate-800: #1e293b;
            --blue-500: #3b82f6;  --blue-600: #2563eb;
            --cyan-500: #06b6d4;
            --orange-500: #f59e0b;
            --orange-100: #fef3c7;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: var(--slate-100);
            padding: 16px;
        }

        .dev-banner {
            background: var(--orange-100);
            border: 1px solid var(--orange-500);
            border-radius: 12px;
            padding: 12px 16px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 13px;
            color: #78350f;
        }
        .dev-banner strong { font-weight: 800; }

        .mail-frame {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 4px 16px rgba(15,23,42,.08);
            border: 1px solid var(--slate-200);
            overflow: hidden;
            max-width: 760px;
            margin: 0 auto;
        }

        .mail-header {
            padding: 14px 18px;
            border-bottom: 1px solid var(--slate-200);
            background: var(--slate-50);
        }

        .mail-row {
            display: flex;
            gap: 8px;
            font-size: 13px;
            margin-bottom: 4px;
            color: var(--slate-700);
        }
        .mail-row:last-child { margin-bottom: 0; }
        .mail-row .lbl {
            color: var(--slate-500);
            font-weight: 700;
            min-width: 64px;
            flex-shrink: 0;
        }
        .mail-row .val {
            color: var(--slate-800);
            font-weight: 600;
            word-break: break-all;
        }
        .mail-row.subject .val { font-weight: 800; }

        .mail-body {
            background: var(--slate-50);
            padding: 18px;
        }

        .mail-body iframe {
            width: 100%;
            min-height: 520px;
            border: none;
            border-radius: 10px;
            background: #fff;
            box-shadow: 0 2px 8px rgba(15,23,42,.05);
        }

        .actions {
            padding: 14px 18px;
            border-top: 1px solid var(--slate-200);
            background: var(--slate-50);
            display: flex;
            justify-content: flex-end;
            gap: 8px;
        }
        .btn {
            padding: 10px 18px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 700;
            font-family: var(--font);
            border: none;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-secondary {
            background: var(--slate-200);
            color: var(--slate-700);
        }
        .btn-secondary:hover { background: var(--slate-300); }

        .btn-primary {
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: #fff;
        }
        .btn-primary:hover {
            box-shadow: 0 8px 16px rgba(37,99,235,.3);
        }

        .empty {
            text-align: center;
            padding: 60px 20px;
            color: var(--slate-500);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="dev-banner">
            <span style="font-size: 18px;">🧪</span>
            <div>
                <strong>Mode développement —</strong>
                Simulation d'envoi de courriel.
                En production, ce courriel serait envoyé à l'adresse du destinataire.
            </div>
        </div>

        <asp:Panel ID="pnlMail" runat="server" CssClass="mail-frame">

            <div class="mail-header">
                <div class="mail-row">
                    <span class="lbl">De&nbsp;:</span>
                    <span class="val">
                        <asp:Literal ID="litFrom" runat="server" />
                    </span>
                </div>
                <div class="mail-row">
                    <span class="lbl">À&nbsp;:</span>
                    <span class="val">
                        <asp:Literal ID="litTo" runat="server" />
                    </span>
                </div>
                <div class="mail-row subject">
                    <span class="lbl">Objet&nbsp;:</span>
                    <span class="val">
                        <asp:Literal ID="litSubject" runat="server" />
                    </span>
                </div>
            </div>

            <div class="mail-body">
                <iframe id="mailFrame" srcdoc=""></iframe>
            </div>

        <%--    <div class="actions">
                <a href="javascript:void(0)" onclick="window.close();" class="btn btn-secondary">
                    Fermer cette fenêtre
                </a>
                <asp:HyperLink ID="lnkOpenLink" runat="server"
                    Target="_blank" CssClass="btn btn-primary">
                    🔗 Ouvrir le lien d'activation
                </asp:HyperLink>
            </div>--%>

        </asp:Panel>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="mail-frame">
            <div class="empty">
                <p>📭 Aucun courriel à afficher.</p>
            </div>
        </asp:Panel>

        <asp:HiddenField ID="hfBody" runat="server" ClientIDMode="Static" />

        <script type="text/javascript">
            // Charger le HTML du courriel dans l'iframe (via srcdoc)
            (function () {
                var hf = document.getElementById('hfBody');
                var frame = document.getElementById('mailFrame');
                if (!hf || !frame) return;
                var html = hf.value || '';
                if (html.length > 0) {
                    frame.srcdoc = html;
                }
            })();
        </script>

    </form>
</body>
</html>
