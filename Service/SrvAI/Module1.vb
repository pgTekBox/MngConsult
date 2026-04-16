Module Module1
    Public Const REG_KEY As String = "HKEY_CURRENT_USER\Software\CronusEmailService"

    Public thisLock As New Object
    Public CounterMailSend As Integer = 0

    Public PoolClientsImap As ArrayList



End Module
