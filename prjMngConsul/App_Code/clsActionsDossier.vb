Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text.RegularExpressions

''' <summary>
''' Actions permises à un employé du cabinet dans un dossier (T393).
''' Dans « Gérer les dossiers », l'administrateur coche, pour chaque dossier
''' confié, les zones de l'ERP du client où l'employé peut agir. Ici :
'''   - la liste des actions et leurs libellés (fr/en/es) ;
'''   - la zone (action) de chaque page de l'ERP ;
'''   - ce que l'utilisateur connecté peut faire dans la compagnie courante
'''     (s1016, mis en cache pour la requête).
''' Aucune restriction enregistrée = tout est permis ; un administrateur du
''' cabinet n'est jamais restreint. Utilisé par clsData (garde des pages) et le
''' menu (entrées masquées).
''' </summary>
Public NotInheritable Class clsActionsDossier

    Private Sub New()
    End Sub

    ''' <summary>Les actions, dans l'ordre du menu de l'ERP.</summary>
    Public Shared ReadOnly Actions As String() =
        {"revenus", "paiements", "processeurs", "rapports", "comptabilite", "taxes", "agenda", "employes", "produits", "parametres"}

    Public Shared Function Libelle(code As String, lang As String) As String
        Dim l As String = If(lang, "fr").ToLowerInvariant()
        Dim t = Function(fr As String, en As String, es As String) If(l = "en", en, If(l = "es", es, fr))
        Select Case code
            Case "revenus" : Return t("Revenus", "Revenue", "Ingresos")
            Case "paiements" : Return t("Paiements", "Payments", "Pagos")
            Case "processeurs" : Return t("Processeurs", "Processors", "Procesadores")
            Case "rapports" : Return t("Rapports", "Reports", "Informes")
            Case "comptabilite" : Return t("Comptabilité", "Accounting", "Contabilidad")
            Case "taxes" : Return t("Taxes", "Sales taxes", "Impuestos")
            Case "agenda" : Return t("Agenda", "Calendar", "Agenda")
            Case "employes" : Return t("Employés", "Employees", "Empleados")
            Case "produits" : Return t("Produits et services", "Products and services", "Productos y servicios")
            Case "parametres" : Return t("Paramètres", "Settings", "Configuración")
            Case Else : Return code
        End Select
    End Function

    ' Page (nom de fichier, sans extension, en minuscules) → action. Une page
    ' absente de la table n'est soumise à aucune action (accueil, messages…).
    Private Shared ReadOnly PageAction As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase) From {
        {"wbfcustomers", "revenus"}, {"wbfcustomeredit", "revenus"}, {"wbfcustomersinvoices", "revenus"},
        {"wbfinvoiceedit", "revenus"}, {"wbfencaissements", "revenus"}, {"wbfaisale", "revenus"},
        {"wbfcustomerpaymentlink", "revenus"},
        {"wbfsuppliers", "paiements"}, {"wbfsupplieredit", "paiements"}, {"wbfsuppliersinvoices", "paiements"},
        {"wbfsupplierinvoinceedit", "paiements"}, {"wbfreceipt", "paiements"}, {"wbfreceiptedit", "paiements"},
        {"wbfreceipteditpopup", "paiements"}, {"receipts", "paiements"}, {"wbfaipaiement", "paiements"},
        {"wbfsupplierpaymentchoice", "paiements"}, {"wbfsupplierpaymentdream", "paiements"},
        {"wbfsupplierpaymentinterac", "paiements"}, {"wbfsupplierpaymentsuccess", "paiements"},
        {"wbfsupplierpaymentsync", "paiements"}, {"wbfscheduleautopay", "paiements"},
        {"wbfpaymentprocessors", "processeurs"}, {"wbfautopayauthorizations", "processeurs"},
        {"wbfautopayschedule", "processeurs"}, {"wbfautopayhistory", "processeurs"},
        {"wbfsupplierstripeonboarding", "processeurs"},
        {"wbfrapportplancomptable", "rapports"}, {"wbfetatresultats", "rapports"}, {"wbfbilan", "rapports"},
        {"wbffluxtresorerie", "rapports"}, {"wbfbeneficesnonrepartis", "rapports"}, {"wbfbalanceverification", "rapports"},
        {"wbfjournal", "comptabilite"}, {"wbfjournallist", "comptabilite"}, {"wbfjournalentryedit", "comptabilite"},
        {"wbftemplate", "comptabilite"}, {"wbftemplatelist", "comptabilite"}, {"wbftemplateedit", "comptabilite"},
        {"plaidaccounts", "comptabilite"}, {"wbfreleve", "comptabilite"}, {"wbffermetureannee", "comptabilite"},
        {"wbfplancomptable", "comptabilite"}, {"wbfplancomptableedit", "comptabilite"},
        {"wbfrapporttaxe", "taxes"},
        {"wbfagenda", "agenda"}, {"wbfappointmentedit", "agenda"},
        {"wbfemployees", "employes"}, {"wbfemployeeedit", "employes"},
        {"wbfproducts", "produits"}, {"wbfproductedit", "produits"}, {"wbfproductcategory", "produits"},
        {"wbfproductcategoryedit", "produits"}, {"wbflieux", "produits"}, {"wbflieuedit", "produits"},
        {"wbfsetting", "parametres"}, {"wbfusers", "parametres"}, {"wbfuseredit", "parametres"},
        {"importations", "parametres"}, {"importation2", "parametres"}
    }

    ''' <summary>L'action d'une page (« ~/wbfX.aspx?y=1 », « /wbfX »…) ou "" si la page est libre.</summary>
    Public Shared Function ActionDePage(url As String) As String
        If String.IsNullOrEmpty(url) Then Return ""
        Dim chemin As String = url
        Dim requete As String = ""
        Dim q As Integer = chemin.IndexOf("?"c)
        If q >= 0 Then requete = chemin.Substring(q) : chemin = chemin.Substring(0, q)
        Dim nom As String = IO.Path.GetFileNameWithoutExtension(chemin)
        ' La fenêtre de règlement sert aux deux sens : un encaissement relève des Revenus
        If (nom.Equals("wbfreceipteditpopup", StringComparison.OrdinalIgnoreCase) OrElse nom.Equals("wbfreceiptedit", StringComparison.OrdinalIgnoreCase)) AndAlso
           Regex.IsMatch(requete, "[?&]sens=\s*encaissement", RegexOptions.IgnoreCase) Then Return "revenus"
        Dim a As String = Nothing
        If PageAction.TryGetValue(nom, a) Then Return a
        Return ""
    End Function

    ''' <summary>
    ''' Pages qui demandent l'accès complet à leur zone : les encaissements et
    ''' décaissements (règlements, liens et paiements fournisseurs) et les
    ''' synchronisations. En accès restreint (lecture seule), elles sont fermées :
    ''' absentes du menu et refusées à l'ouverture.
    ''' </summary>
    Private Shared ReadOnly PagesAccesComplet As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase) From {
        "wbfencaissements", "wbfreceiptedit", "wbfreceipteditpopup", "wbfcustomerpaymentlink",
        "wbfsupplierpaymentchoice", "wbfsupplierpaymentdream", "wbfsupplierpaymentinterac",
        "wbfsupplierpaymentsync", "wbfscheduleautopay", "plaidaccounts"
    }

    ''' <summary>Vrai si la page n'existe qu'en accès complet (règlements, synchronisations).</summary>
    Public Shared Function PageAccesComplet(url As String) As Boolean
        If String.IsNullOrEmpty(url) Then Return False
        Dim chemin As String = url
        Dim q As Integer = chemin.IndexOf("?"c)
        If q >= 0 Then chemin = chemin.Substring(0, q)
        Return PagesAccesComplet.Contains(IO.Path.GetFileNameWithoutExtension(chemin))
    End Function

    ''' <summary>
    ''' Le niveau de chaque action ouverte à l'utilisateur dans la compagnie
    ''' (action → niveau, seulement les niveaux qui ouvrent la zone), ou Nothing
    ''' s'il n'est pas restreint. Mis en cache pour la requête HTTP. (T394)
    ''' </summary>
    Public Shared Function Permises(email As String, company As Guid) As Dictionary(Of String, String)
        If String.IsNullOrEmpty(email) OrElse company = Guid.Empty Then Return Nothing
        Dim ctx As HttpContext = HttpContext.Current
        Dim cle As String = "ActionsDossier|" & email.ToLowerInvariant() & "|" & company.ToString()
        If ctx IsNot Nothing AndAlso ctx.Items.Contains(cle) Then Return TryCast(ctx.Items(cle), Dictionary(Of String, String))

        Dim res As Dictionary(Of String, String) = Nothing
        Try
            Using cn As New SqlConnection(System.Configuration.ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s1016GetActionsPermises", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@UserId", email)
                    cmd.Parameters.AddWithValue("@CompanyGUID", company)
                    cn.Open()
                    Using rd As SqlDataReader = cmd.ExecuteReader()
                        While rd.Read()
                            If Not rd.IsDBNull(0) AndAlso rd.GetBoolean(0) Then
                                If res Is Nothing Then res = New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
                                ' Seules les actions dont le niveau ouvre la zone (PermetPage) sont gardées
                                If Not rd.IsDBNull(1) AndAlso Not rd.IsDBNull(3) AndAlso rd.GetBoolean(3) Then
                                    res(rd.GetString(1)) = If(rd.IsDBNull(2), "complet", rd.GetString(2))
                                End If
                            End If
                        End While
                    End Using
                End Using
            End Using
        Catch
            res = Nothing   ' en cas d'erreur, on ne bloque pas l'ERP
        End Try
        If ctx IsNot Nothing Then ctx.Items(cle) = res
        Return res
    End Function

    ''' <summary>Vrai si l'utilisateur peut ouvrir la page dans la compagnie.</summary>
    Public Shared Function PagePermise(email As String, company As Guid, url As String) As Boolean
        Dim a As String = ActionDePage(url)
        If a = "" Then Return True
        Dim p As Dictionary(Of String, String) = Permises(email, company)
        If p Is Nothing Then Return True
        Dim n As String = Nothing
        If Not p.TryGetValue(a, n) Then Return False
        ' Règlements et synchronisations : accès complet seulement
        If PageAccesComplet(url) AndAlso n <> "complet" Then Return False
        Return True
    End Function

    ''' <summary>
    ''' Message du refus d'ouverture d'une page (zone fermée, ou page de règlement /
    ''' de synchronisation en accès restreint), dans la langue.
    ''' </summary>
    Public Shared Function MessageRefusPage(email As String, company As Guid, url As String, lang As String) As String
        Dim a As String = ActionDePage(url)
        Dim niveau As String = NiveauDe(email, company, a)
        Dim l As String = If(lang, "fr").ToLowerInvariant()
        If niveau <> "aucun" AndAlso PageAccesComplet(url) Then
            Dim zone As String = Libelle(a, l)
            If l = "en" Then Return "Your access to """ & zone & """ in this file is restricted (read-only): cash receipts, payments and synchronizations require full access."
            If l = "es" Then Return "Su acceso a «" & zone & "» en este expediente es restringido (solo lectura): los cobros, los pagos y las sincronizaciones requieren el acceso completo."
            Return "Votre accès à « " & zone & " » dans ce dossier est restreint (lecture seule) : les encaissements, les décaissements et les synchronisations demandent l'accès complet."
        End If
        Return MessageRefus("aucun", a, l)
    End Function

    ''' <summary>
    ''' Pour le tableau de bord et les grilles : "" si l'utilisateur peut encaisser
    ''' (sens ENCAISSEMENT, zone Revenus) ou décaisser (DECAISSEMENT, zone Paiements)
    ''' dans le dossier, sinon le message du refus.
    ''' </summary>
    Public Shared Function MessageReglementBloque(email As String, company As Guid, sens As String, lang As String) As String
        Dim url As String = "~/wbfReceiptEditPopup.aspx?sens=" & If(sens, "ENCAISSEMENT")
        If PagePermise(email, company, url) Then Return ""
        Return MessageRefusPage(email, company, url, lang)
    End Function

    ''' <summary>
    ''' Le niveau d'une action pour l'utilisateur de la session (handlers .ashx,
    ''' sans page) : courriel et compagnie lus dans la session. « complet » si
    ''' rien n'est en session (l'appelant vérifie déjà l'authentification).
    ''' </summary>
    Public Shared Function NiveauSession(ctx As HttpContext, action As String) As String
        Try
            If ctx Is Nothing OrElse ctx.Session Is Nothing Then Return "complet"
            Dim company As Guid = Guid.Empty
            If ctx.Session("Company") IsNot Nothing Then company = CType(ctx.Session("Company"), Guid)
            Dim email As String = Convert.ToString(ctx.Session("UserEmail"))
            If String.IsNullOrEmpty(email) AndAlso ctx.Session("UserId") IsNot Nothing Then
                ' Courriel pas encore en session : le relire (s0314GetUserByUserId)
                Using cn As New SqlConnection(System.Configuration.ConfigurationManager.AppSettings("ConnectionString"))
                    Using cmd As New SqlCommand("s0314GetUserByUserId", cn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@Id", Convert.ToInt32(ctx.Session("UserId")))
                        cn.Open()
                        Using rd As SqlDataReader = cmd.ExecuteReader()
                            If rd.Read() Then email = Convert.ToString(rd("Email"))
                        End Using
                    End Using
                End Using
            End If
            If String.IsNullOrEmpty(email) OrElse company = Guid.Empty Then Return "complet"
            Return NiveauDe(email, company, action)
        Catch
            Return "complet"
        End Try
    End Function

    ''' <summary>
    ''' Pour un handler .ashx qui écrit dans une zone : "" si l'utilisateur de la
    ''' session a l'accès complet à cette action dans le dossier courant, sinon le
    ''' message du refus (lecture seule ou aucun accès), dans la langue de la session.
    ''' </summary>
    Public Shared Function RefusHandler(ctx As HttpContext, action As String) As String
        Dim niveau As String = NiveauSession(ctx, action)
        If niveau = "complet" Then Return ""
        Dim lang As String = "fr"
        Try
            If ctx.Session("Lang") IsNot Nothing Then lang = Convert.ToString(ctx.Session("Lang"))
        Catch
        End Try
        Return MessageRefus(niveau, action, lang) &
               If(lang = "en", " Nothing was saved.", If(lang = "es", " No se guardó nada.", " Rien n'a été enregistré."))
    End Function

    ''' <summary>Message du refus d'une écriture selon le niveau (« aucun » ou lecture seule), dans la langue.</summary>
    Public Shared Function MessageRefus(niveau As String, action As String, lang As String) As String
        Dim zone As String = Libelle(action, lang)
        Dim l As String = If(lang, "fr").ToLowerInvariant()
        If niveau = "aucun" Then
            If l = "en" Then Return "Your firm has not given you access to """ & zone & """ in this file."
            If l = "es" Then Return "Su despacho no le dio acceso a «" & zone & "» en este expediente."
            Return "Votre cabinet ne vous a pas donné accès à « " & zone & " » dans ce dossier."
        End If
        If l = "en" Then Return "Read-only access to """ & zone & """: your firm lets you view this area of the file, but not change it."
        If l = "es" Then Return "Acceso de solo lectura a «" & zone & "»: su despacho le permite consultar esta zona del expediente, pero no modificarla."
        Return "Accès en lecture seule à « " & zone & " » : votre cabinet vous permet de consulter cette zone du dossier, mais pas de la modifier."
    End Function

    ''' <summary>
    ''' Le niveau d'accès de l'utilisateur pour une action dans la compagnie :
    ''' « complet » s'il n'est pas restreint, « aucun » si la zone est fermée,
    ''' sinon le code du niveau (ex. « restreint »). Pour qu'une page limite ce
    ''' qu'on y fait selon le niveau.
    ''' </summary>
    Public Shared Function NiveauDe(email As String, company As Guid, action As String) As String
        Dim p As Dictionary(Of String, String) = Permises(email, company)
        If p Is Nothing Then Return "complet"
        Dim n As String = Nothing
        If p.TryGetValue(action, n) Then Return n
        Return "aucun"
    End Function
End Class

''' <summary>Écriture refusée : la zone du dossier est en accès restreint (lecture seule, T395).</summary>
Public Class LectureSeuleException
    Inherits ApplicationException
    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class
