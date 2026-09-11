Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions

Public Class ImportBalanceVerification
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.BalanceVerification"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Balance de Vérification"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration → staging.BalanceVerification"
    Protected Overrides ReadOnly Property PageIcon As String = "📋"
    Protected Overrides ReadOnly Property SageExportPath As String = "Rapports ▸ Balance de vérification (Trial Balance), à la date de bascule"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "Compte", .DbColumnName = "Compte",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Numéro de compte",
                    .DetectKeywords = New String() {"number", "numéro", "numero", "no", "code"},
                    .Description = "Numéro du compte, s'il existe"
                },
                New ColumnDef With {
                    .FieldName = "Description", .DbColumnName = "Description",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = False, .CsvHeader = "Account Name / Nom du compte",
                    .DetectKeywords = New String() {"name", "nom", "description", "libellé", "libelle", "account"},
                    .Description = "Nom du compte"
                },
                New ColumnDef With {
                    .FieldName = "Debit", .DbColumnName = "Debit",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Debit / Débit",
                    .DetectKeywords = New String() {"debit", "débit"},
                    .Description = "Solde débiteur"
                },
                New ColumnDef With {
                    .FieldName = "Credit", .DbColumnName = "Credit",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Credit / Crédit",
                    .DetectKeywords = New String() {"credit", "crédit"},
                    .Description = "Solde créditeur"
                }
            }
        End Get
    End Property

    ' ── Contrôles (liés au markup) ──
    Protected Overrides ReadOnly Property FileUploadControl As System.Web.UI.WebControls.FileUpload
        Get
            Return fuCsvFile
        End Get
    End Property
    Protected Overrides ReadOnly Property SeparatorDropDown As System.Web.UI.WebControls.DropDownList
        Get
            Return ddlSeparator
        End Get
    End Property
    Protected Overrides ReadOnly Property EncodingDropDown As System.Web.UI.WebControls.DropDownList
        Get
            Return ddlEncoding
        End Get
    End Property
    Protected Overrides ReadOnly Property HasHeaderCheckBox As System.Web.UI.WebControls.CheckBox
        Get
            Return chkHasHeader
        End Get
    End Property
    Protected Overrides ReadOnly Property TruncateCheckBox As System.Web.UI.WebControls.CheckBox
        Get
            Return chkTruncate
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewGrid As System.Web.UI.WebControls.GridView
        Get
            Return gvPreview
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewInfoLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litPreviewInfo
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlPreview
        End Get
    End Property
    Protected Overrides ReadOnly Property SuccessPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlSuccess
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlError
        End Get
    End Property
    Protected Overrides ReadOnly Property WarningPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlWarning
        End Get
    End Property
    Protected Overrides ReadOnly Property SuccessLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litSuccess
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litError
        End Get
    End Property
    Protected Overrides ReadOnly Property WarningLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litWarning
        End Get
    End Property
    Protected Overrides ReadOnly Property ResultsPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlResults
        End Get
    End Property
    Protected Overrides ReadOnly Property InsertedLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litInserted
        End Get
    End Property
    Protected Overrides ReadOnly Property SkippedLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litSkipped
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorsLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litErrors
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorDetailsPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlErrorDetails
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorsGrid As System.Web.UI.WebControls.GridView
        Get
            Return gvErrors
        End Get
    End Property

    ' ── Events ──
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' L'écran écrit dans la base et peut vider une table : il n'est pas
        ' ouvert à qui n'est pas connecté.
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
    End Sub

    Protected Sub btnPreview_Click(sender As Object, e As EventArgs) Handles btnPreview.Click
        DoPreview()
    End Sub

    Protected Sub btnImport_Click(sender As Object, e As EventArgs) Handles btnImport.Click
        ImporterBalance()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click
        DoReset()
    End Sub

    Protected Sub btnTruncateTable_Click(sender As Object, e As EventArgs) Handles btnTruncateTable.Click
        DoTruncate()
    End Sub

