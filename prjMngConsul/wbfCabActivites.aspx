<%@ Page Title="Activités à attribuer" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabActivites.aspx.vb" Inherits="MngConsul.wbfCabActivites" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Activités à attribuer — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; width: 100% }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .cab-head { display: flex; align-items: center; gap: 14px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .legend { display: flex; gap: 14px; flex-wrap: wrap; margin-top: 10px; font-size: 12.5px; font-weight: 700 }
    .legend span { display: inline-flex; align-items: center; gap: 6px; color: #44536E }
    .dot { width: 10px; height: 10px; border-radius: 50% } .dot.cli { background: #0F5A3A } .dot.cab { background: #B4581A } .dot.par { background: #143A73 }

    .toolbar { display: flex; gap: 12px; align-items: center; margin-top: 14px }
    .search { flex: 1; display: flex; align-items: center; gap: 8px; padding: 0 14px; height: 40px; border-radius: 999px; background: var(--mc-page, #F2F5F9); border: 1px solid var(--mc-line, #D5DDE8); color: #44536E }
    .search input { flex: 1; border: 0; background: transparent; font: inherit; font-size: 14px; color: #0E1F3D; outline: none; min-width: 0 }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .msg { margin-top: 12px; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700; background: #E3F3EA; color: #0F5A3A }

    .act { display: grid; grid-template-columns: 1fr 320px; gap: 12px; align-items: center; padding: 10px 12px; border-radius: 12px; }
    .act:nth-child(even) { background: var(--mc-page, #F2F5F9) }
    .act .lib { font-weight: 700; color: #0E1F3D; font-size: 14px }
    .act .rbl label { display: inline-flex; align-items: center; gap: 4px; margin-right: 12px; font-size: 13px; font-weight: 700; color: #44536E; white-space: nowrap }
    @media (max-width: 680px) { .act { grid-template-columns: 1fr } }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
        <div class="legend">
            <span><i class="dot cli"></i><asp:Literal ID="litLegCli" runat="server" /></span>
            <span><i class="dot cab"></i><asp:Literal ID="litLegCab" runat="server" /></span>
            <span><i class="dot par"></i><asp:Literal ID="litLegPar" runat="server" /></span>
        </div>
        <div class="toolbar">
            <label class="search"><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
                <input type="search" id="actSearch" autocomplete="off" />
            </label>
            <asp:Button ID="btnSaveTop" runat="server" CssClass="btn" />
        </div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>

    <section class="boite">
        <div id="actList">
            <asp:Repeater ID="rptActs" runat="server" OnItemDataBound="rptActs_ItemDataBound">
                <ItemTemplate>
                    <div class="act" data-txt="<%# Server.HtmlEncode(Convert.ToString(Eval("Name")).ToLower()) %>">
                        <div class="lib"><%# Server.HtmlEncode(Convert.ToString(Eval("Name"))) %></div>
                        <div class="rbl">
                            <asp:HiddenField ID="hfParamId" runat="server" Value='<%# Eval("ParamId") %>' />
                            <asp:RadioButtonList ID="rblChoix" runat="server" RepeatDirection="Horizontal" RepeatLayout="Flow" />
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
        </div>
        <div style="margin-top:14px"><asp:Button ID="btnSave" runat="server" CssClass="btn" /></div>
    </section>
</div>
<script type="text/javascript">
    (function () {
        var champ = document.getElementById('actSearch');
        var lignes = Array.prototype.slice.call(document.querySelectorAll('#actList .act'));
        if (!champ) return;
        function norm(s) { return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }
        champ.addEventListener('input', function () {
            var q = norm(champ.value.trim());
            lignes.forEach(function (l) { l.style.display = (!q || norm(l.getAttribute('data-txt')).indexOf(q) >= 0) ? '' : 'none'; });
        });
    })();
</script>
</asp:Content>
