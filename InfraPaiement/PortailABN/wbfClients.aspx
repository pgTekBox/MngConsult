<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfClients.aspx.vb" Inherits="PortailABN.wbfClients" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .toolbar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }
        .toolbar input[type=text] { padding:10px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font); min-width:260px; }
        table.grid a.rowlink { font-weight:700; text-decoration:none; color:var(--text); }
        table.grid a.rowlink:hover { color:var(--primary); }
        .eft-yes { color:var(--ok); font-weight:800; }
        .eft-no { color:var(--muted); }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Clients</h1>
            <p class="sub">Les payeurs de votre organisation (contreparties d'encaissement EFT).</p>
        </div>
        <div><a href="wbfClient.aspx" class="btn btn-primary">+ Ajouter un client</a></div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="toolbar">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel, référence)…" />
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" OnClick="btnSearch_Click" />
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Nom</th><th>Type</th><th>Référence</th><th>Ville</th><th>Prêt EFT</th><th>Statut</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td><a class="rowlink" href='wbfClient.aspx?id=<%# Eval("Id") %>'><%# Enc(Eval("Nom")) %></a></td>
                    <td class="muted"><%# Enc(Eval("TypeClient")) %></td>
                    <td class="mono muted"><%# Enc(Eval("ReferenceExterne")) %></td>
                    <td class="muted"><%# Enc(Eval("Ville")) %></td>
                    <td><%# EftReady(Eval("HasBankCoords")) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Statut")) %>'><%# Enc(Eval("Statut")) %></span></td>
                    <td><a href='wbfClient.aspx?id=<%# Eval("Id") %>'>Modifier</a></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun client. Cliquez « + Ajouter un client ».</asp:Panel>
    </div>
</asp:Content>
