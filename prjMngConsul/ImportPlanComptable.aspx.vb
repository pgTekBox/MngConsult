Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Étape 1 de la migration comptable : le plan comptable.
'''
''' L'utilisateur exporte son plan depuis son ancien logiciel — QuickBooks,
''' Sage 50, Acomba — et le dépose ici. La page lit le fichier, normalise ce
''' qu'elle comprend, et met le tout en préparation.
'''
''' Elle n'écrit rien dans <c>T121PlanComptable</c>. Mettre les comptes en
''' correspondance avec le plan de la compagnie est le travail de l'étape
''' suivante, et il se fait avec le comptable : c'est le seul de la migration
''' qui ne puisse pas être décidé par un programme.
''' </summary>
Public Class ImportPlanComptable
    Inherits ImportComptableBase

#Region "Ce que cette page importe"

    Protected Overrides ReadOnly Property TypeDonnees As String
        Get
            Return "PLAN_COMPTABLE"
        End Get
    End Property

    Protected Overrides ReadOnly Property ProcedureChargement As String
        Get
            Return "s0752ChargerPlanComptableStaging"
        End Get
    End Property

    ''' <summary>
    ''' Les cinq colonnes d'un plan comptable. Les mots-clés couvrent le
    ''' français et l'anglais : les exports sortent dans la langue
    ''' d'installation du logiciel, pas dans celle de l'utilisateur.
    ''' </summary>
    Protected Overrides ReadOnly Property Colonnes As List(Of ColonneDef)
        Get
            Return New List(Of ColonneDef) From {
                New ColonneDef With {
                    .Champ = "Compte", .Libelle = "Numéro de compte", .Obligatoire = True,
                    .MotsCles = New String() {"account number", "account no", "acct", "numéro", "numero", "compte", "no compte", "number"},
                    .Description = "Le numéro, tel qu'il figure au plan d'origine"
                },
                New ColonneDef With {
                    .Champ = "Nom", .Libelle = "Nom du compte",
                    .MotsCles = New String() {"account name", "name", "nom", "description", "libellé", "libelle", "titre"},
                    .Description = "Le libellé du compte"
                },
                New ColonneDef With {
                    .Champ = "Type", .Libelle = "Type",
                    .MotsCles = New String() {"account type", "type", "catégorie", "categorie", "classe", "detail type"},
                    .Description = "Actif, passif, capitaux, produit ou charge"
                },
                New ColonneDef With {
                    .Champ = "Solde", .Libelle = "Solde",
                    .MotsCles = New String() {"balance", "solde", "montant", "amount", "total"},
                    .Description = "Le solde à la date d'export, s'il figure au fichier"
                },
                New ColonneDef With {
                    .Champ = "Sens", .Libelle = "Sens",
                    .MotsCles = New String() {"balance type", "sens", "debit", "débit", "credit", "crédit", "dr/cr"},
                    .Description = "Débit ou crédit"
                }
            }
        End Get
    End Property

#End Region

#Region "Cycle de vie"

    ''' <summary>Le lot en cours, conservé entre les allers-retours.</summary>
    Private Property LotCourant As Integer
        Get
            Dim v = ViewState("LotCourant")
            Return If(v Is Nothing, 0, CInt(v))
        End Get
        Set(value As Integer)
            ViewState("LotCourant") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            RemplirSystemes()
            AppliquerReglagesSysteme()
            ChargerLots()
        End If
    End Sub

    Private Sub RemplirSystemes()
        ddlSysteme.Items.Clear()
        For Each s In SystemesSupportes
            ddlSysteme.Items.Add(New ListItem(s.Nom, s.Code))
        Next
        ddlSysteme.SelectedValue = "QBO"
    End Sub

    ''' <summary>
    ''' Chaque logiciel a ses habitudes d'export. On les propose plutôt que de
    ''' laisser l'utilisateur deviner — il peut toujours les changer.
    ''' </summary>
    Private Sub AppliquerReglagesSysteme()
        Dim s = TrouverSysteme(ddlSysteme.SelectedValue)

        ddlSeparateur.SelectedValue = s.Separateur
        ddlEncodage.SelectedValue = s.Encodage
        litCheminExport.Text = Server.HtmlEncode(s.CheminExport)
        litNomSysteme.Text = Server.HtmlEncode(s.Nom)
    End Sub

    Protected Sub ddlSysteme_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlSysteme.SelectedIndexChanged
        AppliquerReglagesSysteme()
    End Sub

