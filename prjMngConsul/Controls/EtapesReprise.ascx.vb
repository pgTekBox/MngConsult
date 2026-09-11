Imports System.Text

''' <summary>
''' Le fil des trois étapes de la reprise du plan comptable, posé en tête de
''' chacune d'elles.
'''
''' Il sert à trois choses : dire où l'on se trouve, permettre d'aller aux deux
''' autres écrans sans repasser par la page d'accueil des importations, et dire
''' où en est l'écran courant — ce qui fonctionne, ce qui manque. Ce dernier
''' point vivait sur la page d'accueil ; il est mieux ici, sous les yeux de
''' celui qui se sert de l'écran.
'''
''' Le numéro du lot voyage d'un écran à l'autre — sans lui, l'étape suivante
''' rouvrirait le dernier lot chargé, qui n'est pas forcément celui qu'on
''' regarde.
''' </summary>
Public Class EtapesReprise
    Inherits System.Web.UI.UserControl

    ''' <summary>1, 2 ou 3 — l'étape où l'on se trouve.</summary>
    Public Property Etape As Integer = 0

    ''' <summary>
    ''' Le lot en cours, passé aux deux autres écrans. À zéro, les liens
    ''' partent sans lot : chaque écran ouvre alors le dernier lot chargé,
    ''' ou dit qu'il n'y en a aucun.
    ''' </summary>
    Public Property LotId As Integer = 0

    Private Structure Cran
        Public No As Integer
        Public Libelle As String
        Public Page As String
        Public Note As Integer
        Public Fait As String
        Public Manque As String
    End Structure

    ''' <summary>
    ''' Les trois étapes et leur état. Les notes reposent sur des essais de
    ''' bout en bout sur un vrai export QuickBooks ; elles se corrigent ici.
    ''' </summary>
    Private Shared ReadOnly Crans As Cran() = {
        New Cran With {
            .No = 1, .Libelle = "Importer le fichier", .Page = "~/ImportPlanComptable.aspx",
            .Note = 9,
            .Fait = "Lit le CSV, reconnaît les colonnes, contrôle les doublons et les lignes " &
                    "invalides, met en préparation. Clé par numéro ou par nom, reconnaissance " &
                    "des comptes déjà au plan dans les quatre langues, aide propre à " &
                    "QuickBooks, glisser-déposer.",
            .Manque = "Ne lit pas les .xlsx — il faut passer par un CSV. L'aide reste à écrire " &
                      "pour Acomba."
        },
        New Cran With {
            .No = 2, .Libelle = "Correspondance des comptes", .Page = "~/CorrespondanceComptes.aspx",
            .Note = 9,
            .Fait = "Propose par numéro, par nom dans les quatre langues, et par IA avec un " &
                    "degré de confiance et un motif. Choix guidé classe ▸ sous-classe ▸ " &
                    "compte. Rien n'est décidé à votre place.",
            .Manque = "Aucun traitement en masse hors « accepter les correspondances par " &
                      "numéro » : le reste se décide ligne par ligne."
        },
        New Cran With {
            .No = 3, .Libelle = "Créer les comptes au plan", .Page = "~/AppliquerPlanComptable.aspx",
            .Note = 8,
            .Fait = "Crée pour de bon les comptes marqués « Créer ». Numéro attribué dans la " &
                    "plage de la classe, contrôles avant écriture, tout ou rien, rejouable " &
                    "sans rien recréer.",
            .Manque = "Ne met pas à jour un compte existant et n'en désactive aucun. Un plan " &
                      "repris de travers se corrige encore à la main."
        }
    }

    ''' <summary>
    ''' La note du parcours entier, pour la page d'accueil des importations :
    ''' un parcours ne vaut que son étape la plus faible.
    ''' </summary>
    Public Shared ReadOnly Property NoteParcours As Integer
        Get
            Return Crans.Min(Function(c) c.Note)
        End Get
    End Property

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        litFil.Text = RendreFil()
        litEtat.Text = RendreEtat()
    End Sub

    Private Function RendreFil() As String
        Dim sb As New StringBuilder()

        For Each c In Crans
            ' Les trois crans sont des liens, toujours. Sans lot, ils partent
            ' sans : chaque écran ouvre alors le dernier lot chargé, ou dit
            ' qu'il n'y en a aucun. L'étape courante reste surlignée.
            Dim url = ResolveUrl(c.Page)
            If LotId > 0 Then url &= "?lot=" & LotId.ToString()

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
    ''' L'état de l'écran courant. Replié par défaut : il renseigne sans
    ''' encombrer celui qui vient simplement faire son travail.
    ''' </summary>
    Private Function RendreEtat() As String
        Dim courant = Crans.FirstOrDefault(Function(c) c.No = Etape)
        If courant.No = 0 Then Return ""

        Dim teinte = If(courant.Note >= 8, "vert", If(courant.Note >= 5, "jaune", "orange"))

        Dim sb As New StringBuilder()
        sb.Append("<details class='etat'><summary>")
        sb.Append("État de cet écran <span class='nt ").Append(teinte).Append("'>")
        sb.Append(courant.Note).Append("/10</span></summary>")
        sb.Append("<p class='fait'><b>Ce qui fonctionne.</b> ").Append(Server.HtmlEncode(courant.Fait)).Append("</p>")
        sb.Append("<p class='manque'><b>Ce qui manque.</b> ").Append(Server.HtmlEncode(courant.Manque)).Append("</p>")
        sb.Append("</details>")

        Return sb.ToString()
    End Function

End Class
