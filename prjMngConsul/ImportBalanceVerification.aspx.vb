Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

''' <summary>
''' La balance de vérification à la date de bascule : lue telle que les
''' logiciels la produisent, ou par l'IA quand le fichier est mal formé ;
''' gardée par compagnie ; contrôlée — équilibre, total annoncé par le fichier —
''' et confrontée au plan comptable importé.
'''
''' Le logiciel d'origine, le séparateur et l'encodage viennent du bloc
''' « D'où viennent vos données ? », commun à tous les écrans d'importation.
''' </summary>
Public Class ImportBalanceVerification
    Inherits clsData

    ''' <summary>
    ''' Les comptes de la dernière lecture, ou de la balance en place : ce que
    ''' le tableau affiche.
    ''' </summary>
    Private Property DerniereImportation As DataTable

    ' ── Events ──
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' L'écran écrit dans la base et peut supprimer une balance : il n'est
        ' pas ouvert à qui n'est pas connecté.
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' En revenant sur l'écran, on retrouve la balance déjà importée : elle
        ' est en base, l'écran ne la montrait simplement plus.
        If Not IsPostBack Then AfficherBalanceEnPlace()
    End Sub

    Protected Sub btnPreview_Click(sender As Object, e As EventArgs) Handles btnPreview.Click
        Apercu()
    End Sub

    Protected Sub btnImport_Click(sender As Object, e As EventArgs) Handles btnImport.Click
        ImporterBalance()
    End Sub

    Protected Async Sub btnIA_Click(sender As Object, e As EventArgs) Handles btnIA.Click
        Await ImporterAvecIA()
    End Sub

    Protected Sub btnControle_Click(sender As Object, e As EventArgs) Handles btnControle.Click
        HideMessages()
        AfficherBalanceEnPlace()
        AfficherControle()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click
        HideMessages()
        pnlResults.Visible = False
        pnlPreview.Visible = False
        pnlErrorDetails.Visible = False
    End Sub

    Protected Sub btnTruncateTable_Click(sender As Object, e As EventArgs) Handles btnTruncateTable.Click
        ViderBalance()
    End Sub

    ''' <summary>
    ''' Les premières lignes du fichier, découpées avec le séparateur choisi :
    ''' de quoi voir d'un coup d'œil si le séparateur et l'encodage sont les bons.
    ''' </summary>
    Private Sub Apercu()
        HideMessages()
        pnlPreview.Visible = False

        Dim texte = LireFichier()
        If texte Is Nothing Then Return

        Dim sep = SeparateurChoisi()
        Dim cellules = texte.Replace(vbCrLf, vbLf).Replace(vbCr, vbLf).Split(ChrW(10)) _
                            .Where(Function(x) Not String.IsNullOrWhiteSpace(x)) _
                            .Take(15) _
                            .Select(Function(x) DecouperLigne(x, sep)) _
                            .ToList()

        Dim dt As New DataTable()
        Dim largeur = If(cellules.Count = 0, 0, cellules.Max(Function(c) c.Length))
        For j = 1 To largeur
            dt.Columns.Add("Colonne " & j)
        Next

        For Each c In cellules
            Dim r = dt.NewRow()
            For j = 0 To c.Length - 1
                r(j) = c(j).Trim()
            Next
            dt.Rows.Add(r)
        Next

        gvPreview.DataSource = dt
        gvPreview.DataBind()
        litPreviewInfo.Text = "Les " & cellules.Count & " premières lignes du fichier, découpées avec le séparateur choisi."
        pnlPreview.Visible = True
    End Sub

#Region "Messages"

    Private Sub HideMessages()
        pnlSuccess.Visible = False
        pnlError.Visible = False
        pnlWarning.Visible = False
    End Sub

    Private Sub ShowSuccess(message As String)
        litSuccess.Text = message
        pnlSuccess.Visible = True
    End Sub

    Private Sub ShowError(message As String)
        litError.Text = message
        pnlError.Visible = True
    End Sub

    Private Sub ShowWarning(message As String)
        litWarning.Text = message
        pnlWarning.Visible = True
    End Sub

#End Region

    ''' <summary>
    ''' Supprime la balance importée — celle de la compagnie, et d'aucune autre.
    ''' Le bouton hérité vidait la table entière, donc la balance de toutes les
    ''' compagnies.
    ''' </summary>
    Private Sub ViderBalance()
        HideMessages()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0769ViderBalanceVerification", p)

            Dim n As Integer = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                n = Convert.ToInt32(ds.Tables(0).Rows(0)("Supprimees"))
            End If

            pnlResults.Visible = False
            ShowSuccess(n & " ligne(s) supprimée(s) de la balance importée de votre compagnie.")
        Catch ex As Exception
            ShowError("Erreur lors de la suppression : " & ex.Message)
        End Try
    End Sub

