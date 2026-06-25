Imports System

''' <summary>
''' Flux OAuth Square pour connecter le compte Square d'un abonne (compagnie).
'''
''' - Sans parametre : genere un state, le stocke en session, et redirige
'''   l'abonne vers la page d'autorisation Square.
''' - Avec ?code=&state= : valide le state, echange le code contre des jetons,
'''   recupere la location principale, sauvegarde (chiffre) sur T010Company,
'''   puis revient vers wbfProducts.aspx.
''' </summary>
Public Class SquareOAuth
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        Dim code As String = Request.QueryString("code")
        Dim state As String = Request.QueryString("state")
        Dim oauthError As String = Request.QueryString("error")

        ' ── Retour Square : refus / erreur ──────────────────────────────────
        If Not String.IsNullOrEmpty(oauthError) Then
            Response.Redirect("~/wbfProducts.aspx?square=denied", True)
            Return
        End If

        ' ── Retour Square : code d'autorisation reçu ────────────────────────
        If Not String.IsNullOrEmpty(code) Then
            Dim expected As String = TryCast(Session("SquareOAuthState"), String)
            If String.IsNullOrEmpty(state) OrElse expected Is Nothing OrElse state <> expected Then
                Response.Redirect("~/wbfProducts.aspx?square=badstate", True)
                Return
            End If
            Session.Remove("SquareOAuthState")

            Try
                Dim info As clsSquare.SquareTokenInfo = clsSquare.ExchangeCodeForToken(code)

                Dim locationId As String = ""
                Try
                    locationId = clsSquare.GetMainLocationId(info.AccessToken)
                Catch
                    ' la location n'est pas bloquante pour la connexion
                End Try

                SaveCompanySquareTokens(info, info.MerchantId, locationId)
                Response.Redirect("~/wbfProducts.aspx?square=connected", True)

            Catch ex As Threading.ThreadAbortException
                ' redirection normale
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("SquareOAuth exchange error: " & ex.Message)
                Response.Redirect("~/wbfProducts.aspx?square=error", True)
            End Try
            Return
        End If

        ' ── Demarrage : rediriger vers la page d'autorisation Square ─────────
        Dim newState As String = Guid.NewGuid().ToString("N")
        Session("SquareOAuthState") = newState
        Try
            Response.Redirect(clsSquare.GetAuthorizeUrl(newState), True)
        Catch ex As Threading.ThreadAbortException
            ' redirection normale
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("SquareOAuth start error: " & ex.Message)
            Response.Redirect("~/wbfProducts.aspx?square=error", True)
        End Try
    End Sub

End Class
