Imports System.Text

''' <summary>
''' « D'où viennent vos données ? » — le logiciel d'origine, le séparateur,
''' l'encodage, et la marche à suivre pour sortir le bon fichier du bon
''' logiciel.
'''
''' Le même bloc sert à chaque écran d'importation : seul change ce qu'on
''' importe (<see cref="Donnees"/>), donc le rapport à sortir. L'écran qui le
''' pose lit ensuite <see cref="Separateur"/> et <see cref="Encodage"/> pour
''' lire le fichier.
''' </summary>
Public Class SourceDonnees
    Inherits System.Web.UI.UserControl

    ''' <summary>CLIENTS, FOURNISSEURS, PRODUITS ou BALANCE.</summary>
    Public Property Donnees As String = "CLIENTS"

    ''' <summary>Le numéro de l'étape affiché devant le titre.</summary>
    Public Property Numero As String = "1"

    ''' <summary>
    ''' Le tableau des colonnes attendues, bâti par l'écran qui sait ce qu'il
    ''' cherche. Vide : le tableau n'est pas affiché.
    ''' </summary>
    Public Property ColonnesHtml As String = ""

#Region "Ce que l'écran lit"

    Public ReadOnly Property Systeme As String
        Get
            Return ddlSysteme.SelectedValue
        End Get
    End Property

    Public ReadOnly Property NomSysteme As String
        Get
            Return If(ddlSysteme.SelectedItem Is Nothing, "", ddlSysteme.SelectedItem.Text)
        End Get
    End Property

    Public ReadOnly Property Separateur As Char
        Get
            Select Case ddlSeparateur.SelectedValue
                Case "TAB" : Return ControlChars.Tab
                Case ";" : Return ";"c
                Case Else : Return ","c
            End Select
        End Get
    End Property

    Public ReadOnly Property Encodage As Encoding
        Get
            Select Case ddlEncodage.SelectedValue
                Case "Windows-1252" : Return Encoding.GetEncoding(1252)
                Case "ISO-8859-1" : Return Encoding.GetEncoding("ISO-8859-1")
                Case Else : Return New UTF8Encoding(False)
            End Select
        End Get
    End Property