#Region "Lecture d'une balance réelle"

    ''' <summary>
    ''' Importe une balance de vérification telle que les logiciels la produisent,
    ''' et non telle qu'un CSV idéal la voudrait.
    '''
    ''' Une balance QuickBooks commence par quatre lignes de titre, n'a pas de
    ''' numéros de compte, écrit ses montants « 21,095.57 » entre guillemets, et
    ''' finit par une ligne TOTAL suivie d'un pied de page. On cherche la vraie
    ''' ligne d'en-tête (celle qui porte Débit et Crédit), on écarte ce qui
    ''' précède, on s'arrête à la ligne TOTAL — dont on garde les montants pour
    ''' contrôler la lecture — et on lit les montants quel que soit leur format.
    '''
    ''' Pour les fichiers que cette lecture ne sait pas démêler, il y a
    ''' <see cref="ImporterAvecIA"/>.
    ''' </summary>
    Private Sub ImporterBalance()
        PreparerEcran()

        Dim texte = LireFichier()
        If texte Is Nothing Then Return

        Try
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
                          "Si le fichier est mal formaté, essayez « Lire avec l'IA ».")
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
            Dim lus = NouvelleTableDesComptes()
            Dim erreurs = NouvelleTableDesErreurs()
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
                ShowError("Aucun compte n'a été lu entre la ligne d'en-tête et la ligne TOTAL. " &
                          "Si le fichier est mal formaté, essayez « Lire avec l'IA ».")
                Return
            End If

            EnregistrerEtAfficher(lus, erreurs, ignorees, fichierDebit, fichierCredit, "")

        Catch ex As Exception
            ShowError("Erreur lors de l'importation : " & ex.Message)
        End Try
    End Sub

#End Region

