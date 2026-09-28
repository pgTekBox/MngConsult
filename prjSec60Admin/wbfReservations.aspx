<%@ Page Title="Réservations" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfReservations.aspx.vb"
    Inherits="prjSec60Admin.wbfReservations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Réservations — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .res-wrap { padding: 20px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
        .res-wrap h1 { font-size: 22px; font-weight: 900; margin: 0 0 6px; color: #0f172a; }
        .res-sub { color: #64748b; font-size: 13px; margin-bottom: 16px; }
        .res-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 14px 16px; overflow: auto; }
        .res-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .res-table th, .res-table td { border-bottom: 1px solid #e2e8f0; padding: 7px 8px; text-align: left; vertical-align: top; white-space: nowrap; }
        .res-table th { background: #f8fafc; font-weight: 800; color: #0f172a; position: sticky; top: 0; }
        .res-table td.wrap { white-space: normal; min-width: 180px; }
        .res-pill { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 12px; font-weight: 800; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
        .res-pill.cab { background: #fef3c7; color: #b45309; border-color: #fcd34d; }
        .res-vide { color: #64748b; font-size: 13px; padding: 14px 0; }
        .res-count { font-weight: 800; color: #0f172a; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="res-wrap">
        <h1>Réservations d'accès anticipé</h1>
        <div class="res-sub">Les demandes « Réserver ma place » faites sur la page d'accueil de 60secondes (<span class="res-count"><asp:Literal ID="litNb" runat="server" /></span> au total, les 500 plus récentes affichées).</div>

        <div class="res-card">
            <asp:Repeater ID="rpt" runat="server">
                <HeaderTemplate>
                    <table class="res-table">
                        <thead><tr><th>#</th><th>Reçue le</th><th>Profil</th><th>Nom</th><th>Courriel</th><th>Société / cabinet</th><th>Secteur</th><th>Détails</th><th>Langue</th><th>Avis</th><th>Statut</th></tr></thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td><%# Eval("Id") %></td>
                        <td><%# FormatDate(Eval("Created")) %></td>
                        <td><span class='res-pill <%# If(Convert.ToString(Eval("Profil")) = "cab", "cab", "") %>'><%# Server.HtmlEncode(Convert.ToString(Eval("ProfilLibelle"))) %></span></td>
                        <td><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></td>
                        <td><a href='mailto:<%# Server.HtmlEncode(Convert.ToString(Eval("Courriel"))) %>'><%# Server.HtmlEncode(Convert.ToString(Eval("Courriel"))) %></a></td>
                        <td><%# Server.HtmlEncode(Convert.ToString(If(IsDBNull(Eval("SocieteNom")), Eval("CabinetNom"), Eval("SocieteNom")))) %></td>
                        <td class="wrap"><%# Secteur(Eval("Secteur"), Eval("SousCategorie"), Eval("ActiviteAutre")) %></td>
                        <td class="wrap"><%# Details(Container.DataItem) %></td>
                        <td><%# Libelle(Eval("Langue")) %></td>
                        <td><%# If(Convert.ToBoolean(Eval("AvisLancement")), "✔", "—") %></td>
                        <td><%# Server.HtmlEncode(Convert.ToString(Eval("Statut"))) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate>
                        </tbody>
                    </table>
                </FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlVide" runat="server" CssClass="res-vide" Visible="false">Aucune réservation pour l'instant.</asp:Panel>
        </div>
    </div>
</asp:Content>
