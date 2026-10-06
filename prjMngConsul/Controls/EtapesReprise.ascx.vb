Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Le fil des trois étapes de la reprise du plan comptable, posé en tête de
''' chacune d'elles.
'''
''' Il sert à trois choses : dire où l'on se trouve, permettre d'aller aux deux
''' autres écrans sans repasser par la page d'accueil des importations, et dire
''' où en est la reprise à cette étape — par une note qui suit les données de
''' la compagnie, pas l'état du code : 10/10 quand l'étape est faite.
'''
'''   étape 1 : 10 dès que le plan est chargé, 0 sinon ;
'''   étape 2 : la part des comptes décidés, 10 quand il n'en reste aucun ;
'''   étape 3 : la part des comptes « Créer » créés, 10 quand il n'en reste
'''             aucun à créer.
'''
''' Ce que l'écran sait faire et ne sait pas encore faire reste dit en dessous,
''' replié : c'est une autre information, elle ne change qu'avec le code.
''' </summary>
Public Class EtapesReprise
    Inherits System.Web.UI.UserControl

    ''' <summary>1, 2 ou 3 — l'étape où l'on se trouve.</summary>
    Public Property Etape As Integer = 0

    Private Structure Cran
        Public No As Integer
        Public Libelle As String
        Public Page As String
        Public Fait As String
        Public Manque As String
    End Structure

    ''' <summary>
    ''' Les trois étapes, et ce que chaque écran sait faire. Ces textes
    ''' décrivent le code ; ils se corrigent ici.
    ''' </summary>
    Private Shared ReadOnly Crans As Cran() = {
        New Cran With {
            .No = 1, .Libelle = "Importer le fichier", .Page = "~/ImportPlanComptable.aspx",
            .Fait = "Lit le plan par QuickBooks en direct ou par un fichier CSV, reconnaît les colonnes, " &
                    "contrôle les doublons et les lignes invalides, met en préparation. Clé par numéro ou " &
                    "par nom, reconnaissance des comptes déjà au plan dans les quatre langues, aide propre à " &
                    "QuickBooks, glisser-déposer.",
            .Manque = "Ne lit pas les .xlsx — il faut passer par un CSV. L'aide reste à écrire " &
                      "pour Acomba."
        },
        New Cran With {
            .No = 2, .Libelle = "Correspondance des comptes", .Page = "~/CorrespondanceComptes.aspx",
            .Fait = "Propose par numéro, par nom dans les quatre langues, et par IA avec un " &
                    "degré de confiance et un motif. Choix guidé classe ▸ sous-classe ▸ " &
                    "compte. Rien n'est décidé à votre place.",
            .Manque = "Aucun traitement en masse hors « accepter les correspondances par " &
                      "numéro » : le reste se décide ligne par ligne."
        },
        New Cran With {
            .No = 3, .Libelle = "Créer les comptes au plan", .Page = "~/AppliquerPlanComptable.aspx",
            .Fait = "Crée pour de bon les comptes marqués « Créer ». Numéro attribué dans la " &
                    "plage de la sous-classe, contrôles avant écriture, tout ou rien, rejouable " &
                    "sans rien recréer.",
            .Manque = "Ne met pas à jour un compte existant et n'en désactive aucun. Un plan " &
                      "repris de travers se corrige encore à la main."
        }
    }

    ''' <summary>Où en est la reprise du plan de la compagnie : les décomptes de l'étape 3 (s0766).</summary>
    Private Structure Avancement
        Public Lu As Boolean
        Public Total As Integer
        Public ADecider As Integer
        Public ACreer As Integer
        Public Crees As Integer
    End Structure

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        litFil.Text = RendreFil()
        litEtat.Text = RendreEtat()
    End Sub

    Private Function RendreFil() As String
        Dim sb As New StringBuilder()

        For Each c In Crans
            ' Les trois crans sont des liens, toujours : il n'y a qu'un plan
            ' comptable en préparation par compagnie, donc rien à désigner dans
            ' l'adresse. L'étape courante reste surlignée.
            Dim url = ResolveUrl(c.Page)

            sb.Append("<a href='").Append(url).Append("'")
            If c.No = Etape Then sb.Append(" class='ici'")
            sb.Append(">")
            sb.Append("<span class='no'>").Append(c.No).Append("</span>")
            sb.Append("<span class='lib'>").Append(Server.HtmlEncode(c.Libelle)).Append("</span>")
            sb.Append("</a>")
        Next

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Les décomptes de la reprise, lus par la page hôte — c'est elle qui porte
    ''' la compagnie et la base. Sans hôte, ou si la lecture échoue : rien de
    ''' lu, et la note reste à zéro plutôt que de mentir.
    ''' </summary>
    Private Function LireAvancement() As Avancement
        Dim av As New Avancement With {.Lu = False}
        Dim hote As clsData = TryCast(Page, clsData)
        If hote Is Nothing Then Return av

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", hote.Company))
            Dim ds As DataSet = hote.ExecuteSQLds("s0766GetAAppliquer", p)
            If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(1).Rows.Count = 0 Then Return av

            Dim r As DataRow = ds.Tables(1).Rows(0)
            av.Lu = True
            av.Total = Entier(r("Total"))
            av.ADecider = Entier(r("ADecider"))
            av.ACreer = Entier(r("ACreer"))
            av.Crees = Entier(r("DejaCrees"))
        Catch
            av.Lu = False
        End Try

        Return av
    End Function

    Private Shared Function Entier(v As Object) As Integer
        Return If(v Is Nothing OrElse IsDBNull(v), 0, Convert.ToInt32(v))
    End Function

    ''' <summary>Une part sur dix, bornée : jamais 10 tant qu'il reste à faire, jamais 0 dès qu'on a commencé.</summary>
    Private Shared Function PartSurDix(faits As Integer, total As Integer) As Integer
        If total <= 0 Then Return 0
        If faits >= total Then Return 10
        Dim n As Integer = CInt(Math.Round(10.0 * faits / total))
        If n >= 10 Then n = 9
        If n <= 0 AndAlso faits > 0 Then n = 1
        Return n
    End Function

    ''' <summary>
    ''' La note et les deux phrases de l'étape courante, d'après l'avancement.
    ''' </summary>
    Private Sub NoterEtape(av As Avancement, ByRef note As Integer, ByRef fait As String, ByRef reste As String)
        note = 0 : fait = "" : reste = ""

        If Not av.Lu OrElse av.Total = 0 Then
            fait = "Aucun plan comptable chargé pour cette compagnie."
            reste = If(Etape = 1,
                       "Importer le plan — par QuickBooks en direct ou par un fichier — : la note passe à 10 dès qu'il est chargé.",
                       "Commencer par l'étape 1 : rien ne peut se décider ni se créer sans plan chargé.")
            Return
        End If

        Dim decides As Integer = av.Total - av.ADecider

        Select Case Etape
            Case 1
                note = 10
                fait = "Plan chargé : " & av.Total & " compte(s) retenu(s) en préparation."
                reste = "Rien ici. Rechargez seulement si l'ancien logiciel a changé ; vos décisions à clé inchangée seront conservées."

            Case 2
                note = PartSurDix(decides, av.Total)
                fait = decides & " compte(s) décidé(s) sur " & av.Total & "."
                reste = If(av.ADecider = 0, "Rien : tous les comptes sont décidés.",
                           av.ADecider & " compte(s) encore à décider — lier, créer ou ignorer.")

            Case 3
                note = PartSurDix(av.Crees, av.Crees + av.ACreer)
                If av.Crees + av.ACreer = 0 Then note = 10
                fait = If(av.Crees + av.ACreer = 0,
                          "Aucun compte à créer : tout est lié ou ignoré.",
                          av.Crees & " compte(s) créé(s) sur " & (av.Crees + av.ACreer) & " marqué(s) « Créer ».")
                reste = If(av.ACreer = 0, "Rien : tout ce qui devait être créé l'est.",
                           av.ACreer & " compte(s) à créer." &
                           If(av.ADecider > 0, " Et " & av.ADecider & " compte(s) encore à décider à l'étape 2.", ""))
        End Select
    End Sub

    ''' <summary>
    ''' L'état de l'étape courante : la note de la reprise en tête, puis, replié,
    ''' ce que l'écran sait faire.
    ''' </summary>
    Private Function RendreEtat() As String
        Dim courant = Crans.FirstOrDefault(Function(c) c.No = Etape)
        If courant.No = 0 Then Return ""

        Dim note As Integer, fait As String = "", reste As String = ""
        NoterEtape(LireAvancement(), note, fait, reste)

        Dim teinte = If(note >= 8, "vert", If(note >= 5, "jaune", "orange"))

        Dim sb As New StringBuilder()
        sb.Append("<details class='etat'><summary>")
        sb.Append("État de cette étape <span class='nt ").Append(teinte).Append("'>")
        sb.Append(note).Append("/10</span></summary>")
        sb.Append("<p class='fait'><b>Où en est la reprise.</b> ").Append(Server.HtmlEncode(fait)).Append("</p>")
        sb.Append("<p class='manque'><b>Ce qui reste.</b> ").Append(Server.HtmlEncode(reste)).Append("</p>")
        sb.Append("<p class='fait'><b>Ce que l'écran sait faire.</b> ").Append(Server.HtmlEncode(courant.Fait)).Append("</p>")
        sb.Append("<p class='manque'><b>Ce qu'il ne sait pas encore faire.</b> ").Append(Server.HtmlEncode(courant.Manque)).Append("</p>")
        sb.Append("</details>")

        Return sb.ToString()
    End Function

End Class
