Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

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
        {"importations", "parametres"}
    }

    ''' <summary>L'action d'une page (« ~/wbfX.aspx?y=1 », « /wbfX »…) ou "" si la page est libre.</summary>
    Public Shared Function ActionDePage(url As String) As String
        If String.IsNullOrEmpty(url) Then Return ""
        Dim chemin As String = url
        Dim q As Integer = chemin.IndexOf("?"c)
        If q >= 0 Then chemin = chemin.Substring(0, q)
        Dim nom As String = IO.Path.GetFileNameWithoutExtension(chemin)
        Dim a As String = Nothing
        If PageAction.TryGetValue(nom, a) Then Return a
        Return ""
    End Function

    ''' <summary>
    ''' Les actions permises à l'utilisateur dans la compagnie, ou Nothing s'il
    ''' n'est pas restreint. Mis en cache pour la requête HTTP.
    ''' </summary>
    Public Shared Function Permises(email As String, company As Guid) As HashSet(Of String)
        If String.IsNullOrEmpty(email) OrElse company = Guid.Empty Then Return Nothing
        Dim ctx As HttpContext = HttpContext.Current
        Dim cle As String = "ActionsDossier|" & email.ToLowerInvariant() & "|" & company.ToString()
        If ctx IsNot Nothing AndAlso ctx.Items.Contains(cle) Then Return TryCast(ctx.Items(cle), HashSet(Of String))

        Dim res As HashSet(Of String) = Nothing
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
                                If res Is Nothing Then res = New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
                                If Not rd.IsDBNull(1) Then res.Add(rd.GetString(1))
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
        Dim p As HashSet(Of String) = Permises(email, company)
        Return p Is Nothing OrElse p.Contains(a)
    End Function
End Class
