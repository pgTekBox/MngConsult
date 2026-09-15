Imports System.Globalization

''' <summary>
''' Les rapports d'Apideck, mis à plat en tableau.
'''
''' • Balances âgées : une ligne par transaction ouverte, avec son tiers, sa
'''   devise et sa tranche d'âge — l'équivalent du rapport « détail » de
'''   QuickBooks. Une tranche sans transaction détaillée garde une ligne de total.
''' • Bilan et état des résultats : chaque section (actifs, passifs, revenus…)
'''   est un arbre ; une ligne par nœud, avec son chemin et son niveau, et les
'''   totaux (bénéfice net…) sur leur propre ligne.
''' </summary>
Public Module Rapports

    Public Class Tableau
        Public Property Entetes As New List(Of String)
        Public Property Lignes As New List(Of IEnumerable(Of String))
    End Class

    Public Function Iso(d As Date) As String
        Return d.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function

    ''' <summary>Le chemin de l'API et ses filtres pour un rapport.</summary>
    Public Function Url(ext As Extraction, opt As OptionsExtraction) As String
        Dim filtres As New List(Of String)
        Dim ajouter = Sub(nom As String, valeur As String) filtres.Add(Uri.EscapeDataString("filter[" & nom & "]") & "=" & Uri.EscapeDataString(valeur))

        Select Case ext.Rapport
            Case GenreRapport.BalanceAgeeClients, GenreRapport.BalanceAgeeFournisseurs
                ajouter("report_as_of_date", Iso(opt.DateBascule))
                ajouter("period_count", opt.PeriodesAgees.ToString(CultureInfo.InvariantCulture))
                ajouter("period_length", "30")
            Case GenreRapport.Bilan
                ajouter("end_date", Iso(opt.DateBascule))
                ajouter("period_count", "1")
                ajouter("period_type", "month")
                ajouter("accounting_method", opt.MethodeComptable)
            Case Else
                ajouter("start_date", Iso(opt.DateDebut))
                ajouter("end_date", Iso(opt.DateBascule))
                ajouter("accounting_method", opt.MethodeComptable)
        End Select

        Return "/accounting/" & ext.Ressource & "?" & String.Join("&", filtres)
    End Function

#Region "Balances âgées"

    Public Function AplatirEcheancier(rapport As JsonNode) As Tableau
        Dim t As New Tableau()
        t.Entetes.AddRange({"report_as_of_date", "party_id", "party_name", "currency", "period_start", "period_end", "period_total",
                            "transaction_id", "transaction_number", "transaction_type", "transaction_date", "due_date",
                            "original_amount", "outstanding_balance"})

        Dim dateRapport = JsonChemin.Valeur(rapport, "report_as_of_date")

        For Each tiers In Elements(JsonChemin.Enfant(rapport, "outstanding_balances"))
            Dim id = JsonChemin.Valeur(tiers, "customer_id|supplier_id")
            Dim nom = JsonChemin.Valeur(tiers, "customer_name|supplier_name")

            For Each devise In Elements(JsonChemin.Enfant(tiers, "outstanding_balances_by_currency"))
                For Each tranche In Elements(JsonChemin.Enfant(devise, "balances_by_period"))
                    Dim tete = {dateRapport, id, nom, JsonChemin.Valeur(devise, "currency"),
                                JsonChemin.Valeur(tranche, "start_date"), JsonChemin.Valeur(tranche, "end_date"),
                                JsonChemin.Valeur(tranche, "total_amount")}

                    Dim transactions = Elements(JsonChemin.Enfant(tranche, "balances_by_transaction")).ToList()
                    If transactions.Count = 0 Then
                        t.Lignes.Add(tete.Concat(Enumerable.Repeat("", 7)).ToList())
                        Continue For
                    End If

                    For Each tx In transactions
                        t.Lignes.Add(tete.Concat({JsonChemin.Valeur(tx, "transaction_id"), JsonChemin.Valeur(tx, "transaction_number"),
                                                  JsonChemin.Valeur(tx, "transaction_type"), JsonChemin.Valeur(tx, "transaction_date"),
                                                  JsonChemin.Valeur(tx, "due_date"), JsonChemin.Valeur(tx, "original_amount"),
                                                  JsonChemin.Valeur(tx, "outstanding_balance")}).ToList())
                    Next
                Next
            Next
        Next

        Return t
    End Function

#End Region

#Region "Bilan et état des résultats"

    ''' <summary>
    ''' Le bilan arrive comme { reports: [...] }, l'état des résultats comme un
    ''' seul rapport : les deux passent par ici.
    ''' </summary>
    Public Function AplatirEtatFinancier(donnees As JsonNode) As Tableau
        Dim t As New Tableau()
        t.Entetes.AddRange({"report_name", "currency", "start_date", "end_date", "section", "level", "path", "account_id", "code", "name", "value"})

        Dim liste = Elements(JsonChemin.Enfant(donnees, "reports")).ToList()
        If liste.Count = 0 AndAlso donnees IsNot Nothing Then liste.Add(donnees)

        Const Entete As String = "|id|report_name|currency|start_date|end_date|custom_mappings|customer|updated_by|created_by|updated_at|created_at|"

        For Each r In liste
            Dim tete = {JsonChemin.Valeur(r, "report_name"), JsonChemin.Valeur(r, "currency"),
                        JsonChemin.Valeur(r, "start_date"), JsonChemin.Valeur(r, "end_date")}
            Dim objet = TryCast(r, JsonObject)
            If objet Is Nothing Then Continue For

            For Each prop In objet
                If Entete.Contains("|" & prop.Key & "|") OrElse prop.Value Is Nothing Then Continue For

                If TypeOf prop.Value Is JsonObject OrElse TypeOf prop.Value Is JsonArray Then
                    ' Une section en arbre : assets, liabilities, income, expenses…
                    Parcourir(prop.Value, prop.Key, 0, "", tete, t)
                ElseIf prop.Value.GetValueKind() = Text.Json.JsonValueKind.Number Then
                    ' Un total : net_assets, gross_profit, net_income…
                    t.Lignes.Add(tete.Concat({prop.Key, "0", prop.Key, "", "", prop.Key, JsonChemin.Texte(prop.Value)}).ToList())
                End If
            Next
        Next

        Return t
    End Function

    ''' <summary>
    ''' Un nœud : un compte (name, value, items) ou une section (title, total,
    ''' records). Un tableau est parcouru élément par élément, au même niveau.
    ''' </summary>
    Private Sub Parcourir(noeud As JsonNode, section As String, niveau As Integer, parent As String,
                          tete As String(), t As Tableau)
        Dim tableau = TryCast(noeud, JsonArray)
        If tableau IsNot Nothing Then
            For Each element In tableau
                Parcourir(element, section, niveau, parent, tete, t)
            Next
            Return
        End If

        If TypeOf noeud IsNot JsonObject Then Return

        Dim nom = JsonChemin.Valeur(noeud, "name|title")
        Dim chemin = If(parent = "", If(nom = "", section, nom), parent & " > " & nom)

        t.Lignes.Add(tete.Concat({section, niveau.ToString(CultureInfo.InvariantCulture), chemin,
                                  JsonChemin.Valeur(noeud, "account_id|id"), JsonChemin.Valeur(noeud, "code"),
                                  nom, JsonChemin.Valeur(noeud, "value|total")}).ToList())

        For Each sousLigne In Elements(JsonChemin.Enfant(noeud, "items")).Concat(Elements(JsonChemin.Enfant(noeud, "records")))
            Parcourir(sousLigne, section, niveau + 1, chemin, tete, t)
        Next
    End Sub

#End Region

    Private Function Elements(noeud As JsonNode) As IEnumerable(Of JsonNode)
        Dim a = TryCast(noeud, JsonArray)
        Return If(a Is Nothing, Enumerable.Empty(Of JsonNode)(), a.Where(Function(x) x IsNot Nothing))
    End Function

End Module
