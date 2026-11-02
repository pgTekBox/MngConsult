''' <summary>
''' « Activités de l'Avatar 60 » du Portail comptable : le journal de tout ce que
''' l'avatar 60 a fait seul pour les clients du cabinet, selon les droits convenus
''' avec chacun. Calqué exactement sur la maquette d'Yves (tuiles de synthèse,
''' filtres période / résultat / famille / client / qui valide, liste groupée par
''' jour, fenêtre de détail avec étapes, données, pièces et règle appliquée).
'''
''' Les données affichées sont **illustratives** (démonstration) : le journal réel
''' de l'avatar n'est pas encore branché à une source. Un bandeau le signale et
''' tout le contenu + l'interactivité vivent côté client. Réservé aux comptables
''' (IsAccountant), en mode Portail comptable.
''' </summary>
Public Class wbfCabAvatar60
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True
    End Sub

End Class