#Region "Lecture par l'IA"

    ''' <summary>
    ''' Confie la lecture à ChatGPT, pour les fichiers que la lecture ordinaire
    ''' ne sait pas démêler : colonnes décalées, séparateurs mêlés, débit et
    ''' crédit fondus en une seule colonne de solde, export Excel collé en texte.
    '''
    ''' Un modèle peut rendre un chiffre plausible qui n'est pas dans le fichier.
    ''' Pour une balance, c'est inacceptable : chaque montant qu'il rend doit
    ''' donc se retrouver tel quel parmi les nombres du fichier d'origine, sinon
    ''' la ligne est refusée et affichée dans le détail des erreurs. S'y ajoutent
    ''' les contrôles habituels : l'équilibre, et l'accord avec le total annoncé.
    ''' </summary>
    Private Async Function ImporterAvecIA() As Task
        PreparerEcran()

        Dim texte = LireFichier()
        If texte Is Nothing Then Return

        ' Une balance tient en quelques pages ; au-delà, ce n'en est sans doute
        ' pas une, et l'appel coûterait cher pour rien.
        If texte.Length > 200000 Then
            ShowError("Le fichier est trop volumineux pour une lecture par l'IA (plus de 200 000 caractères).")
            Return
        End If

        Try
            ' ── La clé et le prompt, là où vivent les autres ────────────────
            Dim pCle As New Collection
            pCle.Add(New SqlParameter("@Parameter", "CHATGPT"))
            Dim dsCle As DataSet = ExecuteSQLds("s0000GetParameter", pCle)
            If dsCle Is Nothing OrElse dsCle.Tables.Count = 0 OrElse dsCle.Tables(0).Rows.Count = 0 Then
                ShowError("La clé d'accès à l'IA n'est pas configurée.")
                Return
            End If
            Dim cle As String = Convert.ToString(dsCle.Tables(0).Rows(0)("Value"))

            Dim pPr As New Collection
            pPr.Add(New SqlParameter("@Parameter", "PROMPT_BALANCE_VERIFICATION"))
            Dim dsPr As DataSet = ExecuteSQLds("s0032GetPromptOpenAPI", pPr)
            If dsPr Is Nothing OrElse dsPr.Tables.Count = 0 OrElse dsPr.Tables(0).Rows.Count = 0 Then
                ShowError("Le prompt de lecture des balances n'est pas configuré.")
                Return
            End If
            Dim prompt As String = Convert.ToString(dsPr.Tables(0).Rows(0)("Prompt"))

            ' ── L'appel ─────────────────────────────────────────────────────
            Dim lecteur As New OpenAiReceiptReader(cle)
            Dim reponse = Await lecteur.ParseInvoiceEmailAsync(texte, prompt)

            Dim jo = LireObjetJson(reponse.JsonText)
            If jo Is Nothing OrElse jo("lignes") Is Nothing Then
                ShowError("L'IA n'a pas rendu une réponse exploitable. Réessayez, ou vérifiez qu'il s'agit bien d'une balance.")
                Return
            End If

            ' ── Les montants du fichier, pour vérifier chaque réponse ───────
            Dim presents = MontantsDuFichier(texte)

            Dim lus = NouvelleTableDesComptes()
            Dim erreurs = NouvelleTableDesErreurs()
            Dim ignorees As Integer = 0
            Dim rang As Integer = 0

            For Each l In jo("lignes")
                rang += 1
                Dim nom = Convert.ToString(l("Description")).Trim()
                Dim num = Convert.ToString(l("Compte")).Trim()
                If num.Equals("null", StringComparison.OrdinalIgnoreCase) Then num = ""

                If nom = "" AndAlso num = "" Then
                    ignorees += 1
                    Continue For
                End If

                Dim debit = MontantJson(l("Debit"))
                Dim credit = MontantJson(l("Credit"))

                ' Le garde-fou : un montant que le fichier ne contient pas est
                ' une invention, pas une lecture.
                Dim absent As String = Nothing
                If debit <> 0D AndAlso Not presents.Contains(Math.Abs(debit)) Then absent = "débit " & debit.ToString("N2")
                If absent Is Nothing AndAlso credit <> 0D AndAlso Not presents.Contains(Math.Abs(credit)) Then absent = "crédit " & credit.ToString("N2")

                If absent IsNot Nothing Then
                    erreurs.Rows.Add(rang, If(num <> "", num & " ", "") & nom,
                                     "Montant introuvable dans le fichier (" & absent & ") : ligne refusée.")
                    Continue For
                End If

                lus.Rows.Add(If(num = "", CObj(DBNull.Value), num),
                             If(nom = "", CObj(DBNull.Value), nom),
                             Math.Abs(debit), Math.Abs(credit))
            Next

            If lus.Rows.Count = 0 Then
                ShowError("L'IA n'a rendu aucun compte dont les montants se retrouvent dans le fichier.")
                Return
            End If

            Dim fichierDebit = MontantJsonNullable(jo("totalDebit"))
            Dim fichierCredit = MontantJsonNullable(jo("totalCredit"))

            Dim noteIA = "✨ Lu par l'IA (gpt-4.1-mini) — coût estimé " & reponse.EstimatedCostUsd.ToString("N4") &
                         " US$. Chaque montant retenu a été retrouvé dans le fichier d'origine."

            EnregistrerEtAfficher(lus, erreurs, ignorees, fichierDebit, fichierCredit, noteIA)

        Catch ex As Exception
            ShowError("Lecture par l'IA : " & ex.Message)
        End Try
    End Function

    ''' <summary>
    ''' Tous les nombres du fichier, en valeur absolue, quel que soit leur
    ''' format. C'est contre eux que chaque réponse de l'IA est vérifiée.
    ''' </summary>
    Private Shared Function MontantsDuFichier(texte As String) As HashSet(Of Decimal)
        Dim ens As New HashSet(Of Decimal)
        Dim motif As New Regex("\(?-?\$?\d{1,3}(?:[ ,. ]\d{3})*(?:[.,]\d{1,2})?\)?|\(?-?\$?\d+(?:[.,]\d{1,2})?\)?")

        For Each m As Match In motif.Matches(texte)
            Dim v = LireMontant(m.Value)
            If v.HasValue Then ens.Add(Math.Abs(v.Value))
        Next

        Return ens
    End Function

    ''' <summary>L'objet JSON de la réponse, même enveloppé dans un bloc de code.</summary>
    Private Shared Function LireObjetJson(brut As String) As JObject
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim debut = brut.IndexOf("{"c)
        Dim fin = brut.LastIndexOf("}"c)
        If debut < 0 OrElse fin <= debut Then Return Nothing

        Try
            Return JObject.Parse(brut.Substring(debut, fin - debut + 1))
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Function MontantJson(t As JToken) As Decimal
        Dim v = MontantJsonNullable(t)
        Return If(v, 0D)
    End Function

    Private Shared Function MontantJsonNullable(t As JToken) As Decimal?
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        If t.Type = JTokenType.Integer OrElse t.Type = JTokenType.Float Then Return t.Value(Of Decimal)()
        Return LireMontant(Convert.ToString(t))
    End Function

