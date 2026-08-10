<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAudit.aspx.vb" Inherits="PortailMaster.wbfAudit" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .toolbar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }
        .toolbar input[type=text], .toolbar select { padding:10px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font); }
        .toolbar input[type=text] { min-width:240px; }
        .mono { font-family:Consolas,monospace; }
        .badge-audit { background:rgba(2,132,199,.12); color:#0284c7; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Journal d'audit</h1>
            <p class="sub">Traçabilité des actions sensibles sur les comptes abonnés (append-only, immuable).</p>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="toolbar">
        <asp:DropDownList ID="ddlAction" runat="server">
            <asp:ListItem Value="">Toutes les actions</asp:ListItem>
            <asp:ListItem Value="Login">Connexion</asp:ListItem>
            <asp:ListItem Value="LoginFailed">Connexion échouée</asp:ListItem>
            <asp:ListItem Value="Logout">Déconnexion</asp:ListItem>
            <asp:ListItem Value="Export">Export</asp:ListItem>
            <asp:ListItem Value="Offboard">Clôture</asp:ListItem>
            <asp:ListItem Value="Reactivate">Réactivation</asp:ListItem>
            <asp:ListItem Value="Anonymize">Anonymisation</asp:ListItem>
            <asp:ListItem Value="KybStatusChange">Statut KYB modifié</asp:ListItem>
            <asp:ListItem Value="ApiKeyCreate">Clé d'API — création</asp:ListItem>
            <asp:ListItem Value="ApiKeyRevoke">Clé d'API — révocation</asp:ListItem>
            <asp:ListItem Value="AuditExport">Export du journal</asp:ListItem>
        </asp:DropDownList>
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (acteur, cible, détails)…" />
        <asp:Button ID="btnFilter" runat="server" CssClass="btn" Text="Filtrer" OnClick="btnFilter_Click" />
        <span style="flex:1"></span>
        <asp:HyperLink ID="lnkExportCsv" runat="server" CssClass="btn" Text="Exporter (CSV)"
            ToolTip="Télécharger le journal d'audit filtré au format CSV (pour un auditeur)." />
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Quand (UTC)</th><th>Action</th><th>Cible</th><th>Acteur</th><th>IP</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="muted mono"><%# FormatDt(Eval("Utc")) %></td>
                    <td><span class='badge <%# ActionBadge(Eval("Action")) %>'><%# Enc(Eval("Action")) %></span></td>
                    <td><%# CibleHtml(Container.DataItem) %></td>
                    <td class="muted"><%# Enc(Eval("ActorEmail")) %></td>
                    <td class="muted mono"><%# Enc(Eval("IpAddress")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucune entrée d'audit.</asp:Panel>
    </div>
</asp:Content>
