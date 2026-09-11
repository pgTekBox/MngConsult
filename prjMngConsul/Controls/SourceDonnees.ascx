<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="SourceDonnees.ascx.vb" Inherits="MngConsul.SourceDonnees" %>

<%-- « D'où viennent vos données ? » — le même bloc sur chaque écran
     d'importation. Seul change ce qu'on importe, donc le rapport à sortir. --%>

<style>
    .sd-h {
        font-size: 15px; font-weight: 800; margin: 0 0 3px; color: #0f172a;
        display: flex; align-items: center; gap: 9px;
    }

    .sd-n {
        width: 24px; height: 24px; border-radius: 999px; flex: 0 0 auto;
        background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;
        font-size: 12px; display: flex; align-items: center; justify-content: center;
    }

    .sd-desc { font-size: 13px; color: #64748b; margin: 0 0 15px; padding-left: 33px }
    .sd-body { padding-left: 33px }

    .sd-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px }

    .sd-fld label { display: block; font-size: 12.5px; font-weight: 700; margin-bottom: 4px; color: #334155 }

    .sd-fld select {
        width: 100%; padding: 8px 11px; border: 1px solid #cbd5e1;
        border-radius: 9px; font-size: 13px; font-family: inherit; background: #fff;
    }

    .sd-hint { font-size: 11.5px; color: #94a3b8; margin-top: 4px }

    .sd-ou {
        display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px;
        background: #f8fafc; border: 1px solid #e2e8f0; color: #475569;
        font-size: 13px; margin-top: 14px;
    }

    .sd-ou p { margin: 0 }

    .sd-aide {
        margin-top: 14px; border: 1px solid #bfdbfe; border-radius: 12px;
        background: #f8fbff; overflow: hidden;
    }

    .sd-aide > summary {
        cursor: pointer; padding: 12px 15px; font-size: 13.5px; font-weight: 700;
        color: #1d4ed8; list-style: none; display: flex; align-items: center; gap: 9px;
    }

    .sd-aide > summary::-webkit-details-marker { display: none }
    .sd-aide > summary:hover { background: #eff6ff }
    .sd-aide .sd-chev { margin-left: auto; transition: transform .15s; font-size: 12px }
    .sd-aide[open] .sd-chev { transform: rotate(180deg) }

    .sd-corps { padding: 4px 15px 16px; border-top: 1px solid #dbeafe }

    .sd-rapport { font-size: 13px; color: #334155; margin: 12px 0 0 }

    .sd-t {
        font-size: 12px; font-weight: 800; text-transform: uppercase;
        letter-spacing: .04em; color: #64748b; margin: 16px 0 7px;
    }

    .sd-p { font-size: 13px; color: #475569; margin: 10px 0 0; line-height: 1.55 }

    .sd-avert {
        display: flex; gap: 10px; margin-top: 12px; padding: 11px 13px;
        border-radius: 10px; background: #fffbeb; border: 1px solid #fde68a;
        color: #78350f; font-size: 13px; line-height: 1.55;
    }

    .sd-avert p { margin: 0 }
    .sd-avert span { flex: 0 0 auto }
    .sd-avert.sd-neutre { background: #f8fafc; border-color: #e2e8f0; color: #475569 }

    ol.sd-etapes, ul.sd-astuces { margin: 0; padding-left: 20px; font-size: 13px; color: #475569; line-height: 1.6 }
    ol.sd-etapes li, ul.sd-astuces li { margin-bottom: 5px }

    .sd-cols { overflow-x: auto; border: 1px solid #e2e8f0; border-radius: 10px; background: #fff }

    table.sd-coltbl { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.sd-coltbl th { background: #f8fafc; text-align: left; padding: 8px 11px; font-weight: 700; color: #334155; border-bottom: 1px solid #e2e8f0; white-space: nowrap }
    table.sd-coltbl td { padding: 7px 11px; border-bottom: 1px solid #f1f5f9; vertical-align: top }
    table.sd-coltbl tr:last-child td { border-bottom: 0 }
    table.sd-coltbl .sd-kw { color: #64748b; font-size: 11.5px }

    .sd-req {
        display: inline-block; padding: 1px 7px; border-radius: 999px; font-size: 10.5px;
        font-weight: 800; background: #fef2f2; color: #b91c1c; white-space: nowrap; margin-left: 4px;
    }
</style>

<div class="sd">
    <h2 class="sd-h"><span class="sd-n"><asp:Literal ID="litNumero" runat="server" /></span>D'où viennent vos données ?</h2>
    <p class="sd-desc">Le séparateur et l'encodage sont ajustés au logiciel choisi — vous pouvez les changer.</p>

    <div class="sd-body">
        <div class="sd-grid">
            <div class="sd-fld">
                <label>Logiciel d'origine</label>
                <asp:DropDownList ID="ddlSysteme" runat="server" AutoPostBack="true" />
            </div>
            <div class="sd-fld">
                <label>Séparateur</label>
                <asp:DropDownList ID="ddlSeparateur" runat="server">
                    <asp:ListItem Value="," Text="Virgule  ," />
                    <asp:ListItem Value=";" Text="Point-virgule  ;" />
                    <asp:ListItem Value="TAB" Text="Tabulation" />
                </asp:DropDownList>
            </div>
            <div class="sd-fld">
                <label>Encodage</label>
                <asp:DropDownList ID="ddlEncodage" runat="server">
                    <asp:ListItem Value="UTF-8" Text="UTF-8" />
                    <asp:ListItem Value="Windows-1252" Text="Windows-1252 (ANSI)" />
                    <asp:ListItem Value="ISO-8859-1" Text="ISO-8859-1" />
                </asp:DropDownList>
                <div class="sd-hint">Des accents en charabia = mauvais encodage</div>
            </div>
        </div>

        <div class="sd-ou">
            <span>📍</span>
            <p>Dans <b><asp:Literal ID="litNomSysteme" runat="server" /></b> : <asp:Literal ID="litCheminExport" runat="server" /></p>
        </div>

        <details class="sd-aide" open>
            <summary>
                <span>❓</span>
                Comment sortir ce fichier de <b><asp:Literal ID="litAideTitre" runat="server" /></b>
                <span class="sd-chev">▾</span>
            </summary>
            <div class="sd-corps">
                <asp:Panel ID="pnlAideSysteme" runat="server">
                    <asp:Literal ID="litAideCorps" runat="server" />
                </asp:Panel>

                <asp:Panel ID="pnlAideAbsente" runat="server" Visible="false" CssClass="sd-avert sd-neutre">
                    <span>ℹ️</span>
                    <p><asp:Literal ID="litAideAbsente" runat="server" /></p>
                </asp:Panel>

                <asp:Panel ID="pnlColonnes" runat="server" Visible="false">
                    <h4 class="sd-t">Les colonnes attendues</h4>
                    <div class="sd-cols"><asp:Literal ID="litColonnes" runat="server" /></div>
                </asp:Panel>
            </div>
        </details>
    </div>
</div>
