<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Default.aspx.vb" Inherits="PortailPartenaire.Default_aspx" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Tableau de bord</h1>
            <p class="sub">Vue d'ensemble de vos abonnés provisionnés</p>
        </div>
        <a href="wbfAbonne.aspx" class="btn btn-primary">+ Nouvel abonné</a>
    </div>

    <div class="cards" style="margin-bottom:24px">
        <div class="kpi"><div class="lbl">Abonnés</div><div class="val"><asp:Literal ID="litNbAbonnes" runat="server" Text="0" /></div><div class="hint">Locataires rattachés</div></div>
        <div class="kpi"><div class="lbl">Actifs</div><div class="val"><asp:Literal ID="litNbActifs" runat="server" Text="0" /></div><div class="hint">Statut « Actif »</div></div>
        <div class="kpi"><div class="lbl">KYB vérifiés</div><div class="val"><asp:Literal ID="litNbKyb" runat="server" Text="0" /></div><div class="hint">Conformité validée</div></div>
        <div class="kpi"><div class="lbl">KYB en attente</div><div class="val"><asp:Literal ID="litNbAttente" runat="server" Text="0" /></div><div class="hint">À vérifier</div></div>
        <div class="kpi"><div class="lbl">Clés API actives</div><div class="val"><asp:Literal ID="litNbCles" runat="server" Text="0" /></div><div class="hint">Intégration</div></div>
    </div>

    <div class="page-head">
        <div><h1 style="font-size:19px">Abonnés récents</h1></div>
        <a href="wbfAbonnes.aspx" class="btn btn-ghost">Voir tous →</a>
    </div>

    <asp:Repeater ID="rptRecents" runat="server">
        <HeaderTemplate>
            <div class="table-wrap"><table class="grid"><thead><tr>
                <th>Abonné</th><th>Courriel</th><th>Statut</th><th>KYB</th><th>Créé</th>
            </tr></thead><tbody>
        </HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td><a class="rowlink" href='wbfAbonne.aspx?id=<%# Eval("Id") %>'><%# Enc(Eval("RaisonSociale")) %></a></td>
                <td><%# Enc(Eval("CourrielContact")) %></td>
                <td><%# StatutBadge(Eval("Statut")) %></td>
                <td><%# KybBadge(Eval("StatutKYB")) %></td>
                <td><%# FormatDate(Eval("CreatedUtc")) %></td>
            </tr>
        </ItemTemplate>
        <FooterTemplate></tbody></table></div></FooterTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
        <div class="table-wrap"><div class="empty">
            Aucun abonné pour l'instant. <a href="wbfAbonne.aspx">Provisionnez votre premier abonné</a>.
        </div></div>
    </asp:Panel>

</asp:Content>
