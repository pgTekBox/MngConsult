<%@ Page Title="Réinitialiser la démo" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfDemoReset.aspx.vb"
    Inherits="prjSec60Admin.wbfDemoReset" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Réinitialiser la démo — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .demo-wrap { padding: 20px; max-width: 720px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
        .demo-wrap h1 { font-size: 22px; font-weight: 900; margin: 0 0 6px; color: #0f172a; }
        .demo-sub { color: #64748b; font-size: 13px; margin-bottom: 18px; }
        .demo-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 18px 20px; }
        .demo-warn { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; border-radius: 10px; padding: 12px 14px; font-size: 13px; margin-bottom: 16px; }
        .demo-info { font-size: 13px; color: #334155; line-height: 1.5; }
        .demo-info b { color: #0f172a; }
        .btn-reset { margin-top: 16px; padding: 11px 20px; background: #dc2626; color: #fff; border: none; border-radius: 10px; font-weight: 800; font-size: 14px; cursor: pointer; }
        .btn-reset:hover { background: #b91c1c; }
        .btn-snap { margin-top: 16px; padding: 11px 20px; background: #2563eb; color: #fff; border: none; border-radius: 10px; font-weight: 800; font-size: 14px; cursor: pointer; }
        .btn-snap:hover { background: #1d4ed8; }
        .demo-hr { border: none; border-top: 1px solid #e2e8f0; margin: 22px 0; }
        .demo-select { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px 16px; margin-bottom: 20px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .demo-select label { font-weight: 800; color: #0f172a; font-size: 14px; }
        .demo-select select { padding: 9px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; font-weight: 700; color: #0f172a; background: #fff; min-width: 240px; }
        .demo-msg { margin-top: 16px; padding: 10px 14px; border-radius: 10px; font-size: 13px; font-weight: 700; }
        .demo-msg.ok { background: rgba(16,185,129,.12); color: #059669; border: 1px solid rgba(16,185,129,.3); }
        .demo-msg.err { background: rgba(239,68,68,.1); color: #dc2626; border: 1px solid rgba(239,68,68,.3); }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="demo-wrap">
        <h1>Gestion des démos</h1>
        <div class="demo-sub">Les actions ci-dessous s'appliquent à la <b>démo sélectionnée</b>. Aucune autre compagnie n'est touchée.</div>

        <div class="demo-select">
            <label for="<%= ddlDemo.ClientID %>">Démo :</label>
            <asp:DropDownList ID="ddlDemo" runat="server" />
        </div>

        <h1>Réinitialiser la démo</h1>
        <div class="demo-sub">Remet la démo sélectionnée dans son état de référence.</div>

        <div class="demo-card">
            <div class="demo-warn">
                ⚠️ Cette action <b>efface toutes les données actuelles</b> de la compagnie démo (clients,
                fournisseurs, factures, écritures, produits, paramètres, etc.) et les <b>restaure à partir du
                cliché de référence</b> (tables <code>DEMO_*</code>). Aucune autre compagnie n'est touchée.
            </div>
            <div class="demo-info">
                À utiliser après qu'un visiteur ait modifié la démo, pour la remettre dans son état initial.<br />
                Le cliché de référence est celui capturé par <b>DEMO_CreateAndSnapshot.sql</b>.
            </div>

            <asp:Button ID="btnReset" runat="server" CssClass="btn-reset"
                Text="Réinitialiser la démo maintenant"
                OnClientClick="return confirm('Réinitialiser la démo sélectionnée ? Les modifications actuelles de cette démo seront perdues.');" />

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <asp:Literal ID="litMsg" runat="server" />
            </asp:Panel>
        </div>

        <hr class="demo-hr" />

        <h1>Recapturer le cliché de référence</h1>
        <div class="demo-sub">À faire après avoir peaufiné la démo sélectionnée directement dans l'application</div>

        <div class="demo-card">
            <div class="demo-warn">
                📸 Cette action <b>remplace le cliché de référence</b> (tables <code>DEMO_*</code>) de la
                démo sélectionnée par son <b>état actuel</b>. La prochaine réinitialisation restaurera donc
                ce nouvel état. Le cliché des autres démos n'est pas modifié.
            </div>
            <div class="demo-info">
                À utiliser <b>après</b> avoir amélioré la démo (nouveaux clients, factures, écritures…) pour
                que ces améliorations deviennent le point de restauration.<br />
                Appelle la proc <code>s0709SnapshotDemoCompany</code> pour la démo sélectionnée.
            </div>

            <asp:Button ID="btnSnapshot" runat="server" CssClass="btn-snap"
                Text="Recapturer le cliché maintenant"
                OnClientClick="return confirm('Remplacer le cliché de référence de la démo sélectionnée par son état actuel ?');" />

            <asp:Panel ID="pnlMsgSnap" runat="server" Visible="false">
                <asp:Literal ID="litMsgSnap" runat="server" />
            </asp:Panel>
        </div>
    </div>
</asp:Content>