#End Region

#Region "Commun aux deux lectures"

    Private Sub PreparerEcran()
        HideMessages()
        pnlResults.Visible = False
        pnlErrorDetails.Visible = False
        pnlBalance.Visible = False
    End Sub

    ''' <summary>Le texte du fichier, ou Nothing — le message d'erreur est alors affiché.</summary>
    Private Function LireFichier() As String
        If Not fuCsvFile.HasFile Then
            ShowError("Veuillez sélectionner un fichier.")
            Return Nothing
        End If

        Dim ext = Path.GetExtension(fuCsvFile.FileName).ToLowerInvariant()
        If ext <> ".csv" AndAlso ext <> ".txt" Then
            ShowError("Seuls les fichiers .csv et .txt sont acceptés.")
            Return Nothing
        End If

        Using lecteur As New StreamReader(fuCsvFile.FileContent, Encodage(), True)
            Return lecteur.ReadToEnd()
        End Using
    End Function

    Private Shared Function NouvelleTableDesComptes() As DataTable
        Dim t As New DataTable()
        t.Columns.Add("Compte", GetType(Object))
        t.Columns.Add("Description", GetType(Object))
        t.Columns.Add("Debit", GetType(Object))
        t.Columns.Add("Credit", GetType(Object))
        Return t
    End Function

    Private Shared Function NouvelleTableDesErreurs() As DataTable
        Dim t As New DataTable()
        t.Columns.Add("Ligne", GetType(Integer))
        t.Columns.Add("Données", GetType(String))
        t.Columns.Add("Erreur", GetType(String))
        Return t
    End Function

    ''' <summary>
    ''' Écrit ce qui a été lu — par procédure, pour la compagnie seulement —
    ''' puis montre aussitôt le résultat.
    ''' </summary>
    Private Sub EnregistrerEtAfficher(lus As DataTable, erreurs As DataTable, ignorees As Integer,
                                      fichierDebit As Decimal?, fichierCredit As Decimal?, note As String)
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
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Lignes", Newtonsoft.Json.JsonConvert.SerializeObject(json)))
        p.Add(New SqlParameter("@Vider", chkTruncate.Checked))
        p.Add(New SqlParameter("@NomFichier", fuCsvFile.FileName))
        p.Add(New SqlParameter("@Source", If(note <> "", "IA", "FICHIER")))

        Dim ds As DataSet = ExecuteSQLds("s0768ImporterBalanceVerification", p)
        Dim inserees As Integer = 0
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            inserees = Convert.ToInt32(ds.Tables(0).Rows(0)("Inserees"))
        End If

        litInserted.Text = inserees.ToString()
        litSkipped.Text = ignorees.ToString()
        litErrors.Text = erreurs.Rows.Count.ToString()

        If erreurs.Rows.Count > 0 Then
            gvErrors.DataSource = erreurs
            gvErrors.DataBind()
            pnlErrorDetails.Visible = True
        End If

        pnlResults.Visible = True
        pnlStats.Visible = True
        litTitreResultat.Text = "Résultat de l'importation"
        litOrigine.Text = ""
        pnlControle.Visible = False
        DerniereImportation = lus
        AfficherBalance(fichierDebit, fichierCredit, note)

        If erreurs.Rows.Count = 0 Then
            ShowSuccess(inserees & " compte(s) importé(s) dans staging.BalanceVerification.")
        Else
            ShowWarning(inserees & " compte(s) importé(s), " & erreurs.Rows.Count & " ligne(s) écartée(s) : voir le détail.")
        End If
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

    ''' <summary>Le séparateur et l'encodage viennent du bloc « D'où viennent vos données ? ».</summary>
    Private Function SeparateurChoisi() As Char
        Return ucSource.Separateur
    End Function

    Private Function Encodage() As Encoding
        Return ucSource.Encodage
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