#End Region

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ddlSysteme.Items.Clear()
        For Each l In Logiciels
            ddlSysteme.Items.Add(New ListItem(l.Nom, l.Code))
        Next
        ddlSysteme.SelectedValue = "QBO"

        Appliquer()
    End Sub

    Protected Sub ddlSysteme_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlSysteme.SelectedIndexChanged
        Appliquer()
    End Sub

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        litNumero.Text = Server.HtmlEncode(Numero)
        litColonnes.Text = ColonnesHtml
        pnlColonnes.Visible = Not String.IsNullOrEmpty(ColonnesHtml)
    End Sub

    ''' <summary>
    ''' Chaque logiciel a ses habitudes d'export : on les propose plutôt que de
    ''' les laisser deviner. Les avertissements passent avant les étapes — ce
    ''' sont eux qui font échouer l'export, et les lire après coup ne sert plus.
    ''' </summary>
    Private Sub Appliquer()
        Dim g = Guide(ddlSysteme.SelectedValue)

        ddlSeparateur.SelectedValue = g.Separateur
        ddlEncodage.SelectedValue = g.Encodage
        litNomSysteme.Text = Server.HtmlEncode(g.Nom)
        litCheminExport.Text = g.CheminExport
        litAideTitre.Text = Server.HtmlEncode(g.Nom)

        pnlAideSysteme.Visible = g.AAide
        pnlAideAbsente.Visible = Not g.AAide

        If Not g.AAide Then
            litAideAbsente.Text = "La marche à suivre propre à <b>" & Server.HtmlEncode(g.Nom) &
                                  "</b> n'est pas encore rédigée. Les colonnes attendues, elles, " &
                                  "sont les mêmes quel que soit le logiciel d'origine."
            litAideCorps.Text = ""
            Return
        End If

        Dim sb As New StringBuilder()

        If g.NomRapport <> "" Then
            sb.Append("<p class='sd-rapport'>Le rapport à sortir : <b>").Append(Server.HtmlEncode(g.NomRapport)).Append("</b></p>")
        End If

        For Each a In g.Avertissements
            sb.Append("<div class='sd-avert'><span>⚠️</span><p>").Append(a).Append("</p></div>")
        Next

        sb.Append("<h4 class='sd-t'>Comment sortir le fichier</h4><ol class='sd-etapes'>")
        For Each e In g.Etapes
            sb.Append("<li>").Append(e).Append("</li>")
        Next
        sb.Append("</ol>")

        If g.Astuces.Count > 0 Then
            sb.Append("<h4 class='sd-t'>Bon à savoir</h4><ul class='sd-astuces'>")
            For Each a In g.Astuces
                sb.Append("<li>").Append(a).Append("</li>")
            Next
            sb.Append("</ul>")
        End If

        litAideCorps.Text = sb.ToString()
    End Sub

#End Region

#Region "Les logiciels, et ce qu'il faut en sortir"

    Private Class Logiciel
        Public Code As String
        Public Nom As String
        Public Separateur As String
        Public Encodage As String
    End Class

    ''' <summary>Ajouter un logiciel, c'est ajouter une entrée ici et sa marche à suivre plus bas.</summary>
    Private Shared ReadOnly Logiciels As Logiciel() = {
        New Logiciel With {.Code = "QBO", .Nom = "QuickBooks", .Separateur = ",", .Encodage = "UTF-8"},
        New Logiciel With {.Code = "ACOMBA", .Nom = "Acomba", .Separateur = ";", .Encodage = "Windows-1252"},
        New Logiciel With {.Code = "AUTRE", .Nom = "Autre logiciel", .Separateur = ";", .Encodage = "UTF-8"}
    }

    ''' <summary>Ce qu'on importe, dit comme on le dirait à quelqu'un.</summary>
    Private Function Quoi() As String
        Select Case Donnees
            Case "FOURNISSEURS" : Return "la liste de vos fournisseurs"
            Case "PRODUITS" : Return "la liste de vos produits et services"
            Case "BALANCE" : Return "la balance de vérification, à la date de bascule,"
            Case Else : Return "la liste de vos clients"
        End Select
    End Function

    Private Function Unite() As String
        Select Case Donnees
            Case "FOURNISSEURS" : Return "fournisseur"
            Case "PRODUITS" : Return "produit ou service"
            Case "BALANCE" : Return "compte"
            Case Else : Return "client"
        End Select
    End Function

    Private Function Guide(code As String) As ImportComptableBase.SystemeSource
        Dim l = Logiciels.FirstOrDefault(Function(x) x.Code = code)
        If l Is Nothing Then l = Logiciels.Last()

        Dim g As New ImportComptableBase.SystemeSource With {
            .Code = l.Code, .Nom = l.Nom, .Separateur = l.Separateur, .Encodage = l.Encodage
        }

        Select Case l.Code
            Case "QBO"
                RemplirQuickBooks(g)
            Case "ACOMBA"
                g.CheminExport = "exportez " & Quoi() & " vers Excel ou en CSV, puis enregistrez-la en CSV."
            Case Else
                g.CheminExport = "exportez " & Quoi() & " en CSV — une ligne par " & Unite() &
                                 ", avec une ligne d'en-tête."
        End Select

        Return g
    End Function

    ''' <summary>
    ''' QuickBooks en ligne. Les libellés sont ceux de l'interface française ;
    ''' ils bougent d'une version à l'autre, d'où les chemins de rechange.
    ''' </summary>
    Private Sub RemplirQuickBooks(g As ImportComptableBase.SystemeSource)

        Const EnCsv As String = "Ouvrez le fichier obtenu dans Excel, puis <b>Fichier ▸ Enregistrer sous ▸ CSV UTF-8</b>."
        Const Deposer As String = "Revenez ici et déposez le fichier CSV."
        Const PasXlsx As String = "QuickBooks exporte vers <b>Excel</b>. Cette page ne lit pas les fichiers " &
                                  "<code>.xlsx</code> : ouvrez-le dans Excel et enregistrez-le en CSV."
        Const Adresse As String = "L'adresse sort souvent en un seul bloc (« 123 rue Principale, Montréal QC H2X 1Y4 »). " &
                                  "La lecture directe la garde telle quelle ; <b>Extraire avec l'IA</b> la découpe en " &
                                  "rue, ville, province et code postal."

        Select Case Donnees

            Case "FOURNISSEURS"
                g.NomRapport = "La liste des fournisseurs — « Vendors » dans QuickBooks en anglais"
                g.CheminExport = "Dépenses ▸ Fournisseurs ▸ icône <b>Exporter vers Excel</b>, au-dessus de la liste"
                g.Etapes = New List(Of String) From {
                    "Ouvrez <b>Dépenses ▸ Fournisseurs</b> dans le menu de gauche. Selon votre version, la liste est aussi sous <b>Payer des factures ▸ Fournisseurs</b>.",
                    "Au-dessus de la liste, à droite, cliquez sur l'icône <b>Exporter vers Excel</b>.",
                    EnCsv, Deposer
                }
                g.Avertissements = New List(Of String) From {PasXlsx}
                g.Astuces = New List(Of String) From {
                    Adresse,
                    "Un fournisseur dont le nom existe déjà dans l'application — y compris comme client — n'est pas recréé : il est signalé, et laissé tel quel.",
                    "Le solde dû n'est pas repris ici : il viendra des factures fournisseurs ouvertes."
                }

            Case "PRODUITS"
                g.NomRapport = "La liste des produits et services — « Products and Services » en anglais"
                g.CheminExport = "Ventes ▸ Produits et services ▸ icône <b>Exporter vers Excel</b>, au-dessus de la liste"
                g.Etapes = New List(Of String) From {
                    "Ouvrez <b>Ventes ▸ Produits et services</b>. On y arrive aussi par <b>⚙️ ▸ Listes ▸ Produits et services</b>.",
                    "Au-dessus de la liste, à droite, cliquez sur l'icône <b>Exporter vers Excel</b>.",
                    EnCsv, Deposer
                }
                g.Avertissements = New List(Of String) From {PasXlsx}
                g.Astuces = New List(Of String) From {
                    "Le prix repris est le <b>prix de vente</b> ; le coût d'achat ne l'est pas.",
                    "Chaque produit reçoit les comptes de revenus et de dépenses par défaut de votre compagnie ; la catégorie se choisit ensuite dans sa fiche.",
                    "Un produit dont le nom existe déjà n'est pas recréé : il est signalé, et laissé tel quel."
                }

            Case "BALANCE"
                g.NomRapport = "Balance de vérification — « Trial Balance » en anglais"
                g.CheminExport = "Rapports ▸ Balance de vérification ▸ <b>Exporter vers Excel</b>"
                g.Etapes = New List(Of String) From {
                    "Ouvrez <b>Rapports</b> et cherchez <b>Balance de vérification</b>.",
                    "Réglez la période pour qu'elle se termine à la <b>date de bascule</b> — la veille du premier jour tenu ici — puis cliquez sur <b>Exécuter le rapport</b>.",
                    "Cliquez sur l'icône d'<b>exportation</b>, puis sur <b>Exporter vers Excel</b>.",
                    EnCsv, Deposer
                }
                g.Avertissements = New List(Of String) From {
                    "La date compte plus que tout : une balance tirée à la mauvaise date est équilibrée, mais ses soldes d'ouverture sont faux.",
                    PasXlsx
                }
                g.Astuces = New List(Of String) From {
                    "Les lignes de titre, la ligne TOTAL et le pied de page du rapport sont écartés d'eux-mêmes ; le total du fichier sert à contrôler la lecture.",
                    "Pas de numéros de comptes ? C'est normal avec QuickBooks en ligne : le nom du compte suffit."
                }

            Case Else ' CLIENTS
                g.NomRapport = "La liste des clients — « Customers » dans QuickBooks en anglais"
                g.CheminExport = "Ventes ▸ Clients ▸ icône <b>Exporter vers Excel</b>, au-dessus de la liste"
                g.Etapes = New List(Of String) From {
                    "Ouvrez <b>Ventes ▸ Clients</b> dans le menu de gauche. Selon votre version, la liste est aussi sous <b>Obtenir des paiements ▸ Clients</b>.",
                    "Au-dessus de la liste, à droite, cliquez sur l'icône <b>Exporter vers Excel</b>.",
                    EnCsv, Deposer
                }
                g.Avertissements = New List(Of String) From {PasXlsx}
                g.Astuces = New List(Of String) From {
                    Adresse,
                    "Un client dont le nom existe déjà dans l'application n'est pas recréé : il est signalé, et laissé tel quel.",
                    "Le solde des clients n'est pas repris ici : les montants dus viendront des factures ouvertes."
                }
        End Select
    End Sub

#End Region

End Class
