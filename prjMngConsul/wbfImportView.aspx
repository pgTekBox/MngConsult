<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfImportView.aspx.vb" Inherits="MngConsul.wbfImportView" %>

<asp:Content ID="titleContent" ContentPlaceHolderID="TitleContent" runat="server">
    Visualisation staging
</asp:Content>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .pg-header { display:flex; align-items:center; gap:14px; }
    .pg-header .pg-ico {
        width:44px; height:44px; border-radius:12px;
        background:linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border:1px solid var(--mc-stroke);
        display:flex; align-items:center; justify-content:center; font-size:20px;
    }
    .pg-header h1 { font-size:20px; font-weight:800; margin:0; }
    .pg-header .pg-sub { font-size:13px; color:var(--mc-muted); margin-top:1px; }

    .iv-section { padding:20px; border-bottom:1px solid var(--mc-stroke); }
    .iv-section:last-child { border-bottom:none; }
    .iv-section h2 { font-size:15px; font-weight:800; margin:0 0 12px; }

    .iv-meta { display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:12px; }
    .iv-meta .iv-cell {
        padding:10px 14px; border:1px solid var(--mc-stroke); border-radius:10px;
        background:#fff;
    }
    .iv-meta .iv-label { font-size:11px; color:var(--mc-muted); text-transform:uppercase; letter-spacing:.4px; font-weight:700; }
    .iv-meta .iv-value { font-size:14px; font-weight:700; margin-top:3px; word-break:break-word; }

    .iv-alert {
        padding:12px 16px; border-radius:12px; font-size:13px; margin:16px 20px 0;
        display:flex; align-items:flex-start; gap:10px; border:1px solid transparent;
    }
    .iv-alert-err { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .iv-alert-wrn { background:#fffbeb; color:#92400e; border-color:#fde68a; }

    .tbl-wrap { overflow-x:auto; border:1px solid var(--mc-stroke); border-radius:12px; }
    .stg-tbl { width:100%; border-collapse:collapse; font-size:12px; }
    .stg-tbl thead th {
        background:var(--mc-blue); color:#fff; padding:9px 12px;
        text-align:left; font-weight:700; font-size:11px; text-transform:uppercase; letter-spacing:.3px;
        white-space:nowrap;
    }
    .stg-tbl tbody td { padding:7px 12px; border-bottom:1px solid rgba(0,0,0,.05); vertical-align:top; }
    .stg-tbl tbody tr:nth-child(even) { background:rgba(37,99,235,.025); }
    .stg-tbl tbody tr:hover { background:rgba(37,99,235,.06); }

    .badge {
        display:inline-block; padding:2px 8px; border-radius:999px; font-size:11px; font-weight:700;
    }
    .badge-pending  { background:#fffbeb; color:#92400e; border:1px solid #fde68a; }
    .badge-migrated { background:#f0fdf4; color:#166534; border:1px solid #bbf7d0; }
    .badge-error    { background:#fef2f2; color:#991b1b; border:1px solid #fecaca; }
    .badge-skipped  { background:#f1f5f9; color:#475569; border:1px solid #e2e8f0; }

    .iv-actions { display:flex; gap:10px; margin-top:18px; justify-content:flex-end; flex-wrap:wrap; }
    .iv-btn {
        padding:8px 16px; border-radius:10px; font-size:13px; font-weight:700;
        font-family:inherit; cursor:pointer; border:1px solid var(--mc-stroke); background:#fff; color:var(--mc-text);
    }
    .iv-btn:hover { background:var(--mc-bg); }
</style>
</asp:Content>

<asp:Content ID="mainContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="toolbar">
        <div class="pg-header">
            <div class="pg-ico">👁</div>
            <div>
                <h1>Visualisation staging</h1>
                <div class="pg-sub"><asp:Literal ID="litHeaderSub" runat="server" /></div>
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="iv-alert iv-alert-err">
        <span>❌</span> <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <asp:Panel ID="pnlWarning" runat="server" Visible="false" CssClass="iv-alert iv-alert-wrn">
        <span>⚠️</span> <asp:Literal ID="litWarning" runat="server" />
    </asp:Panel>

    <asp:Panel ID="pnlContent" runat="server" Visible="false">

        <div class="iv-section">
            <h2>Résumé du fichier</h2>
            <div class="iv-meta">
                <div class="iv-cell"><div class="iv-label">Id</div><div class="iv-value"><asp:Literal ID="litId" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Type</div><div class="iv-value"><asp:Literal ID="litType" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Fichier</div><div class="iv-value"><asp:Literal ID="litFileName" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Téléversé le</div><div class="iv-value"><asp:Literal ID="litUploadDate" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Statut</div><div class="iv-value"><asp:Literal ID="litStatus" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Lignes extraites</div><div class="iv-value"><asp:Literal ID="litRows" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Modèle IA</div><div class="iv-value"><asp:Literal ID="litModel" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Tokens in / out</div><div class="iv-value"><asp:Literal ID="litTokens" runat="server" /></div></div>
                <div class="iv-cell"><div class="iv-label">Coût estimé</div><div class="iv-value"><asp:Literal ID="litCost" runat="server" /></div></div>
            </div>
        </div>

        <asp:Panel ID="pnlParty" runat="server" Visible="false" CssClass="iv-section">
            <h2><asp:Literal ID="litPartyTitle" runat="server" /></h2>
            <div class="tbl-wrap">
                <asp:GridView ID="gvParty" runat="server" CssClass="stg-tbl" AutoGenerateColumns="false">
                    <Columns>
                        <asp:BoundField DataField="LineNumber"           HeaderText="#" />
                        <asp:BoundField DataField="Name"                 HeaderText="Nom" />
                        <asp:BoundField DataField="Attention"            HeaderText="Contact" />
                        <asp:BoundField DataField="Address1"             HeaderText="Adresse 1" />
                        <asp:BoundField DataField="Address2"             HeaderText="Adresse 2" />
                        <asp:BoundField DataField="City"                 HeaderText="Ville" />
                        <asp:BoundField DataField="Province"             HeaderText="Province" />
                        <asp:BoundField DataField="PostalCode"           HeaderText="Code postal" />
                        <asp:BoundField DataField="Phone"                HeaderText="Téléphone" />
                        <asp:BoundField DataField="Email"                HeaderText="Courriel" />
                        <asp:BoundField DataField="TPS"                  HeaderText="TPS" />
                        <asp:BoundField DataField="TVQ"                  HeaderText="TVQ" />
                        <asp:BoundField DataField="Balance"              HeaderText="Solde"  DataFormatString="{0:N2}" />
                        <asp:BoundField DataField="CompteAuxClient"      HeaderText="Cpt. Aux. Client" />
                        <asp:BoundField DataField="CompteAuxFournisseur" HeaderText="Cpt. Aux. Fourn." />
                        <asp:TemplateField HeaderText="Statut">
                            <ItemTemplate>
                                <span class='<%# "badge badge-" & Convert.ToString(Eval("Status")).ToLowerInvariant() %>'><%# Eval("Status") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </asp:Panel>

        <asp:Panel ID="pnlProduct" runat="server" Visible="false" CssClass="iv-section">
            <h2>Produits / Services en staging</h2>
            <div class="tbl-wrap">
                <asp:GridView ID="gvProduct" runat="server" CssClass="stg-tbl" AutoGenerateColumns="false">
                    <Columns>
                        <asp:BoundField DataField="LineNumber"     HeaderText="#" />
                        <asp:BoundField DataField="Name"           HeaderText="Nom" />
                        <asp:BoundField DataField="Description"    HeaderText="Description" />
                        <asp:BoundField DataField="Price"          HeaderText="Prix"  DataFormatString="{0:N2}" />
                        <asp:BoundField DataField="RevenueAccount" HeaderText="Cpt. Vente" />
                        <asp:BoundField DataField="ExpenseAccount" HeaderText="Cpt. Achat" />
                        <asp:TemplateField HeaderText="Taxable">
                            <ItemTemplate>
                                <%# If(Eval("Taxable") Is DBNull.Value, "—", If(CBool(Eval("Taxable")), "Oui", "Non")) %>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Statut">
                            <ItemTemplate>
                                <span class='<%# "badge badge-" & Convert.ToString(Eval("Status")).ToLowerInvariant() %>'><%# Eval("Status") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </asp:Panel>

        <div class="iv-section">
            <div class="iv-actions">
                <button type="button" class="iv-btn" onclick="window.close();">✕ Fermer</button>
            </div>
        </div>

    </asp:Panel>

</asp:Content>
