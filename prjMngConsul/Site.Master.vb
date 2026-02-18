Public Class SiteMaster
    Inherits MasterPage
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load

        Session("Company") = Guid.Parse("87893D29-6D64-40C8-8E45-A3492B4FBB91")



    End Sub
End Class