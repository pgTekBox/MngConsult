<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApiKeys.aspx.vb" Inherits="PortailABN.wbfApiKeys" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .newkey { padding:14px 16px; background:rgba(5,150,105,.08); border:1px solid rgba(5,150,105,.30); border-radius:12px; margin-bottom:18px; }
        .newkey code { display:block; font-family:Consolas,monospace; font-size:15px; font-weight:700; margin-top:8px; word-break:break-all; }
        .newkey .warn { font-size:12px; color:#b45309; margin-top:8px; }
        .toolbar { display:flex; gap:10px; align-items:flex-end; margin-bottom:18px; flex-wrap:wrap; }
        .toolbar .field { margin:0; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Clés d'API</h1>
            <p class="sub">Authentifiez vos appels à l'API 60secPaiement (en-tête <span class="mono">X-Api-Key</span>).</p>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <asp:Panel ID="pnlNewKey" runat="server" Visible="false" CssClass="newkey">
        <strong>Votre nouvelle clé — copiez-la maintenant :</strong>
        <code><asp:Literal ID="litNewKey" runat="server" /></code>
        <div class="warn">⚠ Elle ne sera plus jamais affichée. Seul son empreinte (hash) est conservée.</div>
    </asp:Panel>

    <div class="card" style="margin-bottom:22px">
        <div class="toolbar">
            <div class="field"><label>Étiquette (optionnel)</label><asp:TextBox ID="tbLabel" runat="server" placeholder="ex. Production ERP" /></div>
            <div class="field"><label>Environnement</label>
                <asp:DropDownList ID="ddlEnv" runat="server">
                    <asp:ListItem Value="test">Test</asp:ListItem>
                    <asp:ListItem Value="live">Production</asp:ListItem>
                </asp:DropDownList>
            </div>
            <asp:Button ID="btnGenerate" runat="server" CssClass="btn btn-primary" Text="Générer une clé" OnClick="btnGenerate_Click" />
        </div>
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rptKeys" runat="server" OnItemCommand="rptKeys_ItemCommand">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Préfixe</th><th>Étiquette</th><th>Env.</th><th>Statut</th><th>Créée</th><th>Dern. usage</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Enc(Eval("Prefix")) %>…</td>
                    <td><%# Enc(Eval("Label")) %></td>
                    <td class="mono"><%# Enc(Eval("Environment")) %></td>
                    <td>
                        <span class='badge <%# If(CBool(Eval("IsActive")),"badge-actif","badge-neutre") %>'>
                            <%# If(CBool(Eval("IsActive")),"Active","Révoquée") %></span>
                    </td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                    <td class="muted"><%# FormatDt(Eval("LastUsedUtc")) %></td>
                    <td>
                        <asp:LinkButton runat="server" Text="Révoquer" CommandName="revoke" CommandArgument='<%# Eval("Id") %>'
                            Visible='<%# CBool(Eval("IsActive")) %>' style="color:var(--danger)"
                            OnClientClick="return confirm('Révoquer cette clé ? Les appels qui l''utilisent cesseront de fonctionner.');" />
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucune clé. Générez-en une ci-dessus.</asp:Panel>
    </div>
</asp:Content>
