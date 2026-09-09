Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web.UI.WebControls

''' <summary>
''' Socle des pages d'importation comptable — une page par étape de la
''' migration : plan comptable, tiers, produits, factures, écritures.
'''
''' Ce qui distingue cette classe de l'ancienne <see cref="ImportSageBase"/> :
'''
'''   1. elle ne connaît aucun logiciel en particulier. Sage 50, QuickBooks et
'''      Acomba ne sont que des jeux de réglages — séparateur, encodage,
'''      mots-clés de colonnes, chemin d'export — décrits dans SystemeSource ;
'''   2. elle n'écrit pas de SQL. Tout passe par des procédures stockées, comme
'''      partout ailleurs dans l'application ;
'''   3. elle charge en un seul appel, en JSON, plutôt qu'une requête par ligne.
'''
''' Rien de ce qui entre ici ne touche la comptabilité : tout va en préparation
''' (schéma staging), et c'est une étape distincte qui appliquera.
''' </summary>
Public MustInherit Class ImportComptableBase
    Inherits clsData

#Region "Les logiciels d'origine"

    ''' <summary>
    ''' Un logiciel comptable source, avec ce qu'il faut savoir pour lire ses
    ''' exports et ce qu'il faut dire à l'utilisateur pour qu'il les produise.
    ''' Ajouter un logiciel, c'est ajouter une entrée ici.
    ''' </summary>
    Public Class SystemeSource
        Public Property Code As String
        Public Property Nom As String
        Public Property Separateur As String
        Public Property Encodage As String

        ''' <summary>Où trouver l'export, en une ligne, affiché en permanence.</summary>
        Public Property CheminExport As String

        ''' <summary>Le nom du rapport dans le logiciel, tel qu'on l'y voit.</summary>
        Public Property NomRapport As String = ""

        ''' <summary>Le chemin, clic par clic.</summary>
        Public Property Etapes As New List(Of String)

        ''' <summary>
        ''' Ce qui fait échouer l'export si on n'y pense pas d'avance. Ce sont
        ''' les pièges qui coûtent une demi-heure parce qu'on cherche du mauvais
        ''' côté — d'où leur place en haut de l'aide, pas en bas.
        ''' </summary>
        Public Property Avertissements As New List(Of String)

        ''' <summary>Ce qui fait gagner du temps sans être bloquant.</summary>
        Public Property Astuces As New List(Of String)

        ''' <summary>Une aide est-elle rédigée pour ce logiciel ?</summary>
        Public ReadOnly Property AAide As Boolean
            Get
                Return Etapes.Count > 0
            End Get
        End Property
    End Class

    ''' <summary>
    ''' Les logiciels reconnus. Le chemin d'export est celui du plan comptable ;
    ''' chaque page le redéfinit pour ce qu'elle importe.
    ''' </summary>
    Public Shared ReadOnly Property SystemesSupportes As List(Of SystemeSource)
        Get
            Return New List(Of SystemeSource) From {
                New SystemeSource With {
                    .Code = "QBO", .Nom = "QuickBooks",
                    .Separateur = ",", .Encodage = "UTF-8",
                    .CheminExport = "Rapports ▸ Liste des comptes ▸ Exporter",
                    .NomRapport = "Liste des comptes — « Account List » en anglais, « Account Listing » sur QuickBooks Desktop",
                    .Etapes = New List(Of String) From {
                        "Ouvrez <b>Rapports</b> dans le menu de gauche.",
                        "Cherchez <b>Liste des comptes</b> dans la barre de recherche des rapports. Le rapport se trouve aussi sous <b>Pour mon comptable</b>.",
                        "Cliquez sur l'icône d'<b>exportation</b> en haut à droite du rapport, puis sur <b>Exporter vers Excel</b>.",
                        "Ouvrez le fichier obtenu dans Excel, puis <b>Fichier ▸ Enregistrer sous ▸ CSV (séparateur : point-virgule)</b> ou <b>CSV UTF-8</b>.",
                        "Revenez ici et déposez le fichier CSV."
                    },
                    .Avertissements = New List(Of String) From {
                        "QuickBooks propose souvent <b>Excel</b> mais pas <b>CSV</b> pour ce rapport. " &
                        "Dans ce cas, passez par Excel et enregistrez ensuite en CSV : cette page ne lit pas les fichiers <code>.xlsx</code>."
                    },
                    .Astuces = New List(Of String) From {
                        "<b>Vos comptes n'ont pas de numéros ?</b> C'est normal : QuickBooks en ligne les rend facultatifs et " &
                        "les masque par défaut. L'importation fonctionne quand même — <b>le nom du compte sert alors de clé</b>. " &
                        "Si vous préférez travailler avec des numéros, activez-les avant l'export dans " &
                        "<b>⚙️ Paramètres du compte ▸ Avancé ▸ Plan comptable ▸ Activer les numéros de compte</b>, " &
                        "puis attribuez-les à vos comptes — c'est une décision comptable, pas une formalité.",
                        "Si l'export contient une colonne <b>Detail Type</b> en plus de <b>Type</b>, c'est celle qui est le plus à gauche qui sera retenue. L'aperçu vous dira laquelle.",
                        "Les accents en charabia (<code>Ã©</code> au lieu de <code>é</code>) viennent de l'encodage : réessayez en <b>Windows-1252</b>.",
                        "Le rapport peut contenir une ligne de titre ou une ligne de total. Elles seront signalées comme lignes invalides et écartées — c'est sans conséquence."
                    }
                },
                New SystemeSource With {
                    .Code = "SAGE50", .Nom = "Sage 50",
                    .Separateur = ";", .Encodage = "Windows-1252",
                    .CheminExport = "Reports ▸ Lists ▸ Chart of Accounts ▸ Export CSV"
                },
                New SystemeSource With {
                    .Code = "ACOMBA", .Nom = "Acomba",
                    .Separateur = ";", .Encodage = "Windows-1252",
                    .CheminExport = "Comptabilité ▸ Plan comptable ▸ Exporter"
                },
                New SystemeSource With {
                    .Code = "AUTRE", .Nom = "Autre logiciel",
                    .Separateur = ";", .Encodage = "UTF-8",
                    .CheminExport = "Exportez votre plan comptable en CSV, une ligne par compte."
                }
            }
        End Get
    End Property

    Public Shared Function TrouverSysteme(code As String) As SystemeSource
        Dim s = SystemesSupportes.FirstOrDefault(Function(x) x.Code = code)
        If s Is Nothing Then s = SystemesSupportes.Last()   ' AUTRE
        Return s
    End Function

#End Region

#Region "À définir par chaque page"

    ''' <summary>PLAN_COMPTABLE, TIERS, PRODUITS... — ce que la page importe.</summary>
    Protected MustOverride ReadOnly Property TypeDonnees As String

    ''' <summary>
    ''' Les colonnes attendues, dans l'ordre où on les cherchera à défaut
    ''' d'en-têtes reconnaissables.
    ''' </summary>
    Protected MustOverride ReadOnly Property Colonnes As List(Of ColonneDef)

    ''' <summary>
    ''' Transforme une ligne lue en la ligne qui partira en préparation.
    ''' C'est ici que chaque page met sa normalisation propre.
    ''' </summary>
    Protected MustOverride Function Normaliser(valeurs As Dictionary(Of String, String), ligneNo As Integer) As Dictionary(Of String, Object)

    ''' <summary>La procédure qui charge le lot pour ce type de données.</summary>
    Protected MustOverride ReadOnly Property ProcedureChargement As String

#End Region

#Region "Lecture du fichier"

    ''' <summary>
    ''' Lit le CSV et rend un tableau. Les erreurs de lecture remontent à
    ''' l'appelant : c'est lui qui sait comment les montrer.
    ''' </summary>
    Protected Function LireCsv(contenu As Stream,
                               separateur As Char,
                               encodage As Encoding,
                               avecEntete As Boolean,
                               Optional maxLignes As Integer = 0) As DataTable

        Dim lignes As New List(Of String)
        contenu.Position = 0

        Using lecteur As New StreamReader(contenu, encodage)
            Dim ligne As String = lecteur.ReadLine()
            While ligne IsNot Nothing
                If Not String.IsNullOrWhiteSpace(ligne) Then
                    lignes.Add(ligne)
                    If maxLignes > 0 AndAlso lignes.Count > maxLignes Then Exit While
                End If
                ligne = lecteur.ReadLine()
            End While
        End Using

        Dim dt As New DataTable()
        If lignes.Count = 0 Then Return dt

        Dim premiere = DecouperLigne(lignes(0), separateur)
        Dim depart As Integer = 0

        If avecEntete Then
            For Each col In premiere
                Dim nom = col.Trim()
                If nom = "" Then nom = "Colonne_" & (dt.Columns.Count + 1)
                Dim racine = nom, suffixe = 1
                While dt.Columns.Contains(nom)
                    nom = racine & "_" & suffixe
                    suffixe += 1
                End While
                dt.Columns.Add(nom)
            Next
            depart = 1
        Else
            For i = 0 To premiere.Length - 1
                dt.Columns.Add("Colonne_" & (i + 1))
            Next
        End If

        For i = depart To lignes.Count - 1
            Dim valeurs = DecouperLigne(lignes(i), separateur)
            Dim r = dt.NewRow()
            For j = 0 To Math.Min(valeurs.Length, dt.Columns.Count) - 1
                r(j) = valeurs(j).Trim()
            Next
            dt.Rows.Add(r)
        Next

        Return dt
    End Function

    ''' <summary>
    ''' Découpe une ligne CSV en tenant compte des guillemets : un séparateur
    ''' entre guillemets fait partie de la valeur, et deux guillemets de suite
    ''' en désignent un seul.
    ''' </summary>
    Private Shared Function DecouperLigne(ligne As String, separateur As Char) As String()
        Dim champs As New List(Of String)
        Dim entreGuillemets As Boolean = False
        Dim courant As New StringBuilder()
        Dim i As Integer = 0

        While i < ligne.Length
            Dim c = ligne(i)
            If entreGuillemets Then
                If c = """"c Then
                    If i + 1 < ligne.Length AndAlso ligne(i + 1) = """"c Then
                        courant.Append(""""c) : i += 1
                    Else
                        entreGuillemets = False
                    End If
                Else
                    courant.Append(c)
                End If
            Else
                If c = """"c Then
                    entreGuillemets = True
                ElseIf c = separateur Then
                    champs.Add(courant.ToString()) : courant.Clear()
                Else
                    courant.Append(c)
                End If
            End If
            i += 1
        End While

        champs.Add(courant.ToString())
        Return champs.ToArray()
    End Function

    ''' <summary>
    ''' Associe chaque colonne attendue à une colonne du fichier, par mots-clés
    ''' sur l'en-tête. Sans en-tête exploitable, on retombe sur l'ordre des
    ''' colonnes — c'est moins sûr, mais c'est mieux que de ne rien lire.
    ''' </summary>
    Protected Function AssocierColonnes(dt As DataTable) As Dictionary(Of String, Integer)
        Dim map As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)

        For i = 0 To dt.Columns.Count - 1
            Dim entete = dt.Columns(i).ColumnName.ToLowerInvariant().Trim()
            For Each col In Colonnes
                If map.ContainsKey(col.Champ) Then Continue For
                For Each motCle In col.MotsCles
                    If entete = motCle.ToLowerInvariant() OrElse entete.Contains(motCle.ToLowerInvariant()) Then
                        map(col.Champ) = i
                        Exit For
                    End If
                Next
            Next
        Next

        If map.Count < Math.Min(2, Colonnes.Count) Then
            map.Clear()
            For i = 0 To Math.Min(Colonnes.Count, dt.Columns.Count) - 1
                map(Colonnes(i).Champ) = i
            Next
        End If

        Return map
    End Function

    Protected Shared Function Valeur(r As DataRow, map As Dictionary(Of String, Integer), champ As String) As String
        If Not map.ContainsKey(champ) Then Return ""
        Dim i = map(champ)
        If i >= r.Table.Columns.Count OrElse IsDBNull(r(i)) Then Return ""
        Return Convert.ToString(r(i)).Trim()
    End Function

#End Region

#Region "Écriture en préparation"

    ''' <summary>Ouvre un lot et rend son identifiant.</summary>
    Protected Function OuvrirLot(systemeSource As String,
                                 nomFichier As String,
                                 separateur As String,
                                 encodage As String) As Integer

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@SystemeSource", systemeSource))
        p.Add(New SqlParameter("@TypeDonnees", TypeDonnees))
        p.Add(New SqlParameter("@NomFichier", If(nomFichier, "")))
        p.Add(New SqlParameter("@Separateur", If(separateur, "")))
        p.Add(New SqlParameter("@Encodage", If(encodage, "")))
        p.Add(New SqlParameter("@UserId", UserId))

        Dim ds As DataSet = ExecuteSQLds("s0751OuvrirImportLot", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Throw New InvalidOperationException("Le lot d'importation n'a pas pu être ouvert.")
        End If
        Return Convert.ToInt32(ds.Tables(0).Rows(0)("LotId"))
    End Function

    ''' <summary>
    ''' Envoie tout le fichier en un appel. Le JSON évite un aller-retour par
    ''' ligne, et laisse la procédure voir l'ensemble du lot — c'est ce qui lui
    ''' permet de repérer les doublons internes au fichier.
    ''' </summary>
    Protected Function ChargerLot(lotId As Integer, lignes As List(Of Dictionary(Of String, Object))) As DataRow
        Dim json As String = Newtonsoft.Json.JsonConvert.SerializeObject(lignes)

        Dim p As New Collection
        p.Add(New SqlParameter("@LotId", lotId))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Lignes", json))

        Dim ds As DataSet = ExecuteSQLds(ProcedureChargement, p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

#End Region

#Region "Conversions"

    ''' <summary>
    ''' Lit un montant tel que l'écrivent les logiciels comptables : signe du
    ''' dollar, espaces, virgule décimale, et les parenthèses qui valent un
    ''' signe moins. Rend Nothing quand la valeur n'est pas un nombre — la
    ''' ligne partira quand même en préparation, avec sa valeur d'origine
    ''' conservée à côté.
    ''' </summary>
    Protected Shared Function LireMontant(brut As String) As Decimal?
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim v = brut.Replace("$", "").Replace(" ", "").Replace(" ", "").Trim()
        Dim negatif As Boolean = False

        If v.StartsWith("(") AndAlso v.EndsWith(")") Then
            negatif = True
            v = v.Trim("("c, ")"c)
        End If

        ' « 1 234,56 » et « 1,234.56 » désignent le même montant : on ne garde
        ' que le dernier séparateur comme décimal.
        Dim dernierePoint = v.LastIndexOf("."c)
        Dim derniereVirgule = v.LastIndexOf(","c)

        If dernierePoint >= 0 AndAlso derniereVirgule >= 0 Then
            If derniereVirgule > dernierePoint Then
                v = v.Replace(".", "").Replace(",", ".")
            Else
                v = v.Replace(",", "")
            End If
        ElseIf derniereVirgule >= 0 Then
            v = v.Replace(",", ".")
        End If

        Dim d As Decimal
        If Not Decimal.TryParse(v, Globalization.NumberStyles.Any,
                                Globalization.CultureInfo.InvariantCulture, d) Then
            Return Nothing
        End If

        Return If(negatif, -d, d)
    End Function

#End Region

#Region "Modèles"

    Public Class ColonneDef
        Public Property Champ As String
        Public Property Libelle As String
        Public Property MotsCles As String() = {}
        Public Property Description As String = ""

        ''' <summary>Exigée à elle seule.</summary>
        Public Property Obligatoire As Boolean = False

        ''' <summary>
        ''' Participe à l'identification de la ligne. Il en faut au moins une
        ''' parmi celles marquées ainsi — pas toutes.
        '''
        ''' C'est le cas du plan comptable : le numéro identifie le compte quand
        ''' il existe, le nom quand il n'existe pas. QuickBooks en ligne rend les
        ''' numéros facultatifs et les désactive par défaut ; exiger le numéro
        ''' fermait la porte à toutes les compagnies qui n'en ont jamais eu.
        ''' </summary>
        Public Property Cle As Boolean = False
    End Class

#End Region

End Class
