<%@ Page Title="Demandes à Claude" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfClaudePrompts.aspx.vb" Inherits="prjSec60Admin.wbfClaudePrompts" %>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    #cq{--encre:#0E1F3D;--encre2:#44536E;--encre3:#6A7891;--fond:#F2F5F9;--filet:#E3E9F1;--bord:#D5DDE8;--marine:#1B4F9C;--marine-fonce:#143A73;--vert:#1E6B3A;--vert-pale:#E6F4EA;--pastille:#E8EDF5}
    #cq{color:var(--encre);font-size:15px}
    #cq *{box-sizing:border-box}
    #cq .cq-tete{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:14px}
    #cq h1{font-size:24px;font-weight:800;margin:0}
    #cq .cq-sous{color:var(--encre2);font-size:14px;margin:2px 0 0}
    #cq .cq-filtres{display:inline-flex;background:var(--pastille);border-radius:12px;padding:3px;gap:2px;margin-left:auto}
    #cq .cq-filtres a{border:0;background:transparent;border-radius:9px;padding:7px 14px;font-weight:800;color:var(--encre2);cursor:pointer;text-decoration:none;font-size:14px}
    #cq .cq-filtres a.on{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}
    #cq .cq-liste{display:flex;flex-direction:column;gap:12px}
    #cq .cq-carte{background:#fff;border:1px solid var(--filet);border-radius:16px;padding:14px 16px}
    #cq .cq-carte.fait{opacity:.72}
    #cq .cq-h{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:8px}
    #cq .cq-page{display:inline-block;background:#E3EBF7;color:var(--marine-fonce);border-radius:8px;padding:3px 10px;font-weight:800;font-size:13px}
    #cq .cq-statut{border-radius:999px;padding:3px 10px;font-size:12.5px;font-weight:800}
    #cq .cq-statut.nouveau{background:#FFF4DF;color:#9A5B00}
    #cq .cq-statut.fait{background:var(--vert-pale);color:var(--vert)}
    #cq .cq-meta{color:var(--encre3);font-size:13px;margin-left:auto}
    #cq .cq-prompt{white-space:pre-wrap;word-break:break-word;background:var(--fond);border-radius:10px;padding:10px 12px;font-size:14px;line-height:1.5;margin:0 0 10px}
    #cq .cq-pied{display:flex;align-items:center;gap:12px;flex-wrap:wrap;font-size:13px;color:var(--encre3)}
    #cq .cq-pied a{word-break:break-all;color:var(--marine-fonce);font-weight:700}
    #cq .cq-btn{border:0;border-radius:999px;padding:8px 16px;font-weight:800;font-size:13.5px;cursor:pointer;text-decoration:none;display:inline-block}
    #cq .cq-btn.ok{background:var(--marine);color:#fff}
    #cq .cq-btn.ok:hover{background:var(--marine-fonce)}
    #cq .cq-btn.sec{background:#fff;color:var(--encre);border:1px solid var(--bord)}
    #cq .cq-vide{background:#fff;border:1px dashed var(--bord);border-radius:16px;padding:30px;text-align:center;color:var(--encre2)}
    #cq .cq-act{margin-left:auto}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="cq">
    <div class="cq-tete">
        <div>
            <h1>Demandes à Claude</h1>
            <p class="cq-sous">Les demandes de modification composées depuis l'ERP (bouton flottant « Demande à Claude »).</p>
        </div>
        <div class="cq-filtres">
            <asp:HyperLink ID="lnkNouveau" runat="server" NavigateUrl="?f=nouveau" Text="Nouvelles" />
            <asp:HyperLink ID="lnkTous" runat="server" NavigateUrl="?f=tous" Text="Toutes" />
            <asp:HyperLink ID="lnkFait" runat="server" NavigateUrl="?f=fait" Text="Faites" />
        </div>
    </div>

    <asp:Repeater ID="rptDemandes" runat="server" OnItemCommand="rptDemandes_ItemCommand">
        <HeaderTemplate><div class="cq-liste"></HeaderTemplate>
        <ItemTemplate>
            <div class='cq-carte <%# If(Convert.ToString(Eval("Statut"))="fait","fait","") %>'>
                <div class="cq-h">
                    <span class="cq-page"><%# Server.HtmlEncode(Convert.ToString(Eval("Page"))) %></span>
                    <span class='cq-statut <%# Convert.ToString(Eval("Statut")) %>'><%# If(Convert.ToString(Eval("Statut"))="fait","Fait","Nouveau") %></span>
                    <span class="cq-meta">n&deg; <%# Eval("Id") %> &middot; <%# FormatDate(Eval("Created")) %></span>
                </div>
                <p class="cq-prompt"><%# Server.HtmlEncode(Convert.ToString(Eval("Prompt"))) %></p>
                <div class="cq-pied">
                    <span><%# Server.HtmlEncode(Qui(Eval("UserEmail"), Eval("DossierNom"))) %></span>
                    <%# LienUrl(Eval("Url")) %>
                    <%# InfoFait(Eval("Statut"), Eval("DoneBy"), Eval("DoneUtc")) %>
                    <span class="cq-act">
                        <asp:LinkButton runat="server" CssClass="cq-btn ok" CommandName="Done" CommandArgument='<%# Eval("Id") %>'
                            Text="Marquer comme fait" Visible='<%# Convert.ToString(Eval("Statut"))="nouveau" %>' />
                        <asp:LinkButton runat="server" CssClass="cq-btn sec" CommandName="Reopen" CommandArgument='<%# Eval("Id") %>'
                            Text="Rouvrir" Visible='<%# Convert.ToString(Eval("Statut"))="fait" %>' />
                    </span>
                </div>
            </div>
        </ItemTemplate>
        <FooterTemplate></div></FooterTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlVide" runat="server" Visible="false" CssClass="cq-vide">
        Aucune demande pour ce filtre.
    </asp:Panel>
</div>
</asp:Content>