#End Region

#Region "Aperçu"

    Protected Sub btnApercu_Click(sender As Object, e As EventArgs) Handles btnApercu.Click
        CacherMessages()

        If Not fuFichier.HasFile Then
            Alerte(pnlErreur, litErreur, "Choisissez d'abord un fichier.")
            Return
        End If
        If Not FichierValide() Then Return

        Try
            Dim dt = LireCsv(fuFichier.FileContent, Separateur(), Encodage(),
                             chkEntete.Checked, 15)

            If dt.Rows.Count = 0 Then
                Alerte(pnlErreur, litErreur, "Le fichier ne contient aucune ligne de données.")
                Return
            End If

            ' Ce que la page a compris des colonnes : c'est le point qui se
            ' trompe le plus souvent, autant le montrer avant de charger.
            Dim map = AssocierColonnes(dt)
            litCorrespondance.Text = DecrireCorrespondance(dt, map)

            gvApercu.DataSource = dt
            gvApercu.DataBind()
            litApercuInfo.Text = String.Format("{0} ligne(s) affichée(s), {1} colonne(s) détectée(s).",
                                               dt.Rows.Count, dt.Columns.Count)
            pnlApercu.Visible = True

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture impossible : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>Dit, colonne par colonne, ce qui a été reconnu et ce qui ne l'a pas été.</summary>
    Private Function DecrireCorrespondance(dt As DataTable, map As Dictionary(Of String, Integer)) As String
        Dim sb As New StringBuilder()
        sb.Append("<table class='map-table'><thead><tr><th>Attendu</th><th>Colonne du fichier</th></tr></thead><tbody>")

        For Each col In Colonnes
            sb.Append("<tr><td>")
            sb.Append(Server.HtmlEncode(col.Libelle))
            If col.Obligatoire Then sb.Append(" <span class='req'>obligatoire</span>")
            sb.Append("</td><td>")

            If map.ContainsKey(col.Champ) AndAlso map(col.Champ) < dt.Columns.Count Then
                sb.Append("<b>" & Server.HtmlEncode(dt.Columns(map(col.Champ)).ColumnName) & "</b>")
            ElseIf col.Obligatoire Then
                sb.Append("<span class='miss'>non trouvée</span>")
            Else
                sb.Append("<span class='none'>—</span>")
            End If

            sb.Append("</td></tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString()
    End Function

#End Region

#Region "Chargement en préparation"

    Protected Sub btnCharger_Click(sender As Object, e As EventArgs) Handles btnCharger.Click
        CacherMessages()

        If Not fuFichier.HasFile Then
            Alerte(pnlErreur, litErreur, "Choisissez d'abord un fichier.")
            Return
        End If
        If Not FichierValide() Then Return

        Try
            Dim dt = LireCsv(fuFichier.FileContent, Separateur(), Encodage(), chkEntete.Checked)
            If dt.Rows.Count = 0 Then
                Alerte(pnlErreur, litErreur, "Le fichier ne contient aucune ligne de données.")
                Return
            End If

            Dim map = AssocierColonnes(dt)
            If Not map.ContainsKey("Compte") Then
                Alerte(pnlErreur, litErreur,
                       "La colonne du numéro de compte n'a pas été trouvée. " &
                       "Vérifiez le séparateur, ou décochez « le fichier a une ligne d'en-tête ».")
                Return
            End If

            Dim lignes As New List(Of Dictionary(Of String, Object))
            For i = 0 To dt.Rows.Count - 1
                Dim valeurs As New Dictionary(Of String, String)
                For Each col In Colonnes
                    valeurs(col.Champ) = Valeur(dt.Rows(i), map, col.Champ)
                Next
                lignes.Add(Normaliser(valeurs, If(chkEntete.Checked, i + 2, i + 1)))
            Next

            Dim lotId = OuvrirLot(ddlSysteme.SelectedValue, fuFichier.FileName,
                                  ddlSeparateur.SelectedValue, ddlEncodage.SelectedValue)
            LotCourant = lotId

            Dim r = ChargerLot(lotId, lignes)

            If r Is Nothing Then
                Alerte(pnlErreur, litErreur, "Le chargement n'a rien retourné.")
                Return
            End If

            Dim lues = Convert.ToInt32(r("NbLignesLues"))
            Dim retenues = Convert.ToInt32(r("NbLignesRetenues"))
            Dim anomalies = Convert.ToInt32(r("NbAnomalies"))

            litLues.Text = lues.ToString()
            litRetenues.Text = retenues.ToString()
            litAnomalies.Text = anomalies.ToString()
            pnlResultat.Visible = True

            If anomalies = 0 Then
                Alerte(pnlSucces, litSucces,
                       String.Format("{0} compte(s) en préparation. Rien n'a encore été écrit dans votre plan comptable.", retenues))
            Else
                Alerte(pnlAvertissement, litAvertissement,
                       String.Format("{0} compte(s) en préparation, {1} ligne(s) à regarder de près.", retenues, anomalies))
            End If

            ChargerLignes()
            ChargerLots()

        Catch ex As SqlException
            Alerte(pnlErreur, litErreur, "Base de données : " & Server.HtmlEncode(ex.Message))
        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Chargement impossible : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>
    ''' Met en forme ce qui a été lu. Les colonnes « Source » restent
    ''' disponibles en base : ce sont elles qui font foi si un écart apparaît
    ''' plus tard.
    ''' </summary>
    Protected Overrides Function Normaliser(valeurs As Dictionary(Of String, String), ligneNo As Integer) As Dictionary(Of String, Object)
        Dim compte = valeurs("Compte")
        Dim solde = LireMontant(valeurs("Solde"))

        Return New Dictionary(Of String, Object) From {
            {"LigneNo", ligneNo},
            {"CompteSource", valeurs("Compte")},
            {"NomSource", valeurs("Nom")},
            {"TypeSource", valeurs("Type")},
            {"SoldeSource", valeurs("Solde")},
            {"SensSource", valeurs("Sens")},
            {"Compte", NettoyerNumero(compte)},
            {"Nom", valeurs("Nom")},
            {"TypeNormalise", NormaliserType(valeurs("Type"))},
            {"Solde", If(solde.HasValue, CObj(solde.Value), Nothing)},
            {"Sens", NormaliserSens(valeurs("Sens"), solde)}
        }
    End Function

#End Region

#Region "Normalisation"

    ''' <summary>
    ''' Retire ce que les exports ajoutent autour du numéro : espaces
    ''' insécables, guillemets, et le tiret de séparation que certains
    ''' logiciels collent au libellé (« 1000 - Encaisse »).
    ''' </summary>
    Private Shared Function NettoyerNumero(brut As String) As String
        If String.IsNullOrWhiteSpace(brut) Then Return ""

        Dim v = brut.Replace(" ", " ").Replace("""", "").Trim()

        Dim tiret = v.IndexOf(" - ", StringComparison.Ordinal)
        If tiret > 0 Then v = v.Substring(0, tiret).Trim()

        Return v
    End Function

    ''' <summary>
    ''' Ramène le type d'origine à l'une de nos cinq natures. Les libellés
    ''' varient selon le logiciel et la langue ; ce qui n'est pas reconnu
    ''' reste vide plutôt que d'être rangé au hasard — une nature fausse
    ''' fausserait les états financiers sans rien signaler.
    ''' </summary>
    Private Shared Function NormaliserType(brut As String) As String
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim t = brut.ToLowerInvariant()

        ' L'ordre compte : « accounts receivable » contient « receivable »,
        ' mais aussi « account ». On teste du plus précis au plus général.
        If t.Contains("cost of goods") OrElse t.Contains("coût des") OrElse t.Contains("cout des") Then Return "CHARGE"
        If t.Contains("expense") OrElse t.Contains("charge") OrElse t.Contains("dépense") OrElse t.Contains("depense") Then Return "CHARGE"
        If t.Contains("income") OrElse t.Contains("revenue") OrElse t.Contains("revenu") OrElse t.Contains("produit") OrElse t.Contains("vente") Then Return "PRODUIT"
        If t.Contains("equity") OrElse t.Contains("capitaux") OrElse t.Contains("avoir") OrElse t.Contains("capital") Then Return "CAPITAUX"
        If t.Contains("liability") OrElse t.Contains("passif") OrElse t.Contains("payable") OrElse t.Contains("dette") Then Return "PASSIF"
        If t.Contains("asset") OrElse t.Contains("actif") OrElse t.Contains("receivable") OrElse t.Contains("bank") OrElse t.Contains("banque") Then Return "ACTIF"

        Select Case t.Trim()
            Case "a" : Return "ACTIF"
            Case "l", "p" : Return "PASSIF"
            Case "e", "c" : Return "CAPITAUX"
            Case "i", "r" : Return "PRODUIT"
            Case "x", "d" : Return "CHARGE"
        End Select

        Return Nothing
    End Function

    ''' <summary>
    ''' Débit ou crédit. Quand le fichier ne le dit pas, le signe du solde le
    ''' dit à sa place : un solde négatif est un crédit.
    ''' </summary>
    Private Shared Function NormaliserSens(brut As String, solde As Decimal?) As String
        If Not String.IsNullOrWhiteSpace(brut) Then
            Dim t = brut.ToLowerInvariant().Trim()
            If t.StartsWith("d") OrElse t.Contains("débit") OrElse t.Contains("debit") Then Return "DEBIT"
            If t.StartsWith("c") OrElse t.Contains("crédit") OrElse t.Contains("credit") Then Return "CREDIT"
        End If

        If solde.HasValue AndAlso solde.Value <> 0D Then
            Return If(solde.Value < 0D, "CREDIT", "DEBIT")
        End If

        Return Nothing
    End Function

#End Region

#Region "Ce qui est en préparation"

    Private Sub ChargerLignes()
        If LotCourant = 0 Then
            pnlLignes.Visible = False
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Statut", If(ddlFiltre.SelectedValue = "", CType(DBNull.Value, Object), ddlFiltre.SelectedValue)))
            p.Add(New SqlParameter("@Top", 500))

            Dim ds As DataSet = ExecuteSQLds("s0753GetPlanComptableStaging", p)
            Dim dt As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))

            gvLignes.DataSource = dt
            gvLignes.DataBind()
            pnlLignes.Visible = True

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture de la préparation : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    Protected Sub ddlFiltre_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlFiltre.SelectedIndexChanged
        ChargerLignes()
    End Sub

    Private Sub ChargerLots()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@TypeDonnees", TypeDonnees))
            p.Add(New SqlParameter("@Top", 20))

            Dim ds As DataSet = ExecuteSQLds("s0754GetImportLots", p)
            Dim dt As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))

            gvLots.DataSource = dt
            gvLots.DataBind()
            pnlLots.Visible = (dt IsNot Nothing AndAlso dt.Rows.Count > 0)

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture des lots : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>Revoir ou abandonner un lot précédent.</summary>
    Protected Sub gvLots_RowCommand(sender As Object, e As GridViewCommandEventArgs) Handles gvLots.RowCommand
        Dim lotId As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), lotId) Then Return

        CacherMessages()

        Select Case e.CommandName

            Case "Voir"
                LotCourant = lotId
                ChargerLignes()

            Case "Supprimer"
                Try
                    Dim p As New Collection
                    p.Add(New SqlParameter("@LotId", lotId))
                    p.Add(New SqlParameter("@CompanyGUID", Company))
                    ExecuteSQL("s0755SupprimerImportLot", p)

                    If LotCourant = lotId Then
                        LotCourant = 0
                        pnlLignes.Visible = False
                        pnlResultat.Visible = False
                    End If

                    Alerte(pnlSucces, litSucces, "Le lot a été abandonné.")
                    ChargerLots()

                Catch ex As SqlException
                    ' 50303 : le lot est déjà appliqué. Ce n'est pas une panne.
                    Alerte(pnlErreur, litErreur, Server.HtmlEncode(ex.Message))
                End Try
        End Select
    End Sub

    ''' <summary>Colore la ligne selon son verdict, pour repérer les anomalies d'un coup d'œil.</summary>
    Protected Sub gvLignes_RowDataBound(sender As Object, e As GridViewRowEventArgs) Handles gvLignes.RowDataBound
        If e.Row.RowType <> DataControlRowType.DataRow Then Return

        Dim r = TryCast(e.Row.DataItem, DataRowView)
        If r Is Nothing Then Return

        Select Case Convert.ToString(r("Statut"))
            Case "INVALIDE", "DOUBLON_FICHIER" : e.Row.CssClass = "row-ko"
            Case "EXISTE" : e.Row.CssClass = "row-info"
        End Select
    End Sub

#End Region

#Region "Rendu des verdicts"

    ''' <summary>Classe CSS de la pastille de verdict.</summary>
    Protected Shared Function PilleClasse(statut As Object) As String
        Select Case Convert.ToString(statut)
            Case "OK" : Return "p-ok"
            Case "EXISTE" : Return "p-ex"
            Case Else : Return "p-ko"
        End Select
    End Function

    ''' <summary>Le verdict en clair. « EXISTE » n'est pas une erreur, et le mot doit le dire.</summary>
    Protected Shared Function PilleTexte(statut As Object) As String
        Select Case Convert.ToString(statut)
            Case "OK" : Return "Nouveau"
            Case "EXISTE" : Return "Déjà au plan"
            Case "DOUBLON_FICHIER" : Return "Doublon"
            Case "INVALIDE" : Return "Invalide"
            Case Else : Return Convert.ToString(statut)
        End Select
    End Function

#End Region

#Region "Outils"

    Private Function FichierValide() As Boolean
        Dim nom = fuFichier.FileName.ToLowerInvariant()

        If Not nom.EndsWith(".csv") AndAlso Not nom.EndsWith(".txt") Then
            Alerte(pnlErreur, litErreur,
                   "Seuls les fichiers .csv et .txt sont acceptés. " &
                   "Depuis Excel : Fichier ▸ Enregistrer sous ▸ CSV.")
            Return False
        End If

        If fuFichier.PostedFile.ContentLength > 10 * 1024 * 1024 Then
            Alerte(pnlErreur, litErreur, "Fichier trop volumineux : 10 Mo au maximum.")
            Return False
        End If

        Return True
    End Function

    Private Function Separateur() As Char
        Select Case ddlSeparateur.SelectedValue
            Case "," : Return ","c
            Case vbTab : Return CChar(vbTab)
            Case Else : Return ";"c
        End Select
    End Function

    Private Function Encodage() As Encoding
        Select Case ddlEncodage.SelectedValue
            Case "Windows-1252" : Return Encoding.GetEncoding(1252)
            Case "ISO-8859-1" : Return Encoding.GetEncoding("ISO-8859-1")
            Case Else : Return Encoding.UTF8
        End Select
    End Function

    Private Sub CacherMessages()
        pnlSucces.Visible = False
        pnlErreur.Visible = False
        pnlAvertissement.Visible = False
    End Sub

    Private Shared Sub Alerte(panneau As Panel, texte As Literal, message As String)
        texte.Text = message
        panneau.Visible = True
    End Sub

#End Region

End Class
