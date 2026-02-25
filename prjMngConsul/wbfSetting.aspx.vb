Imports System.Net.NetworkInformation
Imports Telerik.Web.UI


Partial Public Class wbfSetting
        Inherits clsData

        Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
            If Not IsPostBack Then
                BindStaticLists()
                LoadSettings()
            End If
        End Sub

        Private Sub BindStaticLists()



            ddProvince.Items.Clear()
            ddProvince.Items.Add(New RadComboBoxItem("Québec", "QC"))
            ddProvince.Items.Add(New RadComboBoxItem("Ontario", "ON"))
            ddProvince.Items.Add(New RadComboBoxItem("Nouveau-Brunswick", "NB"))
            ddProvince.Items.Add(New RadComboBoxItem("Nouvelle-Écosse", "NS"))
            ddProvince.Items.Add(New RadComboBoxItem("Manitoba", "MB"))
            ddProvince.Items.Add(New RadComboBoxItem("Saskatchewan", "SK"))
            ddProvince.Items.Add(New RadComboBoxItem("Alberta", "AB"))
            ddProvince.Items.Add(New RadComboBoxItem("Colombie-Britannique", "BC"))
            ddProvince.Items.Add(New RadComboBoxItem("Terre-Neuve-et-Labrador", "NL"))
            ddProvince.Items.Add(New RadComboBoxItem("Île-du-Prince-Édouard", "PE"))
            ddProvince.Items.Add(New RadComboBoxItem("Territoires du Nord-Ouest", "NT"))
            ddProvince.Items.Add(New RadComboBoxItem("Nunavut", "NU"))
            ddProvince.Items.Add(New RadComboBoxItem("Yukon", "YT"))

            ddTaxRounding.Items.Clear()
            ddTaxRounding.Items.Add(New RadComboBoxItem("2 décimales (cent)", "2"))
            ddTaxRounding.Items.Add(New RadComboBoxItem("4 décimales (interne)", "4"))
            ddTaxRounding.Items.Add(New RadComboBoxItem("Tronquer (2 décimales)", "TRUNC2"))

            ddTaxMode.Items.Clear()
            ddTaxMode.Items.Add(New RadComboBoxItem("Taxes en sus", "EXCLUSIVE"))
            ddTaxMode.Items.Add(New RadComboBoxItem("Taxes incluses", "INCLUSIVE"))

            ddShowPaidStamp.Items.Clear()
            ddShowPaidStamp.Items.Add(New RadComboBoxItem("Oui", "1"))
            ddShowPaidStamp.Items.Add(New RadComboBoxItem("Non", "0"))

            ddEmailAfterPay.Items.Clear()
            ddEmailAfterPay.Items.Add(New RadComboBoxItem("Oui", "1"))
            ddEmailAfterPay.Items.Add(New RadComboBoxItem("Non", "0"))
        End Sub

        Private Sub LoadSettings()
            ' TODO: Remplace par ta lecture BD (Company/Settings)
            ' Valeurs par défaut utiles
            tbLegalName.Text = "396 7557 Canada Inc."
            tbTradeName.Text = ""
            tbCountry.Text = "Canada"
            ddProvince.SelectedValue = "QC"
            tbCity.Text = "Montréal"

            ntbGSTRate.Value = 5
            ntbQSTRate.Value = 9.975
            ddTaxRounding.SelectedValue = "2"
            ddTaxMode.SelectedValue = "EXCLUSIVE"

            ddShowPaidStamp.SelectedValue = "1"
            ddEmailAfterPay.SelectedValue = "0"

            phStatus.Visible = False
        End Sub

        Protected Sub btnReload_Click(sender As Object, e As EventArgs)
            LoadSettings()
            ShowOk("Paramètres rechargés.")
        End Sub

        Protected Sub btnSave_Click(sender As Object, e As EventArgs)
            ' TODO: Sauvegarde BD ici.
            ' Ex: SaveSetting("Company.LegalName", tbLegalName.Text), etc.

            ' Petite validation minimale
            If String.IsNullOrWhiteSpace(tbLegalName.Text) Then
                ShowErr("Le nom légal est requis.")
                Return
            End If

            ShowOk("Paramètres enregistrés.")
        End Sub

        Private Sub ShowOk(msg As String)
            phStatus.Visible = True
            litStatus.Text = "<span class=""status-ok"">✔ " & Server.HtmlEncode(msg) & "</span>"
        End Sub

        Private Sub ShowErr(msg As String)
            phStatus.Visible = True
            litStatus.Text = "<span class=""status-err"">✖ " & Server.HtmlEncode(msg) & "</span>"
        End Sub
    End Class
