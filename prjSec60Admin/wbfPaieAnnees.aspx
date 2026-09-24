<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfPaieAnnees.aspx.vb" Inherits="prjSec60Admin.wbfPaieAnnees" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paie — Taux de l'année — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pa-wrap { padding: 4px 0 24px; }
        .pa-top { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; flex-wrap: wrap; margin-bottom: 14px; }
        .pa-title { font-size: 22px; font-weight: 900; }
        .pa-sub { font-size: 13px; color: #64748b; margin-top: 4px; max-width: 820px; line-height: 1.5; }
        .pa-btn { cursor: pointer; border: 1px solid #e2e8f0; border-radius: 12px; padding: 10px 14px; font-weight: 800; font-family: inherit;
                  background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10)); color: #0f172a; text-decoration: none; display: inline-block; }
        .pa-btn.primary { border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color: #1d4ed8; }
        .pa-msg { padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid #e2e8f0; background: #fff; margin-bottom: 12px; }
        .pa-msg.bad { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: #dc2626; }
        .pa-msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: #16a34a; }
        .pa-card { background: #fff; border: 1px solid rgba(226,232,240,.9); border-radius: 16px; box-shadow: 0 12px 28px rgba(15,23,42,.08);
                   padding: 16px 18px; margin-bottom: 12px; display: grid; grid-template-columns: 120px 1fr auto; gap: 16px; align-items: center; }
        .pa-annee { font-size: 30px; font-weight: 900; letter-spacing: -.5px; }
        .pa-badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 800; margin-top: 4px; }
        .pa-badge.V { background: rgba(22,163,74,.12); color: #15803d; }
        .pa-badge.B { background: rgba(245,158,11,.14); color: #b45309; }
        .pa-src { font-weight: 700; }
        .pa-meta { font-size: 12.5px; color: #64748b; margin-top: 4px; line-height: 1.6; }
        .pa-note { font-size: 13px; color: #64748b; background: #f8fafc; border: 1px dashed #e2e8f0; border-radius: 12px; padding: 12px 14px; margin-top: 18px; line-height: 1.55; }
        @media (max-width: 720px) { .pa-card { grid-template-columns: 1fr; } }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pa-wrap">
        <div class="pa-top">
            <div>
                <div class="pa-title">Taux de l'année (60secPaie)</div>
                <div class="pa-sub">
                    Impôt fédéral (T4127), impôt du Québec (TP-1015.F), AE, RRQ, RQAP, FSS, CNESST et CNT : une ligne par année,
                    pour toutes les compagnies. Le moteur de paie n'utilise qu'une année <b>validée</b> ; un brouillon se prépare
                    et se vérifie sans rien changer aux paies.
                </div>
            </div>
            <div>
                <asp:Button ID="btnCreer" runat="server" CssClass="pa-btn primary" Text="Créer l'année suivante"
                    OnClientClick="return confirm('Créer l\'année suivante en brouillon, à partir de la plus récente ?');" />
            </div>
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false">
            <p id="pMsg" runat="server" class="pa-msg"></p>
        </asp:Panel>

        <asp:Repeater ID="rptAnnees" runat="server">
            <ItemTemplate>
                <div class="pa-card">
                    <div>
                        <div class="pa-annee"><%# Eval("Annee") %></div>
                        <span class='pa-badge <%# Eval("Statut") %>'><%# If(Eval("Statut").ToString() = "V", "Validée", "Brouillon") %></span>
                    </div>
                    <div>
                        <div class="pa-src"><%# Server.HtmlEncode(Convert.ToString(Eval("Source"))) %></div>
                        <div class="pa-meta">
                            <%# Meta(Container.DataItem) %>
                        </div>
                    </div>
                    <div>
                        <a class="pa-btn" href='wbfPaieAnneeEdit.aspx?annee=<%# Eval("Annee") %>'>Ouvrir</a>
                    </div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucune" runat="server" CssClass="pa-meta" Visible="false" Text="Aucune année. Exécutez le script 02_parametres_annee.sql de 60secPaie." />

        <div class="pa-note">
            <b>Chaque décembre :</b> « Créer l'année suivante » copie la dernière année en brouillon. Quand l'ARC publie le T4127
            de janvier et Revenu Québec le TP-1015.F, ouvrez le brouillon, remplacez chaque valeur, vérifiez avec l'exemple
            chiffré du guide, puis validez. 60secPaie voit la validation dans les cinq minutes. Une édition de juillet se
            traite en modifiant l'année validée : les paies déjà confirmées ne bougent pas.
        </div>
    </div>
</asp:Content>
