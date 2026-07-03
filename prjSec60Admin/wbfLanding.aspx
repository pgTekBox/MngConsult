<%@ Page Title="Contenu LandingPage" Language="vb" AutoEventWireup="false" ValidateRequest="false"
    MasterPageFile="~/Site.Master" MaintainScrollPositionOnPostback="true"
    CodeBehind="wbfLanding.aspx.vb" Inherits="prjSec60Admin.wbfLanding" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Contenu LandingPage</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .lp-wrap { max-width: 1100px; margin: 16px auto; padding: 0 16px 24px; }
        .lp-wrap h2 { font-size: 20px; font-weight: 800; margin: 8px 0 4px; }
        .lp-wrap .sub { color: #64748b; font-size: 13px; margin-bottom: 14px; }
        .lp-bar { display: flex; gap: 14px; align-items: flex-end; flex-wrap: wrap; margin-bottom: 12px; }
        .lp-bar label { display: block; font-size: 12px; font-weight: 700; color: #334155; }
        .lp-bar select { display: block; margin-top: 4px; padding: 8px 10px; border: 1px solid #cbd5e1; border-radius: 8px; min-width: 180px; font: inherit; }
        .lp-bar .btn { padding: 9px 18px; border: 0; border-radius: 8px; background: #2563eb; color: #fff; font-weight: 700; cursor: pointer; }
        .lp-bar .btn:hover { background: #1d4ed8; }
        .lp-code { width: 100%; box-sizing: border-box; font-family: Consolas, "Courier New", monospace; font-size: 12.5px; line-height: 1.5; border: 1px solid #cbd5e1; border-radius: 10px; padding: 12px; background: #0f172a; color: #e2e8f0; }
        .lp-hint { color: #64748b; font-size: 12px; margin-top: 8px; }
        .lp-msg { padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-weight: 600; }
        .lp-msg.ok { background: #dcfce7; color: #166534; }
        .lp-msg.bad { background: #fee2e2; color: #991b1b; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="lp-wrap">
        <h2>Contenu de la LandingPage</h2>
        <div class="sub">Éditez le HTML de chaque section, par page et par langue. Le rendu retombe sur le français si une langue n'est pas remplie.</div>

        <div class="lp-bar">
            <label>Page
                <asp:DropDownList ID="ddlPage" runat="server" AutoPostBack="true" DataTextField="Name" DataValueField="Code" />
            </label>
            <label>Section
                <asp:DropDownList ID="ddlSection" runat="server" AutoPostBack="true" DataTextField="Name" DataValueField="Code" />
            </label>
            <label>Langue
                <asp:DropDownList ID="ddlLang" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="fr" Text="Français" />
                    <asp:ListItem Value="en" Text="English" />
                    <asp:ListItem Value="es" Text="Español" />
                </asp:DropDownList>
            </label>
            <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn" />
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false">
            <p id="pMsg" runat="server" class="lp-msg"></p>
        </asp:Panel>

        <asp:TextBox ID="txtHtml" runat="server" TextMode="MultiLine" Rows="30" CssClass="lp-code" />
        <p class="lp-hint">Astuce : la section « Forfaits » de la page <b>accueil</b> contient le jeton <code>{{PLANS}}</code>, remplacé par les cartes de forfaits au rendu — ne pas le retirer.</p>
    </div>
</asp:Content>