#Region "La balance en place"

    ''' <summary>
    ''' Relit la balance déjà importée par la compagnie et la montre comme au
    ''' sortir de l'import : les comptes, les totaux, l'équilibre — et d'où elle
    ''' vient. Sans cela, revenir sur l'écran donnait l'impression d'avoir perdu
    ''' son importation, alors qu'elle était en base.
    ''' </summary>
    Private Sub AfficherBalanceEnPlace()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0770GetBalanceVerification", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim src = ds.Tables(0)
            Dim dt = NouvelleTableDesComptes()
            For Each r As DataRow In src.Rows
                dt.Rows.Add(r("Compte"), r("Description"), r("Debit"), r("Credit"))
            Next

            Dim premiere = src.Rows(0)
            Dim fr = Globalization.CultureInfo.GetCultureInfo("fr-CA")
            Dim quand = Convert.ToDateTime(premiere("Created")).ToString("d MMMM yyyy 'à' HH:mm", fr)
            Dim fichier = If(IsDBNull(premiere("NomFichier")), "", Convert.ToString(premiere("NomFichier")))
            Dim parIA = Not IsDBNull(premiere("Source")) AndAlso Convert.ToString(premiere("Source")) = "IA"

            Dim sb As New StringBuilder()
            sb.Append("<p class='origine'>Importée le ").Append(Server.HtmlEncode(quand))
            If fichier <> "" Then sb.Append(" depuis « ").Append(Server.HtmlEncode(fichier)).Append(" »")
            If parIA Then sb.Append(", lue par l'IA")
            sb.Append(" — ").Append(src.Rows.Count).Append(" compte(s). ")
            sb.Append("Pour la remplacer, importez simplement un nouveau fichier.</p>")

            litTitreResultat.Text = "Balance importée"
            litOrigine.Text = sb.ToString()
            pnlStats.Visible = False
            pnlResults.Visible = True

            DerniereImportation = dt
            AfficherBalance(Nothing, Nothing, "")

        Catch ex As Exception
            ShowError("Lecture de la balance importée : " & ex.Message)
        End Try
    End Sub

#End Region

