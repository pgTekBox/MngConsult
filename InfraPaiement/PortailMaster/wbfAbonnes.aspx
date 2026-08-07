<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAbonnes.aspx.vb" Inherits="PortailMaster.wbfAbonnes" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .filters { display: flex; gap: 10px; align-items: center; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input[type="text"], .filters select {
            padding: 10px 13px; border: 1px solid var(--line); border-radius: 11px;
            font-size: 14px; font-family: var(--font); outline: none; background: #fff;
        }
        .filters input[type="text"] { min-width: 260px; }
        .filters input:focus, .filters select:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(14,165,164,.13); }
        .count { color: var(--muted); font-size: 13px; margin-left: auto; }
        .muted { color: var(--muted); }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Abonnés</h1>
            <p class="sub">Entreprises abonnées à la plateforme 60secPaiement.</p>
        </div>
        <a class="btn btn-primary" href="wbfAbonne.aspx">+ Nouvel abonné</a>
    </div>

    <div class="filters">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel, NEQ)…" />
        <asp:DropDownList ID="ddlStatut" runat="server">
            <asp:ListItem Value="">Tous les statuts</asp:ListItem>
            <asp:ListItem Value="Prospect">Prospect</asp:ListItem>
            <asp:ListItem Value="Actif">Actif</asp:ListItem>
            <asp:ListItem Value="Suspendu">Suspendu</asp:ListItem>
            <asp:ListItem Value="Ferme">Fermé</asp:ListItem>
        </asp:DropDownList>
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Filtrer" OnClick="btnSearch_Click" />
        <span class="count"><asp:Literal ID="litCount" runat="server" /></span>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <div class="table-wrap">
        <asp:Repeater ID="rptAbonnes" runat="server">
            <HeaderTemplate>
                <table class="grid">
                    <thead>
                        <tr>
                            <th>Raison sociale</th>
                            <th>Contact</th>
                            <th>Ville</th>
                            <th>Devise</th>
                            <th>Statut</th>
                            <th>KYB</th>
                            <th>Créé</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td>
                        <a class="rowlink" href='wbfAbonne.aspx?id=<%# Eval("Id") %>'><%# Server.HtmlEncode(If(Eval("RaisonSociale"), "").ToString()) %></a>
                        <%# DisplaySecondary(Eval("NomAffichage")) %>
                    </td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("CourrielContact"), "").ToString()) %></td>
                    <td class="muted"><%# Server.HtmlEncode(VilleProvince(Eval("Ville"), Eval("Province"))) %></td>
                    <td><%# Server.HtmlEncode(If(Eval("Devise"), "").ToString()) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Statut")) %>'><%# Server.HtmlEncode(LabelStatut(Eval("Statut"))) %></span></td>
                    <td><span class='badge <%# BadgeKyb(Eval("StatutKYB")) %>'><%# Server.HtmlEncode(LabelKyb(Eval("StatutKYB"))) %></span></td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                    <td style="white-space:nowrap">
                        <a href='wbfClients.aspx?abonneId=<%# Eval("Id") %>'>Clients</a> ·
                        <a href='wbfGrandLivre.aspx?abonneId=<%# Eval("Id") %>'>Grand livre</a> ·
                        <a href='wbfPaiements.aspx?abonneId=<%# Eval("Id") %>'>Paiements</a>
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate>
                    </tbody>
                </table>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
            Aucun abonné ne correspond. <a href="wbfAbonne.aspx">Créer le premier abonné</a>.
        </asp:Panel>
    </div>

</asp:Content>
