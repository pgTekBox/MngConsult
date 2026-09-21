''' <summary>What is entered to create a payee.</summary>
Public Class PayeeInput
    Public Property AccountName As String = ""
    Public Property CustomerNumber As String = ""
    Public Property PayeeType As String = "INSURED"
    Public Property FirstName As String = ""
    Public Property LastName As String = ""
    Public Property Email As String = ""
    Public Property Phone As String = ""
    Public Property Language As String = "fr-CA"
    Public Property Address As String = ""
    Public Property Address2 As String = ""
    Public Property City As String = ""
    Public Property Province As String = ""
    Public Property PostalCode As String = ""
End Class

''' <summary>What is entered to add a bank account (EFT).</summary>
Public Class BankAccountInput
    Public Property PayeeUserId As String = ""
    Public Property AccountName As String = ""
    Public Property InstitutionNumber As String = ""
    Public Property TransitNumber As String = ""
    Public Property AccountNumber As String = ""
    Public Property AccountType As String = "CHEQUING"
    Public Property CurrencyCode As String = "CAD"
    Public Property CountryCode As String = "CA"
    Public Property BankName As String = ""

    ''' <summary>
    ''' autoAcceptPaymentMethod is a STRING in the ERP (a method code such as
    ''' "EFT"), not a flag. Empty means the field is left out, which is what the
    ''' website does today.
    ''' </summary>
    Public Property AutoAcceptPaymentMethod As String = ""

    Public Property AutoVerify As Boolean = True
End Class

''' <summary>What is entered to issue a payment.</summary>
Public Class PaymentInput
    Public Property PayeeId As String = ""
    Public Property PayeeUserId As String = ""

    ''' <summary>The amount in dollars, as typed on screen.</summary>
    Public Property Amount As Decimal = 0D

    ''' <summary>
    ''' True sends amount.value as a NUMBER of cents (1000), which is what the
    ''' ERP does. False sends a STRING of dollars ("10.00").
    '''
    ''' The unit is still unconfirmed by Dream — the comment "⚠️ unité à
    ''' confirmer" sits in clsDreamPayments to this day. This switch is here to
    ''' settle it: try one, try the other, and see which one Dream accepts.
    ''' </summary>
    Public Property AmountInCents As Boolean = True

    Public Property CurrencyCode As String = "CAD"
    Public Property Memo As String = ""
    Public Property PaymentType As String = "EXPENSE"

    ''' <summary>The website never sends payoutDate; off by default to match it.</summary>
    Public Property SendPayoutDate As Boolean = False
    Public Property PayoutDate As Date = Date.Today

    Public Property ExternalReference As String = ""
    Public Property DraftNumber As String = ""
    Public Property ClaimNumber As String = ""
    Public Property PolicyNumber As String = ""
    Public Property PcoNumber As String = ""
    Public Property LegalEntity As String = ""
    Public Property LegalEntityLabel As String = ""
    Public Property NotifyEmail As String = ""
    Public Property AllowedMethods As String = "EFT"
End Class

''' <summary>
''' The JSON bodies of each call, modelled on the ERP's clsDreamPayments: this
''' POC has to send exactly what the website sends, or it proves nothing.
'''
''' Nothing is guessed here. Every field, its JSON type, the order of the keys
''' and the rule for leaving a field out all come from clsDreamPayments.vb and
''' from the two payment pages that drive it. Where the ERP itself is unsure —
''' the unit of amount.value — the POC lets you try both rather than pick one.
''' </summary>
Public Module Payloads

    ''' <summary>POST /payees/add — creates the payee and its user.</summary>
    Public Function PayeeBody(p As PayeeInput) As JsonObject
        Dim account As New JsonObject From {{"accountName", p.AccountName}}

        ' Like the ERP: no address block at all when the street is empty, and
        ' address2 always present (possibly empty) when there is one.
        If p.Address <> "" Then
            Dim address As New JsonObject From {
                {"address", p.Address},
                {"address2", p.Address2},
                {"addressType", "BILLING"}
            }
            AddIfSet(address, "city", p.City)
            address("primary") = True
            AddIfSet(address, "province", p.Province)
            AddIfSet(address, "zipCode", p.PostalCode)
            account("addresses") = New JsonObject From {{"address", New JsonArray From {address}}}
        End If

        AddIfSet(account, "customerNumber", p.CustomerNumber)
        account("payeeType") = p.PayeeType

        Dim contactName As New JsonObject()
        AddIfSet(contactName, "firstName", p.FirstName)
        AddIfSet(contactName, "lastName", p.LastName)

        Dim contactInfo As New JsonObject()
        If p.Email <> "" Then
            contactInfo("emails") = New JsonObject From {{"email", New JsonArray From {
                New JsonObject From {{"address", p.Email}, {"emailStatus", "NOT_VERIFIED"}}}}}
        End If
        If p.Phone <> "" Then
            contactInfo("phones") = New JsonObject From {{"phone", New JsonArray From {
                New JsonObject From {{"deviceType", "OTHER"}, {"phoneNumber", p.Phone}}}}}
        End If

        Dim user As New JsonObject()
        If contactInfo.Count > 0 Then user("contactInfo") = contactInfo
        user("contactName") = contactName
        AddIfSet(user, "preferredLanguage", p.Language)

        Return New JsonObject From {
            {"payeeAccountInfo", account},
            {"payeeUserAccountInfo", user}
        }
    End Function

    ''' <summary>POST /payees/{payeeId}/accounts — attaches a bank account.</summary>
    Public Function BankAccountBody(b As BankAccountInput) As JsonObject
        Dim bank As New JsonObject From {{"genericAccountType", "BANK"}}
        AddIfSet(bank, "accountName", b.AccountName)
        AddIfSet(bank, "accountNumber", b.AccountNumber)
        AddIfSet(bank, "institutionNumber", b.InstitutionNumber)
        AddIfSet(bank, "transitNumber", b.TransitNumber)
        AddIfSet(bank, "bankAccountType", b.AccountType)
        AddIfSet(bank, "currencyCode", b.CurrencyCode)
        AddIfSet(bank, "countryCode", b.CountryCode)
        AddIfSet(bank, "bankName", b.BankName)
        AddIfSet(bank, "autoAcceptPaymentMethod", b.AutoAcceptPaymentMethod)

        Return New JsonObject From {
            {"bankAccount", bank},
            {"payeeUserId", b.PayeeUserId},
            {"autoVerify", b.AutoVerify}
        }
    End Function

    ''' <summary>POST /payments/add — issues the payment.</summary>
    Public Function PaymentBody(p As PaymentInput) As JsonObject
        Dim amount As New JsonObject From {{"currencyCode", p.CurrencyCode}}
        If p.AmountInCents Then
            amount("value") = JsonValue.Create(CLng(Math.Round(p.Amount * 100D)))
        Else
            amount("value") = p.Amount.ToString("0.00", Globalization.CultureInfo.InvariantCulture)
        End If

        Dim info As New JsonObject From {{"amount", amount}}
        AddIfSet(info, "memo", p.Memo)
        AddIfSet(info, "paymentType", p.PaymentType)
        If p.SendPayoutDate Then info("payoutDate") = p.PayoutDate.ToString("yyyy-MM-ddT00:00:00Z")
        AddIfSet(info, "externalReferenceData", p.ExternalReference)
        AddIfSet(info, "draftNumber", p.DraftNumber)
        AddIfSet(info, "claimNumber", p.ClaimNumber)
        AddIfSet(info, "policyNumber", p.PolicyNumber)
        AddIfSet(info, "pcoNumber", p.PcoNumber)
        AddIfSet(info, "legalEntity", p.LegalEntity)

        Dim body As New JsonObject From {
            {"payeeId", p.PayeeId},
            {"payeeUserId", p.PayeeUserId},
            {"paymentInfo", info}
        }
        AddIfSet(body, "legalEntityLabel", p.LegalEntityLabel)
        AddIfSet(body, "notifyEmail", p.NotifyEmail)

        Dim methods As New JsonArray()
        For Each m In p.AllowedMethods.Split({","c, " "c}, StringSplitOptions.RemoveEmptyEntries)
            methods.Add(JsonValue.Create(m.Trim().ToUpperInvariant()))
        Next
        If methods.Count > 0 Then body("allowablePaymentMethods") = methods

        Return body
    End Function

    ''' <summary>
    ''' POST /payments/{paymentId}/accept — the payee takes the money.
    ''' EFT needs the bank account; Interac (ETRAN) needs none.
    ''' </summary>
    Public Function AcceptBody(payeeUserId As String, method As String, bankAccountId As String) As JsonObject
        Dim body As New JsonObject()
        If bankAccountId <> "" Then body("bankAccountId") = bankAccountId
        body("payeeUserId") = payeeUserId
        body("paymentMethod") = method
        Return body
    End Function

    ''' <summary>Adds a string property only when it is not empty, like the ERP's AddIf.</summary>
    Private Sub AddIfSet(o As JsonObject, name As String, value As String)
        If value <> "" Then o(name) = value
    End Sub

End Module
