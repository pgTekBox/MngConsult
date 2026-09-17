''' <summary>
''' Règles d'arrondi des guides T4127 (ARC) et TP-1015.F (Revenu Québec).
''' </summary>
Public Module Arrondi

    ''' <summary>Arrondi au cent, le demi-cent étant arrondi vers le haut.</summary>
    Public Function Cents(valeur As Decimal) As Decimal
        Return Math.Round(valeur, 2, MidpointRounding.AwayFromZero)
    End Function

    ''' <summary>Conserve deux décimales sans arrondir (exemption RRQ par période : 3 500 $ ÷ 52 = 67,30 $).</summary>
    Public Function Tronquer2(valeur As Decimal) As Decimal
        Return Math.Truncate(valeur * 100D) / 100D
    End Function

    Public Function Plancher0(valeur As Decimal) As Decimal
        Return If(valeur < 0D, 0D, valeur)
    End Function

End Module
