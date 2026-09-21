# =============================================================================
# Génère un catalogue de produits et services prêt à importer dans QuickBooks
# Online.
#
#   .\GenererProduits.ps1
#   .\GenererProduits.ps1 -Nombre 500
#
# CE FICHIER N'EST PAS GÉNÉRIQUE : il est accordé au compte QuickBooks de
# K9Excel, lu en direct le 2026-09-18. C'est ce qui le rend importable sans
# retouche, et ce qui le rendra faux ailleurs.
#
#   · les comptes de revenus et de dépenses sont CEUX QUI EXISTENT dans le plan
#     comptable. QBO refuse un article dont le compte est inconnu — inventer
#     « Ventes de produits » ferait échouer chaque ligne ;
#   · aucun sous-compte : QBO les refuse pour un article. Vérifié, il n'y en a
#     pas parmi les comptes de revenus ni de coût des marchandises ;
#   · AUCUN article de type Inventory. La préférence QuantityOnHand du compte
#     est à False : le suivi des quantités est désactivé, et un article de stock
#     serait rejeté. D'où Service et Non-inventory seulement ;
#   · les taxes sont désactivées (UsingSalesTax = False), donc la colonne
#     Taxable reste à N ;
#   · AUCUN deux-points dans un nom d'article : c'est le séparateur de
#     catégorie de QuickBooks, et il fait rejeter la ligne. La catégorie
#     voyage dans une colonne à part ;
#   · les noms évitent « ser1 » et « Services », les deux articles déjà
#     présents : QBO refuse un doublon de nom.
#
# Pour un autre compte, relire ces quatre points avant de s'en servir.
# =============================================================================

[CmdletBinding()]
param(
  [int] $Nombre = 200,
  [string] $Dossier = 'C:\MesSources\MngConsul\QBO'
)

$ErrorActionPreference = 'Stop'

# --- Les comptes réels du plan comptable --------------------------------------
$RevenuService  = @('Services', 'Revenus des dépenses facturables')
$RevenuProduit  = @('Revenus provenant de la vente de produits', 'Sales')
$RevenuLivraison= @('Shipping and Delivery Income')
$CoutMarchandise= @('Coût des produits vendus', 'Supplies and materials - COS', 'Purchases - COS')
$CoutMainOeuvre = @('Cost of Labour - COS', 'Subcontractors - COS')
$CoutLivraison  = @('Freight and delivery - COS')

# --- Le catalogue --------------------------------------------------------------
# Chaque article porte sa catégorie, son type, sa fourchette de prix et le
# compte qui lui convient. Un prix tiré au hasard sur tout le catalogue
# donnerait des cartouches d'encre à 2 000 $ et des audits à 15 $.
$Catalogue = @(
  @{ cat='Services professionnels'; type='Service'; min=85;  max=260; rev=$RevenuService; cout=$CoutMainOeuvre; unite='h'
     noms=@('Analyse de besoins','Audit de sécurité','Consultation stratégique','Accompagnement au changement','Étude de faisabilité','Révision de processus','Plan de relève informatique','Expertise réglementaire','Diagnostic de performance','Atelier de cadrage') },

  @{ cat='Développement';           type='Service'; min=95;  max=175; rev=$RevenuService; cout=$CoutMainOeuvre; unite='h'
     noms=@('Développement Web','Développement mobile','Intégration d''API','Migration de données','Automatisation de rapports','Correction d''anomalies','Refonte d''interface','Mise à niveau applicative','Développement de connecteur','Optimisation de requêtes') },

  @{ cat='Soutien technique';       type='Service'; min=55;  max=140; rev=$RevenuService; cout=$CoutMainOeuvre; unite='h'
     noms=@('Soutien téléphonique','Intervention sur place','Dépannage à distance','Surveillance de serveurs','Gestion des sauvegardes','Nettoyage de poste','Réinstallation de système','Configuration de poste','Récupération de données','Assistance prioritaire') },

  @{ cat='Formation';               type='Service'; min=450; max=1850; rev=$RevenuService; cout=$CoutMainOeuvre; unite='jour'
     noms=@('Formation bureautique','Formation comptabilité','Formation sécurité','Formation sur mesure','Atelier pratique','Séance de démarrage','Certification interne','Coaching individuel','Formation en ligne','Mise à niveau annuelle') },

  @{ cat='Entretien et contrats';   type='Service'; min=180; max=2400; rev=$RevenuService; cout=$CoutMainOeuvre; unite='mois'
     noms=@('Contrat d''entretien mensuel','Forfait de soutien annuel','Surveillance continue','Hébergement géré','Sauvegarde infonuagique','Plan de continuité','Garantie prolongée','Infogérance complète','Veille de sécurité','Mises à jour gérées') },

  @{ cat='Matériel informatique';   type='Non-inventory'; min=145; max=3400; rev=$RevenuProduit; cout=$CoutMarchandise; unite=''
     noms=@('Ordinateur portable 14 po','Ordinateur de bureau','Écran 27 po','Station d''accueil','Clavier ergonomique','Souris sans fil','Casque d''écoute','Caméra de conférence','Disque SSD externe','Onduleur 1500 VA','Imprimante laser','Numériseur de documents') },

  @{ cat='Réseau';                  type='Non-inventory'; min=75;  max=2900; rev=$RevenuProduit; cout=$CoutMarchandise; unite=''
     noms=@('Routeur d''entreprise','Commutateur 24 ports','Point d''accès sans fil','Pare-feu géré','Câble réseau 3 m','Panneau de brassage','Injecteur PoE','Module fibre optique','Antenne extérieure','Baie murale 9U') },

  @{ cat='Licences et abonnements'; type='Non-inventory'; min=45;  max=980; rev=$RevenuProduit; cout=$CoutMarchandise; unite='an'
     noms=@('Licence bureautique','Antivirus poste de travail','Licence serveur','Abonnement infonuagique','Certificat SSL','Licence de sauvegarde','Suite de sécurité','Licence de virtualisation','Gestion de mots de passe','Filtrage de courriel') },

  @{ cat='Fournitures';             type='Non-inventory'; min=9;   max=180; rev=$RevenuProduit; cout=$CoutMarchandise; unite=''
     noms=@('Cartouche d''encre noire','Cartouche couleur','Papier multiusage','Étiquettes adhésives','Clé USB 64 Go','Tapis de souris','Rallonge électrique','Barre d''alimentation','Chiffon antistatique','Boîtier de rangement') },

  @{ cat='Livraison et déplacement'; type='Service'; min=25;  max=250; rev=$RevenuLivraison; cout=$CoutLivraison; unite=''
     noms=@('Frais de livraison locale','Livraison express','Frais de déplacement','Kilométrage','Installation sur place','Récupération de matériel','Manutention','Frais de transport interurbain','Livraison le lendemain','Reprise d''équipement') }
)

