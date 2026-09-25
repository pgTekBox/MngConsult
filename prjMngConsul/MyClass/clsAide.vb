Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Web.Caching

''' <summary>
''' L'aide en ligne de l'ERP : un fichier HTML par section dans le dossier Aide/,
''' trilingue (trois blocs &lt;article lang="fr|en|es"&gt; dans chaque fichier).
'''   - SectionPourPage : la section d'aide d'une page (chemin virtuel ~/wbfXxx.aspx).
'''   - Url             : l'adresse à ouvrir dans la fenêtre d'aide (avec ?lang=).
'''   - Texte           : le texte de l'aide dans une langue, pour l'assistant IA
'''                       (balises retirées, mis en cache tant que les fichiers ne changent pas).
''' </summary>
Public NotInheritable Class clsAide

    Private Sub New()
    End Sub

    ''' <summary>Les sections, dans l'ordre du menu. Clé = nom du fichier sans extension.</summary>
    Public Shared ReadOnly Sections As String() = {
        "tableau-de-bord", "ventes", "achats", "produits", "comptabilite", "rapports",
        "importation", "agenda", "employes", "courriel", "approbations", "administration"}

    ''' <summary>Titre d'une section dans une langue (pour l'assistant et le sommaire).</summary>
    Public Shared Function Titre(section As String, langue As String) As String
        Dim fr As String = "", en As String = "", es As String = ""
        Select Case section
            Case "tableau-de-bord" : fr = "Tableau de bord" : en = "Dashboard" : es = "Panel de control"
            Case "ventes" : fr = "Ventes" : en = "Sales" : es = "Ventas"
            Case "achats" : fr = "Achats" : en = "Purchases" : es = "Compras"
            Case "produits" : fr = "Produits et services" : en = "Products and services" : es = "Productos y servicios"
            Case "comptabilite" : fr = "Comptabilité" : en = "Accounting" : es = "Contabilidad"
            Case "rapports" : fr = "Rapports" : en = "Reports" : es = "Informes"
            Case "importation" : fr = "Importation des données" : en = "Data import" : es = "Importación de datos"
            Case "agenda" : fr = "Agenda" : en = "Agenda" : es = "Agenda"
            Case "employes" : fr = "Employés" : en = "Employees" : es = "Empleados"
            Case "courriel" : fr = "Courriel" : en = "Mail" : es = "Correo"
            Case "approbations" : fr = "Tâches à approuver" : en = "Tasks to approve" : es = "Tareas por aprobar"
            Case "administration" : fr = "Administration et compte" : en = "Administration and account" : es = "Administración y cuenta"
            Case Else : fr = "Aide" : en = "Help" : es = "Ayuda"
        End Select
        Select Case langue
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>
    ''' La section d'aide d'une page, d'après son nom de fichier (sans le dossier,
    ''' sans distinction de casse). Les pages inconnues tombent sur le sommaire.
    ''' </summary>
    Public Shared Function SectionPourPage(cheminVirtuel As String) As String
        Dim nom As String = If(cheminVirtuel, "")
        Dim i As Integer = nom.LastIndexOf("/"c)
        If i >= 0 Then nom = nom.Substring(i + 1)
        nom = nom.ToLowerInvariant()
        If nom.EndsWith(".aspx") Then nom = nom.Substring(0, nom.Length - 5)

        Select Case nom
            Case "default" : Return "tableau-de-bord"
            Case "wbfcustomers", "wbfcustomeredit", "wbfcustomersinvoices", "wbfinvoiceedit", "wbfcustomerpaymentlink", "wbfscannedpdf" : Return "ventes"
            Case "wbfsuppliers", "wbfsupplieredit", "wbfsuppliersinvoices", "wbfsupplierinvoinceedit", "wbfsupplierpaymentchoice",
                 "wbfsupplierpaymentdream", "wbfsupplierpaymentinterac", "wbfsupplierpaymentsuccess", "wbfsupplierpaymentsync",
                 "wbfsupplierstripeonboarding", "wbfreceipt", "wbfreceiptedit", "wbfreceipteditpopup", "receipts" : Return "achats"
            Case "wbfproducts", "wbfproductedit", "wbfproductcategory", "wbfproductcategoryedit" : Return "produits"
            Case "wbfjournal", "wbfjournallist", "wbfjournalentryedit", "wbftemplate", "wbftemplatelist", "wbftemplateedit",
                 "plaidaccounts", "wbfreleve", "wbfrapporttaxe", "wbffermetureannee", "wbfplancomptable", "wbfplancomptableedit" : Return "comptabilite"
            Case "wbfrapportplancomptable", "wbfetatresultats", "wbfbilan", "wbffluxtresorerie", "wbfbeneficesnonrepartis",
                 "wbfbalanceverification", "wbfaipaiement", "wbfaisale" : Return "rapports"
            Case "importations", "importapideck", "importplancomptable", "correspondancecomptes", "appliquerplancomptable",
                 "importclients", "importfournisseurs", "importproduits", "importbalanceverification", "wbfimport", "wbfimportview" : Return "importation"
            Case "wbfagenda", "wbfappointmentedit" : Return "agenda"
            Case "wbfemployees", "wbfemployeeedit", "wbfmailboxreset" : Return "employes"
            Case "wbfmailbox" : Return "courriel"
            Case "wbfapprobations" : Return "approbations"
            Case "wbfnewuser", "wbfusers", "wbfuseredit", "wbfsetting", "wbfpaymentprocessors", "squareoauth",
                 "wbfautopayauthorizations", "wbfautopayschedule", "wbfautopayhistory", "wbfscheduleautopay",
                 "wbfpayment", "wbfpaymentsuccess", "wbflogin", "wbfregister", "wbfforgotpassword", "wbfresetpassword",
                 "wbfactivate", "wbfverifycompanymail", "wbfassistant" : Return "administration"
            Case Else
                If nom.StartsWith("valider") Then Return "importation"
                Return "index"
        End Select
    End Function

    ''' <summary>L'adresse relative (~/Aide/xxx.html?lang=fr) d'une section.</summary>
    Public Shared Function Url(section As String, langue As String) As String
        Dim s As String = If(String.IsNullOrEmpty(section), "index", section)
        Dim l As String = If(langue = "en" OrElse langue = "es", langue, "fr")
        Return "~/Aide/" & s & ".html?lang=" & l
    End Function

    ''' <summary>
    ''' Le texte de l'aide dans une langue, toutes sections dans l'ordre (ou une
    ''' seule si demandée), pour l'assistant IA. Relu quand un fichier change.
    ''' </summary>
    Public Shared Function Texte(langue As String, Optional section As String = Nothing) As String
        Dim l As String = If(langue = "en" OrElse langue = "es", langue, "fr")
        Dim liste As IEnumerable(Of String) = If(String.IsNullOrEmpty(section), Sections, New String() {section})
        Dim sb As New StringBuilder()
        For Each s In liste
            Dim t As String = TexteSection(s, l)
            If t.Length = 0 Then Continue For
            sb.AppendLine("# " & Titre(s, l) & " (" & s & ")")
            sb.AppendLine(t)
            sb.AppendLine()
        Next
        Return sb.ToString()
    End Function

    Private Shared Function TexteSection(section As String, langue As String) As String
        Dim chemin As String = HttpContext.Current.Server.MapPath("~/Aide/" & section & ".html")
        Dim cle As String = "AideTexte:" & section & ":" & langue
        Dim enCache As String = TryCast(HttpRuntime.Cache(cle), String)
        If enCache IsNot Nothing Then Return enCache
        If Not File.Exists(chemin) Then Return ""

        Dim html As String = File.ReadAllText(chemin, Encoding.UTF8)
        ' On ne garde que l'article de la langue demandée.
        Dim m As Match = Regex.Match(html, "<article[^>]*lang=""" & langue & """[^>]*>([\s\S]*?)</article>", RegexOptions.IgnoreCase)
        If m.Success Then html = m.Groups(1).Value
        html = Regex.Replace(html, "<style[\s\S]*?</style>|<script[\s\S]*?</script>|<nav[\s\S]*?</nav>|<header[\s\S]*?</header>", " ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "</(h1|h2|h3|h4|p|li|tr|div|dt|dd|details|summary)>", vbLf, RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<(td|th)[^>]*>", " | ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<h2[^>]*>", vbLf & "## ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<h3[^>]*>", vbLf & "### ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<h4[^>]*>", vbLf & "#### ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<li[^>]*>", "- ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<[^>]+>", "")
        html = HttpUtility.HtmlDecode(html)
        html = Regex.Replace(html, "[ \t]+", " ")
        html = Regex.Replace(html, "(\r?\n\s*){3,}", vbLf & vbLf)
        Dim texte As String = html.Trim()
        HttpRuntime.Cache.Insert(cle, texte, New CacheDependency(chemin))
        Return texte
    End Function

End Class
