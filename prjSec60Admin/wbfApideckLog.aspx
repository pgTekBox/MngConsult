<%@ Page Title="Journal Apideck" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfApideckLog.aspx.vb" Inherits="prjSec60Admin.wbfApideckLog" %>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    #al{--encre:#0E1F3D;--encre2:#44536E;--encre3:#6A7891;--fond:#F2F5F9;--filet:#E3E9F1;--bord:#D5DDE8;--marine:#1B4F9C;--marine-fonce:#143A73;--vert:#1E6B3A;--vert-pale:#E6F4EA;--rouge:#A3261C;--rouge-pale:#FDE8E8;--ambre:#9A5B00;--ambre-pale:#FFF4DF;--pastille:#E8EDF5}
    #al{color:var(--encre);font-size:15px}
    #al *{box-sizing:border-box}
    #al .al-tete{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:14px}
    #al h1{font-size:24px;font-weight:800;margin:0}
    #al .al-sous{color:var(--encre2);font-size:14px;margin:2px 0 0}
    #al .al-filtres{display:inline-flex;background:var(--pastille);border-radius:12px;padding:3px;gap:2px}
    #al .al-filtres a{border-radius:9px;padding:7px 13px;font-weight:800;color:var(--encre2);text-decoration:none;font-size:13.5px}
    #al .al-filtres a.on{background:#fff;color:var(--encre);box-shadow:0 1px 3px rgba(14,31,61,.18)}
    #al .al-barre{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:0 0 14px}
    #al .al-cherche{display:inline-flex;gap:6px;margin-left:auto}
    #al .al-cherche input{border:1px solid var(--bord);border-radius:10px;padding:8px 10px;font:inherit;font-size:14px;width:260px}
    #al .al-btn{border:0;border-radius:999px;padding:8px 16px;font-weight:800;font-size:13.5px;cursor:pointer;text-decoration:none;display:inline-block;font-family:inherit}
    #al .al-btn.ok{background:var(--marine);color:#fff}
    #al .al-btn.ok:hover{background:var(--marine-fonce)}
    #al .al-btn.sec{background:#fff;color:var(--encre);border:1px solid var(--bord)}
    #al .al-btn.danger{background:#fff;color:var(--rouge);border:1px solid #E8B4AE}
    #al .al-kpis{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:10px;margin-bottom:12px}
    #al .al-kpi{background:#fff;border:1px solid var(--filet);border-radius:14px;padding:10px 12px}
    #al .al-kpi span{display:block;font-size:12px;color:var(--encre3);font-weight:700;text-transform:uppercase;letter-spacing:.04em}
    #al .al-kpi b{display:block;font-size:20px;font-weight:800;margin-top:2px}
    #al .al-kpi b.rouge{color:var(--rouge)}
    #al .al-kpi small{font-size:12.5px;color:var(--encre2);font-weight:600}
    #al .al-codes{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:14px;font-size:13px;color:var(--encre2)}
    #al .st{display:inline-block;min-width:44px;text-align:center;border-radius:999px;padding:2px 9px;font-weight:800;font-size:12.5px}
    #al .st.ok{background:var(--vert-pale);color:var(--vert)}
    #al .st.err{background:var(--rouge-pale);color:var(--rouge)}
    #al .st.zero{background:var(--ambre-pale);color:var(--ambre)}
    #al .al-liste{background:#fff;border:1px solid var(--filet);border-radius:16px;overflow:hidden}
    #al details{border-top:1px solid var(--filet)}
    #al details:first-child{border-top:0}
    #al summary{list-style:none;display:grid;grid-template-columns:150px 62px minmax(0,1fr) 220px 200px 70px 44px;gap:10px;align-items:center;padding:9px 14px;cursor:pointer;font-size:13.5px}
    #al summary::-webkit-details-marker{display:none}
    #al summary:hover{background:var(--fond)}
    #al details[open] summary{background:#F7F9FC}
    #al .ch{font-family:Consolas,ui-monospace,monospace;font-size:12.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    #al .ch b{font-family:inherit;color:var(--marine-fonce);margin-right:6px}
    #al .cie,#al .qui{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--encre2)}
    #al .num{text-align:right;color:var(--encre2);font-variant-numeric:tabular-nums}
    #al .dt{color:var(--encre3);font-variant-numeric:tabular-nums}
    #al .al-entete{display:grid;grid-template-columns:150px 62px minmax(0,1fr) 220px 200px 70px 44px;gap:10px;padding:8px 14px;background:var(--fond);font-size:11.5px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:var(--encre3)}
    #al .al-detail{padding:4px 14px 14px;display:flex;flex-direction:column;gap:8px;background:#F7F9FC}
    #al .al-detail h4{margin:4px 0 2px;font-size:11.5px;text-transform:uppercase;letter-spacing:.06em;color:var(--encre3)}
    #al .al-detail pre{margin:0;white-space:pre-wrap;word-break:break-word;background:#fff;border:1px solid var(--filet);border-radius:10px;padding:8px 10px;font-size:12.5px;max-height:260px;overflow:auto}
    #al .al-detail pre.erreur{border-color:#F1C4BF;background:#FFF8F7;color:var(--rouge)}
    #al .al-detail .meta{font-size:13px;color:var(--encre2)}
    #al .al-vide{background:#fff;border:1px dashed var(--bord);border-radius:16px;padding:30px;text-align:center;color:var(--encre2)}
    #al .al-msg{background:var(--vert-pale);color:var(--vert);border-radius:10px;padding:8px 12px;font-weight:700;margin-bottom:12px}
    #al .al-pied{font-size:12.5px;color:var(--encre3);margin-top:10px}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="al">
    <div class="al-tete">
        <div>
            <h1>Journal Apideck</h1>
            <p class="al-sous">Chaque appel de l'ERP à Apideck (connexions, sessions Vault, lectures comptables, passe-plat), réussi ou non. La clé d'API n'est jamais inscrite.</p>
        </div>
    </div>

    <asp:Literal ID="litMessage" runat="server" />

    <div class="al-barre">
        <div class="al-filtres">
            <asp:HyperLink ID="lnkJ1" runat="server" Text="24 h" />
            <asp:HyperLink ID="lnkJ7" runat="server" Text="7 jours" />
            <asp:HyperLink ID="lnkJ30" runat="server" Text="30 jours" />
            <asp:HyperLink ID="lnkJ90" runat="server" Text="90 jours" />
        </div>
        <div class="al-filtres">
            <asp:HyperLink ID="lnkTous" runat="server" Text="Tous les appels" />
            <asp:HyperLink ID="lnkErreurs" runat="server" Text="Erreurs" />
        </div>
        <div class="al-cherche">
            <asp:TextBox ID="txtRecherche" runat="server" placeholder="Chemin, erreur, compagnie, courriel, statut…" />
            <asp:Button ID="btnChercher" runat="server" CssClass="al-btn ok" Text="Chercher" />
        </div>
    </div>

    <div class="al-kpis">
        <div class="al-kpi"><span>Appels</span><b><asp:Literal ID="litAppels" runat="server" /></b></div>
        <div class="al-kpi"><span>Erreurs</span><b class="rouge"><asp:Literal ID="litErreurs" runat="server" /></b><small><asp:Literal ID="litTaux" runat="server" /></small></div>
        <div class="al-kpi"><span>Durée moyenne</span><b><asp:Literal ID="litDuree" runat="server" /></b></div>
        <div class="al-kpi"><span>Compagnies</span><b><asp:Literal ID="litCies" runat="server" /></b></div>
        <div class="al-kpi"><span>Dernier appel</span><small><asp:Literal ID="litDernier" runat="server" /></small></div>
        <div class="al-kpi"><span>Dernière erreur</span><small><asp:Literal ID="litDerniereErreur" runat="server" /></small></div>
    </div>
    <div class="al-codes"><asp:Literal ID="litCodes" runat="server" /></div>

    <asp:Repeater ID="rptLog" runat="server">
        <HeaderTemplate>
            <div class="al-liste">
                <div class="al-entete"><span>Date</span><span>Statut</span><span>Appel</span><span>Compagnie</span><span>Usager · page</span><span style="text-align:right">Durée</span><span style="text-align:right">Essai</span></div>
        </HeaderTemplate>
        <ItemTemplate>
            <details>
                <summary>
                    <span class="dt"><%# FormatDate(Eval("Created")) %></span>
                    <span><%# Statut(Eval("StatutHttp"), Eval("Succes")) %></span>
                    <span class="ch" title='<%# Server.HtmlEncode(Convert.ToString(Eval("Chemin"))) %>'><b><%# Server.HtmlEncode(Convert.ToString(Eval("Methode"))) %></b><%# Server.HtmlEncode(Convert.ToString(Eval("Chemin"))) %></span>
                    <span class="cie"><%# Server.HtmlEncode(Texte(Eval("Compagnie"), "—")) %></span>
                    <span class="qui"><%# Server.HtmlEncode(Qui(Eval("UserEmail"), Eval("Page"))) %></span>
                    <span class="num"><%# Duree(Eval("DureeMs")) %></span>
                    <span class="num"><%# Eval("Essai") %></span>
                </summary>
                <div class="al-detail">
                    <div class="meta">n&deg; <%# Eval("Id") %> · service <b><%# Server.HtmlEncode(Texte(Eval("ServiceId"), "—")) %></b> · compagnie <%# Server.HtmlEncode(Texte(Eval("CompanyGUID"), "—")) %> · réponse <%# Taille(Eval("TailleReponse")) %></div>
                    <%# Bloc("Erreur", Eval("Erreur"), True) %>
                    <%# Bloc("Passe-plat (adresse en aval)", Eval("Aval"), False) %>
                    <%# Bloc("Requête envoyée (extrait)", Eval("Requete"), False) %>
                    <%# Bloc("Réponse reçue (extrait)", Eval("Reponse"), False) %>
                </div>
            </details>
        </ItemTemplate>
        <FooterTemplate></div></FooterTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlVide" runat="server" Visible="false" CssClass="al-vide">
        Aucun appel à Apideck pour ce filtre.
    </asp:Panel>

    <div class="al-pied">
        <asp:Literal ID="litPied" runat="server" />
        <asp:Button ID="btnPurger" runat="server" CssClass="al-btn danger" Text="Effacer les entrées de plus de 90 jours"
            OnClientClick="if (!confirm('Effacer définitivement les entrées du journal Apideck de plus de 90 jours ?')) { return false; }" />
    </div>
</div>
</asp:Content>