# Déclinaisons : de quoi produire deux cents articles distincts sans répéter.
# Trait d'union simple plutôt que tiret cadratin : moins de surprises à l'import.
$Variantes = @('', ' - standard', ' - avancé', ' - essentiel', ' - professionnel', ' - 1 an', ' - 3 ans',
               ' - petite entreprise', ' - grande entreprise', ' - hors garantie', ' - urgence',
               ' - fin de semaine', ' - gamme A', ' - gamme B', ' - reconditionné', ' - sur mesure')

function Tirer($liste) { $liste[(Get-Random -Maximum $liste.Count)] }

function Sku($cat, $n) {
  $p = ($cat -replace '[^A-Za-zÀ-ÿ]', '').Substring(0,3).ToUpperInvariant()
  "{0}-{1:0000}" -f $p, $n
}

# --- Génération ----------------------------------------------------------------
# Les deux articles déjà dans QuickBooks : un doublon de nom fait rejeter la ligne.
$vus = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
[void]$vus.Add('ser1'); [void]$vus.Add('Services')

$articles = New-Object 'System.Collections.Generic.List[object]'
$sequence = 0
$garde = 0

while ($articles.Count -lt $Nombre -and $garde -lt ($Nombre * 60)) {
  $garde++
  $c = Tirer $Catalogue
  $nom = (Tirer $c.noms) + (Tirer $Variantes)
  if (-not $vus.Add($nom)) { continue }

  $sequence++
  $prix = [Math]::Round((Get-Random -Minimum $c.min -Maximum $c.max) + 0.0, 0)
  # Le prix se termine en 5 ou en 9 comme dans la vraie vie, sauf les gros montants.
  if ($prix -lt 1000) { $prix = [Math]::Floor($prix / 5) * 5 - 0.05 } else { $prix = [Math]::Round($prix / 10) * 10 }
  # La marge : plus serrée sur la marchandise que sur le service.
  $marge = if ($c.type -eq 'Service') { Get-Random -Minimum 35 -Maximum 60 } else { Get-Random -Minimum 55 -Maximum 78 }
  $cout = [Math]::Round($prix * $marge / 100, 2)

  $suffixeUnite = if ($c.unite) { " / " + $c.unite } else { "" }

  # Le deux-points est le séparateur de catégorie de QuickBooks : il est donc
  # INTERDIT dans le nom d'un article. La catégorie part dans sa propre
  # colonne, à mapper si l'écran d'import la propose, à laisser de côté sinon.
  $nomComplet = $nom
  $sku = Sku $c.cat $sequence

  $articles.Add([pscustomobject][ordered]@{
    'Product/Service Name' = $nomComplet
    'Category'             = $c.cat
    'SKU'                  = $sku
    'Type'                 = $c.type
    'Sales Description'    = $nom + $suffixeUnite
    'Sales Price'          = ("{0:F2}" -f $prix)
    'Income Account'       = Tirer $c.rev
    'Purchase Description' = $nom
    'Purchase Cost'        = ("{0:F2}" -f $cout)
    'Expense Account'      = Tirer $c.cout
    'Taxable'              = 'N'      # les taxes sont désactivées dans ce compte
  })
}

if ($articles.Count -lt $Nombre) {
  Write-Warning "Seulement $($articles.Count) articles distincts : ajoutez des noms ou des variantes au catalogue."
}

# --- Écriture -------------------------------------------------------------------
if (-not (Test-Path $Dossier)) { New-Item -ItemType Directory -Path $Dossier | Out-Null }
$chemin = Join-Path $Dossier 'produits-services-qbo-200.csv'

# BOM UTF-8 : Excel affiche alors correctement « Développement » et « Numériseur ».
[IO.File]::WriteAllLines($chemin, ($articles | ConvertTo-Csv -NoTypeInformation), (New-Object Text.UTF8Encoding($true)))

"$chemin  —  $($articles.Count) articles"