#Region "Incohérences avec le plan comptable"

    ''' <summary>
    ''' Compare la balance importée au dernier plan comptable importé et à la
    ''' correspondance déjà décidée, et dit ce qui ne se répond pas — avant que
    ''' la reprise des soldes ne perde ou ne fausse un montant.
    ''' </summary>
    Private Sub AfficherControle()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0771ControleBalancePlan", p)
            If ds Is Nothing OrElse ds.Tables.Count < 2 Then Return

            Dim ctx = ds.Tables(0).Rows(0)
            Dim anomalies = ds.Tables(1)
            Dim fr = Globalization.CultureInfo.GetCultureInfo("fr-CA")
            Dim sb As New StringBuilder()

            sb.Append("<div class='ctrl'><h3>🔍 Incohérences avec le plan comptable</h3>")

            If IsDBNull(ctx("LotPlan")) Then
                sb.Append("<p class='ctx'>Aucun plan comptable n'a encore été importé pour cette compagnie : ")
                sb.Append("il n'y a rien à comparer. Commencez par l'étape 1 de la reprise du plan comptable.</p></div>")
                litControle.Text = sb.ToString()
                pnlControle.Visible = True
                Return
            End If

            Dim datePlan = Convert.ToDateTime(ctx("DatePlan")).ToString("d MMMM yyyy", fr)
            sb.Append("<p class='ctx'>Balance : ").Append(ctx("ComptesBalance")).Append(" compte(s)")
            If Not IsDBNull(ctx("FichierBalance")) Then sb.Append(" — « ").Append(Server.HtmlEncode(Convert.ToString(ctx("FichierBalance")))).Append(" »")
            sb.Append("<br />Plan comptable : lot ").Append(ctx("LotPlan")).Append(", ").Append(ctx("ComptesPlan")).Append(" compte(s)")
            If Not IsDBNull(ctx("FichierPlan")) Then sb.Append(" — « ").Append(Server.HtmlEncode(Convert.ToString(ctx("FichierPlan")))).Append(" »")
            sb.Append(", importé le ").Append(Server.HtmlEncode(datePlan)).Append(".<br />")
            sb.Append("Rapprochement par le numéro quand les deux en ont un, sinon par le nom : un compte renommé entre les deux exports apparaît comme absent.</p>")

            Dim nErr = Convert.ToInt32(ctx("Erreurs"))
            Dim nVer = Convert.ToInt32(ctx("AVerifier"))
            Dim nInf = Convert.ToInt32(ctx("Infos"))

            If anomalies.Rows.Count = 0 Then
                sb.Append("<div class='rien'>✔ Aucune incohérence : chaque compte de la balance a son compte au plan, et inversement.</div></div>")
                litControle.Text = sb.ToString()
                pnlControle.Visible = True
                Return
            End If

            sb.Append("<div class='chips'>")
            sb.Append("<span class='chip grv-err'>").Append(nErr).Append(" erreur(s)</span>")
            sb.Append("<span class='chip grv-ver'>").Append(nVer).Append(" à vérifier</span>")
            sb.Append("<span class='chip grv-inf'>").Append(nInf).Append(" pour information</span>")
            sb.Append("</div>")

            sb.Append("<div class='tbl-wrap'><table class='imp-tbl'><thead><tr>")
            sb.Append("<th>Gravité</th><th>Compte</th><th>Ce qui ne va pas</th></tr></thead><tbody>")

            For Each r As DataRow In anomalies.Rows
                Dim g = Convert.ToString(r("Gravite"))
                Dim cls = If(g = "ERREUR", "grv-err", If(g = "VERIFIER", "grv-ver", "grv-inf"))
                Dim lib_ = If(g = "ERREUR", "Erreur", If(g = "VERIFIER", "À vérifier", "Info"))
                Dim nom = Texte(r("Nom"))
                Dim num = Texte(r("Compte"))
                sb.Append("<tr><td><span class='grv ").Append(cls).Append("'>").Append(lib_).Append("</span></td>")
                sb.Append("<td>").Append(Server.HtmlEncode(If(num <> "", num & " — ", "") & nom)).Append("</td>")
                sb.Append("<td>").Append(Server.HtmlEncode(Texte(r("Detail")))).Append("</td></tr>")
            Next

            sb.Append("</tbody></table></div></div>")
            litControle.Text = sb.ToString()
            pnlControle.Visible = True

        Catch ex As Exception
            ShowError("Contrôle avec le plan comptable : " & ex.Message)
        End Try
    End Sub

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
    ''' la table, qui garde aussi les importations précédentes de la compagnie.
    ''' </summary>
    Private Sub AfficherBalance(fichierDebit As Decimal?, fichierCredit As Decimal?, note As String)
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

        If note <> "" Then
            bandeau.Append("<div class='equil ia'>").Append(Server.HtmlEncode(note)).Append("</div>")
        End If

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
