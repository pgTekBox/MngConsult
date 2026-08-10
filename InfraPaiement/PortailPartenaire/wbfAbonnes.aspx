<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAbonnes.aspx.vb" Inherits="PortailPartenaire.wbfAbonnes" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Abonnés</h1>
            <p class="sub">Les locataires que vous avez provisionnés</p>
        </div>
        <a href="wbfAbonne.aspx" class="btn btn-primary">+ Nouvel abonné</a>
    </div>

    <div style="display:flex; gap:10px; margin-bottom:18px; max-width:520px">
        <asp:TextBox ID="tbSearch" runat="server" CssClass="" placeholder="Rechercher par nom ou courriel…"
            style="flex:1; padding:11px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font)" />
        <asp:Button ID="btnSearch" runat="server" Text="Rechercher" CssClass="btn" OnClick="btnSearch_Click" />
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <asp:Repeater ID="rptList" runat="server">
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
            Aucun abonné trouvé. <a href="wbfAbonne.aspx">Provisionnez un abonné</a>.
        </div></div>
    </asp:Panel>

    <asp:Panel ID="pnlPager" runat="server" Visible="false"
        style="display:flex; align-items:center; gap:12px; margin-top:16px; justify-content:flex-end">
        <asp:LinkButton ID="btnPrev" runat="server" CssClass="btn" Text="← Précédent" OnClick="btnPrev_Click" CausesValidation="false" />
        <span class="sub"><asp:Literal ID="litRange" runat="server" /></span>
        <asp:LinkButton ID="btnNext" runat="server" CssClass="btn" Text="Suivant →" OnClick="btnNext_Click" CausesValidation="false" />
    </asp:Panel>

</asp:Content>
