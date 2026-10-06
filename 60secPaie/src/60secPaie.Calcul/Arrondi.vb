''' <summary>
''' Règles d'arrondi des guides T4127 (ARC) et TP-1015.F (Revenu Québec).
''' </summary>
Public Module Arrondi

    ''' <summary>Arrondi au cent, le demi-cent étant arrondi vers le haut.</summary>
    Public Function Cents(valeur As Decimal) As Decimal
        Return Math.Round(valeur, 2, MidpointRounding.AwayFromZero)
    End Function

    ''' <summary>
    ''' Arrondi au cent du résultat d'une division ou d'une différence d'impôts annuels.
    ''' Ces calculs traînent des fractions qui ne tombent pas juste (0,0495 ÷ 0,0595, un impôt
    ''' annuel divisé par 52) : le résultat porte une trentaine de chiffres dont les derniers
    ''' sont perdus. Un montant qui vaut exactement 96,605 $ peut alors sortir à 96,60499999…
    ''' et s'arrondir vers le bas. On l'arrête donc d'abord à 8 décimales : le demi-cent
    ''' redevient un demi-cent, et s'arrondit vers le haut comme le veut le guide.
    ''' </summary>
    Public Function CentsExacts(valeur As Decimal) As Decimal
        Return Cents(Math.Round(valeur, 8, MidpointRounding.AwayFromZero))
    End Function

    ''' <summary>Conserve deux décimales sans arrondir (exemption RRQ par période : 3 500 $ ÷ 52 = 67,30 $).</summary>
    Public Function Tronquer2(valeur As Decimal) As Decimal
        Return Math.Truncate(valeur * 100D) / 100D
    End Function

    Public Function Plancher0(valeur As Decimal) As Decimal
        Return If(valeur < 0D, 0D, valeur)
    End Function

End Module
