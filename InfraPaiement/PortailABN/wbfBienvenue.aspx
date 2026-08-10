<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfBienvenue.aspx.vb" Inherits="PortailABN.wbfBienvenue" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .ob-progress { background:#fff; border:1px solid var(--line); border-radius:16px; padding:20px 22px; margin-bottom:22px; }
        .ob-progress .top { display:flex; justify-content:space-between; align-items:baseline; margin-bottom:12px; }
        .ob-progress .lbl { font-weight:800; font-size:15px; }
        .ob-progress .pct { font-variant-numeric:tabular-nums; font-weight:800; color:var(--primary); }
        .bar { height:12px; background:#eef2f7; border-radius:999px; overflow:hidden; }
        .bar > span { display:block; height:100%; background:linear-gradient(135deg, var(--primary), var(--secondary)); border-radius:999px; transition:width .3s; }

        .steps { display:flex; flex-direction:column; gap:14px; }
        .step { display:flex; gap:16px; align-items:flex-start; background:#fff; border:1px solid var(--line); border-radius:16px; padding:18px 20px; }
        .step.done { border-color:rgba(5,150,105,.35); background:rgba(5,150,105,.04); }
        .step .mark { flex:0 0 auto; width:34px; height:34px; border-radius:50%; display:flex; align-items:center; justify-content:center;
                      font-weight:800; font-size:15px; background:#eef2f7; color:var(--muted); }
        .step.done .mark { background:var(--ok); color:#fff; }
        .step .body { flex:1; }
        .step .body h3 { margin:0 0 3px; font-size:15px; }
        .step .body p { margin:0; color:var(--muted); font-size:13px; }
        .step .cta { flex:0 0 auto; align-self:center; }
        .step .opt { font-size:11px; font-weight:800; color:var(--secondary); background:rgba(79,70,229,.10); padding:2px 8px; border-radius:999px; margin-left:6px; }
        .step .done-lbl { color:var(--ok); font-weight:800; font-size:13px; }
        .admin-note { font-size:12px; color:var(--muted); }
        .ob-done { padding:22px; background:rgba(5,150,105,.06); border:1px solid rgba(5,150,105,.30); border-radius:16px; }
        .ob-done h2 { margin:0 0 6px; font-size:19px; color:var(--ok); }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Bienvenue, <asp:Literal ID="litAbonne" runat="server" /> 👋</h1>
            <p class="sub">Quelques étapes pour configurer votre espace et commencer à encaisser et décaisser par EFT.</p>
        </div>
        <div><a href="Default.aspx" class="btn btn-ghost">Aller au tableau de bord →</a></div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="ob-progress">
        <div class="top">
            <span class="lbl">Configuration</span>
            <span class="pct"><asp:Literal ID="litPct" runat="server" /></span>
        </div>
        <div class="bar"><span id="barFill" runat="server"></span></div>
    </div>

    <asp:Panel ID="pnlAllDone" runat="server" Visible="false" CssClass="ob-done">
        <h2>🎉 Tout est prêt !</h2>
        <p class="sub">Votre espace est configuré. Vous pouvez piloter vos flux depuis le tableau de bord.</p>
    </asp:Panel>

    <div class="steps">
        <asp:Literal ID="litSteps" runat="server" />
    </div>
</asp:Content>
