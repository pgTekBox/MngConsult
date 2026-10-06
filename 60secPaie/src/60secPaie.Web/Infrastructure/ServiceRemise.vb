Imports System.Text
Imports Paie60Sec.Calcul

''' <summary>Solde des retenues à payer à un gouvernement.</summary>
Public Class SoldeRemise
    Public Property Montant As Decimal
    Public Property NbPaies As Integer
    ''' <summary>Date de la plus ancienne paie dont les retenues ne sont pas payées.</summary>
    Public Property PlusAnciennePaie As Date?
    ''' <summary>Fin de la période de remise qui contient cette paie.</summary>
    Public Property FinPeriode As Date?
    ''' <summary>Date limite du paiement pour cette période.</summary>
    Public Property Echeance As Date?

    Public ReadOnly Property EnRetard As Boolean
        Get
            Return Echeance.HasValue AndAlso Echeance.Value < Date.Today
        End Get
    End Property
End Class

''' <summary>
''' Remises gouvernementales. Ce qui est dû dépend de la province de chaque paie (paie.Paie.Province).
'''
''' QUÉBEC
'''   Fédéral (Receveur général) : impôt fédéral + assurance-emploi (employés et employeur).
'''   Revenu Québec : impôt du Québec + RRQ + RQAP (employés et employeur) + FSS + CNESST.
'''   La cotisation relative aux normes du travail (CNT) se paie une fois l'an avec le sommaire 1 : elle n'en fait pas partie.
'''
''' HORS QUÉBEC (toutes les autres provinces et les territoires)
'''   Fédéral (Receveur général) : impôt fédéral + impôt de la province + RPC (employés et employeur) + assurance-emploi.
'''   L'ARC perçoit l'impôt de la province : il n'y a aucune remise provinciale, et rien ne va à Revenu Québec.
'''   La cotisation santé de l'employeur (ISE de l'Ontario, de la Colombie-Britannique…) et la prime de la commission
'''   des accidents du travail (WSIB, WCB…) se paient à part : elles sont calculées et affichées, mais ne font
'''   partie d'aucune remise. Il en va de même de l'impôt de 2 % sur la paie des Territoires du Nord-Ouest et du
'''   Nunavut, retenu à l'employé et remis au territoire (colonne RQAP de paie.Paie).
'''
''' Rappel : hors Québec, l'impôt provincial et le RPC occupent les colonnes ImpotQuebec et RRQ de paie.Paie.
'''
''' Ces règles vivent dans la base, avec les procédures : paie.fnDuFederal et paie.fnDuQuebec (ce qu'une paie doit),
''' paie.fnRemiseLignes (les lignes d'une remise), paie.spRemise_* (Database\07_procedures.sql). Le gouvernement
''' est passé en paramètre (@g = F ou Q) ; les libellés de l'impôt provincial viennent du code (LibellesImpot).
''' </summary>
Public NotInheritable Class ServiceRemise

    Public Const Federal As String = "F"
    Public Const Quebec As String = "Q"

    Private Sub New()
    End Sub

    Public Shared Function NomGouvernement(gouvernement As Object) As String
        Return If(Convert.ToString(gouvernement) = Federal, "Receveur général du Canada", "Revenu Québec")
    End Function

    ''' <summary>F ou Q, et rien d'autre : la valeur vient d'une liste déroulante, elle est vérifiée avant d'aller à la base.</summary>
    Private Shared Function VerifierGouvernement(gouvernement As String) As String
        Select Case gouvernement
            Case Federal, Quebec : Return gouvernement
            Case Else : Throw New SaisieInvalideException("Gouvernement invalide.")
        End Select
    End Function

    ''' <summary>
    ''' « ON=Impôt de l'Ontario|AB=Impôt de l'Alberta|… » : le libellé de la ligne d'impôt provincial d'une remise
    ''' fédérale, par province (une ligne par province, parce qu'une compagnie qui a changé de province peut en
    ''' remettre deux à la fois). Les libellés viennent du code, jamais d'une saisie.
    ''' </summary>
    Private Shared Function LibellesImpot() As String
        Dim parts As New List(Of String)()
        For Each prov In Provinces.Gerees
            If prov = Province.Quebec Then Continue For
            parts.Add(Provinces.Code(prov) & "=" & LibellesProvince.Pour(prov).ImpotProvincial.Replace("|", " "))
        Next
        Return String.Join("|", parts)
    End Function

    ''' <summary>
    ''' Vrai si la compagnie a affaire à Revenu Québec : elle est au Québec, ou il lui reste des
    ''' retenues à y payer (compagnie passée du Québec à une autre province).
    ''' </summary>
    Public Shared Function QuebecConcerne() As Boolean
        If Not Contexte.HorsQuebec Then Return True
        Return Solde(Quebec).NbPaies > 0
    End Function

    ' ---------- Échéances ----------

    Public Shared Function Frequence(gouvernement As String) As String
        Return Convert.ToString(Db.Scalaire("paie.spCompagnie_FrequenceRemise", Db.P("@c", Contexte.CompagnieId), Db.P("@g", VerifierGouvernement(gouvernement))))
    End Function

    ''' <summary>Dernier jour du mois (remise mensuelle) ou du trimestre (remise trimestrielle) de la paie.</summary>
    Public Shared Function FinPeriodeRemise(datePaie As Date, frequence As String) As Date
        Dim mois = If(frequence = "T", ((datePaie.Month - 1) \ 3 + 1) * 3, datePaie.Month)
        Return New Date(datePaie.Year, mois, 1).AddMonths(1).AddDays(-1)
    End Function

    ''' <summary>Le paiement est dû le 15 du mois qui suit la période.</summary>
    Public Shared Function Echeance(datePaie As Date, frequence As String) As Date
        Return FinPeriodeRemise(datePaie, frequence).AddDays(15)
    End Function

    Public Shared Function Solde(gouvernement As String) As SoldeRemise
        Dim r = Db.Ligne("paie.spRemise_Solde", Db.P("@c", Contexte.CompagnieId), Db.P("@fin", New Date(9999, 12, 31)), Db.P("@g", VerifierGouvernement(gouvernement)))
        Dim s As New SoldeRemise With {.Montant = r.Dcm("Montant"), .NbPaies = r.Ent("NbPaies"), .PlusAnciennePaie = r.DtN("PlusAncienne")}
        If s.PlusAnciennePaie.HasValue Then
            Dim f = Frequence(gouvernement)
            s.FinPeriode = FinPeriodeRemise(s.PlusAnciennePaie.Value, f)
            s.Echeance = Echeance(s.PlusAnciennePaie.Value, f)
        End If
        Return s
    End Function

    ''' <summary>CNT accumulée dans l'année (payable une fois l'an, à titre indicatif).</summary>
    Public Shared Function CntAccumulee(annee As Integer) As Decimal
        Return Convert.ToDecimal(Db.Scalaire("paie.spPaie_CntAccumulee", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee)))
    End Function

    ''' <summary>
    ''' Hors Québec : ce qui s'accumule dans l'année sans faire partie des remises au Receveur général, une
    ''' ligne par province (une compagnie peut en avoir changé). Colonnes : Province, Sante et MasseSante
    ''' (cotisation santé de l'employeur), Accidents et AssurableAccidents (commission des accidents du
    ''' travail), ImpotPaie et GainsImpotPaie (impôt sur la paie des T.N.-O. et du Nunavut, retenu aux
    ''' employés et à remettre au territoire). Les montants sont donnés à titre indicatif.
    ''' </summary>
    Public Shared Function HorsRemiseProvinces(annee As Integer) As DataTable
        Return Db.Table("paie.spPaie_HorsRemiseProvinces", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee))
    End Function

    ' ---------- Calcul et enregistrement ----------

    ''' <summary>Détail des montants à payer pour les retenues accumulées jusqu'à la date donnée (rien n'est enregistré).</summary>
    Public Shared Function LignesAPayer(gouvernement As String, finPeriode As Date) As DataTable
        Return Db.Table("paie.spRemise_LignesAPayer", Db.P("@c", Contexte.CompagnieId), Db.P("@fin", finPeriode),
                        Db.P("@g", VerifierGouvernement(gouvernement)), Db.P("@LibellesImpot", LibellesImpot()))
    End Function

    Public Shared Function LotsAPayer(gouvernement As String, finPeriode As Date) As DataTable
        Return Db.Table("paie.spRemise_Lots", Db.P("@c", Contexte.CompagnieId), Db.P("@g", VerifierGouvernement(gouvernement)), Db.P("@fin", finPeriode))
    End Function

    ''' <summary>Enregistre le paiement : rattache les paies à la remise et fige les montants, en une seule transaction.</summary>
    Public Shared Function Enregistrer(gouvernement As String, finPeriode As Date, datePaiement As Date, parCheque As Boolean, reference As String) As Integer
        Dim id = Db.ScalaireEntier("paie.spRemise_Enregistrer",
            Db.P("@c", Contexte.CompagnieId), Db.P("@g", VerifierGouvernement(gouvernement)), Db.P("@fin", finPeriode), Db.P("@paiement", datePaiement),
            Db.P("@parCheque", parCheque), Db.P("@ref", reference), Db.P("@u", Contexte.Utilisateur), Db.P("@LibellesImpot", LibellesImpot()))

        If id = 0 Then Throw New SaisieInvalideException("Aucune retenue à payer à " & NomGouvernement(gouvernement) & " pour cette période.")

        Dim total = Convert.ToDecimal(Db.Scalaire("paie.spRemise_Total", Db.P("@id", id)))
        Contexte.Journaliser("Paiement des retenues à " & NomGouvernement(gouvernement) & " : " & ArgentFr(total) & ".", "~/Remises/Detail.aspx?id=" & id.ToString())
        Return id
    End Function

    ''' <summary>Annule une remise : les paies redeviennent « à payer ». Le numéro de chèque n'est pas réutilisé.</summary>
    Public Shared Sub Annuler(remiseId As Integer)
        Dim r = Db.Ligne("paie.spRemise_Get", Db.P("@id", remiseId), Db.P("@c", Contexte.CompagnieId))
        If r Is Nothing Then Throw New SaisieInvalideException("Remise introuvable.")
        If r.Txt("Statut") <> "P" Then Throw New SaisieInvalideException("Cette remise est déjà annulée.")

        Db.Exec("paie.spRemise_Annuler", Db.P("@id", remiseId))
        Contexte.Journaliser("Paiement des retenues à " & NomGouvernement(r("Gouvernement")) & " du " & TexteDate(r("DatePaiement")) & " annulé.",
                             "~/Remises/Detail.aspx?id=" & remiseId.ToString())
    End Sub

    ''' <summary>Lots de paie couverts par une remise enregistrée (vide si elle est annulée).</summary>
    Public Shared Function LotsDeLaRemise(remiseId As Integer, gouvernement As String) As DataTable
        Return Db.Table("paie.spRemise_Lots", Db.P("@c", Contexte.CompagnieId), Db.P("@g", VerifierGouvernement(gouvernement)), Db.P("@id", remiseId))
    End Function

    ' ---------- Rendu ----------

    ''' <summary>Tableau des montants (lignes avec colonnes Libelle et Montant) suivi des paies couvertes.</summary>
    Public Shared Function Rendu(lignes As DataTable, lots As DataTable) As String
        Dim sb As New StringBuilder()
        Dim total As Decimal = 0D
        sb.Append("<table class=""liste""><thead><tr><th>Retenue ou cotisation</th><th class=""num"">Montant</th></tr></thead><tbody>")
        For Each l As DataRow In lignes.Rows
            total += l.Dcm("Montant")
            sb.Append("<tr><td>").Append(HttpUtility.HtmlEncode(l.Txt("Libelle"))).Append("</td><td class=""num"">").Append(Argent(l("Montant"))).Append("</td></tr>")
        Next
        sb.Append("</tbody><tfoot><tr><td>Total à payer</td><td class=""num"">").Append(Argent(total)).Append("</td></tr></tfoot></table>")

        If lots.Rows.Count > 0 Then
            sb.Append("<h2 style=""margin-top:20px"">Paies couvertes</h2><table class=""liste""><thead><tr><th>Date de paie</th><th>Période</th>")
            sb.Append("<th class=""num"">Employés</th><th class=""num"">Rémunération brute</th></tr></thead><tbody>")
            For Each lot As DataRow In lots.Rows
                sb.Append("<tr><td><a href=""../Paie/Detail.aspx?lot=").Append(lot.Ent("Id")).Append(""">").Append(TexteDate(lot("DatePaie"))).Append("</a></td><td>")
                sb.Append(TexteDate(lot("DateDebutPeriode"))).Append(" au ").Append(TexteDate(lot("DateFinPeriode"))).Append("</td><td class=""num"">")
                sb.Append(lot.Ent("NbEmployes")).Append("</td><td class=""num"">").Append(Argent(lot("Brut"))).Append("</td></tr>")
            Next
            sb.Append("</tbody></table>")
        End If
        Return sb.ToString()
    End Function

End Class
