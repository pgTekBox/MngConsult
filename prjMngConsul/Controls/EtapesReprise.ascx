<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="EtapesReprise.ascx.vb" Inherits="MngConsul.EtapesReprise" %>

<%-- Le fil des trois étapes, repris tel quel en tête de chacune. On voit où
     l'on est, et on passe d'un écran à l'autre sans repasser par le menu. --%>
<style>
    .fil {
        display: flex; align-items: stretch; gap: 0; flex-wrap: wrap;
        border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;
        background: #fff; margin-bottom: 16px; font-size: 12.5px;
    }

    .fil a, .fil span.cran {
        flex: 1 1 190px; display: flex; align-items: center; gap: 9px;
        padding: 10px 14px; text-decoration: none; color: #475569;
        border-right: 1px solid #e2e8f0; min-width: 0;
    }

    .fil a:last-child, .fil span.cran:last-child { border-right: none }
    .fil a:hover { background: #f8fafc; color: #1e293b }

    .fil .no {
        flex: 0 0 auto; width: 22px; height: 22px; border-radius: 999px;
        background: #f1f5f9; color: #64748b; font-weight: 800; font-size: 11px;
        display: flex; align-items: center; justify-content: center;
    }

    .fil .lib { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }

    /* L'étape courante : sans lien, elle ne se clique pas. */
    .fil .ici { background: #eff6ff; color: #1d4ed8; font-weight: 800 }
    .fil .ici .no { background: #2563eb; color: #fff }

    /* Une étape qu'aucun lot ne rend atteignable pour l'instant. */
    .fil .hors { color: #cbd5e1; cursor: default }
    .fil .hors .no { background: #f8fafc; color: #cbd5e1 }
</style>

<div class="fil"><asp:Literal ID="litFil" runat="server" /></div>
