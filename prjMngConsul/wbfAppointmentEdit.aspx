<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfAppointmentEdit.aspx.vb" Inherits="MngConsul.wbfAppointmentEdit" %>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= T("Rendez-vous","Appointment","Cita") %></title>
    <%-- Signature « Portail du client » (voir css/edition-60s.css) --%>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" />
    <link rel="stylesheet" href="css/edition-60s.css?v=2026102104" />
    <style>
        /* =============================================
           « Nouveau RDV » : trois étapes à gauche (client, service, quand),
           résumé et confirmation à droite. Préfixe nr- : rien ne se mêle
           aux styles partagés de edition-60s.css (sauf .field, voulu).
        ============================================= */
        body.f60 { --nr-navy: #0E1F3D; --nr-ok: #3FB27F; --nr-gold: #8A5A00; --nr-cta-off: #8AA8D6; background: #FFFFFF; }

        .nr { min-height: 100vh; display: flex; flex-direction: column; }

        /* ----- En-tête ----- */
        .nr-tete {
            position: sticky; top: 0; z-index: 6;
            display: flex; align-items: center; gap: 14px;
            padding: 14px 22px; background: #FFFFFF; border-bottom: 1px solid var(--f-line2);
        }
        .nr-ico {
            width: 44px; height: 44px; border-radius: 12px; flex: none;
            display: grid; place-items: center; background: #E3EBF7; color: var(--f-blue);
        }
        .nr-tete h1 { margin: 0; font-size: 22px; font-weight: 800; line-height: 1.2; }
        .nr-sous { font-size: 13px; color: var(--f-muted); }
        .nr-tete .nr-esp { flex: 1; }
        .nr-x {
            width: 40px; height: 40px; border-radius: 50%; flex: none;
            display: grid; place-items: center; background: #E9EDF3;
            color: var(--f-ink) !important; font-size: 22px; font-weight: 800; text-decoration: none; cursor: pointer;
        }
        .nr-x:hover { background: #DCE3EC; }

        /* ----- Corps : deux colonnes ----- */
        .nr-corps { flex: 1; display: grid; grid-template-columns: minmax(0, 1fr) 344px; }
        .nr-gauche { padding: 18px 22px 24px; }
        .nr-droite {
            background: var(--f-bg); border-left: 1px solid var(--f-line2);
            padding: 18px 22px; display: flex; flex-direction: column; gap: 12px;
        }

        .nr-msg { margin: 0 0 14px; }

        /* ----- Étapes ----- */
        .nr-etape { margin-bottom: 16px; }
        .nr-etape-t { display: flex; align-items: center; gap: 12px; font-size: 16px; font-weight: 800; margin-bottom: 10px; }
        .nr-pastille {
            width: 30px; height: 30px; border-radius: 50%; flex: none;
            display: grid; place-items: center; color: #FFFFFF; font-weight: 800; font-size: 14px;
            background: var(--f-blue);
        }
        .nr-pastille.ok { background: var(--nr-ok); }
        .nr-etape-c { margin-left: 42px; }
        .nr-etape-c.field .RadDropDownList .rddlInner { min-height: 46px !important; height: 46px !important; border-radius: 10px !important; }
        .nr-etape-c.field .rddlFakeInput { font-size: 16px !important; font-weight: 800 !important; }

        /* Lieu */
        .nr-lieu { display: flex; align-items: center; gap: 6px; margin-top: 8px; flex-wrap: wrap; }
        .nr-lieu-l { font-size: 13px; font-weight: 800; color: var(--f-muted); margin-right: 4px; }
        .nr-puce {
            border: 1px solid var(--f-line); background: #FFFFFF; border-radius: 999px;
            padding: 7px 12px; font: 800 13px Nunito, "Segoe UI", sans-serif; color: var(--f-ink); cursor: pointer;
        }
        .nr-puce:hover { border-color: var(--f-blue); }
        .nr-puce.on { background: #E3EBF7; border-color: var(--f-blue); }

        /* Quand : semaine, jours, plages */
        .nr-sem {
            width: 100%; height: 46px; padding: 0 14px; border: 1px solid var(--f-field); border-radius: 10px;
            background: #FFFFFF; font: 800 16px Nunito, "Segoe UI", sans-serif; color: var(--f-ink);
        }
        .nr-sem:focus { outline: none; border-color: var(--f-blue); box-shadow: 0 0 0 3px #DCE6F6; }
        .nr-jours { display: flex; gap: 8px; margin: 10px 0 12px; flex-wrap: wrap; }
        .nr-jour {
            width: 112px; padding: 8px 0; border-radius: 10px; text-align: center; cursor: pointer; line-height: 1.15;
            border: 1px solid var(--f-line); background: #FFFFFF; color: var(--f-ink); font-family: inherit;
        }
        .nr-jour:hover { border-color: var(--f-blue); }
        .nr-jour .j1 { display: block; font-size: 12px; font-weight: 800; text-transform: capitalize; }
        .nr-jour .j2 { display: block; font-size: 20px; font-weight: 800; }
        .nr-jour .j3 { display: block; font-size: 11px; font-weight: 800; }
        .nr-jour.plein .j3 { color: var(--f-muted); }
        .nr-jour.on { background: var(--nr-navy); border-color: var(--nr-navy); color: #FFFFFF; }
        .nr-jour.on .j3 { color: #FFFFFF; }

        .nr-periode { font-size: 12px; font-weight: 800; letter-spacing: .06em; color: var(--f-muted); text-transform: uppercase; margin: 6px 0; }
        .nr-plages { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 7px; }
        .nr-plage {
            height: 44px; border: 1px solid var(--f-line); border-radius: 10px; background: #FFFFFF;
            font: 800 15px Nunito, "Segoe UI", sans-serif; color: var(--f-ink); cursor: pointer;
        }
        .nr-plage:hover { border-color: var(--f-blue); }
        .nr-plage.on { background: var(--f-blue); border-color: var(--f-blue); color: #FFFFFF; }
        .nr-vide { font-size: 14px; color: var(--f-muted); padding: 8px 0; }

        /* Plus de détails (champs complets de la fiche) */
        .nr-plus { margin-top: 8px; border-top: 1px solid var(--f-line2); padding-top: 12px; }
        .nr-plus > summary { cursor: pointer; font-weight: 800; color: var(--f-blue); font-size: 14px; list-style: none; }
        .nr-plus > summary::-webkit-details-marker { display: none; }
        .nr-plus > summary::before { content: "▸ "; }
        .nr-plus[open] > summary::before { content: "▾ "; }
        .nr-grille { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-top: 12px; }
        .nr-grille .large { grid-column: 1 / -1; }
        .nr-coche { display: inline-flex !important; align-items: center; gap: 8px; margin-top: 34px !important; }

        /* ----- Résumé ----- */
        .nr-droite-t { font-size: 13px; font-weight: 800; letter-spacing: .08em; color: var(--f-muted); text-transform: uppercase; }
        .nr-boite { background: #FFFFFF; border-radius: 14px; padding: 14px; }
        .nr-nom { font-size: 18px; font-weight: 800; }
        .nr-svc { font-size: 13px; color: var(--f-muted); padding-bottom: 10px; border-bottom: 1px solid var(--f-line2); margin-bottom: 4px; }
        .nr-ligne { display: flex; gap: 10px; align-items: flex-start; margin-top: 8px; }
        .nr-ligne-ico { width: 28px; height: 28px; border-radius: 8px; flex: none; display: grid; place-items: center; background: #E3EBF7; color: var(--f-blue); }
        .nr-k { font-size: 11px; font-weight: 800; color: var(--f-muted); text-transform: uppercase; }
        .nr-v { font-size: 14px; font-weight: 800; }
        .nr-v.attente { color: var(--nr-gold); }
        body.f60 label.nr-rappel { display: flex; align-items: center; gap: 12px; margin: 0; font-size: 14px; cursor: pointer; }
        .nr-rappel input { width: 22px; height: 22px; accent-color: var(--f-blue); margin: 0; }
        .nr-note.field textarea.riTextBox { min-height: 62px !important; font-weight: 600 !important; }
        .nr-droite .nr-esp { flex: 1; }

        .nr-cta {
            width: 100%; min-height: 64px; border: 0; border-radius: 999px; cursor: pointer;
            background: var(--f-blue); color: #FFFFFF; font: 800 24px Nunito, "Segoe UI", sans-serif; padding: 0 18px;
        }
        .nr-cta:hover { background: var(--f-blue-d); }
        .nr-cta:disabled { background: var(--nr-cta-off); cursor: not-allowed; }
        .nr-aide { text-align: center; font-size: 12px; color: var(--f-muted); }
        .nr-autres { display: flex; gap: 8px; justify-content: center; flex-wrap: wrap; }
        .nr-lien {
            border: 1px solid var(--f-line); background: #FFFFFF; border-radius: 999px; padding: 8px 14px;
            font: 800 13px Nunito, "Segoe UI", sans-serif; color: var(--f-ink); cursor: pointer;
        }
        .nr-lien:hover { border-color: var(--f-blue); }
        .nr-lien:disabled { opacity: .5; cursor: not-allowed; }
        .nr-lien.danger { color: #B42318; border-color: rgba(180,35,24,.35); }

        @media (max-width: 860px) {
            .nr-corps { grid-template-columns: 1fr; }
            .nr-droite { border-left: 0; border-top: 1px solid var(--f-line2); }
            .nr-etape-c { margin-left: 0; }
            .nr-plages { grid-template-columns: repeat(3, minmax(0, 1fr)); }
            .nr-grille { grid-template-columns: 1fr; }
            .nr-coche { margin-top: 0 !important; }
        }
    </style>
</head>

<body class="f60">
    <form id="form1" runat="server">

        <%-- ===== TELERIK GLOBAL ===== --%>
        <telerik:RadScriptManager
            ID="RadScriptManager1"
            runat="server"
            EnablePartialRendering="true"
            AsyncPostBackTimeout="300" />

        <telerik:RadAjaxManager ID="ram1" runat="server">
            <AjaxSettings>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <%-- Hidden : map JSON  Id-de-type → DurationMinutes --%>
        <asp:HiddenField ID="hfTypeDurations" runat="server" ClientIDMode="Static" />
        <%-- Hidden : « 1 » quand une plage est choisie (RDV existant, heure touchée dans l'agenda, plage cliquée) --%>
        <asp:HiddenField ID="hfChoisi" runat="server" ClientIDMode="Static" Value="0" />
        <asp:HiddenField ID="hfId" runat="server" Value="0" />

        <div class="nr">

            <%-- ===== ENTÊTE ===== --%>
            <div class="nr-tete">
                <div class="nr-ico" aria-hidden="true">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M10 15h4M12 13v4"/></svg>
                </div>
                <div>
                    <h1><asp:Literal ID="litTitle" runat="server" Text="Nouveau RDV" /></h1>
                    <div class="nr-sous"><asp:Literal ID="litRubrique" runat="server" /> · <%= T("9 h à 19 h","9 a.m. to 7 p.m.","9 h a 19 h") %></div>
                </div>
                <div class="nr-esp"></div>
                <asp:HyperLink ID="lnkBack" runat="server" CssClass="nr-x" onclick="return closeWin();">×</asp:HyperLink>
            </div>

            <div class="nr-corps">

                <%-- ===== GAUCHE : LES TROIS ÉTAPES ===== --%>
                <div class="nr-gauche">

                    <asp:Panel ID="pnlMsg" runat="server" Visible="false" CssClass="nr-msg">
                        <p id="pMsg" runat="server" class="msg"></p>
                    </asp:Panel>

                    <%-- 1. Client --%>
                    <div class="nr-etape">
                        <div class="nr-etape-t"><span class="nr-pastille" id="nrP1">1</span><%= T("Pour quel client ?","For which customer?","¿Para qué cliente?") %></div>
                        <div class="nr-etape-c field">
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlCustomer"
                                runat="server" DefaultMessage="Sélectionner…" Width="100%"
                                DropDownHeight="260px" Skin="Metro" OnClientSelectedIndexChanged="nrMaj" />
                        </div>
                    </div>

                    <%-- 2. Service et lieu --%>
                    <div class="nr-etape">
                        <div class="nr-etape-t"><span class="nr-pastille" id="nrP2">2</span><%= T("Quel service ?","Which service?","¿Qué servicio?") %></div>
                        <div class="nr-etape-c field">
                            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlType"
                                runat="server" DefaultMessage="Sélectionner…" Width="100%"
                                DropDownHeight="260px" Skin="Metro" OnClientSelectedIndexChanged="aeOnTypeChanged">
                            </telerik:RadDropDownList>
                            <%-- Les lieux du service choisi (Produits et services › Lieux), dessinés par nrLieux() --%>
                            <div class="nr-lieu" id="nrLieuRow" hidden>
                                <span class="nr-lieu-l"><%= T("Lieu","Location","Lugar") %></span>
                            </div>
                        </div>
                    </div>

                    <%-- 3. Quand : semaine, jour, plage libre --%>
                    <div class="nr-etape">
                        <div class="nr-etape-t"><span class="nr-pastille" id="nrP3">3</span><%= T("Quand ?","When?","¿Cuándo?") %></div>
                        <div class="nr-etape-c">
                            <select class="nr-sem" id="nrSem" aria-label="<%= T("Semaine","Week","Semana") %>"></select>
                            <div class="nr-jours" id="nrJours"></div>
                            <div id="nrPlages"></div>
                        </div>
                    </div>

                    <%-- Plus de détails : tous les champs de la fiche --%>
                    <details class="nr-plus" id="nrPlus" <%= If(pnlMsg.Visible, "open", "") %>>
                        <summary><%= T("Plus de détails (titre, employé, heures, récurrence…)","More details (title, employee, times, recurrence…)","Más detalles (título, empleado, horas, recurrencia…)") %></summary>
                        <div class="nr-grille">
                            <div class="field large">
                                <label><%= T("Titre","Title","Título") %></label>
                                <telerik:RadTextBox ID="txtTitle" runat="server" RenderMode="Lightweight" CssClass="rtbLike"
                                    EmptyMessage="Le service ou le client si vide" />
                            </div>
                            <div class="field">
                                <label><%= T("Employé","Employee","Empleado") %></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlEmployee"
                                    runat="server" DefaultMessage="Sélectionner…" Width="100%"
                                    DropDownHeight="200px" Skin="Metro" OnClientSelectedIndexChanged="nrMaj" />
                            </div>
                            <div class="field">
                                <label><%= T("Statut","Status","Estado") %></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlStatus"
                                    runat="server" DropDownHeight="200px" Skin="Metro" Width="100%">
                                    <Items>
                                        <telerik:DropDownListItem Value="Planifié" Text="Planifié" />
                                        <telerik:DropDownListItem Value="Confirmé" Text="Confirmé" />
                                        <telerik:DropDownListItem Value="Terminé"  Text="Terminé" />
                                        <telerik:DropDownListItem Value="Annulé"   Text="Annulé" />
                                        <telerik:DropDownListItem Value="NoShow"   Text="No-show" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>
                            <div class="field">
                                <label><%= T("Lieu","Location","Lugar") %></label>
                                <telerik:RadTextBox ID="txtLocation" runat="server" RenderMode="Lightweight" CssClass="rtbLike">
                                    <ClientEvents OnValueChanged="nrMaj" />
                                </telerik:RadTextBox>
                            </div>
                            <div class="field">
                                <label><%= T("Date de début","Start date","Fecha de inicio") %> *</label>
                                <telerik:RadDatePicker ID="rdpStart" runat="server"
                                    RenderMode="Lightweight" Skin="Metro" Width="100%">
                                    <DateInput DateFormat="yyyy-MM-dd" DisplayDateFormat="yyyy-MM-dd" />
                                    <ClientEvents OnDateSelected="aeOnStartChanged" />
                                </telerik:RadDatePicker>
                            </div>
                            <div class="field">
                                <label><%= T("Heure de début","Start time","Hora de inicio") %> *</label>
                                <telerik:RadTimePicker ID="rtpStart" runat="server"
                                    RenderMode="Lightweight" Skin="Metro" Width="100%">
                                    <DateInput DateFormat="HH:mm" DisplayDateFormat="HH:mm" />
                                    <TimeView Interval="00:15:00" StartTime="07:00:00" EndTime="21:00:00" />
                                    <ClientEvents OnDateSelected="aeOnStartChanged" />
                                </telerik:RadTimePicker>
                            </div>
                            <div class="field">
                                <label class="nr-coche">
                                    <asp:CheckBox ID="cbAllDay" runat="server" />
                                    <span><%= T("Toute la journée","All day","Todo el día") %></span>
                                </label>
                            </div>
                            <div class="field">
                                <label><%= T("Date de fin","End date","Fecha de fin") %> *</label>
                                <telerik:RadDatePicker ID="rdpEnd" runat="server"
                                    RenderMode="Lightweight" Skin="Metro" Width="100%">
                                    <DateInput DateFormat="yyyy-MM-dd" DisplayDateFormat="yyyy-MM-dd" />
                                    <ClientEvents OnDateSelected="nrMaj" />
                                </telerik:RadDatePicker>
                            </div>
                            <div class="field">
                                <label><%= T("Heure de fin","End time","Hora de fin") %> *</label>
                                <telerik:RadTimePicker ID="rtpEnd" runat="server"
                                    RenderMode="Lightweight" Skin="Metro" Width="100%">
                                    <DateInput DateFormat="HH:mm" DisplayDateFormat="HH:mm" />
                                    <TimeView Interval="00:15:00" StartTime="07:00:00" EndTime="21:00:00" />
                                    <ClientEvents OnDateSelected="nrMaj" />
                                </telerik:RadTimePicker>
                            </div>
                            <div class="field">
                                <label><%= T("Récurrence","Recurrence","Recurrencia") %></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlRecurrence"
                                    runat="server" DropDownHeight="200px" Skin="Metro" Width="100%">
                                    <Items>
                                        <telerik:DropDownListItem Value="" Text="Aucune" />
                                        <telerik:DropDownListItem Value="FREQ=DAILY;INTERVAL=1"   Text="Tous les jours" />
                                        <telerik:DropDownListItem Value="FREQ=WEEKLY;INTERVAL=1"  Text="Toutes les semaines" />
                                        <telerik:DropDownListItem Value="FREQ=WEEKLY;INTERVAL=2"  Text="Toutes les 2 semaines" />
                                        <telerik:DropDownListItem Value="FREQ=MONTHLY;INTERVAL=1" Text="Tous les mois" />
                                        <telerik:DropDownListItem Value="FREQ=YEARLY;INTERVAL=1"  Text="Tous les ans" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>
                            <div class="field">
                                <label><%= T("Rappel","Reminder","Recordatorio") %></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlReminder"
                                    runat="server" DropDownHeight="200px" Skin="Metro" Width="100%"
                                    OnClientSelectedIndexChanged="nrMaj">
                                    <Items>
                                        <telerik:DropDownListItem Value=""    Text="Aucun" />
                                        <telerik:DropDownListItem Value="5"   Text="5 minutes avant" />
                                        <telerik:DropDownListItem Value="15"  Text="15 minutes avant" />
                                        <telerik:DropDownListItem Value="30"  Text="30 minutes avant" />
                                        <telerik:DropDownListItem Value="60"  Text="1 heure avant" />
                                        <telerik:DropDownListItem Value="1440" Text="1 jour avant" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>
                        </div>
                    </details>

                </div>

                <%-- ===== DROITE : RÉSUMÉ ET CONFIRMATION ===== --%>
                <aside class="nr-droite">
                    <div class="nr-droite-t"><%= T("Résumé","Summary","Resumen") %></div>

                    <div class="nr-boite">
                        <div class="nr-nom" id="nrNom"></div>
                        <div class="nr-svc" id="nrSvc"></div>
                        <div class="nr-ligne">
                            <div class="nr-ligne-ico" aria-hidden="true"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/></svg></div>
                            <div><div class="nr-k"><%= T("Quand","When","Cuándo") %></div><div class="nr-v" id="nrQuand"></div></div>
                        </div>
                        <div class="nr-ligne">
                            <div class="nr-ligne-ico" aria-hidden="true"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 21s-7-6.2-7-11a7 7 0 0 1 14 0c0 4.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/></svg></div>
                            <div><div class="nr-k"><%= T("Lieu","Location","Lugar") %></div><div class="nr-v" id="nrLieu"></div></div>
                        </div>
                        <div class="nr-ligne">
                            <div class="nr-ligne-ico" aria-hidden="true"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg></div>
                            <div><div class="nr-k"><%= T("Durée","Duration","Duración") %></div><div class="nr-v" id="nrDuree"></div></div>
                        </div>
                        <div class="nr-ligne" id="nrMontantLigne" hidden>
                            <div class="nr-ligne-ico" aria-hidden="true"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/></svg></div>
                            <div><div class="nr-k"><%= T("Montant prévu","Expected amount","Importe previsto") %></div><div class="nr-v" id="nrMontant"></div></div>
                        </div>
                    </div>

                    <label class="nr-boite nr-rappel">
                        <input type="checkbox" id="nrRappel" />
                        <%= T("Rappel 24 h avant","Reminder 24 h before","Recordatorio 24 h antes") %>
                    </label>

                    <div class="nr-note field">
                        <telerik:RadTextBox ID="txtDescription" Width="100%" runat="server"
                            RenderMode="Lightweight" CssClass="rtbLike"
                            TextMode="MultiLine" Rows="3" EmptyMessage="Note pour le RDV (facultatif)" />
                    </div>

                    <div class="nr-esp"></div>
                    <asp:Button ID="btnSave" runat="server" Text="Confirmer le RDV" CssClass="nr-cta" ClientIDMode="Static" />
                    <div class="nr-aide" id="nrAide"></div>
                    <div class="nr-autres">
                        <asp:Button ID="btnInvoice" runat="server" Text="Facturer" CssClass="nr-lien" ClientIDMode="Static"
                            ToolTip="Sauvegarder le rendez-vous et créer une facture" />
                        <asp:Button ID="btnDelete" runat="server" Text="Supprimer"
                            CssClass="nr-lien danger" Visible="false"
                            OnClientClick="return confirm('Supprimer ce rendez-vous ?');" />
                    </div>
                </aside>
            </div>
        </div>


        <%-- =====================================================
             JAVASCRIPT
        ===================================================== --%>
        <script type="text/javascript">

            // ============================================================
            // Récupère les vrais ClientID (auto-générés par ASP.NET)
            // ============================================================
            var AE_IDS = {
                rdpStart: '<%= rdpStart.ClientID %>',
                rtpStart: '<%= rtpStart.ClientID %>',
                rdpEnd:   '<%= rdpEnd.ClientID %>',
                rtpEnd:   '<%= rtpEnd.ClientID %>',
                rddlType: '<%= rddlType.ClientID %>',
                rddlCustomer: '<%= rddlCustomer.ClientID %>',
                rddlEmployee: '<%= rddlEmployee.ClientID %>',
                rddlReminder: '<%= rddlReminder.ClientID %>',
                txtLocation: '<%= txtLocation.ClientID %>',
                cbAllDay: '<%= cbAllDay.ClientID %>',
                hfTypeDurations: '<%= hfTypeDurations.ClientID %>'
            };

            // Semaines, RDV déjà pris et textes (wbfAppointmentEdit.BatirPlages)
            var NR = <%= PlagesJson %>;

            // ============================================================
            // Map des durées par type
            // ============================================================
            var AE_TYPE_DURATIONS = {};
            try {
                var raw = document.getElementById(AE_IDS.hfTypeDurations).value || '{}';
                AE_TYPE_DURATIONS = JSON.parse(raw);
            } catch (e) {
                AE_TYPE_DURATIONS = {};
            }

            // ============================================================
            // État
            // ============================================================
            var AE_lastStart = null;   // valeur de Début avant le changement
            var AE_busy = false;       // évite les boucles

            // ============================================================
            // Helpers
            // ============================================================
            function aeGetDateTime(dpId, tpId) {
                var dp = $find(dpId);
                var tp = $find(tpId);
                if (!dp || !tp) return null;
                var d = dp.get_selectedDate();
                var t = tp.get_selectedDate();
                if (!d) return null;
                return new Date(
                    d.getFullYear(), d.getMonth(), d.getDate(),
                    t ? t.getHours() : 0,
                    t ? t.getMinutes() : 0,
                    0, 0
                );
            }

            function aeSetDateTime(dpId, tpId, dt) {
                var dp = $find(dpId);
                var tp = $find(tpId);
                if (!dp || !tp || !dt) return;
                dp.set_selectedDate(new Date(dt.getFullYear(), dt.getMonth(), dt.getDate()));
                tp.set_selectedDate(new Date(1980, 0, 1, dt.getHours(), dt.getMinutes(), 0));
            }

            // ============================================================
            // Handler appelé par RadDatePicker / RadTimePicker (Début)
            //   ClientEvents OnDateSelected="aeOnStartChanged"
            // ============================================================
            function aeOnStartChanged(sender, args) {
                if (AE_busy) return;

                // Différé : laisse Telerik finir d'appliquer ses changements
                setTimeout(function () {
                    AE_busy = true;
                    try {
                        var newStart = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                        if (!newStart) return;

                        var oldEnd = aeGetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd);

                        if (AE_lastStart && oldEnd) {
                            // Décale la fin du même delta → la durée est préservée
                            var delta = newStart.getTime() - AE_lastStart.getTime();
                            var newEnd = new Date(oldEnd.getTime() + delta);
                            aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd, newEnd);
                        } else if (oldEnd && oldEnd <= newStart) {
                            aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd,
                                new Date(newStart.getTime() + 60 * 60000));
                        }

                        AE_lastStart = newStart;
                    } finally {
                        AE_busy = false;
                    }
                    // Une heure saisie à la main vaut une plage choisie
                    nrChoisir(true);
                }, 50);
            }

            // ============================================================
            // Handler appelé par RadDropDownList (Type)
            //   ClientEvents OnSelectedIndexChanged="aeOnTypeChanged"
            // ============================================================
            function aeOnTypeChanged(sender, args) {
                if (AE_busy) return;

                var item = sender.get_selectedItem();
                var typeId = item ? item.get_value() : '';
                var durMin = parseInt(AE_TYPE_DURATIONS[typeId], 10);
                var startDt = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);

                if (durMin > 0 && startDt) {
                    AE_busy = true;
                    try {
                        var newEnd = new Date(startDt.getTime() + durMin * 60000);
                        aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd, newEnd);
                    } finally {
                        AE_busy = false;
                    }
                }
                // La durée change : les plages libres aussi
                nrMaj();
            }

            // ============================================================
            // Mémoriser la valeur initiale du Début pour le calcul du delta
            // ============================================================
            function aeInitLastStart() {
                AE_lastStart = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
            }

            // ============================================================
            // Étapes, plages libres et résumé
            // ============================================================
            var NR_sem = 0;          // semaine affichée (0 = celle du début du RDV)
            var NR_jour = null;      // jour affiché, 'yyyy-MM-dd'
            var NR_texteCta = '';    // texte du bouton une fois la plage choisie
            var NR_LOC = { fr: 'fr-CA', en: 'en-CA', es: 'es' };

            function nrLoc() { return NR_LOC[NR && NR.lang] || 'fr-CA'; }
            function nrIso(d) {
                return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
            }
            function nrDate(iso) { var p = iso.split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
            function nrAjout(d, n) { var x = new Date(d.getTime()); x.setDate(x.getDate() + n); return x; }
            function nrCourt(d) { return d.toLocaleDateString(nrLoc(), { day: 'numeric', month: 'short' }); }

            // 16 h 15 (fr, es) ou 4:15 p.m. (en)
            function nrHeure(min) {
                var h = Math.floor(min / 60), m = min % 60;
                if (NR && NR.lang === 'en') {
                    return (h % 12 || 12) + ':' + ('0' + m).slice(-2) + (h < 12 ? ' a.m.' : ' p.m.');
                }
                return h + ' h' + (m ? ' ' + ('0' + m).slice(-2) : '');
            }
            function nrDureeTxt(min) {
                if (min < 60) return min + ' min';
                var h = Math.floor(min / 60), m = min % 60;
                return h + ' h' + (m ? ' ' + ('0' + m).slice(-2) : '');
            }

            function nrDdl(id) { var c = $find(id); var it = c && c.get_selectedItem(); return it && it.get_value() ? it : null; }
            function nrEstChoisi() { return document.getElementById('hfChoisi').value === '1'; }

            function nrDuree() {
                var s = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                var e = aeGetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd);
                var d = (s && e) ? Math.round((e - s) / 60000) : 0;
                return d > 0 ? d : 60;
            }

            // Les RDV qui comptent : ceux de l'employé choisi et ceux sans employé (tous, si aucun employé)
            function nrPris(jour) {
                var emp = nrDdl(AE_IDS.rddlEmployee);
                emp = emp ? emp.get_value() : '';
                return (NR.pris || []).filter(function (r) {
                    return r.j === jour && (!emp || !r.emp || r.emp === emp);
                });
            }

            function nrPlagesDuJour(jour, duree) {
                var out = [], pris = nrPris(jour), pas = 15;
                if (jour < NR.aujourdhui) return out;
                for (var t = NR.ouv; t + duree <= NR.ferm; t += pas) {
                    if (jour === NR.aujourdhui && t < NR.maintenant) continue;
                    var libre = pris.every(function (r) { return t + duree <= r.deb || t >= r.fin; });
                    if (libre) out.push(t);
                }
                return out;
            }

            // Jours ouvrables (lun.-ven.) d'une semaine, à partir d'aujourd'hui
            function nrJours(sem) {
                var lundi = nrAjout(nrDate(NR.base), 7 * sem), out = [];
                for (var i = 0; i < 5; i++) {
                    var iso = nrIso(nrAjout(lundi, i));
                    if (iso >= NR.aujourdhui) out.push(iso);
                }
                return out;
            }

            function nrSemaines(duree) {
                var sel = document.getElementById('nrSem'), html = '';
                var lundiAuj = nrIso(nrAjout(nrDate(NR.aujourdhui), -((nrDate(NR.aujourdhui).getDay() + 6) % 7)));
                for (var s = 0; s < NR.semaines; s++) {
                    var lundi = nrAjout(nrDate(NR.base), 7 * s), iso = nrIso(lundi);
                    var nb = 0;
                    nrJours(s).forEach(function (j) { nb += nrPlagesDuJour(j, duree).length; });
                    var nom = iso === lundiAuj ? NR.t.cetteSemaine
                        : iso === nrIso(nrAjout(nrDate(lundiAuj), 7)) ? NR.t.semProchaine
                        : NR.t.semDu + ' ' + nrCourt(lundi);
                    var etendue = lundi.getDate() + ' – ' + nrCourt(nrAjout(lundi, 4));
                    html += '<option value="' + s + '"' + (s === NR_sem ? ' selected' : '') + '>' +
                        nom + ' · ' + etendue + ' · ' + nb + ' ' + (nb === 1 ? NR.t.libre1 : NR.t.libres) + '</option>';
                }
                sel.innerHTML = html;
            }

            function nrDessinerJours(duree) {
                var box = document.getElementById('nrJours'), jours = nrJours(NR_sem);
                if (jours.indexOf(NR_jour) < 0) {
                    // Le premier jour qui a une plage libre, sinon le premier jour
                    NR_jour = jours.filter(function (j) { return nrPlagesDuJour(j, duree).length; })[0] || jours[0] || null;
                }
                box.innerHTML = '';
                jours.forEach(function (j) {
                    var d = nrDate(j), nb = nrPlagesDuJour(j, duree).length;
                    var b = document.createElement('button');
                    b.type = 'button';
                    b.className = 'nr-jour' + (j === NR_jour ? ' on' : '') + (nb ? '' : ' plein');
                    b.innerHTML = '<span class="j1">' + (j === NR.aujourdhui ? NR.t.auj : d.toLocaleDateString(nrLoc(), { weekday: 'short' })) + '</span>' +
                        '<span class="j2">' + d.getDate() + '</span>' +
                        '<span class="j3">' + (nb ? nb + ' ' + NR.t.libresCourt : NR.t.complet) + '</span>';
                    b.onclick = function () { NR_jour = j; nrMaj(); };
                    box.appendChild(b);
                });
            }

            function nrDessinerPlages(duree) {
                var box = document.getElementById('nrPlages');
                box.innerHTML = '';
                if (!NR_jour) { box.innerHTML = '<div class="nr-vide">' + NR.t.aucune + '</div>'; return; }

                var plages = nrPlagesDuJour(NR_jour, duree);
                var debut = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart), actuelle = -1;
                if (nrEstChoisi() && debut && nrIso(debut) === NR_jour) {
                    actuelle = debut.getHours() * 60 + debut.getMinutes();
                    if (plages.indexOf(actuelle) < 0) { plages.push(actuelle); plages.sort(function (a, b) { return a - b; }); }
                }
                if (!plages.length) { box.innerHTML = '<div class="nr-vide">' + NR.t.aucune + '</div>'; return; }

                [[0, 12 * 60, NR.t.matin], [12 * 60, 17 * 60, NR.t.apm], [17 * 60, 24 * 60, NR.t.soir]].forEach(function (p) {
                    var du = plages.filter(function (t) { return t >= p[0] && t < p[1]; });
                    if (!du.length) return;
                    var titre = document.createElement('div');
                    titre.className = 'nr-periode'; titre.textContent = p[2];
                    var grille = document.createElement('div');
                    grille.className = 'nr-plages';
                    du.forEach(function (t) {
                        var b = document.createElement('button');
                        b.type = 'button';
                        b.className = 'nr-plage' + (t === actuelle ? ' on' : '');
                        b.textContent = nrHeure(t);
                        b.onclick = function () { nrPrendre(NR_jour, t, duree); };
                        grille.appendChild(b);
                    });
                    box.appendChild(titre); box.appendChild(grille);
                });
            }

            // Une plage cliquée : début et fin dans les champs de la fiche
            function nrPrendre(jour, min, duree) {
                var d = nrDate(jour);
                var deb = new Date(d.getFullYear(), d.getMonth(), d.getDate(), Math.floor(min / 60), min % 60);
                AE_busy = true;
                try {
                    aeSetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart, deb);
                    aeSetDateTime(AE_IDS.rdpEnd, AE_IDS.rtpEnd, new Date(deb.getTime() + duree * 60000));
                    AE_lastStart = deb;
                } finally {
                    AE_busy = false;
                }
                var cb = document.getElementById(AE_IDS.cbAllDay);
                if (cb) cb.checked = false;
                nrChoisir(false);
            }

            function nrChoisir(suivreDebut) {
                document.getElementById('hfChoisi').value = '1';
                if (suivreDebut) nrSuivreDebut();
                nrMaj();
            }

            // Montre la semaine et le jour du début du RDV
            function nrSuivreDebut() {
                var debut = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                if (!debut || !NR) return;
                var ecart = Math.floor((nrDate(nrIso(debut)) - nrDate(NR.base)) / (7 * 86400000));
                if (ecart >= 0 && ecart < NR.semaines) { NR_sem = ecart; NR_jour = nrIso(debut); }
            }

            function nrResume(duree) {
                var cli = nrDdl(AE_IDS.rddlCustomer), typ = nrDdl(AE_IDS.rddlType), emp = nrDdl(AE_IDS.rddlEmployee);
                var choisi = nrEstChoisi();

                document.getElementById('nrP1').className = 'nr-pastille' + (cli ? ' ok' : '');
                document.getElementById('nrP1').textContent = cli ? '✓' : '1';
                document.getElementById('nrP2').className = 'nr-pastille' + (typ ? ' ok' : '');
                document.getElementById('nrP2').textContent = typ ? '✓' : '2';
                document.getElementById('nrP3').className = 'nr-pastille' + (choisi ? ' ok' : '');
                document.getElementById('nrP3').textContent = choisi ? '✓' : '3';

                var service = typ && NR.services ? NR.services[typ.get_value()] : null;
                document.getElementById('nrNom').textContent = cli ? cli.get_text() : NR.t.aucunClient;
                var svc = typ ? (service ? service.nom : typ.get_text()) + ' · ' + nrDureeTxt(duree) : NR.t.aucunService;
                if (emp) svc += ' · ' + NR.t.avec + ' ' + emp.get_text();
                document.getElementById('nrSvc').textContent = svc;

                var quand = document.getElementById('nrQuand');
                var debut = aeGetDateTime(AE_IDS.rdpStart, AE_IDS.rtpStart);
                if (choisi && debut) {
                    var iso = nrIso(debut), min = debut.getHours() * 60 + debut.getMinutes();
                    var jour = iso === NR.aujourdhui ? NR.t.aujLong + ' ' + nrCourt(debut)
                        : debut.toLocaleDateString(nrLoc(), { weekday: 'long', day: 'numeric', month: 'short' });
                    var cb = document.getElementById(AE_IDS.cbAllDay);
                    quand.textContent = jour.charAt(0).toUpperCase() + jour.slice(1) +
                        (cb && cb.checked ? '' : ' · ' + nrHeure(min) + ' – ' + nrHeure(min + duree));
                    quand.className = 'nr-v';
                } else {
                    quand.textContent = NR.t.choisir;
                    quand.className = 'nr-v attente';
                }

                var loc = $find(AE_IDS.txtLocation), lieu = loc ? loc.get_value() : '';
                document.getElementById('nrLieu').textContent = lieu || '—';
                nrLieux(typ ? typ.get_value() : '', lieu);
                document.getElementById('nrDuree').textContent = nrDureeTxt(duree);

                // Montant prévu : le prix du service, avant taxes
                var prix = service ? Number(service.prix) || 0 : 0;
                document.getElementById('nrMontantLigne').hidden = !(prix > 0);
                document.getElementById('nrMontant').textContent = prix > 0
                    ? prix.toLocaleString(nrLoc(), { style: 'currency', currency: 'CAD' }) + ' ' + NR.t.avantTaxes : '';

                var rap = $find(AE_IDS.rddlReminder);
                document.getElementById('nrRappel').checked = !!(rap && rap.get_selectedItem() && rap.get_selectedItem().get_value() === '1440');

                var cta = document.getElementById('btnSave'), fact = document.getElementById('btnInvoice');
                cta.disabled = !choisi;
                cta.value = choisi ? NR_texteCta : NR.t.choisir;
                if (fact) fact.disabled = !choisi;
                document.getElementById('nrAide').textContent = choisi ? NR.t.pret : NR.t.reste;
            }

            // Les lieux cochés dans la fiche du service ; aucun lieu coché ou aucun service : aucun lieu
            function nrLieuxDuService(typeId) {
                var s = typeId && NR.services ? NR.services[typeId] : null;
                if (!s || !s.lieux || !s.lieux.length) return [];
                return (NR.lieux || []).filter(function (l) { return s.lieux.indexOf(l.id) >= 0; });
            }

            // Une puce par lieu ; toucher une puce pose le lieu du RDV
            function nrLieux(typeId, lieuActuel) {
                var rangee = document.getElementById('nrLieuRow');
                Array.prototype.forEach.call(rangee.querySelectorAll('.nr-puce'), function (p) { p.remove(); });
                var liste = nrLieuxDuService(typeId);
                rangee.hidden = !liste.length;
                liste.forEach(function (l) {
                    var b = document.createElement('button');
                    b.type = 'button';
                    b.className = 'nr-puce' + (l.nom === lieuActuel ? ' on' : '');
                    b.textContent = l.nom;
                    if (l.adr) b.title = l.adr;
                    b.onclick = function () {
                        var loc = $find(AE_IDS.txtLocation);
                        if (loc) loc.set_value(l.nom);
                        nrMaj();
                    };
                    rangee.appendChild(b);
                });
                // Un seul lieu offert et aucun lieu posé : c'est celui-là
                if (liste.length === 1 && !lieuActuel) {
                    var loc = $find(AE_IDS.txtLocation);
                    if (loc) { loc.set_value(liste[0].nom); document.getElementById('nrLieu').textContent = liste[0].nom; rangee.querySelector('.nr-puce').classList.add('on'); }
                }
            }

            function nrMaj() {
                if (!NR) return;
                var duree = nrDuree();
                nrSemaines(duree);
                nrDessinerJours(duree);
                nrDessinerPlages(duree);
                nrResume(duree);
            }

            function nrInit() {
                aeInitLastStart();
                if (!NR) return;
                NR_texteCta = document.getElementById('btnSave').value;
                nrSuivreDebut();

                document.getElementById('nrSem').onchange = function () {
                    NR_sem = parseInt(this.value, 10) || 0; NR_jour = null; nrMaj();
                };
                document.getElementById('nrRappel').onchange = function () {
                    var rap = $find(AE_IDS.rddlReminder);
                    var it = rap && rap.findItemByValue(this.checked ? '1440' : '');
                    if (it) it.select();
                    nrMaj();
                };
                var cb = document.getElementById(AE_IDS.cbAllDay);
                if (cb) cb.onclick = nrMaj;
                nrMaj();
            }

            if (typeof Sys !== 'undefined' && Sys.Application) {
                Sys.Application.add_load(nrInit);
            } else {
                document.addEventListener('DOMContentLoaded', nrInit);
            }

            // ============================================================
            // Fenêtre parente
            // ============================================================
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
                return false;
            }

        </script>

    </form>
</body>
</html>
