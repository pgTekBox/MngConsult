Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

''' <summary>
''' « Qui fait quoi » : la répartition des actions entre l'entreprise, son cabinet
''' et 60secondes (modèle 60secondes-qui-fait-quoi.html). Affichée dans l'onglet
''' « Qui fait quoi » de la fenêtre Mon cabinet comptable.
'''
''' Le serveur fournit le contexte affiché (window.QFQ_CONTEXTE) : le nom de
''' l'entreprise et le cabinet choisi (T323MonCabinet). Profil et métier ne sont
''' pas encore des données de l'entreprise : en attendant, ceux de la
''' démonstration du modèle.
''' </summary>
Public Class QuiFaitQuoi
    Inherits clsData

    ' À remplacer quand le profil et le métier de l'entreprise seront enregistrés.
    Private Const ProfilDemo As String = "TA"
    Private Const MetierDemo As String = "Massothérapeute"

    Protected ContexteJson As String = "null"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        Dim js As New JavaScriptSerializer()
        Dim ctx As New Dictionary(Of String, Object) From {
            {"entreprise", CompanyName},
            {"profil", ProfilDemo},
            {"metier", MetierDemo},
            {"cabinet", LireCabinet(js)}
        }
        ' Inséré dans un <script> : « </ » ne doit pas fermer la balise.
        ContexteJson = js.Serialize(ctx).Replace("</", "<\/")
    End Sub

    ''' <summary>Le cabinet choisi dans Mon cabinet comptable, ou Nothing s'il n'y en a pas.</summary>
    Private Function LireCabinet(js As JavaScriptSerializer) As Object
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0908GetMonCabinet", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing

            Dim etat = js.Deserialize(Of Dictionary(Of String, Object))(Convert.ToString(ds.Tables(0).Rows(0)("Etat")))
            Dim cab = TryCast(If(etat IsNot Nothing AndAlso etat.ContainsKey("cabinet"), etat("cabinet"), Nothing), Dictionary(Of String, Object))
            If cab Is Nothing Then Return Nothing

            Dim nom As String = If(cab.ContainsKey("nom"), Convert.ToString(cab("nom")), "")
            If String.IsNullOrWhiteSpace(nom) Then Return Nothing
            ' Un cabinet de l'annuaire porte sa certification (« Certifié · 2026 ») ; un comptable invité, non.
            Dim cert As String = If(cab.ContainsKey("cert"), Convert.ToString(cab("cert")), "")
            Return New Dictionary(Of String, Object) From {{"nom", nom}, {"certifie", Not String.IsNullOrWhiteSpace(cert)}}
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("QuiFaitQuoi : " & ex.Message)
            Return Nothing
        End Try
    End Function
End Class
