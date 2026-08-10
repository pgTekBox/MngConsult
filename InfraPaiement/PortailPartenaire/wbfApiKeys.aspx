<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApiKeys.aspx.vb" Inherits="PortailPartenaire.wbfApiKeys" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Clés d'API</h1>
            <p class="sub">Vos clés partenaire (<span class="mono">pk_…</span>) pour l'intégration API</p>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:18px">
        <p class="sub" style="margin:0 0 14px">
            Une clé partenaire donne accès aux endpoints <span class="mono">/api/v1/abonnes</span> (provisioning) et, avec
            l'en-tête <span class="mono">X-Abonne-Id</span>, aux opérations d'un abonné. La clé n'est affichée qu'<b>une seule fois</b>.
        </p>
        <div style="display:flex; gap:12px; align-items:flex-end; flex-wrap:wrap">
            <div class="field" style="margin:0">
                <label>Environnement</label>
                <asp:DropDownList ID="ddlEnv" runat="server"
                    style="padding:11px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font)">
                    <asp:ListItem Value="test" Text="Test" />
                    <asp:ListItem Value="live" Text="Production" />
                </asp:DropDownList>
            </div>
            <div class="field" style="margin:0; flex:1; min-width:200px">
                <label>Libellé (optionnel)</label>
                <asp:TextBox ID="tbLabel" runat="server" placeholder="Ex. Intégration Dentitek" />
            </div>
            <asp:Button ID="btnGenerate" runat="server" Text="Générer une clé" CssClass="btn btn-primary" OnClick="btnGenerate_Click" />
        </div>
    </div>

    <asp:Panel ID="pnlNewKey" runat="server" Visible="false" CssClass="msg-ok" style="word-break:break-all">
        <b>Nouvelle clé (copiez-la maintenant, elle ne sera plus affichée) :</b><br />
        <span class="mono" style="font-size:15px"><asp:Literal ID="litNewKey" runat="server" /></span>
    </asp:Panel>

    <asp:Repeater ID="rptKeys" runat="server" OnItemCommand="rptKeys_ItemCommand">
        <HeaderTemplate>
            <div class="table-wrap"><table class="grid"><thead><tr>
                <th>Préfixe</th><th>Libellé</th><th>Env.</th><th>Statut</th><th>Dernier usage</th><th></th>
            </tr></thead><tbody>
        </HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td class="mono"><%# Enc(Eval("Prefix")) %>…</td>
                <td><%# Enc(Eval("Label")) %></td>
                <td><%# Enc(Eval("Environment")) %></td>
                <td><%# IIf(CBool(Eval("IsActive")), "<span class='badge badge-actif'>Active</span>", "<span class='badge badge-neutre'>Révoquée</span>") %></td>
                <td><%# FormatDt(Eval("LastUsedUtc")) %></td>
                <td class="num">
                    <asp:LinkButton runat="server" CssClass="btn" CommandName="revoke"
                        CommandArgument='<%# Eval("Id") %>' Visible='<%# CBool(Eval("IsActive")) %>'
                        Text="Révoquer" OnClientClick="return confirm('Révoquer cette clé ? Les intégrations qui l''utilisent cesseront de fonctionner.');" />
                </td>
            </tr>
        </ItemTemplate>
        <FooterTemplate></tbody></table></div></FooterTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
        <div class="table-wrap"><div class="empty">Aucune clé pour l'instant. Générez-en une ci-dessus.</div></div>
    </asp:Panel>

</asp:Content>
