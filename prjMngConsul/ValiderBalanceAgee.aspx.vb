Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' La balance âgée importée — clients ou fournisseurs.
'''
''' Cet écran ne valide rien et ne crée rien, et c'est sa raison d'être. La
''' balance âgée n'est pas une liste à reprendre : c'est le rapport qui dit si
''' la reprise est juste. Les factures, elles, arrivent par leur propre écran.
'''
''' LA FORME DE LA TABLE. staging.BalanceAgeeImport porte UNE LIGNE PAR TRANCHE
''' d'ancienneté, pas une par tiers : un client à cinq tranches donne cinq
''' lignes, et TotalTiers y est répété. C'est le prix d'une table plate, payé à
''' l'import. L'écran fait le chemin inverse — il repivote les tranches en
''' colonnes, parce que c'est ainsi qu'une balance âgée se lit.
'''
''' LE RAPPROCHEMENT. Le total de la balance est comparé au solde des factures
''' en préparation, tiers par tiers, par l'identifiant de la source. Les deux
''' viennent du même logiciel : un écart ne veut pas dire qu'un des deux a tort,
''' il veut dire qu'il manque des factures — ou qu'on en a de trop.
'''
''' Le genre passe par la requête (?genre=Fournisseur) : l'écran reste
''' partageable en lien et le retour arrière du navigateur fonctionne.
''' </summary>
Public Class ValiderBalanceAgee
    Inherits clsData

    Private Shared ReadOnly Genres As New Dictionary(Of String, String) From {
        {"Client", "Clients"},
        {"Fournisseur", "Fournisseurs"}
    }

    ''' <summary>Le type de document qui répond à ce genre, pour le rapprochement.</summary>
    Private Shared ReadOnly TypeDocument As New Dictionary(Of String, Integer) From {
        {"Client", 1},
        {"Fournisseur", 2}
    }

    Private ReadOnly Property Genre As String
        Get
            Dim g As String = If(Request.QueryString("genre"), "").Trim()
            Return If(Genres.ContainsKey(g), g, "Client")
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then Afficher()
    End Sub

    Private Sub Afficher()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Genre", DBNull.Value))

        Dim ds As DataSet
        Try
            ds = ExecuteSQLds("s0813GetBalanceAgee", p)
        Catch ex As Exception
            litTableau.Text = "<div class='rien'>La balance âgée n'a pas pu être lue : " &
                              H(ex.Message) & "</div>"
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 2 Then
            litTableau.Text = Vide()
            Return
        End If

        ' Le premier jeu récapitule chaque genre : il sert aux onglets ET au
        ' bandeau de la date arrêtée.
        litOnglets.Text = Onglets(ds.Tables(0))

        Dim sommaire As DataRow = Nothing
        For Each r As DataRow In ds.Tables(0).Rows
            If Txt(r("Genre")) = Genre Then sommaire = r
        Next

        Dim lignes As DataRow() = ds.Tables(1).Select("Genre = '" & Genre.Replace("'", "''") & "'")
        If sommaire Is Nothing OrElse lignes.Length = 0 Then
            litTableau.Text = Vide()
            Return
        End If

        litRepere.Text = Repere(sommaire)
        litTableau.Text = Tableau(lignes)
        litControle.Text = Controle(lignes)
        litNote.Text = Note()
    End Sub

    ' =========================================================================
    ' LE RENDU
    ' =========================================================================

    Private Function Onglets(sommaires As DataTable) As String
        Dim sb As New StringBuilder("<div class='onglets'>")

        For Each g In Genres
            Dim nb As String = ""
            For Each r As DataRow In sommaires.Rows
                If Txt(r("Genre")) = g.Key Then nb = Txt(r("NbTiers")) & " tiers"
            Next

            sb.Append("<a href='ValiderBalanceAgee.aspx?genre=").Append(g.Key).Append("'")
            If g.Key = Genre Then sb.Append(" class='on'")
            sb.Append(">").Append(H(g.Value))
            sb.Append("<span class='n'>").Append(H(If(nb <> "", nb, "aucune"))).Append("</span>")
            sb.Append("</a>")
        Next

        Return sb.Append("</div>").ToString()
    End Function

    ''' <summary>La date d'arrêt, la largeur des tranches, ce que la source annonce.</summary>
    Private Function Repere(r As DataRow) As String
        Dim sb As New StringBuilder("<div class='repere'>")
        sb.Append(Bloc("Arrêtée au", Jour(r("DateArrete"))))
        sb.Append(Bloc("Tranches", Txt(r("LongueurPeriode")) & " jours"))
        sb.Append(Bloc("Tiers", Txt(r("NbTiers"))))
        sb.Append(Bloc("Total annoncé", Somme(r("Total"))))
        Return sb.Append("</div>").ToString()
    End Function

    Private Shared Function Bloc(libelle As String, valeur As String) As String
        Return "<div class='bloc'><div class='l'>" & H(libelle) & "</div><div class='v'>" &
               H(valeur) & "</div></div>"
    End Function

    ''' <summary>
    ''' Les tranches redeviennent des colonnes. Leur nombre n'est pas décidé ici :
    ''' il vient de la source — cinq chez QuickBooks, mais rien ne l'impose.
    ''' L'entête de chaque colonne est bâti sur les dates réellement reçues.
    ''' </summary>
    Private Function Tableau(lignes As DataRow()) As String
        Dim titres As New SortedDictionary(Of Integer, String)
        For Each r As DataRow In lignes
            Dim ordre As Integer = Ent(r("PeriodeOrdre"))
            If Not titres.ContainsKey(ordre) Then titres(ordre) = TitreTranche(r)
        Next

        Dim sb As New StringBuilder("<table class='bag'><thead><tr><th>Tiers</th>")
        For Each t In titres
            sb.Append("<th class='n'>").Append(H(t.Value)).Append("</th>")
        Next
        sb.Append("<th class='n'>Total</th></tr></thead><tbody>")

        ' Un dictionnaire par tiers, puis par tranche : la table est plate, le
        ' tableau ne l'est pas.
        Dim parTiers As New List(Of String)
        Dim montants As New Dictionary(Of String, Dictionary(Of Integer, Decimal))
        Dim noms As New Dictionary(Of String, String)
        Dim totaux As New Dictionary(Of String, Decimal)

        For Each r As DataRow In lignes
            Dim cle As String = Txt(r("TiersExterneId")) & "|" & Txt(r("TiersNom"))
            If Not montants.ContainsKey(cle) Then
                montants(cle) = New Dictionary(Of Integer, Decimal)
                noms(cle) = Txt(r("TiersNom"))
                totaux(cle) = 0D
                parTiers.Add(cle)
            End If
            montants(cle)(Ent(r("PeriodeOrdre"))) = Dec(r("Montant"))
            totaux(cle) += Dec(r("Montant"))
        Next

        Dim grand As New Dictionary(Of Integer, Decimal)
        Dim grandTotal As Decimal = 0D

        For Each cle As String In parTiers
            sb.Append("<tr><td>").Append(H(noms(cle))).Append("</td>")
            For Each t In titres
                Dim v As Decimal = 0D
                montants(cle).TryGetValue(t.Key, v)
                If Not grand.ContainsKey(t.Key) Then grand(t.Key) = 0D
                grand(t.Key) += v
                sb.Append("<td class='n").Append(If(v = 0D, " zero", "")).Append("'>")
                sb.Append(Somme(v)).Append("</td>")
            Next
            grandTotal += totaux(cle)
            sb.Append("<td class='n'>").Append(Somme(totaux(cle))).Append("</td></tr>")
        Next

        sb.Append("</tbody><tfoot><tr><td>Total</td>")
        For Each t In titres
            Dim v As Decimal = 0D
            grand.TryGetValue(t.Key, v)
            sb.Append("<td class='n'>").Append(Somme(v)).Append("</td>")
        Next
        sb.Append("<td class='n'>").Append(Somme(grandTotal)).Append("</td></tr></tfoot></table>")

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' « Courant », « 1 à 30 jours »… Les bornes viennent de la source : la
    ''' première tranche n'a pas de fin, la dernière n'a pas de début.
    ''' </summary>
    Private Shared Function TitreTranche(r As DataRow) As String
        Dim ordre As Integer = Ent(r("PeriodeOrdre"))
        Dim sansFin As Boolean = IsDBNull(r("PeriodeFin"))
        Dim sansDebut As Boolean = IsDBNull(r("PeriodeDebut"))

        If ordre = 0 AndAlso sansFin Then Return "Courant"
        If sansDebut Then Return "Le plus ancien"

        Dim debut As Date = Convert.ToDateTime(r("PeriodeDebut"))
        Dim fin As Date = If(sansFin, Date.Today, Convert.ToDateTime(r("PeriodeFin")))
        Return debut.ToString("d MMM", FrCa) & " – " & fin.ToString("d MMM", FrCa)
    End Function

    ''' <summary>
    ''' Le rapprochement avec les factures en préparation, tiers par tiers.
    '''
    ''' On compare par l'identifiant de la source, jamais par le nom : c'est la
    ''' seule clé que les deux extractions partagent avec certitude.
    ''' </summary>
    Private Function Controle(lignes As DataRow()) As String
        Dim sb As New StringBuilder("<div class='ctrl'><h2>Rapprochement avec les factures en préparation</h2>")
        sb.Append("<p class='desc'>Le solde des factures déposées par l'import, comparé à ce que la ")
        sb.Append("balance âgée annonce. Les deux viennent de la même comptabilité : un écart ")
        sb.Append("signale des factures manquantes, ou des factures déjà payées restées dans le lot.</p>")

        Dim attendu As New Dictionary(Of String, Decimal)
        Dim nomDe As New Dictionary(Of String, String)
        Dim totalAttendu As Decimal = 0D

        For Each r As DataRow In lignes
            Dim id As String = Txt(r("TiersExterneId"))
            If id = "" Then Continue For
            If Not attendu.ContainsKey(id) Then
                attendu(id) = 0D
                nomDe(id) = Txt(r("TiersNom"))
            End If
            attendu(id) += Dec(r("Montant"))
            totalAttendu += Dec(r("Montant"))
        Next

        Dim factures As DataTable = Nothing
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@DocumentTypeId", TypeDocument(Genre)))
            p.Add(New SqlParameter("@RunId", DBNull.Value))
            Dim ds As DataSet = ExecuteSQLds("s0782GetDocumentsImport", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then factures = ds.Tables(0)
        Catch ex As Exception
            sb.Append("<div class='verdict rien'>Les factures n'ont pas pu être lues : ")
            sb.Append(H(ex.Message)).Append("</div></div>")
            Return sb.ToString()
        End Try

        If factures Is Nothing OrElse factures.Rows.Count = 0 Then
            sb.Append("<div class='verdict rien'>Aucune facture en préparation pour l'instant : ")
            sb.Append("importez-les, puis revenez ici pour vérifier le total.</div></div>")
            Return sb.ToString()
        End If

        Dim trouve As New Dictionary(Of String, Decimal)
        Dim totalTrouve As Decimal = 0D
        For Each r As DataRow In factures.Rows
            Dim id As String = Txt(r("TiersExterneId"))
            If id = "" Then Continue For
            If Not trouve.ContainsKey(id) Then trouve(id) = 0D
            trouve(id) += Dec(r("Solde"))
            totalTrouve += Dec(r("Solde"))
        Next

        Dim ecart As Decimal = totalTrouve - totalAttendu
        If Math.Abs(ecart) <= 0.01D Then
            sb.Append("<div class='verdict ok'>⚖️ Les deux concordent — ")
            sb.Append(Somme(totalAttendu)).Append(" de part et d'autre.</div>")
        Else
            sb.Append("<div class='verdict ko'>⚠️ Écart de ").Append(Somme(Math.Abs(ecart)))
            sb.Append(" : la balance annonce ").Append(Somme(totalAttendu))
            sb.Append(", les factures en préparation totalisent ").Append(Somme(totalTrouve))
            sb.Append(".</div>")
        End If

        ' Le détail par tiers, mais seulement là où ça diffère : une liste de
        ' lignes justes n'apprend rien.
        Dim tous As New SortedDictionary(Of String, String)
        For Each k In attendu.Keys : tous(k) = nomDe(k) : Next
        For Each r As DataRow In factures.Rows
            Dim id As String = Txt(r("TiersExterneId"))
            If id <> "" AndAlso Not tous.ContainsKey(id) Then tous(id) = Txt(r("TiersNom"))
        Next

        Dim corps As New StringBuilder()
        For Each t In tous
            Dim a As Decimal = 0D : attendu.TryGetValue(t.Key, a)
            Dim f As Decimal = 0D : trouve.TryGetValue(t.Key, f)
            If Math.Abs(f - a) <= 0.01D Then Continue For

            corps.Append("<tr class='ecart'><td>").Append(H(t.Value)).Append("</td>")
            corps.Append("<td class='n'>").Append(Somme(a)).Append("</td>")
            corps.Append("<td class='n'>").Append(Somme(f)).Append("</td>")
            corps.Append("<td class='n'>").Append(Somme(f - a)).Append("</td></tr>")
        Next

        If corps.Length > 0 Then
            sb.Append("<table class='bag' style='margin-top:12px'><thead><tr><th>Tiers</th>")
            sb.Append("<th class='n'>Balance âgée</th><th class='n'>Factures en préparation</th>")
            sb.Append("<th class='n'>Écart</th></tr></thead><tbody>")
            sb.Append(corps.ToString()).Append("</tbody></table>")
        End If

        Return sb.Append("</div>").ToString()
    End Function

    Private Function Note() As String
        Return "<div class='note'>Ce rapport est <b>agrégé</b> : il donne des montants par tiers " &
               "et par tranche, jamais le numéro d'une facture. Le détail, c'est l'import des " &
               "factures qui l'apporte. Rien ici ne s'applique à la comptabilité — une nouvelle " &
               "extraction remplace simplement la précédente.</div>"
    End Function

    Private Function Vide() As String
        Return "<div class='rien'>Aucune balance âgée " & H(Genres(Genre).ToLowerInvariant()) &
               " en préparation.<br />Rapatriez-la depuis l'écran <b>Import par connecteur</b>.</div>"
    End Function

    ' =========================================================================
    ' PETITS OUTILS
    ' =========================================================================

    Private Shared ReadOnly FrCa As Globalization.CultureInfo =
        Globalization.CultureInfo.GetCultureInfo("fr-CA")

    Private Shared Function H(texte As String) As String
        Return HttpUtility.HtmlEncode(If(texte, ""))
    End Function

    Private Shared Function Txt(v As Object) As String
        Return If(v Is Nothing OrElse IsDBNull(v), "", Convert.ToString(v))
    End Function

    Private Shared Function Ent(v As Object) As Integer
        Return If(v Is Nothing OrElse IsDBNull(v), 0, Convert.ToInt32(v))
    End Function

    Private Shared Function Dec(v As Object) As Decimal
        Return If(v Is Nothing OrElse IsDBNull(v), 0D, Convert.ToDecimal(v))
    End Function

    Private Shared Function Somme(v As Object) As String
        Return Dec(v).ToString("N2", FrCa) & " $"
    End Function

    Private Shared Function Jour(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return "—"
        Return Convert.ToDateTime(v).ToString("d MMMM yyyy", FrCa)
    End Function

End Class
