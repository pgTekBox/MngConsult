Public Class wbfSupplierEdit
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim SupplierId As Integer
        Dim MySourcePage As Object = Me.Context.Handler
        SupplierId = MySourcePage.SupplierId




    End Sub

End Class