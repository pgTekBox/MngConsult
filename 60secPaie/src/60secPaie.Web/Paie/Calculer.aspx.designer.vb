Option Strict On
Option Explicit On

Partial Public Class PageCalculerPaie
    Protected WithEvents litPeriode As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litEtapes As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents mvEtapes As Global.System.Web.UI.WebControls.MultiView
    Protected WithEvents vwPeriode As Global.System.Web.UI.WebControls.View
    Protected WithEvents pnlBrouillon As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litBrouillon As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lnkReprendre As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents btnSupprimerBrouillon As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlNouvelle As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents ddlPeriodes As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtFinPeriode As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtDatePaie As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnCreer As Global.System.Web.UI.WebControls.Button
    Protected WithEvents vwSaisie As Global.System.Web.UI.WebControls.View
    Protected WithEvents rptPaies As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents btnCalculer As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnSupprimerLot As Global.System.Web.UI.WebControls.Button
    Protected WithEvents vwLignes As Global.System.Web.UI.WebControls.View
    Protected WithEvents litEmployeLignes As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptLignes As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents lblAucuneLigne As Global.System.Web.UI.WebControls.Label
    Protected WithEvents ddlElement As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents txtHeures As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtTaux As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents txtMontant As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnAjouterLigne As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lnkRetourSaisie As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents vwRevision As Global.System.Web.UI.WebControls.View
    Protected WithEvents litRevision As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litSommaire As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents btnConfirmer As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lnkModifier As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents vwConfirmation As Global.System.Web.UI.WebControls.View
    Protected WithEvents litConfirmation As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lnkDetail As Global.System.Web.UI.WebControls.HyperLink
End Class
