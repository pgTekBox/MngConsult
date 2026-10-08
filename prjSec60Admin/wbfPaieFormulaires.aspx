<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfPaieFormulaires.aspx.vb" Inherits="prjSec60Admin.wbfPaieFormulaires" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paie — Formulaires T4 et Relevé 1 — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pf-wrap { padding: 4px 0 24px; }
        .pf-title { font-size: 22px; font-weight: 900; }
        .pf-sub { font-size: 13px; color: #64748b; margin: 4px 0 14px; max-width: 820px; line-height: 1.5; }
        .pf-msg { padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid #e2e8f0; background: #fff; margin-bottom: 12px; }
        .pf-msg.bad { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: #dc2626; }
        .pf-msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: #16a34a; }
        .pf-card { background: #fff; border: 1px solid rgba(226,232,240,.9); border-radius: 16px; box-shadow: 0 12px 28px rgba(15,23,42,.08); padding: 16px 18px; margin-bottom: 14px; }
        .pf-card h3 { margin: 0 0 10px; font-size: 15px; font-weight: 900; }
        .pf-form { display: grid; grid-template-columns: 140px 260px 1fr auto; gap: 12px; align-items: end; }
        .pf-form label { display: block; font-size: 12px; font-weight: 800; color: #475569; margin-bottom: 4px; }
        .pf-form select, .pf-form input[type=file] { width: 100%; padding: 8px 10px; border: 1px solid #e2e8f0; border-radius: 10px; font-family: inherit; }
        .pf-btn { cursor: pointer; border: 1px solid rgba(37,99,235,.4); border-radius: 12px; padding: 10px 14px; font-weight: 800; font-family: inherit; background: rgba(37,99,235,.08); color: #1d4ed8; text-decoration: none; display: inline-block; }
        .pf-btn.danger { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.06); color: #dc2626; }
        .pf-table { width: 100%; border-collapse: collapse; font-size: 13.5px; }
        .pf-table th { text-align: left; font-size: 12px; color: #64748b; border-bottom: 1px solid #e2e8f0; padding: 8px 6px; }
        .pf-table td { padding: 10px 6px; border-bottom: 1px solid #f1f5f9; }
        .pf-table .num { text-align: right; }
        .pf-annee { font-size: 20px; font-weight: 900; }
        .pf-note { font-size: 13px; color: #64748b; background: #f8fafc; border: 1px dashed #e2e8f0; border-radius: 12px; padding: 12px 14px; margin-top: 18px; line-height: 1.55; }
        @media (max-width: 860px) { .pf-form { grid-template-columns: 1fr; } }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pf-wrap">
        <div class="pf-title">Formulaires T4 et Relevé 1 (60secPaie)</div>
        <div class="pf-sub">
            Le <b>T4 à remplir</b> de l'ARC (fichier « t4-fill-AAf.pdf ») et le <b>Relevé 1 à remplir</b> de Revenu Québec, par année,
            pour toutes les compagnies. Dès qu'ils sont ici, 60secPaie produit les feuillets de l'année sur ces formulaires
            (copie de l'employé, copie de l'employeur, copies du gouvernement, pièce jointe des courriels). Une compagnie peut
            téléverser les siens dans sa propre configuration : ils l'emportent alors sur ceux-ci. Les <b>Instructions T4 (ARC)</b>, par année,
            sont un simple document : 60secPaie l'offre tel quel à toutes les compagnies (lien dans Rapports › T4 et Relevés 1 et dans
            Configuration › Formulaires officiels).
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false">
            <p id="pMsg" runat="server" class="pf-msg"></p>
        </asp:Panel>

        <div class="pf-card">
            <h3>Téléverser un formulaire</h3>
            <div class="pf-form">
                <div><label for="ddlAnnee">Année des feuillets</label><asp:DropDownList ID="ddlAnnee" runat="server" /></div>
                <div><label for="ddlType">Formulaire</label>
                    <asp:DropDownList ID="ddlType" runat="server">
                        <asp:ListItem Value="T4" Text="T4 (ARC)" />
                        <asp:ListItem Value="R1" Text="Relevé 1 (Revenu Québec)" />
                        <asp:ListItem Value="TI" Text="Instructions T4 (ARC)" />
                    </asp:DropDownList></div>
                <div><label for="fuFichier">Fichier PDF (le formulaire officiel, tel que téléchargé)</label><asp:FileUpload ID="fuFichier" runat="server" /></div>
                <div><asp:Button ID="btnTeleverser" runat="server" CssClass="pf-btn" Text="Téléverser" /></div>
            </div>
        </div>

        <div class="pf-card">
            <h3>Formulaires en place</h3>
            <asp:Repeater ID="rptFormulaires" runat="server">
                <HeaderTemplate><table class="pf-table"><thead><tr><th>Année</th><th>Formulaire</th><th>Fichier</th><th>Téléversé le</th><th>Par</th><th class="num">Taille</th><th></th></tr></thead><tbody></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="pf-annee"><%# Eval("Annee") %></td>
                        <td><%# LibelleType(Eval("Type")) %></td>
                        <td><%# Server.HtmlEncode(Convert.ToString(Eval("NomFichier"))) %></td>
                        <td><%# Quand(Eval("TeleverseLe")) %></td>
                        <td><%# Server.HtmlEncode(Convert.ToString(Eval("TeleversePar"))) %></td>
                        <td class="num"><%# Taille(Eval("Taille")) %></td>
                        <td><asp:LinkButton runat="server" CssClass="pf-btn danger" CommandName="Supprimer" CommandArgument='<%# Convert.ToString(Eval("Annee")) & "|" & Convert.ToString(Eval("Type")) %>' CausesValidation="false"
                                OnClientClick="if (!confirm('Retirer ce formulaire ? Les feuillets de cette année reprendront la mise en page de 60secPaie, sauf pour les compagnies qui ont le leur.')) { return false; }">Retirer</asp:LinkButton></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Label ID="lblAucun" runat="server" CssClass="pf-sub" Visible="false" Text="Aucun formulaire : les feuillets sortent sur la mise en page de 60secPaie." />
        </div>

        <div class="pf-note">
            <b>Chaque année, en janvier :</b> téléchargez le T4 à remplir de l'année qui vient de finir sur le site de l'ARC et le
            Relevé 1 à remplir sur celui de Revenu Québec, puis téléversez-les ici pour cette année. Le fichier est vérifié
            (il doit porter la case 14 du feuillet 1 pour le T4, la case A pour le Relevé 1), débarrassé de son chiffrement et de
            ses scripts, et conservé tel quel : il ne sert qu'à être rempli. Un nouveau téléversement remplace le précédent.
            Les instructions T4 ne sont pas vérifiées au-delà de leur en-tête PDF : elles sont servies telles quelles.
        </div>
    </div>
</asp:Content>