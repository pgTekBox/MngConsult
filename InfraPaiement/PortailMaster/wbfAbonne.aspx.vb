Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Création / édition d'un abonné.
'''   wbfAbonne.aspx            -> création
'''   wbfAbonne.aspx?id=N       -> édition de l'abonné N
''' </summary>
Public Class wbfAbonne
    Inherits clsData

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Le master redirige les non-authentifiés ; on évite tout accès BD ici.
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            If AbonneId > 0 Then
                LoadAbonne(AbonneId)
            End If
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Abonné enregistré avec succès."
            End If
            Select Case Request.QueryString("off")
                Case "closed" : pnlOk.Visible = True : litOk.Text = "Compte clôturé : accès désactivés, contreparties gelées."
                Case "react" : pnlOk.Visible = True : litOk.Text = "Compte réactivé : statut Actif, accès des utilisateurs rétabli. Ré-émettez les clés d'API et réactivez le webhook / les contreparties au besoin."
                Case "anon" : pnlOk.Visible = True : litOk.Text = "Données personnelles anonymisées (grand livre et paiements conservés)."
            End Select
            Select Case Request.QueryString("kyb")
                Case "Verified" : pnlOk.Visible = True : litOk.Text = "Vérification KYB : ✔ Vérifié — statut KYB mis à « Vérifié »."
                Case "Rejected" : pnlError.Visible = True : litError.Text = "Vérification KYB : ✘ Rejeté — statut KYB mis à « Rejeté »."
                Case "Review" : pnlOk.Visible = True : litOk.Text = "Vérification KYB : revue requise — statut KYB mis à « En cours »."
            End Select
        End If
    End Sub

    Private Sub LoadAbonne(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0005GetAbonne", p)

            If ds.Tables(0).Rows.Count = 0 Then
                ShowError("Abonné introuvable.")
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)

            litTitle.Text = Server.HtmlEncode(Val(r, "RaisonSociale"))
            litMeta.Text = "Réf. locataire : " & Val(r, "TenantGUID") &
                           " · Créé le " & FormatDate(r("CreatedUtc"))

            ' Accès aux clients et au grand livre de cet abonné (édition uniquement).
            lnkClients.Visible = True
            lnkClients.Text = "Clients"
            lnkClients.NavigateUrl = "wbfClients.aspx?abonneId=" & id
            lnkGrandLivre.Visible = True
            lnkGrandLivre.Text = "Grand livre"
            lnkGrandLivre.NavigateUrl = "wbfGrandLivre.aspx?abonneId=" & id
            lnkPaiements.Visible = True
            lnkPaiements.Text = "Paiements"
            lnkPaiements.NavigateUrl = "wbfPaiements.aspx?abonneId=" & id
            lnkFournisseurs.Visible = True
            lnkFournisseurs.Text = "Fournisseurs"
            lnkFournisseurs.NavigateUrl = "wbfFournisseurs.aspx?abonneId=" & id
            lnkDecaissements.Visible = True
            lnkDecaissements.Text = "Décaissements"
            lnkDecaissements.NavigateUrl = "wbfDecaissements.aspx?abonneId=" & id
            lnkInterac.Visible = True
            lnkInterac.Text = "Interac"
            lnkInterac.NavigateUrl = "wbfInterac.aspx?abonneId=" & id
            lnkApiKeys.Visible = True
            lnkApiKeys.Text = "Clés API"
            lnkApiKeys.NavigateUrl = "wbfApiKeys.aspx?abonneId=" & id
            lnkWebhooks.Visible = True
            lnkWebhooks.Text = "Webhooks"
            lnkWebhooks.NavigateUrl = "wbfWebhooks.aspx?abonneId=" & id
            lnkExport.Visible = True
            lnkExport.Text = "Exporter (JSON)"
            lnkExport.NavigateUrl = "AbonneExport.ashx?abonneId=" & id
            lnkExport.ToolTip = "Télécharger toutes les données de l'abonné (portabilité RGPD), sans secrets."

            tbRaisonSociale.Text = Val(r, "RaisonSociale")
            tbNomAffichage.Text = Val(r, "NomAffichage")
            tbNumeroEntreprise.Text = Val(r, "NumeroEntreprise")
            tbCourriel.Text = Val(r, "CourrielContact")
            tbTelephone.Text = Val(r, "Telephone")
            tbAdresse1.Text = Val(r, "Adresse1")
            tbAdresse2.Text = Val(r, "Adresse2")
            tbVille.Text = Val(r, "Ville")
            tbProvince.Text = Val(r, "Province")
            tbCodePostal.Text = Val(r, "CodePostal")
            tbPays.Text = Val(r, "Pays")
            SelectValue(ddlDevise, Val(r, "Devise"))
            SelectValue(ddlStatut, Val(r, "Statut"))
            SelectValue(ddlKyb, Val(r, "StatutKYB"))
            tbNotes.Text = Val(r, "Notes")

            BindOffboard(id)
            BindKyb(id)
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("LoadAbonne: " & ex.Message)
        End Try
    End Sub

    ' =====================================================================
    ' KYB (Know Your Business)
    ' =====================================================================

    Private Sub BindKyb(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", id))
            p.Add(New SqlParameter("@Top", 15))
            Dim t As DataTable = ExecuteSQLds("s0102ListKybChecks", p).Tables(0)
            Dim sb As New System.Text.StringBuilder()
            If t.Rows.Count = 0 Then
                sb.Append("<div class=""meta"">Aucune vérification KYB effectuée. Le statut KYB actuel est modifiable manuellement dans « Plateforme » ci-dessus.</div>")
            Else
                sb.Append("<div class=""table-wrap""><table class=""grid""><thead><tr><th>Fournisseur</th><th>Résultat</th><th class=""num"">Score</th><th>Registre</th><th>Sanctions</th><th>Adresse</th><th>Détail</th><th>Quand</th></tr></thead><tbody>")
                For Each r As DataRow In t.Rows
                    sb.Append("<tr><td class=""mono"">").Append(Server.HtmlEncode(Val(r, "Provider"))).Append("</td>")
                    sb.Append("<td><span class=""badge ").Append(KybBadge(Val(r, "Status"))).Append(""">").Append(Server.HtmlEncode(Val(r, "Status"))).Append("</span></td>")
                    sb.Append("<td class=""num"">").Append(If(IsDBNull(r("Score")), "—", r("Score").ToString())).Append("</td>")
                    sb.Append("<td>").Append(Flag(r("RegistryMatch"))).Append("</td>")
                    sb.Append("<td>").Append(Flag(r("WatchlistClear"))).Append("</td>")
                    sb.Append("<td>").Append(Flag(r("AddressValid"))).Append("</td>")
                    sb.Append("<td class=""muted"">").Append(Server.HtmlEncode(Val(r, "Message"))).Append("</td>")
                    sb.Append("<td class=""muted"">").Append(FormatDt(r("Utc"))).Append("</td></tr>")
                Next
                sb.Append("</tbody></table></div>")
            End If
            litKyb.Text = sb.ToString()
            pnlKyb.Visible = True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("BindKyb: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnRunKyb_Click(sender As Object, e As EventArgs)
        If AbonneId <= 0 Then Return
        Try
            Dim res As KybResult = clsKyb.RunCheck(AbonneId, AdminId, AdminEmail, Request.UserHostAddress)
            Response.Redirect("wbfAbonne.aspx?id=" & AbonneId & "&kyb=" & res.Status)
        Catch ex As Exception
            ShowError("Vérification KYB impossible : " & ex.Message)
            LoadAbonne(AbonneId)
        End Try
    End Sub

    Private Function KybBadge(status As String) As String
        Select Case status
            Case "Verified" : Return "badge-verifie"
            Case "Rejected" : Return "badge-rejete"
            Case "Review" : Return "badge-encours"
            Case Else : Return "badge-nondebute"
        End Select
    End Function

    Private Function Flag(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return "<span class=""muted"">—</span>"
        Return If(CBool(o), "<span style=""color:var(--ok);font-weight:800"">✔</span>", "<span style=""color:var(--danger);font-weight:800"">✘</span>")
    End Function

    ' =====================================================================
    ' Offboarding (clôture + anonymisation)
    ' =====================================================================

    ''' <summary>Affiche l'état de préparation à la clôture (soldes, en-cours,
    ''' accès) et pilote la visibilité des boutons Clôturer / Anonymiser.</summary>
    Private Sub BindOffboard(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", id))
            Dim t As DataTable = ExecuteSQLds("s0087GetOffboardPreflight", p).Tables(0)
            If t.Rows.Count = 0 Then Return
            Dim r As DataRow = t.Rows(0)

            Dim isClosed As Boolean = ToBool(r("IsClosed"))
            Dim isAnon As Boolean = ToBool(r("IsAnonymized"))
            Dim canClose As Boolean = ToBool(r("CanClose"))

            Dim sb As New System.Text.StringBuilder()
            sb.Append("<div class=""form-grid"">")
            sb.Append(Kpi("Solde disponible", Money(r("SoldeCents"))))
            sb.Append(Kpi("Réservé", Money(r("ReserveCents"))))
            sb.Append(Kpi("EFT entrant en cours", Money(r("EftInCents"))))
            sb.Append(Kpi("EFT sortant en cours", Money(r("EftOutCents"))))
            sb.Append(Kpi("Paiements en cours (Initié)", CInt(r("InFlightCount")).ToString()))
            sb.Append(Kpi("Utilisateurs actifs", CInt(r("ActiveUsers")).ToString()))
            sb.Append(Kpi("Clés d'API actives", CInt(r("ActiveApiKeys")).ToString()))
            sb.Append(Kpi("Clients / Fournisseurs", CInt(r("ClientCount")).ToString() & " / " & CInt(r("FournisseurCount")).ToString()))
            sb.Append("</div>")

            If isAnon Then
                sb.Append("<div class=""msg-ok"" style=""margin-top:14px"">Compte clôturé et <strong>anonymisé</strong> le " & FormatDt(r("AnonymizedUtc")) & ". Aucune donnée personnelle résiduelle.</div>")
            ElseIf isClosed Then
                sb.Append("<div class=""msg-ok"" style=""margin-top:14px"">Compte <strong>clôturé</strong> le " & FormatDt(r("ClosedUtc")) & ". Vous pouvez le <strong>réactiver</strong>, ou anonymiser les données personnelles (irréversible, après la période de conservation légale).</div>")
            ElseIf canClose Then
                sb.Append("<div class=""msg-ok"" style=""margin-top:14px"">Prêt à être clôturé : aucun fonds ni paiement en cours.</div>")
            Else
                sb.Append("<div class=""msg-err"" style=""margin-top:14px"">Clôture bloquée : régularisez les fonds détenus et les paiements en cours avant de clôturer.</div>")
            End If
            litPreflight.Text = sb.ToString()

            ' Boutons : Clôturer si pas encore fermé (activé seulement si prêt) ;
            ' Anonymiser une fois fermé et pas déjà anonymisé.
            btnClose.Visible = Not isClosed
            btnClose.Enabled = canClose
            btnReactivate.Visible = isClosed AndAlso Not isAnon
            btnAnonymize.Visible = isClosed AndAlso Not isAnon

            litAudit.Text = AuditHistoryHtml(id)
            pnlOffboard.Visible = True
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("BindOffboard: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnClose_Click(sender As Object, e As EventArgs)
        If AbonneId <= 0 Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            ExecuteSQL("s0088OffboardAbonne", p)
            Audit("Offboard")
            Response.Redirect("wbfAbonne.aspx?id=" & AbonneId & "&off=closed")
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            LoadAbonne(AbonneId)
        Catch ex As Exception
            ShowError("Clôture impossible.")
            System.Diagnostics.Debug.WriteLine("Offboard close: " & ex.Message)
            LoadAbonne(AbonneId)
        End Try
    End Sub

    Protected Sub btnReactivate_Click(sender As Object, e As EventArgs)
        If AbonneId <= 0 Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            ExecuteSQL("s0090ReactivateAbonne", p)
            Audit("Reactivate")
            Response.Redirect("wbfAbonne.aspx?id=" & AbonneId & "&off=react")
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            LoadAbonne(AbonneId)
        Catch ex As Exception
            ShowError("Réactivation impossible.")
            System.Diagnostics.Debug.WriteLine("Offboard react: " & ex.Message)
            LoadAbonne(AbonneId)
        End Try
    End Sub

    Protected Sub btnAnonymize_Click(sender As Object, e As EventArgs)
        If AbonneId <= 0 Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Audit("Anonymize")   ' avant le scrub : le nom cible est encore lisible
            ExecuteSQL("s0089AnonymizeAbonne", p)
            Response.Redirect("wbfAbonne.aspx?id=" & AbonneId & "&off=anon")
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            LoadAbonne(AbonneId)
        Catch ex As Exception
            ShowError("Anonymisation impossible.")
            System.Diagnostics.Debug.WriteLine("Offboard anon: " & ex.Message)
            LoadAbonne(AbonneId)
        End Try
    End Sub

    ''' <summary>Lit la fiche actuelle d'un abonné (pour détecter les changements
    ''' de statut avant enregistrement). Nothing si introuvable/erreur.</summary>
    Private Function GetCurrentAbonneRow(id As Integer) As DataRow
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0005GetAbonne", p)
            If ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GetCurrentAbonneRow: " & ex.Message)
        End Try
        Return Nothing
    End Function

    ''' <summary>Enregistre une action sensible dans le journal d'audit.</summary>
    Private Sub Audit(action As String)
        Dim nom As String = If(tbRaisonSociale.Text, "").Trim()
        clsAudit.Write(AdminId, AdminEmail, action, "Abonne", AbonneId, nom, Nothing, Request.UserHostAddress)
    End Sub

    ''' <summary>Rend l'historique d'audit récent de cet abonné.</summary>
    Private Function AuditHistoryHtml(id As Integer) As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@TargetType", "Abonne"))
            p.Add(New SqlParameter("@TargetId", id))
            p.Add(New SqlParameter("@Action", DBNull.Value))
            p.Add(New SqlParameter("@Search", DBNull.Value))
            p.Add(New SqlParameter("@Top", 20))
            Dim t As DataTable = ExecuteSQLds("s0093ListAuditLog", p).Tables(0)
            Dim sb As New System.Text.StringBuilder()
            sb.Append("<div class=""section-title"" style=""margin-top:22px"">Journal d'audit</div>")
            If t.Rows.Count = 0 Then
                sb.Append("<div class=""meta"">Aucune action sensible enregistrée pour cet abonné.</div>")
                Return sb.ToString()
            End If
            sb.Append("<div class=""table-wrap""><table class=""grid""><thead><tr><th>Quand</th><th>Action</th><th>Acteur</th><th>IP</th></tr></thead><tbody>")
            For Each r As DataRow In t.Rows
                sb.Append("<tr><td class=""muted"">").Append(FormatDt(r("Utc"))).Append("</td>")
                sb.Append("<td><span class=""badge badge-encours"">").Append(Server.HtmlEncode(If(IsDBNull(r("Action")), "", r("Action").ToString()))).Append("</span></td>")
                sb.Append("<td class=""muted"">").Append(Server.HtmlEncode(If(IsDBNull(r("ActorEmail")), "—", r("ActorEmail").ToString()))).Append("</td>")
                sb.Append("<td class=""muted mono"">").Append(Server.HtmlEncode(If(IsDBNull(r("IpAddress")), "—", r("IpAddress").ToString()))).Append("</td></tr>")
            Next
            sb.Append("</tbody></table></div>")
            Return sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("AuditHistory: " & ex.Message)
            Return ""
        End Try
    End Function

    Private Function Kpi(label As String, value As String) As String
        Return "<div class=""field""><label>" & Server.HtmlEncode(label) & "</label><div style=""font-weight:800;font-size:18px;font-variant-numeric:tabular-nums"">" & Server.HtmlEncode(value) & "</div></div>"
    End Function

    Private Shared ReadOnly OffCult As Globalization.CultureInfo = New Globalization.CultureInfo("fr-CA")
    Private Function Money(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Return (c / 100D).ToString("N2", OffCult) & " $"
    End Function
    Private Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function
    Private Function ToBool(o As Object) As Boolean
        Return Not (o Is Nothing OrElse IsDBNull(o)) AndAlso CBool(o)
    End Function

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim raison As String = If(tbRaisonSociale.Text, "").Trim()
        If raison.Length = 0 Then
            ShowError("La raison sociale est obligatoire.")
            Return
        End If

        ' Capture les statuts actuels (édition) pour détecter les changements.
        Dim isEdit As Boolean = (AbonneId > 0)
        Dim oldKyb As String = ""
        Dim oldStatut As String = ""
        If isEdit Then
            Dim cur As DataRow = GetCurrentAbonneRow(AbonneId)
            If cur IsNot Nothing Then
                oldKyb = Val(cur, "StatutKYB")
                oldStatut = Val(cur, "Statut")
            End If
        End If

        ' La transition vers/depuis « Fermé » doit passer par le flux d'offboarding
        ' gardé (contrôle des fonds, désactivation des accès / réactivation), jamais
        ' par un simple enregistrement.
        If isEdit Then
            Dim newStatut As String = ddlStatut.SelectedValue
            If newStatut = "Ferme" AndAlso oldStatut <> "Ferme" Then
                ShowError("Pour clôturer un compte, utilisez « Clôturer le compte » dans la section Offboarding ci-dessous (elle vérifie l'absence de fonds et de paiements en cours).")
                LoadAbonne(AbonneId)
                Return
            End If
            If oldStatut = "Ferme" AndAlso newStatut <> "Ferme" Then
                ShowError("Pour rouvrir un compte clôturé, utilisez « Réactiver le compte » dans la section Offboarding ci-dessous.")
                LoadAbonne(AbonneId)
                Return
            End If
        End If

        Try
            Dim newId As Integer = AbonneId

            Dim p As New Collection
            p.Add(New SqlParameter("@Id", newId))
            p.Add(New SqlParameter("@RaisonSociale", raison))
            p.Add(New SqlParameter("@NomAffichage", ParamOrNull(tbNomAffichage.Text)))
            p.Add(New SqlParameter("@NumeroEntreprise", ParamOrNull(tbNumeroEntreprise.Text)))
            p.Add(New SqlParameter("@CourrielContact", ParamOrNull(tbCourriel.Text)))
            p.Add(New SqlParameter("@Telephone", ParamOrNull(tbTelephone.Text)))
            p.Add(New SqlParameter("@Adresse1", ParamOrNull(tbAdresse1.Text)))
            p.Add(New SqlParameter("@Adresse2", ParamOrNull(tbAdresse2.Text)))
            p.Add(New SqlParameter("@Ville", ParamOrNull(tbVille.Text)))
            p.Add(New SqlParameter("@Province", ParamOrNull(tbProvince.Text)))
            p.Add(New SqlParameter("@CodePostal", ParamOrNull(tbCodePostal.Text)))
            p.Add(New SqlParameter("@Pays", ParamOrNull(tbPays.Text)))
            p.Add(New SqlParameter("@Devise", ddlDevise.SelectedValue))
            p.Add(New SqlParameter("@Statut", ddlStatut.SelectedValue))
            p.Add(New SqlParameter("@StatutKYB", ddlKyb.SelectedValue))
            p.Add(New SqlParameter("@Notes", ParamOrNull(tbNotes.Text)))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))

            Dim ds As DataSet = ExecuteSQLds("s0006SaveAbonne", p)
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                newId = CInt(ds.Tables(0).Rows(0)("Id"))
            End If

            ' Audit d'un changement de statut KYB (conformité).
            If isEdit AndAlso oldKyb.Length > 0 AndAlso oldKyb <> ddlKyb.SelectedValue Then
                clsAudit.Write(AdminId, AdminEmail, "KybStatusChange", "Abonne", newId, raison,
                               "KYB: " & oldKyb & " -> " & ddlKyb.SelectedValue, Request.UserHostAddress)
            End If

            Response.Redirect("wbfAbonne.aspx?id=" & newId & "&saved=1")

        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("SaveAbonne: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers ---

    Private Function Val(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Function ParamOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub SelectValue(ddl As DropDownList, value As String)
        Dim item As ListItem = ddl.Items.FindByValue(If(value, ""))
        If item IsNot Nothing Then
            ddl.ClearSelection()
            item.Selected = True
        End If
    End Sub

    Private Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