#Region "Lecture d'une balance réelle"

    ''' <summary>
    ''' Importe une balance de vérification telle que les logiciels la produisent,
    ''' et non telle qu'un CSV idéal la voudrait.
    '''
    ''' Une balance QuickBooks commence par quatre lignes de titre, n'a pas de
    ''' numéros de compte, écrit ses montants « 21,095.57 » entre guillemets, et
    ''' finit par une ligne TOTAL suivie d'un pied de page. Le lecteur générique
    ''' des écrans Sage n'en voyait rien : avec le point-virgule par défaut, il
    ''' rangeait la ligne entière dans la colonne du numéro et laissait tous les
    ''' montants à zéro.
    '''
    ''' Ici : on cherche la vraie ligne d'en-tête (celle qui porte Débit et
    ''' Crédit), on écarte ce qui précède, on s'arrête à la ligne TOTAL — dont on
    ''' garde les montants pour contrôler la lecture — et on lit les montants
    ''' quel que soit leur format.
    ''' </summary>
    Private Sub ImporterBalance()
        HideMessages()
        pnlResults.Visible = False
        pnlErrorDetails.Visible = False
        pnlBalance.Visible = False

        If Not fuCsvFile.HasFile Then
            ShowError("Veuillez sélectionner un fichier CSV.")
            Return
        End If

        Dim ext = Path.GetExtension(fuCsvFile.FileName).ToLowerInvariant()
        If ext <> ".csv" AndAlso ext <> ".txt" Then
            ShowError("Seuls les fichiers .csv et .txt sont acceptés.")
            Return
        End If

        Try
            Dim texte As String
            Using lecteur As New StreamReader(fuCsvFile.FileContent, Encodage(), True)
                texte = lecteur.ReadToEnd()
            End Using

            Dim lignes = texte.Replace(vbCrLf, vbLf).Replace(vbCr, vbLf).Split(ChrW(10))

            ' Le séparateur choisi d'abord. S'il ne fait apparaître aucune ligne
            ' d'en-tête, on essaie les autres plutôt que de tout ranger dans une
            ' seule colonne sans rien dire.
            Dim sep As Char = SeparateurChoisi()
            Dim entete As Integer = TrouverEntete(lignes, sep)
            If entete < 0 Then
                For Each autre In New Char() {","c, ";"c, ControlChars.Tab}
                    If autre = sep Then Continue For
                    entete = TrouverEntete(lignes, autre)
                    If entete >= 0 Then
                        sep = autre
                        Exit For
                    End If
                Next
            End If

            If entete < 0 Then
                ShowError("Aucune ligne d'en-tête portant une colonne Débit et une colonne Crédit n'a été trouvée. " &
                          "Vérifiez qu'il s'agit bien d'une balance de vérification.")
                Return
            End If

            ' ── Les colonnes, d'après l'en-tête trouvé ──────────────────────
            Dim titres = DecouperLigne(lignes(entete), sep)
            Dim iCompte As Integer = -1, iNom As Integer = -1, iDebit As Integer = -1, iCredit As Integer = -1

            For j = 0 To titres.Length - 1
                Dim h = titres(j).Trim().ToLowerInvariant()
                If h = "" Then Continue For

                If iDebit < 0 AndAlso (h.Contains("debit") OrElse h.Contains("débit")) Then
                    iDebit = j
                ElseIf iCredit < 0 AndAlso (h.Contains("credit") OrElse h.Contains("crédit")) Then
                    iCredit = j
                ElseIf iCompte < 0 AndAlso (h.Contains("number") OrElse h.Contains("numéro") OrElse h.Contains("numero") OrElse
                                            h = "no" OrElse h.StartsWith("no ") OrElse h.StartsWith("n°") OrElse
                                            h = "code" OrElse h = "compte") Then
                    iCompte = j
                ElseIf iNom < 0 AndAlso (h.Contains("name") OrElse h.Contains("nom") OrElse h.Contains("description") OrElse
                                         h.Contains("libell") OrElse h.Contains("account") OrElse h.Contains("compte")) Then
                    iNom = j
                End If
            Next

            ' QuickBooks Desktop laisse parfois la première colonne sans titre :
            ' c'est alors elle qui porte le compte.
            If iNom < 0 AndAlso iCompte < 0 Then
                For j = 0 To titres.Length - 1
                    If j <> iDebit AndAlso j <> iCredit Then
                        iNom = j
                        Exit For
                    End If
                Next
            End If

            ' ── Les lignes ──────────────────────────────────────────────────
            Dim lus As New DataTable()
            lus.Columns.Add("Compte", GetType(Object))
            lus.Columns.Add("Description", GetType(Object))
            lus.Columns.Add("Debit", GetType(Object))
            lus.Columns.Add("Credit", GetType(Object))

            Dim erreurs As New DataTable()
            erreurs.Columns.Add("Ligne", GetType(Integer))
            erreurs.Columns.Add("Données", GetType(String))
            erreurs.Columns.Add("Erreur", GetType(String))

            Dim ignorees As Integer = 0
            Dim fichierDebit As Decimal? = Nothing
            Dim fichierCredit As Decimal? = Nothing
            Dim numeroEnTete As New Regex("^(\d[\d.\-]{0,19})\s+(?:-\s+)?(\S.*)$")

            For i = entete + 1 To lignes.Length - 1
                Dim brut = lignes(i)
                If String.IsNullOrWhiteSpace(brut) Then Continue For

                Dim c = DecouperLigne(brut, sep)
                Dim nom = Cellule(c, iNom)
                Dim num = Cellule(c, iCompte)
                Dim tete = If(num <> "", num, nom)

                ' La ligne TOTAL clôt la balance ; ce qui la suit est le pied de
                ' page. Ses montants servent à contrôler ce qu'on a lu.
                If tete.StartsWith("total", StringComparison.OrdinalIgnoreCase) Then
                    fichierDebit = LireMontant(Cellule(c, iDebit))
                    fichierCredit = LireMontant(Cellule(c, iCredit))
                    Exit For
                End If

                If nom = "" AndAlso num = "" Then
                    ignorees += 1
                    Continue For
                End If

                Dim brutDebit = Cellule(c, iDebit)
                Dim brutCredit = Cellule(c, iCredit)
                Dim debit = LireMontant(brutDebit)
                Dim credit = LireMontant(brutCredit)

                If brutDebit <> "" AndAlso Not debit.HasValue Then
                    erreurs.Rows.Add(i + 1, brut, "Débit illisible : « " & brutDebit & " »")
                    Continue For
                End If
                If brutCredit <> "" AndAlso Not credit.HasValue Then
                    erreurs.Rows.Add(i + 1, brut, "Crédit illisible : « " & brutCredit & " »")
                    Continue For
                End If

                ' Sans colonne de numéro, un numéro peut précéder le nom :
                ' « 1000 Encaisse », « 1000 - Encaisse ».
                If iCompte < 0 Then
                    Dim m = numeroEnTete.Match(nom)
                    If m.Success Then
                        num = m.Groups(1).Value
                        nom = m.Groups(2).Value.Trim()
                    End If
                End If

                lus.Rows.Add(If(num = "", CObj(DBNull.Value), num),
                             If(nom = "", CObj(DBNull.Value), nom),
                             If(debit, 0D), If(credit, 0D))
            Next

            If lus.Rows.Count = 0 Then
                ShowError("Aucun compte n'a été lu entre la ligne d'en-tête et la ligne TOTAL.")
                Return
            End If

            ' ── L'écriture, par procédure ───────────────────────────────────
            Dim json As New List(Of Object)
            For Each r As DataRow In lus.Rows
                json.Add(New With {
                    .Compte = If(IsDBNull(r("Compte")), Nothing, CStr(r("Compte"))),
                    .Description = If(IsDBNull(r("Description")), Nothing, CStr(r("Description"))),
                    .Debit = CDec(r("Debit")),
                    .Credit = CDec(r("Credit"))
                })
            Next

            Dim p As New Collection
            p.Add(New SqlParameter("@Lignes", Newtonsoft.Json.JsonConvert.SerializeObject(json)))
            p.Add(New SqlParameter("@Vider", chkTruncate.Checked))

            Dim ds As DataSet = ExecuteSQLds("s0768ImporterBalanceVerification", p)
            Dim inserees As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                inserees = Convert.ToInt32(ds.Tables(0).Rows(0)("Inserees"))
            End If

            ' ── Le résultat, aussitôt ───────────────────────────────────────
            litInserted.Text = inserees.ToString()
            litSkipped.Text = ignorees.ToString()
            litErrors.Text = erreurs.Rows.Count.ToString()

            If erreurs.Rows.Count > 0 Then
                gvErrors.DataSource = erreurs
                gvErrors.DataBind()
                pnlErrorDetails.Visible = True
            End If

            pnlResults.Visible = True
            DerniereImportation = lus
            AfficherBalance(fichierDebit, fichierCredit)

            If erreurs.Rows.Count = 0 Then
                ShowSuccess(inserees & " compte(s) importé(s) dans staging.BalanceVerification.")
            Else
                ShowWarning(inserees & " compte(s) importé(s), " & erreurs.Rows.Count & " ligne(s) écartée(s) : voir le détail.")
            End If

        Catch ex As Exception
            ShowError("Erreur lors de l'importation : " & ex.Message)
        End Try
    End Sub

    ''' <summary>La première ligne qui porte une colonne Débit et une colonne Crédit.</summary>
    Private Shared Function TrouverEntete(lignes As String(), sep As Char) As Integer
        For i = 0 To Math.Min(lignes.Length, 40) - 1
            Dim aDebit As Boolean = False
            Dim aCredit As Boolean = False

            For Each champ In DecouperLigne(lignes(i), sep)
                Dim h = champ.Trim().ToLowerInvariant()
                If h.Length = 0 OrElse h.Length > 40 Then Continue For
                If h.Contains("debit") OrElse h.Contains("débit") Then aDebit = True
                If h.Contains("credit") OrElse h.Contains("crédit") Then aCredit = True
            Next

            If aDebit AndAlso aCredit Then Return i
        Next

        Return -1
    End Function

    Private Function SeparateurChoisi() As Char
        Dim v = ddlSeparator.SelectedValue
        If String.IsNullOrEmpty(v) Then Return ","c
        If v = "&#9;" OrElse v = "\t" Then Return ControlChars.Tab
        Return v(0)
    End Function

    Private Function Encodage() As Encoding
        Dim v = ddlEncoding.SelectedValue
        If String.IsNullOrEmpty(v) OrElse v.Equals("UTF-8", StringComparison.OrdinalIgnoreCase) Then
            Return New UTF8Encoding(False)
        End If
        Return Encoding.GetEncoding(v)
    End Function

    Private Shared Function Cellule(c As String(), idx As Integer) As String
        If idx < 0 OrElse idx >= c.Length Then Return ""
        Return c(idx).Trim()
    End Function

    ''' <summary>
    ''' Découpe une ligne CSV en tenant compte des guillemets : un séparateur
    ''' entre guillemets fait partie de la valeur — « "21,095.57" » reste un seul
    ''' montant.
    ''' </summary>
    Private Shared Function DecouperLigne(ligne As String, separateur As Char) As String()
        Dim champs As New List(Of String)
        Dim entreGuillemets As Boolean = False
        Dim courant As New StringBuilder()
        Dim i As Integer = 0

        While i < ligne.Length
            Dim ch = ligne(i)
            If entreGuillemets Then
                If ch = """"c Then
                    If i + 1 < ligne.Length AndAlso ligne(i + 1) = """"c Then
                        courant.Append(""""c) : i += 1
                    Else
                        entreGuillemets = False
                    End If
                Else
                    courant.Append(ch)
                End If
            Else
                If ch = """"c Then
                    entreGuillemets = True
                ElseIf ch = separateur Then
                    champs.Add(courant.ToString()) : courant.Clear()
                Else
                    courant.Append(ch)
                End If
            End If
            i += 1
        End While

        champs.Add(courant.ToString())
        Return champs.ToArray()
    End Function

    ''' <summary>
    ''' Un montant, quel que soit son format : « 1 234,56 », « 1,234.56 »,
    ''' « $107,449.98 », « (366.63) ». Le dernier séparateur est le décimal.
    ''' </summary>
    Private Shared Function LireMontant(brut As String) As Decimal?
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim v = brut.Replace("$", "").Replace(" ", "").Replace(ChrW(160), "").Trim()
        Dim negatif As Boolean = False

        If v.StartsWith("(") AndAlso v.EndsWith(")") Then
            negatif = True
            v = v.Trim("("c, ")"c)
        End If

        Dim dernierPoint = v.LastIndexOf("."c)
        Dim derniereVirgule = v.LastIndexOf(","c)

        If dernierPoint >= 0 AndAlso derniereVirgule >= 0 Then
            If derniereVirgule > dernierPoint Then
                v = v.Replace(".", "").Replace(",", ".")
            Else
                v = v.Replace(",", "")
            End If
        ElseIf derniereVirgule >= 0 Then
            v = v.Replace(",", ".")
        End If

        Dim d As Decimal
        If Not Decimal.TryParse(v, Globalization.NumberStyles.Any,
                                Globalization.CultureInfo.InvariantCulture, d) Then
            Return Nothing
        End If

        Return If(negatif, -d, d)
    End Function

#End Region

#Region "Le résultat, aussitôt"

    ''' <summary>
    ''' Montre, dès l'importation faite, ce qui vient d'entrer : les comptes,
    ''' leurs soldes, l'équilibre, et l'accord avec le total annoncé par le
    ''' fichier. Une balance dont les débits n'égalent pas les crédits est
    ''' fausse ; une lecture qui ne retrouve pas le total du fichier a perdu
    ''' des lignes. Mieux vaut le voir ici que trois étapes plus loin.
    '''
    ''' Les lignes viennent de l'importation elle-même, pas d'une relecture de
    ''' la table : elle est partagée, et mêlerait d'autres importations.
    ''' </summary>
    Private Sub AfficherBalance(fichierDebit As Decimal?, fichierCredit As Decimal?)
        pnlBalance.Visible = False

        Dim dt = DerniereImportation
        If dt Is Nothing OrElse dt.Rows.Count = 0 Then Return

        Dim fr = Globalization.CultureInfo.GetCultureInfo("fr-CA")
        Dim totalDebit As Decimal = 0D
        Dim totalCredit As Decimal = 0D

        ' Une balance QuickBooks n'a pas de numéros : une colonne vide de bout
        ' en bout n'apprend rien, on ne l'affiche pas.
        Dim avecNumeros As Boolean = False
        For Each r As DataRow In dt.Rows
            If Texte(r("Compte")) <> "" Then avecNumeros = True : Exit For
        Next

        Dim sb As New StringBuilder()
        sb.Append("<div class='tbl-wrap'><table class='imp-tbl'><thead><tr>")
        If avecNumeros Then sb.Append("<th>Compte</th>")
        sb.Append("<th>Nom du compte</th><th class='num'>Débit</th><th class='num'>Crédit</th>")
        sb.Append("</tr></thead><tbody>")

        For Each r As DataRow In dt.Rows
            Dim debit = Montant(r("Debit"))
            Dim credit = Montant(r("Credit"))
            totalDebit += debit
            totalCredit += credit

            sb.Append("<tr>")
            If avecNumeros Then sb.Append("<td>").Append(Server.HtmlEncode(Texte(r("Compte")))).Append("</td>")
            sb.Append("<td>").Append(Server.HtmlEncode(Texte(r("Description")))).Append("</td>")
            sb.Append("<td class='num'>").Append(If(debit = 0D, "", debit.ToString("N2", fr))).Append("</td>")
            sb.Append("<td class='num'>").Append(If(credit = 0D, "", credit.ToString("N2", fr))).Append("</td></tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td")
        If avecNumeros Then sb.Append(" colspan='2'")
        sb.Append(">Total — ").Append(dt.Rows.Count).Append(" compte(s)</td>")
        sb.Append("<td class='num'>").Append(totalDebit.ToString("N2", fr)).Append("</td>")
        sb.Append("<td class='num'>").Append(totalCredit.ToString("N2", fr)).Append("</td>")
        sb.Append("</tr></tfoot></table></div>")
        litBalance.Text = sb.ToString()

        Dim bandeau As New StringBuilder()
        Dim ecart = totalDebit - totalCredit

        ' Tout à zéro n'est pas un équilibre, c'est une lecture ratée.
        If totalDebit = 0D AndAlso totalCredit = 0D Then
            bandeau.Append("<div class='equil ko'>⚠️ Aucun montant n'a été lu — tous les soldes valent zéro. ")
            bandeau.Append("Le séparateur ou l'encodage ne correspond sans doute pas au fichier. ")
            bandeau.Append("Vérifiez le tableau ci-dessous avant d'aller plus loin.</div>")
        ElseIf ecart = 0D Then
            bandeau.Append("<div class='equil ok'>⚖️ Balance équilibrée — débits et crédits totalisent chacun ")
            bandeau.Append(totalDebit.ToString("N2", fr)).Append(" $.</div>")
        Else
            bandeau.Append("<div class='equil ko'>⚠️ Balance déséquilibrée — écart de ")
            bandeau.Append(Math.Abs(ecart).ToString("N2", fr)).Append(" $ (")
            bandeau.Append(If(ecart > 0D, "plus de débits que de crédits", "plus de crédits que de débits"))
            bandeau.Append("). Vérifiez l'export avant d'aller plus loin.</div>")
        End If

        ' Le fichier annonce ses propres totaux : s'ils ne concordent pas avec
        ' ce qu'on a lu, des lignes se sont perdues en route.
        If fichierDebit.HasValue OrElse fichierCredit.HasValue Then
            Dim fd = If(fichierDebit, 0D)
            Dim fc = If(fichierCredit, 0D)

            If fd = totalDebit AndAlso fc = totalCredit Then
                bandeau.Append("<div class='equil ok'>✔ Le total annoncé par le fichier (")
                bandeau.Append(fd.ToString("N2", fr)).Append(" $ au débit, ")
                bandeau.Append(fc.ToString("N2", fr)).Append(" $ au crédit) correspond à la somme des lignes lues : ")
                bandeau.Append("rien n'a été perdu à la lecture.</div>")
            Else
                bandeau.Append("<div class='equil ko'>⚠️ Le fichier annonce ")
                bandeau.Append(fd.ToString("N2", fr)).Append(" $ au débit et ")
                bandeau.Append(fc.ToString("N2", fr)).Append(" $ au crédit ; la lecture donne ")
                bandeau.Append(totalDebit.ToString("N2", fr)).Append(" $ et ")
                bandeau.Append(totalCredit.ToString("N2", fr)).Append(" $. Des lignes ont été mal lues.</div>")
            End If
        End If

        litEquilibre.Text = bandeau.ToString()
        pnlBalance.Visible = True
    End Sub

    Private Shared Function Montant(v As Object) As Decimal
        If v Is Nothing OrElse IsDBNull(v) Then Return 0D
        Return Convert.ToDecimal(v)
    End Function

    Private Shared Function Texte(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToString(v)
    End Function

#End Region

End Class
