<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApiKeys.aspx.vb" Inherits="PortailMaster.wbfApiKeys" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .keybox { background:#0f172a; color:#e2e8f0; border-radius:12px; padding:14px 16px; font-family:Consolas,monospace;
                  font-size:14px; word-break:break-all; display:flex; align-items:center; justify-content:space-between; gap:12px; }
        .mono { font-family:Consolas,monospace; }
        .badge-test { background: rgba(217,119,6,.14); color:#b45309; }
        .badge-live { background: rgba(5,150,105,.12); color: var(--ok); }
        .badge-off { background: rgba(100,116,139,.16); color:#475569; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="crumbs">
                <a href="wbfAbonnes.aspx">Abonnés</a> ›
                <a id="lnkAbonne" runat="server">Abonné</a> › Clés API
            </div>
            <h1>Clés d'API</h1>
            <p class="sub">Clés utilisées par l'application de <asp:Literal ID="litAbonne" runat="server" /> pour appeler l'API 60secPaiement.</p>
        </div>
    </div>

    <asp:Panel ID="pnlNewKey" runat="server" Visible="false" CssClass="msg-ok">
        <div style="margin-bottom:10px"><b>Clé générée — copiez-la maintenant, elle ne sera plus jamais affichée.</b></div>
        <div class="keybox"><span class="mono"><asp:Literal ID="litNewKey" runat="server" /></span></div>
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:22px">
        <h3 style="margin:0 0 14px 0;font-size:16px">Générer une clé</h3>
        <div class="form-grid">
            <div class="field">
                <label>Libellé</label>
                <asp:TextBox ID="tbLabel" runat="server" placeholder="ex. Production, Intégration…" />
            </div>
            <div class="field">
                <label>Environnement</label>
                <asp:DropDownList ID="ddlEnv" runat="server">
                    <asp:ListItem Value="test">Test</asp:ListItem>
                    <asp:ListItem Value="live">Production</asp:ListItem>
                </asp:DropDownList>
            </div>
        </div>
        <div class="form-actions">
            <asp:Button ID="btnGenerate" runat="server" CssClass="btn btn-primary" Text="Générer la clé" OnClick="btnGenerate_Click" />
        </div>
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rptKeys" runat="server" OnItemCommand="rptKeys_ItemCommand">
            <HeaderTemplate>
                <table class="grid">
                    <thead><tr>
                        <th>Préfixe</th><th>Libellé</th><th>Env.</th><th>Statut</th>
                        <th>Créée</th><th>Dernière utilisation</th><th></th>
                    </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Server.HtmlEncode(If(Eval("Prefix"),"").ToString()) %>…</td>
                    <td><%# Server.HtmlEncode(If(Eval("Label"),"").ToString()) %></td>
                    <td><span class='badge <%# If(Eval("Environment").ToString()="live","badge-live","badge-test") %>'><%# Eval("Environment") %></span></td>
                    <td><span class='badge <%# If(CBool(Eval("IsActive")),"badge-actif","badge-off") %>'><%# If(CBool(Eval("IsActive")),"Active","Révoquée") %></span></td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                    <td class="muted"><%# FormatDateTime2(Eval("LastUsedUtc")) %></td>
                    <td>
                        <asp:LinkButton runat="server" Text="Révoquer" CommandName="revoke" CommandArgument='<%# Eval("Id") %>'
                            Visible='<%# CBool(Eval("IsActive")) %>' style="color:var(--danger);font-weight:700"
                            OnClientClick="return confirm('Révoquer définitivement cette clé ?');" />
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucune clé. Générez-en une ci-dessus.</asp:Panel>
    </div>

</asp:Content>
