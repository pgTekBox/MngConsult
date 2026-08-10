<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfReleve.aspx.vb" Inherits="PortailABN.wbfReleve" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .delta-pos { color: var(--ok); font-weight: 700; }
        .delta-neg { color: var(--danger); font-weight: 700; }
        .sumline { display:flex; gap:26px; flex-wrap:wrap; margin-bottom:22px; }
        .sumline .it .l { font-size:12px; font-weight:800; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }
        .sumline .it .v { font-size:20px; font-weight:800; font-variant-numeric:tabular-nums; margin-top:4px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Relevé</h1>
            <p class="sub">Grand livre de votre compte : chaque mouvement affecte votre solde ou votre réserve.</p>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:22px">
        <div class="sumline">
            <div class="it"><div class="l">Solde disponible</div><div class="v" style="color:var(--ok)"><asp:Literal ID="litSolde" runat="server" /></div></div>
            <div class="it"><div class="l">Réservé</div><div class="v" style="color:var(--secondary)"><asp:Literal ID="litReserve" runat="server" /></div></div>
            <div class="it"><div class="l">EFT entrant en cours</div><div class="v" style="color:#0284c7"><asp:Literal ID="litEftIn" runat="server" /></div></div>
            <div class="it"><div class="l">EFT sortant en cours</div><div class="v" style="color:#0284c7"><asp:Literal ID="litEftOut" runat="server" /></div></div>
        </div>
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>#</th><th>Date</th><th>Type</th><th>Description</th>
                    <th class="num">Δ Solde</th><th class="num">Δ Réservé</th><th>Comptabilisé</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono muted"><%# Eval("Id") %></td>
                    <td class="muted"><%# FormatDate(Eval("EffectiveDate")) %></td>
                    <td><span class="badge badge-neutre"><%# Enc(Eval("TxnType")) %></span></td>
                    <td><%# Enc(Eval("Description")) %></td>
                    <td class="num"><%# DeltaHtml(Eval("DeltaSoldeCents")) %></td>
                    <td class="num"><%# DeltaHtml(Eval("DeltaReserveCents")) %></td>
                    <td class="muted"><%# FormatDt(Eval("CreatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun mouvement pour l'instant.</asp:Panel>
    </div>
</asp:Content>
