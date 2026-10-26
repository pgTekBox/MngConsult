<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfLieuEdit.aspx.vb" Inherits="MngConsul.wbfLieuEdit" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("pageTitle") %></title>
    <%-- Signature « Portail du client » (voir css/edition-60s.css) --%>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" />
    <link rel="stylesheet" href="css/edition-60s.css?v=2026102104" />
    <style>
        /* La fiche d'un lieu, dans la fenêtre ouverte par Produits et services › Lieux */
        .le { min-height: 100vh; display: flex; flex-direction: column; }
        .le-tete { display: flex; align-items: center; gap: 12px; padding: 16px 20px; background: #FFFFFF; border-bottom: 1px solid var(--f-line); }
        .le-tete .t { flex: 1; min-width: 0; }
        .le-tete h1 { margin: 0; font-size: 22px; font-weight: 800; color: var(--f-ink); }
        .le-corps { flex: 1; padding: 18px 20px; }
        .le-boite { background: #FFFFFF; border-radius: 20px; padding: 18px; display: grid; gap: 14px; }
        .le-deux { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 14px; }
        body.f60 .field select {
            width: 100%; min-height: 44px; padding: 0 14px; border: 1px solid var(--f-field); border-radius: 12px;
            background: #FFFFFF; font: inherit; font-size: 15px; font-weight: 700; color: var(--f-ink); box-sizing: border-box;
        }
        .le-actif { display: flex !important; align-items: center; gap: 8px; margin: 0 !important; font-weight: 700 !important; }
        .le-actif input { width: 18px; height: 18px; accent-color: var(--f-blue); margin: 0; }
        .le-msg { margin: 0 0 14px; padding: 12px 16px; border-radius: 16px; font-weight: 700; background: #FDECEA; color: #8A1F14; }
        .le-pied { display: flex; justify-content: flex-end; gap: 8px; padding: 14px 20px; background: #FFFFFF; border-top: 1px solid var(--f-line); }
        .le-btn { min-height: 44px; padding: 0 18px; border: 1px solid var(--f-field); border-radius: 999px; background: #FFFFFF; color: var(--f-ink); font: 800 14px Nunito, "Segoe UI", sans-serif; cursor: pointer; }
        .le-btn:hover { background: var(--f-bg); }
        .le-btn.primaire { border-color: var(--f-blue); background: var(--f-blue); color: #FFFFFF; }
        .le-btn.primaire:hover { background: var(--f-blue-d); }
        @media (max-width: 600px) { .le-deux { grid-template-columns: 1fr; } }
    </style>
</head>
<body class="f60">
    <form id="form1" runat="server">
        <asp:ScriptManager ID="sm1" runat="server" />
        <asp:HiddenField ID="hfId" runat="server" Value="0" />

        <div class="le">
            <div class="le-tete">
                <div class="t">
                    <div class="f60-rub"><%= L("rubrique") %></div>
                    <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                </div>
            </div>

            <asp:Panel ID="pnlCorps" runat="server" CssClass="le-corps" DefaultButton="btnSave">
                <asp:Panel ID="pnlMsg" runat="server" Visible="false" CssClass="le-msg">
                    <asp:Literal ID="litMsg" runat="server" />
                </asp:Panel>

                <div class="le-boite">
                    <div class="field">
                        <label for="<%= txtNom.ClientID %>"><%= L("nom") %> *</label>
                        <asp:TextBox ID="txtNom" runat="server" MaxLength="150" />
                    </div>
                    <div class="le-deux">
                        <div class="field">
                            <label for="<%= ddlType.ClientID %>"><%= L("type") %></label>
                            <asp:DropDownList ID="ddlType" runat="server" />
                        </div>
                        <div class="field">
                            <label for="<%= txtAdresse.ClientID %>"><%= L("adresse") %></label>
                            <asp:TextBox ID="txtAdresse" runat="server" MaxLength="300" />
                        </div>
                    </div>
                    <label class="le-actif">
                        <asp:CheckBox ID="chkActif" runat="server" Checked="true" />
                        <%= L("actifLong") %>
                    </label>
                </div>
            </asp:Panel>

            <div class="le-pied">
                <button type="button" class="le-btn" onclick="closeWin();"><%= L("fermer") %></button>
                <asp:Button ID="btnSave" runat="server" CssClass="le-btn primaire" />
            </div>
        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }
            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
            }
        </script>
    </form>
</body>
</html>
