Imports System.Text

''' <summary>
''' Le fil des trois étapes de la reprise du plan comptable, posé en tête de
''' chacune d'elles.
'''
''' Il sert à deux choses : dire où l'on se trouve, et permettre d'aller aux
''' deux autres écrans sans repasser par la page d'accueil des importations.
''' Le numéro du lot voyage d'un écran à l'autre — sans lui, l'étape suivante
''' rouvrirait le dernier lot chargé, qui n'est pas forcément celui qu'on
''' regarde.
''' </summary>
Public Class EtapesReprise
    Inherits System.Web.UI.UserControl

    ''' <summary>1, 2 ou 3 — l'étape où l'on se trouve.</summary>
    Public Property Etape As Integer = 0

    ''' <summary>
    ''' Le lot en cours. À zéro, les étapes 2 et 3 restent affichées mais
    ''' éteintes : il n'y a rien à leur montrer tant qu'aucun fichier n'est
    ''' chargé, et un lien qui mène à un écran vide est pire qu'un lien absent.
    ''' </summary>
    Public Property LotId As Integer = 0

    Private Structure Cran
        Public No As Integer
        Public Libelle As String
        Public Page As String
    End Structure

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender

        Dim crans = New Cran() {
            New Cran With {.No = 1, .Libelle = "Importer le fichier", .Page = "~/ImportPlanComptable.aspx"},
            New Cran With {.No = 2, .Libelle = "Correspondance des comptes", .Page = "~/CorrespondanceComptes.aspx"},
            New Cran With {.No = 3, .Libelle = "Créer les comptes au plan", .Page = "~/AppliquerPlanComptable.aspx"}
        }

        Dim sb As New StringBuilder()

        For Each c In crans

            ' L'étape courante ne se clique pas : on y est déjà.
            If c.No = Etape Then
                sb.Append("<span class='cran ici'>")
                sb.Append("<span class='no'>").Append(c.No).Append("</span>")
                sb.Append("<span class='lib'>").Append(Server.HtmlEncode(c.Libelle)).Append("</span>")
                sb.Append("</span>")
                Continue For
            End If

            ' Les étapes 2 et 3 n'ont de sens qu'avec un lot.
            If c.No > 1 AndAlso LotId = 0 Then
                sb.Append("<span class='cran hors' title='Chargez d''abord un fichier'>")
                sb.Append("<span class='no'>").Append(c.No).Append("</span>")
                sb.Append("<span class='lib'>").Append(Server.HtmlEncode(c.Libelle)).Append("</span>")
                sb.Append("</span>")
                Continue For
            End If

            Dim url = ResolveUrl(c.Page)
            If LotId > 0 Then url &= "?lot=" & LotId.ToString()

            sb.Append("<a href='").Append(url).Append("'>")
            sb.Append("<span class='no'>").Append(c.No).Append("</span>")
            sb.Append("<span class='lib'>").Append(Server.HtmlEncode(c.Libelle)).Append("</span>")
            sb.Append("</a>")
        Next

        litFil.Text = sb.ToString()
    End Sub

End Class
