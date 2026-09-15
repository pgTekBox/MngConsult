Imports System.Globalization

''' <summary>
''' Les rapports Codat, mis à plat en tableau.
'''
''' • Balances âgées : une ligne par tiers, devise et tranche d'âge, avec le
'''   détail (factures, notes de crédit) de chaque montant.
''' • Bilan et état des résultats : Codat les rend mois par mois, chaque section
'''   (actifs, passifs, revenus…) en arbre de lignes. Une ligne par nœud, avec son
'''   chemin et son niveau, et les totaux (bénéfice net…) sur leur propre ligne.
''' </summary>
Public Module Rapports

    Public Class Tableau
        Public Property Entetes As New List(Of String)
        Public Property Lignes As New List(Of IEnumerable(Of String))
    End Class

    Public Function Iso(d As Date) As String
        Return d.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function

    ''' <summary>Le chemin de l'API et ses paramètres pour un rapport.</summary>
    Public Function Url(genre As GenreRapport, companyId As String, opt As OptionsExtraction) As String
        Dim societe = "/companies/" & Uri.EscapeDataString(companyId)

        ' Nombre de mois du début de l'exercice à la bascule, bornes comprises.
        Dim mois = Math.Max(1, (opt.DateBascule.Year - opt.DateDebut.Year) * 12 + opt.DateBascule.Month - opt.DateDebut.Month + 1)
        Dim moisBascule = Iso(New Date(opt.DateBascule.Year, opt.DateBascule.Month, 1))

        Select Case genre
            Case GenreRapport.BalanceAgeeClients
                Return societe & $"/reports/agedDebtor?reportDate={Iso(opt.DateBascule.AddDays(1))}&numberOfPeriods={opt.PeriodesAgees}&periodLengthDays=30"
            Case GenreRapport.BalanceAgeeFournisseurs
                Return societe & $"/reports/agedCreditor?reportDate={Iso(opt.DateBascule.AddDays(1))}&numberOfPeriods={opt.PeriodesAgees}&periodLengthDays=30"
            Case GenreRapport.Bilan
                Return societe & $"/data/financials/balanceSheet?periodLength=1&periodsToCompare={mois}&startMonth={moisBascule}"
            Case Else
                Return societe & $"/data/financials/profitAndLoss?periodLength=1&periodsToCompare={mois}&startMonth={moisBascule}"
        End Select
    End Function

#Region "Balances âgées"

    Public Function AplatirEcheancier(reponse As JsonNode, fournisseurs As Boolean) As Tableau
        Dim t As New Tableau()
        Dim tiers = If(fournisseurs, "supplier", "customer")
        t.Entetes.AddRange({"reportDate", tiers & "Id", tiers & "Name", "currency", "fromDate", "toDate", "amount", "details"})

        ' La réponse est un rapport, ou une liste de rapports selon la version de l'API.
        Dim lesRapports As IEnumerable(Of JsonNode) = If(TryCast(reponse, JsonArray), CType({reponse}, IEnumerable(Of JsonNode)))

        For Each r In lesRapports
            Dim dateRapport = JsonChemin.Valeur(r, "reportDate")
            For Each ligne In Elements(JsonChemin.Enfant(r, "data"))
                For Each devise In Elements(JsonChemin.Enfant(ligne, "agedCurrencyOutstanding"))
                    For Each tranche In Elements(JsonChemin.Enfant(devise, "agedOutstandingAmounts"))
                        Dim details = String.Join(" | ", Elements(JsonChemin.Enfant(tranche, "details")) _
                                                        .Select(Function(d) JsonChemin.Valeur(d, "name") & "=" & JsonChemin.Valeur(d, "amount")))
                        t.Lignes.Add(New List(Of String) From {
                            dateRapport, JsonChemin.Valeur(ligne, tiers & "Id"), JsonChemin.Valeur(ligne, tiers & "Name"),
                            JsonChemin.Valeur(devise, "currency"), JsonChemin.Valeur(tranche, "fromDate"),
                            JsonChemin.Valeur(tranche, "toDate"), JsonChemin.Valeur(tranche, "amount"), details})
                    Next
                Next
            Next
        Next

        Return t
    End Function

#End Region

#Region "Bilan et état des résultats"

    Public Function AplatirEtatFinancier(reponse As JsonNode) As Tableau
        Dim t As New Tableau()
        t.Entetes.AddRange({"currency", "reportBasis", "date", "fromDate", "toDate", "section", "level", "path", "accountId", "name", "value"})

        Dim devise = JsonChemin.Valeur(reponse, "currency")
        Dim base = JsonChemin.Valeur(reponse, "reportBasis")

        For Each r In Elements(JsonChemin.Enfant(reponse, "reports"))
            Dim tete = {devise, base, JsonChemin.Valeur(r, "date"), JsonChemin.Valeur(r, "fromDate"), JsonChemin.Valeur(r, "toDate")}
            Dim objet = TryCast(r, JsonObject)
            If objet Is Nothing Then Continue For

            For Each prop In objet
                Select Case True
                    Case TypeOf prop.Value Is JsonObject
                        ' Une section en arbre : assets, liabilities, income, expenses…
                        Parcourir(prop.Value, prop.Key, 0, "", tete, t)
                    Case prop.Value IsNot Nothing AndAlso prop.Value.GetValueKind() = Text.Json.JsonValueKind.Number
                        ' Un total : netAssets, grossProfit, netProfit…
                        t.Lignes.Add(tete.Concat({prop.Key, "0", prop.Key, "", prop.Key, JsonChemin.Texte(prop.Value)}).ToList())
                End Select
            Next
        Next

        Return t
    End Function

    Private Sub Parcourir(noeud As JsonNode, section As String, niveau As Integer, parent As String,
                          tete As String(), t As Tableau)
        Dim nom = JsonChemin.Valeur(noeud, "name")
        Dim chemin = If(parent = "", nom, parent & " > " & nom)

        t.Lignes.Add(tete.Concat({section, niveau.ToString(CultureInfo.InvariantCulture), chemin,
                                  JsonChemin.Valeur(noeud, "accountId"), nom, JsonChemin.Valeur(noeud, "value")}).ToList())

        For Each sousLigne In Elements(JsonChemin.Enfant(noeud, "items"))
            Parcourir(sousLigne, section, niveau + 1, chemin, tete, t)
        Next
    End Sub

#End Region

    Private Function Elements(noeud As JsonNode) As IEnumerable(Of JsonNode)
        Dim a = TryCast(noeud, JsonArray)
        Return If(a Is Nothing, Enumerable.Empty(Of JsonNode)(), a.Where(Function(x) x IsNot Nothing))
    End Function

End Module
