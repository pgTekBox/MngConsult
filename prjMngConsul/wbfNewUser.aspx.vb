Imports System.Data
Imports System.Data.SqlClient
Imports Newtonsoft.Json.Linq

Public Class wbfNewUser
    Inherits clsData

    Private Const TRIAL_DAYS As Integer = 30

    ' Prompt d'extraction envoyé à OpenAI (gpt-4.1-mini) pour remplir le formulaire.
    Private Const EXTRACT_PROMPT As String =
        "Tu es un extracteur de données d'entreprise québécoise et canadienne. " &
        "À partir du document fourni (immatriculation au Registraire des entreprises du Québec, " &
        "lettre de l'Agence du revenu du Canada ou de Revenu Québec, certificat de constitution, etc.), " &
        "retourne UNIQUEMENT un objet JSON valide avec exactement ces clés (mets null si l'information est absente) : " &
        "{""legal_name"": string, ""neq"": string, ""federal_business_number"": string, ""gst_number"": string, " &
        """qst_number"": string, ""hst_number"": string, ""incorporation_date"": ""YYYY-MM-DD"", ""fiscal_year_end"": ""YYYY-MM-DD""}. " &
        "legal_name = dénomination / nom légal. neq = Numéro d'entreprise du Québec (10 chiffres). " &
        "federal_business_number = numéro d'entreprise fédéral (BN, 9 chiffres, parfois suivi de RT/RC). " &
        "gst_number = numéro de TPS. qst_number = numéro de TVQ. hst_number = numéro de TVH. " &
        "Ne retourne que le JSON, sans texte ni balises de code autour."

    ''' <summary>Langue courante : ?lang=fr|en|es (défaut fr).</summary>
    Protected ReadOnly Property CurrentLang As String
        Get
            Dim l As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
            Select Case l
                Case "en", "es", "fr"
                    Return l
                Case Else
                    Return "fr"
            End Select
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx?lang=" & CurrentLang)
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            Dim plan As String = If(Request.QueryString("plan"), "").ToLower()
            If String.IsNullOrEmpty(plan) Then plan = "solo"
            hfPlan.Value = plan
            LoadProfile()
        End If
    End Sub

    ''' <summary>Applique la langue aux contrôles serveur (boutons).</summary>
    Private Sub ApplyLocalization()
        btnExtract.Text = L("extractBtn")
        btnRestart.Text = L("restartBtn")
        btnSave.Text = L("saveBtn")
    End Sub

    ''' <summary>Traductions de la page profil/onboarding (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Mon profil — 60Sec-AI", "My profile — 60Sec-AI", "Mi perfil — 60Sec-AI")
            Case "h2" : Return Choose3(lang, "Complétez votre profil", "Complete your profile", "Complete su perfil")
            Case "subtitle" : Return Choose3(lang, "Ces informations servent à la facturation et aux déclarations gouvernementales.", "This information is used for billing and government filings.", "Esta información se utiliza para la facturación y las declaraciones gubernamentales.")
            Case "progress" : Return Choose3(lang, "Progression du profil", "Profile completion", "Progreso del perfil")
            Case "autoFill" : Return Choose3(lang, "Remplissage automatique", "Auto-fill", "Autocompletar")
            Case "uploadTitle" : Return Choose3(lang, "Importer un document", "Import a document", "Importar un documento")
            Case "uploadSub" : Return Choose3(lang, "Téléversez un document officiel (immatriculation au REQ, lettre de l'ARC ou de Revenu Québec, certificat de constitution — PDF ou image) et l'IA remplira automatiquement les champs. Vous pourrez tout vérifier avant d'enregistrer.", "Upload an official document (Quebec enterprise registration, CRA or Revenu Québec letter, certificate of incorporation — PDF or image) and the AI will fill the fields automatically. You can review everything before saving.", "Suba un documento oficial (registro de empresa de Quebec, carta de la CRA o Revenu Québec, certificado de constitución — PDF o imagen) y la IA rellenará los campos automáticamente. Podrá revisarlo todo antes de guardar.")
            Case "extractBtn" : Return Choose3(lang, "Analyser le document", "Analyze the document", "Analizar el documento")
            Case "identity" : Return Choose3(lang, "Identité de l'administrateur", "Administrator identity", "Identidad del administrador")
            Case "firstName" : Return Choose3(lang, "Prénom", "First name", "Nombre")
            Case "lastName" : Return Choose3(lang, "Nom de famille", "Last name", "Apellido")
            Case "email" : Return Choose3(lang, "Adresse courriel", "Email address", "Correo electrónico")
            Case "locked" : Return Choose3(lang, "· non modifiable", "· read-only", "· no editable")
            Case "phone" : Return Choose3(lang, "Téléphone", "Phone", "Teléfono")
            Case "company" : Return Choose3(lang, "Entreprise", "Company", "Empresa")
            Case "neq" : Return Choose3(lang, "NEQ (Numéro d'entreprise du Québec)", "NEQ (Quebec enterprise number)", "NEQ (número de empresa de Quebec)")
            Case "legalName" : Return Choose3(lang, "Nom de l'entreprise (nom légal)", "Company name (legal name)", "Nombre de la empresa (nombre legal)")
            Case "incorpDate" : Return Choose3(lang, "Date de constitution", "Incorporation date", "Fecha de constitución")
            Case "bn" : Return Choose3(lang, "Numéro d'entreprise fédéral (BN)", "Federal business number (BN)", "Número de empresa federal (BN)")
            Case "fiscalYearEnd" : Return Choose3(lang, "Fin de l'exercice fiscal", "Fiscal year end", "Fin del ejercicio fiscal")
            Case "tps" : Return Choose3(lang, "Numéro de TPS", "GST number (TPS)", "Número de GST (TPS)")
            Case "tvq" : Return Choose3(lang, "Numéro de TVQ", "QST number (TVQ)", "Número de QST (TVQ)")
            Case "tvh" : Return Choose3(lang, "Numéro de TVH", "HST number (TVH)", "Número de HST (TVH)")
            Case "restartBtn" : Return Choose3(lang, "Recommencer", "Start over", "Reiniciar")
            Case "saveBtn" : Return Choose3(lang, "Enregistrer et continuer →", "Save and continue →", "Guardar y continuar →")
            Case "errFirstName" : Return Choose3(lang, "Le prénom est obligatoire.", "First name is required.", "El nombre es obligatorio.")
            Case "errLastName" : Return Choose3(lang, "Le nom de famille est obligatoire.", "Last name is required.", "El apellido es obligatorio.")
            Case "errSave" : Return Choose3(lang, "Erreur lors de la sauvegarde : ", "Error while saving: ", "Error al guardar: ")
            Case "upChoose" : Return Choose3(lang, "Veuillez d'abord choisir un document.", "Please choose a document first.", "Elija primero un documento.")
            Case "upEmpty" : Return Choose3(lang, "Le fichier est vide.", "The file is empty.", "El archivo está vacío.")
            Case "upNoKey" : Return Choose3(lang, "La configuration OpenAI est absente. Saisissez les champs manuellement.", "OpenAI configuration is missing. Please fill the fields manually.", "Falta la configuración de OpenAI. Rellene los campos manualmente.")
            Case "upFormat" : Return Choose3(lang, "Format non supporté. Utilisez un PDF ou une image (JPG/PNG).", "Unsupported format. Use a PDF or an image (JPG/PNG).", "Formato no admitido. Use un PDF o una imagen (JPG/PNG).")
            Case "upFilled" : Return Choose3(lang, "{0} champ(s) pré-rempli(s) à partir du document. Vérifiez puis enregistrez.", "{0} field(s) pre-filled from the document. Please review, then save.", "{0} campo(s) rellenado(s) desde el documento. Revise y luego guarde.")
            Case "upNone" : Return Choose3(lang, "Aucune information exploitable n'a été reconnue dans ce document.", "No usable information was recognized in this document.", "No se reconoció información utilizable en este documento.")
            Case "upError" : Return Choose3(lang, "Impossible d'analyser le document. Réessayez ou saisissez les champs manuellement.", "Could not analyze the document. Try again or fill the fields manually.", "No se pudo analizar el documento. Inténtelo de nuevo o rellene los campos manualmente.")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ' =====================================================================
    ' Chargement du profil (identité + entreprise) depuis la BD
    ' =====================================================================
    Private Sub LoadProfile()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserId))
        Dim ds As DataSet = ExecuteSQLds("s0685GetOnboardingProfile", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim r As DataRow = ds.Tables(0).Rows(0)
        If r.Table.Columns.Contains("CompanyGUID") AndAlso Not IsDBNull(r("CompanyGUID")) Then
            Company = CType(r("CompanyGUID"), Guid)
        End If

        txtFirstName.Text = S(r, "FirstName")
        txtLastName.Text = S(r, "LastName")
        txtEmail.Text = S(r, "Email")
        txtPhone.Text = S(r, "Phone")

        txtNeq.Text = S(r, "NEQ")
        txtLegalName.Text = S(r, "LegalName")
        txtIncorpDate.Text = D(r, "IncorporationDate")
        txtBusinessNumber.Text = S(r, "BusinessNumber")
        txtFiscalYearEnd.Text = D(r, "FiscalYearEnd")
        txtTps.Text = S(r, "TpsNumber")
        txtTvq.Text = S(r, "TvqNumber")
        txtTvh.Text = S(r, "HstNumber")
    End Sub

    ' =====================================================================
    ' Remplissage automatique via document (OpenAI)
    ' =====================================================================
    Protected Async Sub btnExtract_Click(sender As Object, e As EventArgs) Handles btnExtract.Click

        If Not fileDoc.HasFile Then
            ShowUpload(L("upChoose"), True)
            Return
        End If

        Try
            Dim bytes As Byte() = fileDoc.FileBytes
            If bytes Is Nothing OrElse bytes.Length = 0 Then
                ShowUpload(L("upEmpty"), True)
                Return
            End If

            Dim fileName As String = If(fileDoc.FileName, "").ToLowerInvariant()
            Dim ct As String = If(fileDoc.PostedFile IsNot Nothing, If(fileDoc.PostedFile.ContentType, ""), "").ToLowerInvariant()

            Dim apiKey As String = GetParam("CHATGPT")
            If String.IsNullOrEmpty(apiKey) Then
                ShowUpload(L("upNoKey"), True)
                Return
            End If

            Dim reader As New OpenAiReceiptReader(apiKey)
            Dim json As String

            If ct.Contains("pdf") OrElse fileName.EndsWith(".pdf") Then
                Dim res = Await reader.ParseInvoicePdfAsync(bytes, EXTRACT_PROMPT)
                json = res.JsonText
            ElseIf ct.StartsWith("image") OrElse fileName.EndsWith(".jpg") OrElse fileName.EndsWith(".jpeg") OrElse fileName.EndsWith(".png") Then
                Dim mime As String = If(ct.StartsWith("image"), ct, If(fileName.EndsWith(".png"), "image/png", "image/jpeg"))
                Dim res = Await reader.ReadReceiptAsJsonAsync(bytes, mime, EXTRACT_PROMPT)
                json = res.JsonResult
            Else
                ShowUpload(L("upFormat"), True)
                Return
            End If

            Dim n As Integer = FillFromJson(json)
            If n > 0 Then
                ShowUpload(String.Format(L("upFilled"), n), False)
            Else
                ShowUpload(L("upNone"), True)
            End If

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("wbfNewUser extract error: " & ex.Message)
            ShowUpload(L("upError"), True)
        End Try
    End Sub

    ''' <summary>Remplit les champs à partir du JSON retourné par OpenAI. Retourne le nombre de champs remplis.</summary>
    Private Function FillFromJson(json As String) As Integer
        If String.IsNullOrWhiteSpace(json) Then Return 0

        Dim iStart As Integer = json.IndexOf("{"c)
        Dim iEnd As Integer = json.LastIndexOf("}"c)
        If iStart < 0 OrElse iEnd <= iStart Then Return 0

        Dim jo As JObject
        Try
            jo = JObject.Parse(json.Substring(iStart, iEnd - iStart + 1))
        Catch
            Return 0
        End Try

        Dim n As Integer = 0
        n += SetIf(txtLegalName, J(jo, "legal_name"))
        n += SetIf(txtNeq, J(jo, "neq"))
        n += SetIf(txtBusinessNumber, J(jo, "federal_business_number"))
        n += SetIf(txtTps, J(jo, "gst_number"))
        n += SetIf(txtTvq, J(jo, "qst_number"))
        n += SetIf(txtTvh, J(jo, "hst_number"))
        n += SetIf(txtIncorpDate, NormDate(J(jo, "incorporation_date")))
        n += SetIf(txtFiscalYearEnd, NormDate(J(jo, "fiscal_year_end")))
        Return n
    End Function

    Private Shared Function J(jo As JObject, key As String) As String
        Dim t As JToken = jo(key)
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return ""
        Return t.ToString().Trim()
    End Function

    Private Shared Function SetIf(tb As System.Web.UI.WebControls.TextBox, val As String) As Integer
        If String.IsNullOrWhiteSpace(val) OrElse val.Equals("null", StringComparison.OrdinalIgnoreCase) Then Return 0
        tb.Text = val
        Return 1
    End Function

    Private Shared Function NormDate(s As String) As String
        If String.IsNullOrWhiteSpace(s) Then Return ""
        Dim d As Date
        If Date.TryParse(s, d) Then Return d.ToString("yyyy-MM-dd")
        Return ""
    End Function

    ' =====================================================================
    ' Recommencer : recharge l'identité, vide les champs entreprise (aucune suppression en base)
    ' =====================================================================
    Protected Sub btnRestart_Click(sender As Object, e As EventArgs) Handles btnRestart.Click
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserId))
        Dim ds As DataSet = ExecuteSQLds("s0685GetOnboardingProfile", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim r As DataRow = ds.Tables(0).Rows(0)
            If r.Table.Columns.Contains("CompanyGUID") AndAlso Not IsDBNull(r("CompanyGUID")) Then
                Company = CType(r("CompanyGUID"), Guid)
            End If
            txtFirstName.Text = S(r, "FirstName")
            txtLastName.Text = S(r, "LastName")
            txtEmail.Text = S(r, "Email")
            txtPhone.Text = S(r, "Phone")
        End If

        txtNeq.Text = ""
        txtLegalName.Text = ""
        txtIncorpDate.Text = ""
        txtBusinessNumber.Text = ""
        txtFiscalYearEnd.Text = ""
        txtTps.Text = ""
        txtTvq.Text = ""
        txtTvh.Text = ""

        pnlUpload.Visible = False
    End Sub

    ' =====================================================================
    ' Enregistrer et continuer
    ' =====================================================================
    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        If String.IsNullOrWhiteSpace(txtFirstName.Text) Then
            ShowMessage(L("errFirstName"), isError:=True)
            Return
        End If
        If String.IsNullOrWhiteSpace(txtLastName.Text) Then
            ShowMessage(L("errLastName"), isError:=True)
            Return
        End If

        Try
            Dim modifiedBy As String = UserEmail
            SaveProfile(modifiedBy)

            UserFirstName = txtFirstName.Text.Trim()
            UserLastName = txtLastName.Text.Trim()

            Dim subscriptionId As Integer = StartFreeTrial(UserId, modifiedBy)
            Response.Redirect("~/wbfWelcome.aspx?id=" & subscriptionId.ToString())

        Catch ex As Threading.ThreadAbortException
            ' Response.Redirect normal
        Catch ex As Exception
            ShowMessage(L("errSave") & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub SaveProfile(modifiedBy As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserId))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@FirstName", IfDbStr(txtFirstName.Text)))
        p.Add(New SqlParameter("@LastName", IfDbStr(txtLastName.Text)))
        p.Add(New SqlParameter("@Phone", IfDbStr(txtPhone.Text)))
        p.Add(New SqlParameter("@LegalName", IfDbStr(txtLegalName.Text)))
        p.Add(New SqlParameter("@NEQ", IfDbStr(txtNeq.Text)))
        p.Add(New SqlParameter("@IncorporationDate", IfDbDate(txtIncorpDate.Text)))
        p.Add(New SqlParameter("@BusinessNumber", IfDbStr(txtBusinessNumber.Text)))
        p.Add(New SqlParameter("@FiscalYearEnd", IfDbDate(txtFiscalYearEnd.Text)))
        p.Add(New SqlParameter("@TpsNumber", IfDbStr(txtTps.Text)))
        p.Add(New SqlParameter("@TvqNumber", IfDbStr(txtTvq.Text)))
        p.Add(New SqlParameter("@HstNumber", IfDbStr(txtTvh.Text)))
        p.Add(New SqlParameter("@ProfileCompleted", ComputeProgress()))
        p.Add(New SqlParameter("@ModifiedBy", IfDbStr(modifiedBy)))
        ExecuteSQL("s0686SaveOnboardingProfile", p)
    End Sub

    ''' <summary>% de complétion : champs remplis / 12.</summary>
    Private Function ComputeProgress() As Integer
        Dim vals() As String = {
            txtFirstName.Text, txtLastName.Text, txtEmail.Text, txtPhone.Text,
            txtNeq.Text, txtLegalName.Text, txtIncorpDate.Text, txtBusinessNumber.Text,
            txtFiscalYearEnd.Text, txtTps.Text, txtTvq.Text, txtTvh.Text
        }
        Dim filled As Integer = 0
        For Each v As String In vals
            If Not String.IsNullOrWhiteSpace(v) Then filled += 1
        Next
        Return CInt(Math.Round(filled / vals.Length * 100.0))
    End Function

    ' =====================================================================
    ' Essai gratuit (conservé de la version précédente)
    ' =====================================================================
    Private Function StartFreeTrial(uId As Integer, modifiedBy As String) As Integer
        Dim plan As String = If(hfPlan.Value, "solo").ToLower()

        Dim planName As String = ""
        Dim amount As Decimal
        Select Case plan
            Case "solo" : planName = "Solo" : amount = 19D
            Case "comsolo" : planName = "ComSolo" : amount = 99D
            Case "com119" : planName = "COM119" : amount = 199D
        End Select

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@UserId", uId))
        p.Add(New SqlParameter("@PlanCode", plan))
        p.Add(New SqlParameter("@PlanName", planName))
        p.Add(New SqlParameter("@Amount", amount))
        p.Add(New SqlParameter("@TrialDays", TRIAL_DAYS))
        p.Add(New SqlParameter("@CreatedBy", IfDbStr(modifiedBy)))

        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outNew)

        ExecuteSQL("s0312StartTrialSubscription", p)

        If outNew.Value Is Nothing OrElse IsDBNull(outNew.Value) Then Return 0
        Return CInt(outNew.Value)
    End Function

    ' =====================================================================
    ' Helpers
    ' =====================================================================
    Private Function GetParam(key As String) As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Parameter", key))
            Dim ds As DataSet = ExecuteSQLds("s0000GetParameter", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)("Value").ToString()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Shared Function S(r As DataRow, col As String) As String
        If r.Table.Columns.Contains(col) AndAlso Not IsDBNull(r(col)) Then Return r(col).ToString()
        Return ""
    End Function

    Private Shared Function D(r As DataRow, col As String) As String
        If r.Table.Columns.Contains(col) AndAlso Not IsDBNull(r(col)) Then Return CDate(r(col)).ToString("yyyy-MM-dd")
        Return ""
    End Function

    Private Function IfDbStr(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Function IfDbDate(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Dim d As Date
        If Date.TryParse(s, d) Then Return d
        Return DBNull.Value
    End Function

    Private Sub ShowUpload(text As String, isError As Boolean)
        pnlUpload.Visible = True
        litUpload.Text = System.Web.HttpUtility.HtmlEncode(text)
        pnlUpload.CssClass = If(isError, "upload-msg err", "upload-msg ok")
    End Sub

    Private Sub ShowMessage(text As String, isError As Boolean)
        pnlMessage.Visible = True
        litMessage.Text = System.Web.HttpUtility.HtmlEncode(text)
        If isError Then
            pnlMessage.Style("background") = "rgba(239,68,68,.08)"
            pnlMessage.Style("border") = "1px solid rgba(239,68,68,.25)"
            pnlMessage.Style("color") = "#dc2626"
        Else
            pnlMessage.Style("background") = "rgba(16,185,129,.08)"
            pnlMessage.Style("border") = "1px solid rgba(16,185,129,.25)"
            pnlMessage.Style("color") = "#059669"
        End If
    End Sub

End Class
