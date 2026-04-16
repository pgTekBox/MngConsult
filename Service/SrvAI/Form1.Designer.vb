<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Form1
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Dim DataGridViewCellStyle1 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Dim DataGridViewCellStyle2 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Dim DataGridViewCellStyle3 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(Form1))
        Me.txtLogEvent = New System.Windows.Forms.TextBox()
        Me.MenuStrip1 = New System.Windows.Forms.MenuStrip()
        Me.AjustementToolStripMenuItem = New System.Windows.Forms.ToolStripMenuItem()
        Me.btnDelEvents = New System.Windows.Forms.Button()
        Me.TabControl1 = New System.Windows.Forms.TabControl()
        Me.tbStatus = New System.Windows.Forms.TabPage()
        Me.GroupBox2 = New System.Windows.Forms.GroupBox()
        Me.Label37 = New System.Windows.Forms.Label()
        Me.Label34 = New System.Windows.Forms.Label()
        Me.lblSendStep = New System.Windows.Forms.Label()
        Me.lblLastSend = New System.Windows.Forms.Label()
        Me.lblNbSendMail = New System.Windows.Forms.Label()
        Me.lblSendFrom = New System.Windows.Forms.Label()
        Me.Label35 = New System.Windows.Forms.Label()
        Me.lblSendTo = New System.Windows.Forms.Label()
        Me.Label36 = New System.Windows.Forms.Label()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.Label8 = New System.Windows.Forms.Label()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.lblCounterEmailInput = New System.Windows.Forms.Label()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.lblStatusSMTPStepInput = New System.Windows.Forms.Label()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.lblMailSizeInput = New System.Windows.Forms.Label()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.lblLastRecipient = New System.Windows.Forms.Label()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.lblSMTPStep = New System.Windows.Forms.Label()
        Me.lblLastDomainName = New System.Windows.Forms.Label()
        Me.lblSMTPClientIP = New System.Windows.Forms.Label()
        Me.Label7 = New System.Windows.Forms.Label()
        Me.Label9 = New System.Windows.Forms.Label()
        Me.lblThreadSMTPInputStarted = New System.Windows.Forms.Label()
        Me.lblThreadSMTPLastReceived = New System.Windows.Forms.Label()
        Me.tbEvents = New System.Windows.Forms.TabPage()
        Me.tbError = New System.Windows.Forms.TabPage()
        Me.btnDelError = New System.Windows.Forms.Button()
        Me.txtlogError = New System.Windows.Forms.TextBox()
        Me.tbGridMail = New System.Windows.Forms.TabPage()
        Me.btnResend = New System.Windows.Forms.Button()
        Me.btnRefresh = New System.Windows.Forms.Button()
        Me.dvListMail = New System.Windows.Forms.DataGridView()
        Me.Id = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.RCPT = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.sTo = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.Retry = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.SendAt = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.Received = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.Sended = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.tosend = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.SendWithSuccess = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.tbGridError = New System.Windows.Forms.TabPage()
        Me.lblMessageError = New System.Windows.Forms.Label()
        Me.dvListError = New System.Windows.Forms.DataGridView()
        Me.DataGridViewTextBoxColumn1 = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.DataGridViewTextBoxColumn4 = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.DataGridViewTextBoxColumn3 = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.DataGridViewTextBoxColumn5 = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.dCreated = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.tbSource = New System.Windows.Forms.TabPage()
        Me.txtMail = New System.Windows.Forms.TextBox()
        Me.tbHTML = New System.Windows.Forms.TabPage()
        Me.txtHTML = New System.Windows.Forms.TextBox()
        Me.tbText = New System.Windows.Forms.TabPage()
        Me.txtText = New System.Windows.Forms.TextBox()
        Me.tbParser = New System.Windows.Forms.TabPage()
        Me.lblIP = New System.Windows.Forms.Label()
        Me.Label23 = New System.Windows.Forms.Label()
        Me.lblDomaine = New System.Windows.Forms.Label()
        Me.Label22 = New System.Windows.Forms.Label()
        Me.lblRCPT = New System.Windows.Forms.Label()
        Me.Label20 = New System.Windows.Forms.Label()
        Me.lblErrorParsing = New System.Windows.Forms.Label()
        Me.lblResentMessageId = New System.Windows.Forms.Label()
        Me.lblMessageId = New System.Windows.Forms.Label()
        Me.lblXPriority = New System.Windows.Forms.Label()
        Me.lblImportance = New System.Windows.Forms.Label()
        Me.lblInReplyTo = New System.Windows.Forms.Label()
        Me.lblTo = New System.Windows.Forms.Label()
        Me.lblSender = New System.Windows.Forms.Label()
        Me.lblResentTo = New System.Windows.Forms.Label()
        Me.lblResentSender = New System.Windows.Forms.Label()
        Me.lblResentReplyTo = New System.Windows.Forms.Label()
        Me.lblResentFrom = New System.Windows.Forms.Label()
        Me.lblResentCc = New System.Windows.Forms.Label()
        Me.lblResentBcc = New System.Windows.Forms.Label()
        Me.lblReplyTo = New System.Windows.Forms.Label()
        Me.lblCC = New System.Windows.Forms.Label()
        Me.lblBCC = New System.Windows.Forms.Label()
        Me.lblFrom = New System.Windows.Forms.Label()
        Me.lblSubject = New System.Windows.Forms.Label()
        Me.Label18 = New System.Windows.Forms.Label()
        Me.Label19 = New System.Windows.Forms.Label()
        Me.Label16 = New System.Windows.Forms.Label()
        Me.Label17 = New System.Windows.Forms.Label()
        Me.Label15 = New System.Windows.Forms.Label()
        Me.Label14 = New System.Windows.Forms.Label()
        Me.Label12 = New System.Windows.Forms.Label()
        Me.Label13 = New System.Windows.Forms.Label()
        Me.Label10 = New System.Windows.Forms.Label()
        Me.Label11 = New System.Windows.Forms.Label()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.Label21 = New System.Windows.Forms.Label()
        Me.Label24 = New System.Windows.Forms.Label()
        Me.Label25 = New System.Windows.Forms.Label()
        Me.Label26 = New System.Windows.Forms.Label()
        Me.Label27 = New System.Windows.Forms.Label()
        Me.Label28 = New System.Windows.Forms.Label()
        Me.Label29 = New System.Windows.Forms.Label()
        Me.Label30 = New System.Windows.Forms.Label()
        Me.tbAttachment = New System.Windows.Forms.TabPage()
        Me.dgvAttachment = New System.Windows.Forms.DataGridView()
        Me.FileName = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.Disposition = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.MimeType = New System.Windows.Forms.DataGridViewTextBoxColumn()
        Me.tbAbout = New System.Windows.Forms.TabPage()
        Me.Label38 = New System.Windows.Forms.Label()
        Me.Label33 = New System.Windows.Forms.Label()
        Me.Label32 = New System.Windows.Forms.Label()
        Me.Button1 = New System.Windows.Forms.Button()
        Me.Timer1 = New System.Windows.Forms.Timer(Me.components)
        Me.Label31 = New System.Windows.Forms.Label()
        Me.lblCurrentEmailId = New System.Windows.Forms.Label()
        Me.Label39 = New System.Windows.Forms.Label()
        Me.txtFiltre = New System.Windows.Forms.TextBox()
        Me.btnSet = New System.Windows.Forms.Button()
        Me.btnX = New System.Windows.Forms.Button()
        Me.MenuStrip1.SuspendLayout()
        Me.TabControl1.SuspendLayout()
        Me.tbStatus.SuspendLayout()
        Me.GroupBox2.SuspendLayout()
        Me.GroupBox1.SuspendLayout()
        Me.tbEvents.SuspendLayout()
        Me.tbError.SuspendLayout()
        Me.tbGridMail.SuspendLayout()
        CType(Me.dvListMail, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tbGridError.SuspendLayout()
        CType(Me.dvListError, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tbSource.SuspendLayout()
        Me.tbHTML.SuspendLayout()
        Me.tbText.SuspendLayout()
        Me.tbParser.SuspendLayout()
        Me.tbAttachment.SuspendLayout()
        CType(Me.dgvAttachment, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tbAbout.SuspendLayout()
        Me.SuspendLayout()
        '
        'txtLogEvent
        '
        Me.txtLogEvent.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtLogEvent.BackColor = System.Drawing.SystemColors.Window
        Me.txtLogEvent.Location = New System.Drawing.Point(4, 5)
        Me.txtLogEvent.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.txtLogEvent.Multiline = True
        Me.txtLogEvent.Name = "txtLogEvent"
        Me.txtLogEvent.ReadOnly = True
        Me.txtLogEvent.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.txtLogEvent.Size = New System.Drawing.Size(1124, 642)
        Me.txtLogEvent.TabIndex = 0
        '
        'MenuStrip1
        '
        Me.MenuStrip1.GripMargin = New System.Windows.Forms.Padding(2, 2, 0, 2)
        Me.MenuStrip1.ImageScalingSize = New System.Drawing.Size(24, 24)
        Me.MenuStrip1.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.AjustementToolStripMenuItem})
        Me.MenuStrip1.Location = New System.Drawing.Point(0, 0)
        Me.MenuStrip1.Name = "MenuStrip1"
        Me.MenuStrip1.Size = New System.Drawing.Size(1376, 33)
        Me.MenuStrip1.TabIndex = 15
        Me.MenuStrip1.Text = "MenuStrip1"
        '
        'AjustementToolStripMenuItem
        '
        Me.AjustementToolStripMenuItem.Name = "AjustementToolStripMenuItem"
        Me.AjustementToolStripMenuItem.Size = New System.Drawing.Size(118, 29)
        Me.AjustementToolStripMenuItem.Text = "Ajustement"
        '
        'btnDelEvents
        '
        Me.btnDelEvents.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnDelEvents.Location = New System.Drawing.Point(1018, 658)
        Me.btnDelEvents.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.btnDelEvents.Name = "btnDelEvents"
        Me.btnDelEvents.Size = New System.Drawing.Size(112, 35)
        Me.btnDelEvents.TabIndex = 17
        Me.btnDelEvents.Text = "Effacer"
        Me.btnDelEvents.UseVisualStyleBackColor = True
        '
        'TabControl1
        '
        Me.TabControl1.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.TabControl1.Controls.Add(Me.tbStatus)
        Me.TabControl1.Controls.Add(Me.tbEvents)
        Me.TabControl1.Controls.Add(Me.tbError)
        Me.TabControl1.Controls.Add(Me.tbGridMail)
        Me.TabControl1.Controls.Add(Me.tbGridError)
        Me.TabControl1.Controls.Add(Me.tbSource)
        Me.TabControl1.Controls.Add(Me.tbHTML)
        Me.TabControl1.Controls.Add(Me.tbText)
        Me.TabControl1.Controls.Add(Me.tbParser)
        Me.TabControl1.Controls.Add(Me.tbAttachment)
        Me.TabControl1.Controls.Add(Me.tbAbout)
        Me.TabControl1.Location = New System.Drawing.Point(18, 58)
        Me.TabControl1.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.TabControl1.Name = "TabControl1"
        Me.TabControl1.SelectedIndex = 0
        Me.TabControl1.Size = New System.Drawing.Size(1340, 772)
        Me.TabControl1.TabIndex = 21
        '
        'tbStatus
        '
        Me.tbStatus.Controls.Add(Me.GroupBox2)
        Me.tbStatus.Controls.Add(Me.GroupBox1)
        Me.tbStatus.Location = New System.Drawing.Point(4, 29)
        Me.tbStatus.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbStatus.Name = "tbStatus"
        Me.tbStatus.Padding = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbStatus.Size = New System.Drawing.Size(1332, 739)
        Me.tbStatus.TabIndex = 0
        Me.tbStatus.Text = "Status"
        Me.tbStatus.UseVisualStyleBackColor = True
        '
        'GroupBox2
        '
        Me.GroupBox2.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.GroupBox2.Controls.Add(Me.Label37)
        Me.GroupBox2.Controls.Add(Me.Label34)
        Me.GroupBox2.Controls.Add(Me.lblSendStep)
        Me.GroupBox2.Controls.Add(Me.lblLastSend)
        Me.GroupBox2.Controls.Add(Me.lblNbSendMail)
        Me.GroupBox2.Controls.Add(Me.lblSendFrom)
        Me.GroupBox2.Controls.Add(Me.Label35)
        Me.GroupBox2.Controls.Add(Me.lblSendTo)
        Me.GroupBox2.Controls.Add(Me.Label36)
        Me.GroupBox2.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.0!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.GroupBox2.Location = New System.Drawing.Point(9, 468)
        Me.GroupBox2.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.GroupBox2.Name = "GroupBox2"
        Me.GroupBox2.Padding = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.GroupBox2.Size = New System.Drawing.Size(1118, 231)
        Me.GroupBox2.TabIndex = 28
        Me.GroupBox2.TabStop = False
        Me.GroupBox2.Text = "Transmission de courriel"
        '
        'Label37
        '
        Me.Label37.AutoSize = True
        Me.Label37.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label37.Location = New System.Drawing.Point(9, 146)
        Me.Label37.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label37.Name = "Label37"
        Me.Label37.Size = New System.Drawing.Size(107, 20)
        Me.Label37.TabIndex = 22
        Me.Label37.Text = "Date d'envoi:"
        '
        'Label34
        '
        Me.Label34.AutoSize = True
        Me.Label34.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label34.Location = New System.Drawing.Point(9, 34)
        Me.Label34.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label34.Name = "Label34"
        Me.Label34.Size = New System.Drawing.Size(227, 20)
        Me.Label34.TabIndex = 18
        Me.Label34.Text = "Nombre de courriel transmis:"
        '
        'lblSendStep
        '
        Me.lblSendStep.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lblSendStep.Font = New System.Drawing.Font("Microsoft Sans Serif", 12.0!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblSendStep.ForeColor = System.Drawing.Color.Black
        Me.lblSendStep.Location = New System.Drawing.Point(28, 191)
        Me.lblSendStep.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSendStep.Name = "lblSendStep"
        Me.lblSendStep.Size = New System.Drawing.Size(1071, 31)
        Me.lblSendStep.TabIndex = 17
        Me.lblSendStep.Text = "..."
        Me.lblSendStep.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'lblLastSend
        '
        Me.lblLastSend.AutoSize = True
        Me.lblLastSend.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblLastSend.Location = New System.Drawing.Point(142, 146)
        Me.lblLastSend.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblLastSend.Name = "lblLastSend"
        Me.lblLastSend.Size = New System.Drawing.Size(33, 20)
        Me.lblLastSend.TabIndex = 25
        Me.lblLastSend.Text = "......"
        '
        'lblNbSendMail
        '
        Me.lblNbSendMail.AutoSize = True
        Me.lblNbSendMail.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblNbSendMail.Location = New System.Drawing.Point(242, 34)
        Me.lblNbSendMail.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblNbSendMail.Name = "lblNbSendMail"
        Me.lblNbSendMail.Size = New System.Drawing.Size(33, 20)
        Me.lblNbSendMail.TabIndex = 19
        Me.lblNbSendMail.Text = "......"
        '
        'lblSendFrom
        '
        Me.lblSendFrom.AutoSize = True
        Me.lblSendFrom.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblSendFrom.Location = New System.Drawing.Point(174, 108)
        Me.lblSendFrom.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSendFrom.Name = "lblSendFrom"
        Me.lblSendFrom.Size = New System.Drawing.Size(33, 20)
        Me.lblSendFrom.TabIndex = 24
        Me.lblSendFrom.Text = "......"
        '
        'Label35
        '
        Me.Label35.AutoSize = True
        Me.Label35.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label35.Location = New System.Drawing.Point(9, 69)
        Me.Label35.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label35.Name = "Label35"
        Me.Label35.Size = New System.Drawing.Size(144, 20)
        Me.Label35.TabIndex = 20
        Me.Label35.Text = "Courriel envoyé à:"
        '
        'lblSendTo
        '
        Me.lblSendTo.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lblSendTo.AutoEllipsis = True
        Me.lblSendTo.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblSendTo.Location = New System.Drawing.Point(177, 69)
        Me.lblSendTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSendTo.Name = "lblSendTo"
        Me.lblSendTo.Size = New System.Drawing.Size(922, 20)
        Me.lblSendTo.TabIndex = 23
        Me.lblSendTo.Text = "......"
        '
        'Label36
        '
        Me.Label36.AutoSize = True
        Me.Label36.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label36.Location = New System.Drawing.Point(9, 108)
        Me.Label36.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label36.Name = "Label36"
        Me.Label36.Size = New System.Drawing.Size(153, 20)
        Me.Label36.TabIndex = 21
        Me.Label36.Text = "Courriel envoyé de:"
        '
        'GroupBox1
        '
        Me.GroupBox1.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.GroupBox1.Controls.Add(Me.Label8)
        Me.GroupBox1.Controls.Add(Me.Label1)
        Me.GroupBox1.Controls.Add(Me.lblCounterEmailInput)
        Me.GroupBox1.Controls.Add(Me.Label2)
        Me.GroupBox1.Controls.Add(Me.lblStatusSMTPStepInput)
        Me.GroupBox1.Controls.Add(Me.Label4)
        Me.GroupBox1.Controls.Add(Me.lblMailSizeInput)
        Me.GroupBox1.Controls.Add(Me.Label5)
        Me.GroupBox1.Controls.Add(Me.lblLastRecipient)
        Me.GroupBox1.Controls.Add(Me.Label6)
        Me.GroupBox1.Controls.Add(Me.lblSMTPStep)
        Me.GroupBox1.Controls.Add(Me.lblLastDomainName)
        Me.GroupBox1.Controls.Add(Me.lblSMTPClientIP)
        Me.GroupBox1.Controls.Add(Me.Label7)
        Me.GroupBox1.Controls.Add(Me.Label9)
        Me.GroupBox1.Controls.Add(Me.lblThreadSMTPInputStarted)
        Me.GroupBox1.Controls.Add(Me.lblThreadSMTPLastReceived)
        Me.GroupBox1.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.75!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.GroupBox1.Location = New System.Drawing.Point(9, 9)
        Me.GroupBox1.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Padding = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.GroupBox1.Size = New System.Drawing.Size(1118, 435)
        Me.GroupBox1.TabIndex = 27
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "Réception"
        '
        'Label8
        '
        Me.Label8.AutoSize = True
        Me.Label8.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label8.Location = New System.Drawing.Point(9, 312)
        Me.Label8.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label8.Name = "Label8"
        Me.Label8.Size = New System.Drawing.Size(125, 20)
        Me.Label8.TabIndex = 12
        Me.Label8.Text = "Courriel reçu à:"
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label1.Location = New System.Drawing.Point(9, 35)
        Me.Label1.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(195, 20)
        Me.Label1.TabIndex = 0
        Me.Label1.Text = "Nombre de courriel reçu:"
        '
        'lblCounterEmailInput
        '
        Me.lblCounterEmailInput.AutoSize = True
        Me.lblCounterEmailInput.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblCounterEmailInput.Location = New System.Drawing.Point(200, 35)
        Me.lblCounterEmailInput.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblCounterEmailInput.Name = "lblCounterEmailInput"
        Me.lblCounterEmailInput.Size = New System.Drawing.Size(33, 20)
        Me.lblCounterEmailInput.TabIndex = 1
        Me.lblCounterEmailInput.Text = "......"
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label2.Location = New System.Drawing.Point(9, 75)
        Me.Label2.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(287, 20)
        Me.Label2.TabIndex = 2
        Me.Label2.Text = "Étape de réception du service SMTP:"
        '
        'lblStatusSMTPStepInput
        '
        Me.lblStatusSMTPStepInput.AutoSize = True
        Me.lblStatusSMTPStepInput.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblStatusSMTPStepInput.Location = New System.Drawing.Point(296, 75)
        Me.lblStatusSMTPStepInput.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblStatusSMTPStepInput.Name = "lblStatusSMTPStepInput"
        Me.lblStatusSMTPStepInput.Size = New System.Drawing.Size(33, 20)
        Me.lblStatusSMTPStepInput.TabIndex = 3
        Me.lblStatusSMTPStepInput.Text = "......"
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label4.Location = New System.Drawing.Point(9, 117)
        Me.Label4.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(206, 20)
        Me.Label4.TabIndex = 4
        Me.Label4.Text = "Grosseur du courriel reçu:"
        '
        'lblMailSizeInput
        '
        Me.lblMailSizeInput.AutoSize = True
        Me.lblMailSizeInput.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblMailSizeInput.Location = New System.Drawing.Point(210, 117)
        Me.lblMailSizeInput.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblMailSizeInput.Name = "lblMailSizeInput"
        Me.lblMailSizeInput.Size = New System.Drawing.Size(33, 20)
        Me.lblMailSizeInput.TabIndex = 5
        Me.lblMailSizeInput.Text = "......"
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label5.Location = New System.Drawing.Point(9, 165)
        Me.Label5.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(171, 20)
        Me.Label5.TabIndex = 6
        Me.Label5.Text = "Dernier récipiendaire:"
        '
        'lblLastRecipient
        '
        Me.lblLastRecipient.AutoSize = True
        Me.lblLastRecipient.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblLastRecipient.Location = New System.Drawing.Point(178, 165)
        Me.lblLastRecipient.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblLastRecipient.Name = "lblLastRecipient"
        Me.lblLastRecipient.Size = New System.Drawing.Size(33, 20)
        Me.lblLastRecipient.TabIndex = 7
        Me.lblLastRecipient.Text = "......"
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label6.Location = New System.Drawing.Point(9, 220)
        Me.Label6.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(167, 20)
        Me.Label6.TabIndex = 8
        Me.Label6.Text = "Dernier domain reçu:"
        '
        'lblSMTPStep
        '
        Me.lblSMTPStep.Anchor = CType(((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lblSMTPStep.Font = New System.Drawing.Font("Microsoft Sans Serif", 12.0!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblSMTPStep.ForeColor = System.Drawing.Color.Black
        Me.lblSMTPStep.Location = New System.Drawing.Point(22, 400)
        Me.lblSMTPStep.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSMTPStep.Name = "lblSMTPStep"
        Me.lblSMTPStep.Size = New System.Drawing.Size(1077, 31)
        Me.lblSMTPStep.TabIndex = 16
        Me.lblSMTPStep.Text = "..."
        Me.lblSMTPStep.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'lblLastDomainName
        '
        Me.lblLastDomainName.AutoSize = True
        Me.lblLastDomainName.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblLastDomainName.Location = New System.Drawing.Point(176, 220)
        Me.lblLastDomainName.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblLastDomainName.Name = "lblLastDomainName"
        Me.lblLastDomainName.Size = New System.Drawing.Size(33, 20)
        Me.lblLastDomainName.TabIndex = 9
        Me.lblLastDomainName.Text = "......"
        '
        'lblSMTPClientIP
        '
        Me.lblSMTPClientIP.AutoSize = True
        Me.lblSMTPClientIP.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblSMTPClientIP.Location = New System.Drawing.Point(152, 355)
        Me.lblSMTPClientIP.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSMTPClientIP.Name = "lblSMTPClientIP"
        Me.lblSMTPClientIP.Size = New System.Drawing.Size(33, 20)
        Me.lblSMTPClientIP.TabIndex = 15
        Me.lblSMTPClientIP.Text = "......"
        '
        'Label7
        '
        Me.Label7.AutoSize = True
        Me.Label7.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label7.Location = New System.Drawing.Point(9, 268)
        Me.Label7.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label7.Name = "Label7"
        Me.Label7.Size = New System.Drawing.Size(191, 20)
        Me.Label7.TabIndex = 10
        Me.Label7.Text = "Service démarré depuis:"
        '
        'Label9
        '
        Me.Label9.AutoSize = True
        Me.Label9.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label9.Location = New System.Drawing.Point(9, 355)
        Me.Label9.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label9.Name = "Label9"
        Me.Label9.Size = New System.Drawing.Size(141, 20)
        Me.Label9.TabIndex = 14
        Me.Label9.Text = "Adresse IP client:"
        '
        'lblThreadSMTPInputStarted
        '
        Me.lblThreadSMTPInputStarted.AutoSize = True
        Me.lblThreadSMTPInputStarted.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblThreadSMTPInputStarted.Location = New System.Drawing.Point(200, 268)
        Me.lblThreadSMTPInputStarted.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblThreadSMTPInputStarted.Name = "lblThreadSMTPInputStarted"
        Me.lblThreadSMTPInputStarted.Size = New System.Drawing.Size(33, 20)
        Me.lblThreadSMTPInputStarted.TabIndex = 11
        Me.lblThreadSMTPInputStarted.Text = "......"
        '
        'lblThreadSMTPLastReceived
        '
        Me.lblThreadSMTPLastReceived.AutoSize = True
        Me.lblThreadSMTPLastReceived.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblThreadSMTPLastReceived.Location = New System.Drawing.Point(135, 312)
        Me.lblThreadSMTPLastReceived.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblThreadSMTPLastReceived.Name = "lblThreadSMTPLastReceived"
        Me.lblThreadSMTPLastReceived.Size = New System.Drawing.Size(33, 20)
        Me.lblThreadSMTPLastReceived.TabIndex = 13
        Me.lblThreadSMTPLastReceived.Text = "......"
        '
        'tbEvents
        '
        Me.tbEvents.Controls.Add(Me.txtLogEvent)
        Me.tbEvents.Controls.Add(Me.btnDelEvents)
        Me.tbEvents.Location = New System.Drawing.Point(4, 29)
        Me.tbEvents.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbEvents.Name = "tbEvents"
        Me.tbEvents.Padding = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbEvents.Size = New System.Drawing.Size(1332, 739)
        Me.tbEvents.TabIndex = 1
        Me.tbEvents.Text = "Évenements"
        Me.tbEvents.UseVisualStyleBackColor = True
        '
        'tbError
        '
        Me.tbError.Controls.Add(Me.btnDelError)
        Me.tbError.Controls.Add(Me.txtlogError)
        Me.tbError.Location = New System.Drawing.Point(4, 29)
        Me.tbError.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbError.Name = "tbError"
        Me.tbError.Size = New System.Drawing.Size(1332, 739)
        Me.tbError.TabIndex = 2
        Me.tbError.Text = "Erreur"
        Me.tbError.UseVisualStyleBackColor = True
        '
        'btnDelError
        '
        Me.btnDelError.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.btnDelError.Location = New System.Drawing.Point(1018, 658)
        Me.btnDelError.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.btnDelError.Name = "btnDelError"
        Me.btnDelError.Size = New System.Drawing.Size(112, 35)
        Me.btnDelError.TabIndex = 2
        Me.btnDelError.Text = "Effacer"
        Me.btnDelError.UseVisualStyleBackColor = True
        '
        'txtlogError
        '
        Me.txtlogError.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtlogError.BackColor = System.Drawing.SystemColors.Window
        Me.txtlogError.Location = New System.Drawing.Point(4, 5)
        Me.txtlogError.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.txtlogError.Multiline = True
        Me.txtlogError.Name = "txtlogError"
        Me.txtlogError.ReadOnly = True
        Me.txtlogError.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.txtlogError.Size = New System.Drawing.Size(1124, 642)
        Me.txtlogError.TabIndex = 1
        '
        'tbGridMail
        '
        Me.tbGridMail.Controls.Add(Me.btnX)
        Me.tbGridMail.Controls.Add(Me.btnSet)
        Me.tbGridMail.Controls.Add(Me.txtFiltre)
        Me.tbGridMail.Controls.Add(Me.Label39)
        Me.tbGridMail.Controls.Add(Me.btnResend)
        Me.tbGridMail.Controls.Add(Me.btnRefresh)
        Me.tbGridMail.Controls.Add(Me.dvListMail)
        Me.tbGridMail.Location = New System.Drawing.Point(4, 29)
        Me.tbGridMail.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbGridMail.Name = "tbGridMail"
        Me.tbGridMail.Size = New System.Drawing.Size(1332, 739)
        Me.tbGridMail.TabIndex = 3
        Me.tbGridMail.Text = "Courriels"
        Me.tbGridMail.UseVisualStyleBackColor = True
        '
        'btnResend
        '
        Me.btnResend.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
        Me.btnResend.Location = New System.Drawing.Point(132, 692)
        Me.btnResend.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.btnResend.Name = "btnResend"
        Me.btnResend.Size = New System.Drawing.Size(112, 35)
        Me.btnResend.TabIndex = 5
        Me.btnResend.Text = "Re-send"
        Me.btnResend.UseVisualStyleBackColor = True
        '
        'btnRefresh
        '
        Me.btnRefresh.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
        Me.btnRefresh.Location = New System.Drawing.Point(4, 692)
        Me.btnRefresh.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.btnRefresh.Name = "btnRefresh"
        Me.btnRefresh.Size = New System.Drawing.Size(112, 35)
        Me.btnRefresh.TabIndex = 4
        Me.btnRefresh.Text = "Refresh"
        Me.btnRefresh.UseVisualStyleBackColor = True
        '
        'dvListMail
        '
        Me.dvListMail.AllowUserToAddRows = False
        Me.dvListMail.AllowUserToDeleteRows = False
        Me.dvListMail.AllowUserToResizeRows = False
        Me.dvListMail.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.dvListMail.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvListMail.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.Id, Me.RCPT, Me.sTo, Me.Retry, Me.SendAt, Me.Received, Me.Sended, Me.tosend, Me.SendWithSuccess})
        Me.dvListMail.Location = New System.Drawing.Point(4, 49)
        Me.dvListMail.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.dvListMail.MultiSelect = False
        Me.dvListMail.Name = "dvListMail"
        Me.dvListMail.ReadOnly = True
        Me.dvListMail.RowHeadersWidth = 62
        Me.dvListMail.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvListMail.ShowEditingIcon = False
        Me.dvListMail.Size = New System.Drawing.Size(1318, 634)
        Me.dvListMail.TabIndex = 1
        '
        'Id
        '
        Me.Id.DataPropertyName = "Id"
        Me.Id.HeaderText = "Id"
        Me.Id.MinimumWidth = 8
        Me.Id.Name = "Id"
        Me.Id.ReadOnly = True
        Me.Id.Width = 60
        '
        'RCPT
        '
        Me.RCPT.DataPropertyName = "RCPT"
        Me.RCPT.HeaderText = "RCPT"
        Me.RCPT.MinimumWidth = 8
        Me.RCPT.Name = "RCPT"
        Me.RCPT.ReadOnly = True
        Me.RCPT.Width = 175
        '
        'sTo
        '
        Me.sTo.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill
        Me.sTo.DataPropertyName = "To"
        Me.sTo.HeaderText = "To"
        Me.sTo.MinimumWidth = 8
        Me.sTo.Name = "sTo"
        Me.sTo.ReadOnly = True
        '
        'Retry
        '
        Me.Retry.DataPropertyName = "Retry"
        Me.Retry.HeaderText = "Retry"
        Me.Retry.MinimumWidth = 8
        Me.Retry.Name = "Retry"
        Me.Retry.ReadOnly = True
        Me.Retry.Width = 50
        '
        'SendAt
        '
        Me.SendAt.DataPropertyName = "SendAt"
        Me.SendAt.HeaderText = "Send At"
        Me.SendAt.MinimumWidth = 8
        Me.SendAt.Name = "SendAt"
        Me.SendAt.ReadOnly = True
        Me.SendAt.Width = 110
        '
        'Received
        '
        Me.Received.DataPropertyName = "Received"
        DataGridViewCellStyle1.NullValue = " "
        Me.Received.DefaultCellStyle = DataGridViewCellStyle1
        Me.Received.HeaderText = "Received"
        Me.Received.MinimumWidth = 8
        Me.Received.Name = "Received"
        Me.Received.ReadOnly = True
        Me.Received.Width = 110
        '
        'Sended
        '
        Me.Sended.DataPropertyName = "Sended"
        DataGridViewCellStyle2.NullValue = " "
        Me.Sended.DefaultCellStyle = DataGridViewCellStyle2
        Me.Sended.HeaderText = "Sended"
        Me.Sended.MinimumWidth = 8
        Me.Sended.Name = "Sended"
        Me.Sended.ReadOnly = True
        Me.Sended.Width = 110
        '
        'tosend
        '
        Me.tosend.DataPropertyName = "tosend"
        Me.tosend.HeaderText = "ToSend"
        Me.tosend.MinimumWidth = 8
        Me.tosend.Name = "tosend"
        Me.tosend.ReadOnly = True
        Me.tosend.Visible = False
        Me.tosend.Width = 8
        '
        'SendWithSuccess
        '
        Me.SendWithSuccess.DataPropertyName = "SendWithSuccess"
        Me.SendWithSuccess.HeaderText = "SendWithSuccess"
        Me.SendWithSuccess.MinimumWidth = 8
        Me.SendWithSuccess.Name = "SendWithSuccess"
        Me.SendWithSuccess.ReadOnly = True
        Me.SendWithSuccess.Visible = False
        Me.SendWithSuccess.Width = 150
        '
        'tbGridError
        '
        Me.tbGridError.Controls.Add(Me.lblMessageError)
        Me.tbGridError.Controls.Add(Me.dvListError)
        Me.tbGridError.Location = New System.Drawing.Point(4, 29)
        Me.tbGridError.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbGridError.Name = "tbGridError"
        Me.tbGridError.Size = New System.Drawing.Size(1332, 739)
        Me.tbGridError.TabIndex = 10
        Me.tbGridError.Text = "Mail Server Error"
        Me.tbGridError.UseVisualStyleBackColor = True
        '
        'lblMessageError
        '
        Me.lblMessageError.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.lblMessageError.BackColor = System.Drawing.Color.WhiteSmoke
        Me.lblMessageError.Location = New System.Drawing.Point(21, 635)
        Me.lblMessageError.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblMessageError.Name = "lblMessageError"
        Me.lblMessageError.Size = New System.Drawing.Size(1164, 74)
        Me.lblMessageError.TabIndex = 3
        '
        'dvListError
        '
        Me.dvListError.AllowUserToAddRows = False
        Me.dvListError.AllowUserToDeleteRows = False
        Me.dvListError.AllowUserToResizeRows = False
        Me.dvListError.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.dvListError.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dvListError.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.DataGridViewTextBoxColumn1, Me.DataGridViewTextBoxColumn4, Me.DataGridViewTextBoxColumn3, Me.DataGridViewTextBoxColumn5, Me.dCreated})
        Me.dvListError.Location = New System.Drawing.Point(4, 28)
        Me.dvListError.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.dvListError.MultiSelect = False
        Me.dvListError.Name = "dvListError"
        Me.dvListError.ReadOnly = True
        Me.dvListError.RowHeadersWidth = 62
        Me.dvListError.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dvListError.ShowEditingIcon = False
        Me.dvListError.Size = New System.Drawing.Size(1203, 586)
        Me.dvListError.TabIndex = 2
        '
        'DataGridViewTextBoxColumn1
        '
        Me.DataGridViewTextBoxColumn1.DataPropertyName = "Id"
        Me.DataGridViewTextBoxColumn1.HeaderText = "Id"
        Me.DataGridViewTextBoxColumn1.MinimumWidth = 8
        Me.DataGridViewTextBoxColumn1.Name = "DataGridViewTextBoxColumn1"
        Me.DataGridViewTextBoxColumn1.ReadOnly = True
        Me.DataGridViewTextBoxColumn1.Width = 60
        '
        'DataGridViewTextBoxColumn4
        '
        Me.DataGridViewTextBoxColumn4.DataPropertyName = "MailId"
        Me.DataGridViewTextBoxColumn4.HeaderText = "MailId"
        Me.DataGridViewTextBoxColumn4.MinimumWidth = 8
        Me.DataGridViewTextBoxColumn4.Name = "DataGridViewTextBoxColumn4"
        Me.DataGridViewTextBoxColumn4.ReadOnly = True
        Me.DataGridViewTextBoxColumn4.Width = 150
        '
        'DataGridViewTextBoxColumn3
        '
        Me.DataGridViewTextBoxColumn3.DataPropertyName = "To"
        Me.DataGridViewTextBoxColumn3.HeaderText = "To"
        Me.DataGridViewTextBoxColumn3.MinimumWidth = 8
        Me.DataGridViewTextBoxColumn3.Name = "DataGridViewTextBoxColumn3"
        Me.DataGridViewTextBoxColumn3.ReadOnly = True
        Me.DataGridViewTextBoxColumn3.Width = 200
        '
        'DataGridViewTextBoxColumn5
        '
        Me.DataGridViewTextBoxColumn5.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill
        Me.DataGridViewTextBoxColumn5.DataPropertyName = "ErrorMessage"
        DataGridViewCellStyle3.NullValue = " "
        Me.DataGridViewTextBoxColumn5.DefaultCellStyle = DataGridViewCellStyle3
        Me.DataGridViewTextBoxColumn5.HeaderText = "Error Message"
        Me.DataGridViewTextBoxColumn5.MinimumWidth = 8
        Me.DataGridViewTextBoxColumn5.Name = "DataGridViewTextBoxColumn5"
        Me.DataGridViewTextBoxColumn5.ReadOnly = True
        '
        'dCreated
        '
        Me.dCreated.DataPropertyName = "dCreated"
        Me.dCreated.HeaderText = "Created"
        Me.dCreated.MinimumWidth = 8
        Me.dCreated.Name = "dCreated"
        Me.dCreated.ReadOnly = True
        Me.dCreated.Width = 150
        '
        'tbSource
        '
        Me.tbSource.Controls.Add(Me.txtMail)
        Me.tbSource.Location = New System.Drawing.Point(4, 29)
        Me.tbSource.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbSource.Name = "tbSource"
        Me.tbSource.Size = New System.Drawing.Size(1332, 739)
        Me.tbSource.TabIndex = 4
        Me.tbSource.Text = "Source"
        Me.tbSource.UseVisualStyleBackColor = True
        '
        'txtMail
        '
        Me.txtMail.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtMail.Location = New System.Drawing.Point(4, 5)
        Me.txtMail.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.txtMail.Multiline = True
        Me.txtMail.Name = "txtMail"
        Me.txtMail.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtMail.Size = New System.Drawing.Size(1118, 687)
        Me.txtMail.TabIndex = 2
        Me.txtMail.WordWrap = False
        '
        'tbHTML
        '
        Me.tbHTML.Controls.Add(Me.txtHTML)
        Me.tbHTML.Location = New System.Drawing.Point(4, 29)
        Me.tbHTML.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbHTML.Name = "tbHTML"
        Me.tbHTML.Size = New System.Drawing.Size(1332, 739)
        Me.tbHTML.TabIndex = 5
        Me.tbHTML.Text = "HTML"
        Me.tbHTML.UseVisualStyleBackColor = True
        '
        'txtHTML
        '
        Me.txtHTML.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtHTML.Location = New System.Drawing.Point(4, 5)
        Me.txtHTML.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.txtHTML.Multiline = True
        Me.txtHTML.Name = "txtHTML"
        Me.txtHTML.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtHTML.Size = New System.Drawing.Size(1124, 687)
        Me.txtHTML.TabIndex = 3
        Me.txtHTML.WordWrap = False
        '
        'tbText
        '
        Me.tbText.Controls.Add(Me.txtText)
        Me.tbText.Location = New System.Drawing.Point(4, 29)
        Me.tbText.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbText.Name = "tbText"
        Me.tbText.Size = New System.Drawing.Size(1332, 739)
        Me.tbText.TabIndex = 6
        Me.tbText.Text = "Texte"
        Me.tbText.UseVisualStyleBackColor = True
        '
        'txtText
        '
        Me.txtText.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.txtText.Location = New System.Drawing.Point(0, 5)
        Me.txtText.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.txtText.Multiline = True
        Me.txtText.Name = "txtText"
        Me.txtText.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txtText.Size = New System.Drawing.Size(1129, 687)
        Me.txtText.TabIndex = 3
        Me.txtText.WordWrap = False
        '
        'tbParser
        '
        Me.tbParser.Controls.Add(Me.lblIP)
        Me.tbParser.Controls.Add(Me.Label23)
        Me.tbParser.Controls.Add(Me.lblDomaine)
        Me.tbParser.Controls.Add(Me.Label22)
        Me.tbParser.Controls.Add(Me.lblRCPT)
        Me.tbParser.Controls.Add(Me.Label20)
        Me.tbParser.Controls.Add(Me.lblErrorParsing)
        Me.tbParser.Controls.Add(Me.lblResentMessageId)
        Me.tbParser.Controls.Add(Me.lblMessageId)
        Me.tbParser.Controls.Add(Me.lblXPriority)
        Me.tbParser.Controls.Add(Me.lblImportance)
        Me.tbParser.Controls.Add(Me.lblInReplyTo)
        Me.tbParser.Controls.Add(Me.lblTo)
        Me.tbParser.Controls.Add(Me.lblSender)
        Me.tbParser.Controls.Add(Me.lblResentTo)
        Me.tbParser.Controls.Add(Me.lblResentSender)
        Me.tbParser.Controls.Add(Me.lblResentReplyTo)
        Me.tbParser.Controls.Add(Me.lblResentFrom)
        Me.tbParser.Controls.Add(Me.lblResentCc)
        Me.tbParser.Controls.Add(Me.lblResentBcc)
        Me.tbParser.Controls.Add(Me.lblReplyTo)
        Me.tbParser.Controls.Add(Me.lblCC)
        Me.tbParser.Controls.Add(Me.lblBCC)
        Me.tbParser.Controls.Add(Me.lblFrom)
        Me.tbParser.Controls.Add(Me.lblSubject)
        Me.tbParser.Controls.Add(Me.Label18)
        Me.tbParser.Controls.Add(Me.Label19)
        Me.tbParser.Controls.Add(Me.Label16)
        Me.tbParser.Controls.Add(Me.Label17)
        Me.tbParser.Controls.Add(Me.Label15)
        Me.tbParser.Controls.Add(Me.Label14)
        Me.tbParser.Controls.Add(Me.Label12)
        Me.tbParser.Controls.Add(Me.Label13)
        Me.tbParser.Controls.Add(Me.Label10)
        Me.tbParser.Controls.Add(Me.Label11)
        Me.tbParser.Controls.Add(Me.Label3)
        Me.tbParser.Controls.Add(Me.Label21)
        Me.tbParser.Controls.Add(Me.Label24)
        Me.tbParser.Controls.Add(Me.Label25)
        Me.tbParser.Controls.Add(Me.Label26)
        Me.tbParser.Controls.Add(Me.Label27)
        Me.tbParser.Controls.Add(Me.Label28)
        Me.tbParser.Controls.Add(Me.Label29)
        Me.tbParser.Controls.Add(Me.Label30)
        Me.tbParser.Location = New System.Drawing.Point(4, 29)
        Me.tbParser.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbParser.Name = "tbParser"
        Me.tbParser.Size = New System.Drawing.Size(1332, 739)
        Me.tbParser.TabIndex = 7
        Me.tbParser.Text = "Détail"
        Me.tbParser.UseVisualStyleBackColor = True
        '
        'lblIP
        '
        Me.lblIP.AutoSize = True
        Me.lblIP.Location = New System.Drawing.Point(190, 51)
        Me.lblIP.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblIP.Name = "lblIP"
        Me.lblIP.Size = New System.Drawing.Size(24, 20)
        Me.lblIP.TabIndex = 87
        Me.lblIP.Text = "IP"
        '
        'Label23
        '
        Me.Label23.AutoSize = True
        Me.Label23.Location = New System.Drawing.Point(27, 51)
        Me.Label23.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label23.Name = "Label23"
        Me.Label23.Size = New System.Drawing.Size(68, 20)
        Me.Label23.TabIndex = 86
        Me.Label23.Text = "Client IP"
        '
        'lblDomaine
        '
        Me.lblDomaine.AutoSize = True
        Me.lblDomaine.Location = New System.Drawing.Point(190, 31)
        Me.lblDomaine.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblDomaine.Name = "lblDomaine"
        Me.lblDomaine.Size = New System.Drawing.Size(73, 20)
        Me.lblDomaine.TabIndex = 85
        Me.lblDomaine.Text = "Domaine"
        '
        'Label22
        '
        Me.Label22.AutoSize = True
        Me.Label22.Location = New System.Drawing.Point(27, 31)
        Me.Label22.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label22.Name = "Label22"
        Me.Label22.Size = New System.Drawing.Size(73, 20)
        Me.Label22.TabIndex = 84
        Me.Label22.Text = "Domaine"
        '
        'lblRCPT
        '
        Me.lblRCPT.AutoSize = True
        Me.lblRCPT.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblRCPT.Location = New System.Drawing.Point(190, 11)
        Me.lblRCPT.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblRCPT.Name = "lblRCPT"
        Me.lblRCPT.Size = New System.Drawing.Size(58, 20)
        Me.lblRCPT.TabIndex = 83
        Me.lblRCPT.Text = "RCPT"
        '
        'Label20
        '
        Me.Label20.AutoSize = True
        Me.Label20.Font = New System.Drawing.Font("Microsoft Sans Serif", 8.25!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label20.Location = New System.Drawing.Point(27, 11)
        Me.Label20.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label20.Name = "Label20"
        Me.Label20.Size = New System.Drawing.Size(58, 20)
        Me.Label20.TabIndex = 82
        Me.Label20.Text = "RCPT"
        '
        'lblErrorParsing
        '
        Me.lblErrorParsing.AutoSize = True
        Me.lblErrorParsing.Location = New System.Drawing.Point(190, 491)
        Me.lblErrorParsing.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblErrorParsing.Name = "lblErrorParsing"
        Me.lblErrorParsing.Size = New System.Drawing.Size(97, 20)
        Me.lblErrorParsing.TabIndex = 81
        Me.lblErrorParsing.Text = "ErrorParsing"
        '
        'lblResentMessageId
        '
        Me.lblResentMessageId.AutoSize = True
        Me.lblResentMessageId.Location = New System.Drawing.Point(190, 468)
        Me.lblResentMessageId.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentMessageId.Name = "lblResentMessageId"
        Me.lblResentMessageId.Size = New System.Drawing.Size(140, 20)
        Me.lblResentMessageId.TabIndex = 80
        Me.lblResentMessageId.Text = "ResentMessageId"
        '
        'lblMessageId
        '
        Me.lblMessageId.AutoSize = True
        Me.lblMessageId.Location = New System.Drawing.Point(190, 445)
        Me.lblMessageId.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblMessageId.Name = "lblMessageId"
        Me.lblMessageId.Size = New System.Drawing.Size(88, 20)
        Me.lblMessageId.TabIndex = 79
        Me.lblMessageId.Text = "MessageId"
        '
        'lblXPriority
        '
        Me.lblXPriority.AutoSize = True
        Me.lblXPriority.Location = New System.Drawing.Point(190, 422)
        Me.lblXPriority.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblXPriority.Name = "lblXPriority"
        Me.lblXPriority.Size = New System.Drawing.Size(67, 20)
        Me.lblXPriority.TabIndex = 78
        Me.lblXPriority.Text = "XPriority"
        '
        'lblImportance
        '
        Me.lblImportance.AutoSize = True
        Me.lblImportance.Location = New System.Drawing.Point(190, 398)
        Me.lblImportance.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblImportance.Name = "lblImportance"
        Me.lblImportance.Size = New System.Drawing.Size(90, 20)
        Me.lblImportance.TabIndex = 77
        Me.lblImportance.Text = "Importance"
        '
        'lblInReplyTo
        '
        Me.lblInReplyTo.AutoSize = True
        Me.lblInReplyTo.Location = New System.Drawing.Point(190, 375)
        Me.lblInReplyTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblInReplyTo.Name = "lblInReplyTo"
        Me.lblInReplyTo.Size = New System.Drawing.Size(81, 20)
        Me.lblInReplyTo.TabIndex = 76
        Me.lblInReplyTo.Text = "InReplyTo"
        '
        'lblTo
        '
        Me.lblTo.AutoSize = True
        Me.lblTo.Location = New System.Drawing.Point(190, 352)
        Me.lblTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblTo.Name = "lblTo"
        Me.lblTo.Size = New System.Drawing.Size(27, 20)
        Me.lblTo.TabIndex = 75
        Me.lblTo.Text = "To"
        '
        'lblSender
        '
        Me.lblSender.AutoSize = True
        Me.lblSender.Location = New System.Drawing.Point(190, 329)
        Me.lblSender.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSender.Name = "lblSender"
        Me.lblSender.Size = New System.Drawing.Size(61, 20)
        Me.lblSender.TabIndex = 74
        Me.lblSender.Text = "Sender"
        '
        'lblResentTo
        '
        Me.lblResentTo.AutoSize = True
        Me.lblResentTo.Location = New System.Drawing.Point(190, 306)
        Me.lblResentTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentTo.Name = "lblResentTo"
        Me.lblResentTo.Size = New System.Drawing.Size(79, 20)
        Me.lblResentTo.TabIndex = 73
        Me.lblResentTo.Text = "ResentTo"
        '
        'lblResentSender
        '
        Me.lblResentSender.AutoSize = True
        Me.lblResentSender.Location = New System.Drawing.Point(190, 283)
        Me.lblResentSender.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentSender.Name = "lblResentSender"
        Me.lblResentSender.Size = New System.Drawing.Size(113, 20)
        Me.lblResentSender.TabIndex = 72
        Me.lblResentSender.Text = "ResentSender"
        '
        'lblResentReplyTo
        '
        Me.lblResentReplyTo.AutoSize = True
        Me.lblResentReplyTo.Location = New System.Drawing.Point(190, 260)
        Me.lblResentReplyTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentReplyTo.Name = "lblResentReplyTo"
        Me.lblResentReplyTo.Size = New System.Drawing.Size(119, 20)
        Me.lblResentReplyTo.TabIndex = 71
        Me.lblResentReplyTo.Text = "ResentReplyTo"
        '
        'lblResentFrom
        '
        Me.lblResentFrom.AutoSize = True
        Me.lblResentFrom.Location = New System.Drawing.Point(190, 237)
        Me.lblResentFrom.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentFrom.Name = "lblResentFrom"
        Me.lblResentFrom.Size = New System.Drawing.Size(98, 20)
        Me.lblResentFrom.TabIndex = 70
        Me.lblResentFrom.Text = "ResentFrom"
        '
        'lblResentCc
        '
        Me.lblResentCc.AutoSize = True
        Me.lblResentCc.Location = New System.Drawing.Point(190, 214)
        Me.lblResentCc.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentCc.Name = "lblResentCc"
        Me.lblResentCc.Size = New System.Drawing.Size(80, 20)
        Me.lblResentCc.TabIndex = 69
        Me.lblResentCc.Text = "ResentCc"
        '
        'lblResentBcc
        '
        Me.lblResentBcc.AutoSize = True
        Me.lblResentBcc.Location = New System.Drawing.Point(190, 191)
        Me.lblResentBcc.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblResentBcc.Name = "lblResentBcc"
        Me.lblResentBcc.Size = New System.Drawing.Size(88, 20)
        Me.lblResentBcc.TabIndex = 68
        Me.lblResentBcc.Text = "ResentBcc"
        '
        'lblReplyTo
        '
        Me.lblReplyTo.AutoSize = True
        Me.lblReplyTo.Location = New System.Drawing.Point(190, 168)
        Me.lblReplyTo.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblReplyTo.Name = "lblReplyTo"
        Me.lblReplyTo.Size = New System.Drawing.Size(67, 20)
        Me.lblReplyTo.TabIndex = 67
        Me.lblReplyTo.Text = "ReplyTo"
        '
        'lblCC
        '
        Me.lblCC.AutoSize = True
        Me.lblCC.Location = New System.Drawing.Point(190, 145)
        Me.lblCC.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblCC.Name = "lblCC"
        Me.lblCC.Size = New System.Drawing.Size(31, 20)
        Me.lblCC.TabIndex = 66
        Me.lblCC.Text = "CC"
        '
        'lblBCC
        '
        Me.lblBCC.AutoSize = True
        Me.lblBCC.Location = New System.Drawing.Point(190, 122)
        Me.lblBCC.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblBCC.Name = "lblBCC"
        Me.lblBCC.Size = New System.Drawing.Size(42, 20)
        Me.lblBCC.TabIndex = 65
        Me.lblBCC.Text = "BCC"
        '
        'lblFrom
        '
        Me.lblFrom.AutoSize = True
        Me.lblFrom.Location = New System.Drawing.Point(190, 98)
        Me.lblFrom.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblFrom.Name = "lblFrom"
        Me.lblFrom.Size = New System.Drawing.Size(46, 20)
        Me.lblFrom.TabIndex = 64
        Me.lblFrom.Text = "From"
        '
        'lblSubject
        '
        Me.lblSubject.AutoSize = True
        Me.lblSubject.Location = New System.Drawing.Point(190, 75)
        Me.lblSubject.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblSubject.Name = "lblSubject"
        Me.lblSubject.Size = New System.Drawing.Size(67, 20)
        Me.lblSubject.TabIndex = 63
        Me.lblSubject.Text = "Subject "
        '
        'Label18
        '
        Me.Label18.AutoSize = True
        Me.Label18.Location = New System.Drawing.Point(26, 491)
        Me.Label18.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label18.Name = "Label18"
        Me.Label18.Size = New System.Drawing.Size(97, 20)
        Me.Label18.TabIndex = 62
        Me.Label18.Text = "ErrorParsing"
        '
        'Label19
        '
        Me.Label19.AutoSize = True
        Me.Label19.Location = New System.Drawing.Point(26, 468)
        Me.Label19.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label19.Name = "Label19"
        Me.Label19.Size = New System.Drawing.Size(140, 20)
        Me.Label19.TabIndex = 61
        Me.Label19.Text = "ResentMessageId"
        '
        'Label16
        '
        Me.Label16.AutoSize = True
        Me.Label16.Location = New System.Drawing.Point(26, 445)
        Me.Label16.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label16.Name = "Label16"
        Me.Label16.Size = New System.Drawing.Size(88, 20)
        Me.Label16.TabIndex = 60
        Me.Label16.Text = "MessageId"
        '
        'Label17
        '
        Me.Label17.AutoSize = True
        Me.Label17.Location = New System.Drawing.Point(26, 422)
        Me.Label17.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label17.Name = "Label17"
        Me.Label17.Size = New System.Drawing.Size(67, 20)
        Me.Label17.TabIndex = 59
        Me.Label17.Text = "XPriority"
        '
        'Label15
        '
        Me.Label15.AutoSize = True
        Me.Label15.Location = New System.Drawing.Point(26, 398)
        Me.Label15.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label15.Name = "Label15"
        Me.Label15.Size = New System.Drawing.Size(90, 20)
        Me.Label15.TabIndex = 58
        Me.Label15.Text = "Importance"
        '
        'Label14
        '
        Me.Label14.AutoSize = True
        Me.Label14.Location = New System.Drawing.Point(26, 375)
        Me.Label14.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label14.Name = "Label14"
        Me.Label14.Size = New System.Drawing.Size(81, 20)
        Me.Label14.TabIndex = 57
        Me.Label14.Text = "InReplyTo"
        '
        'Label12
        '
        Me.Label12.AutoSize = True
        Me.Label12.Location = New System.Drawing.Point(26, 352)
        Me.Label12.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label12.Name = "Label12"
        Me.Label12.Size = New System.Drawing.Size(27, 20)
        Me.Label12.TabIndex = 56
        Me.Label12.Text = "To"
        '
        'Label13
        '
        Me.Label13.AutoSize = True
        Me.Label13.Location = New System.Drawing.Point(26, 329)
        Me.Label13.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label13.Name = "Label13"
        Me.Label13.Size = New System.Drawing.Size(61, 20)
        Me.Label13.TabIndex = 55
        Me.Label13.Text = "Sender"
        '
        'Label10
        '
        Me.Label10.AutoSize = True
        Me.Label10.Location = New System.Drawing.Point(26, 306)
        Me.Label10.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label10.Name = "Label10"
        Me.Label10.Size = New System.Drawing.Size(79, 20)
        Me.Label10.TabIndex = 54
        Me.Label10.Text = "ResentTo"
        '
        'Label11
        '
        Me.Label11.AutoSize = True
        Me.Label11.Location = New System.Drawing.Point(26, 283)
        Me.Label11.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label11.Name = "Label11"
        Me.Label11.Size = New System.Drawing.Size(113, 20)
        Me.Label11.TabIndex = 53
        Me.Label11.Text = "ResentSender"
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(26, 260)
        Me.Label3.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(119, 20)
        Me.Label3.TabIndex = 52
        Me.Label3.Text = "ResentReplyTo"
        '
        'Label21
        '
        Me.Label21.AutoSize = True
        Me.Label21.Location = New System.Drawing.Point(26, 237)
        Me.Label21.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label21.Name = "Label21"
        Me.Label21.Size = New System.Drawing.Size(98, 20)
        Me.Label21.TabIndex = 51
        Me.Label21.Text = "ResentFrom"
        '
        'Label24
        '
        Me.Label24.AutoSize = True
        Me.Label24.Location = New System.Drawing.Point(26, 214)
        Me.Label24.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label24.Name = "Label24"
        Me.Label24.Size = New System.Drawing.Size(80, 20)
        Me.Label24.TabIndex = 50
        Me.Label24.Text = "ResentCc"
        '
        'Label25
        '
        Me.Label25.AutoSize = True
        Me.Label25.Location = New System.Drawing.Point(26, 191)
        Me.Label25.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label25.Name = "Label25"
        Me.Label25.Size = New System.Drawing.Size(88, 20)
        Me.Label25.TabIndex = 49
        Me.Label25.Text = "ResentBcc"
        '
        'Label26
        '
        Me.Label26.AutoSize = True
        Me.Label26.Location = New System.Drawing.Point(26, 168)
        Me.Label26.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label26.Name = "Label26"
        Me.Label26.Size = New System.Drawing.Size(67, 20)
        Me.Label26.TabIndex = 48
        Me.Label26.Text = "ReplyTo"
        '
        'Label27
        '
        Me.Label27.AutoSize = True
        Me.Label27.Location = New System.Drawing.Point(26, 145)
        Me.Label27.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label27.Name = "Label27"
        Me.Label27.Size = New System.Drawing.Size(31, 20)
        Me.Label27.TabIndex = 47
        Me.Label27.Text = "CC"
        '
        'Label28
        '
        Me.Label28.AutoSize = True
        Me.Label28.Location = New System.Drawing.Point(26, 122)
        Me.Label28.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label28.Name = "Label28"
        Me.Label28.Size = New System.Drawing.Size(42, 20)
        Me.Label28.TabIndex = 46
        Me.Label28.Text = "BCC"
        '
        'Label29
        '
        Me.Label29.AutoSize = True
        Me.Label29.Location = New System.Drawing.Point(26, 98)
        Me.Label29.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label29.Name = "Label29"
        Me.Label29.Size = New System.Drawing.Size(46, 20)
        Me.Label29.TabIndex = 45
        Me.Label29.Text = "From"
        '
        'Label30
        '
        Me.Label30.AutoSize = True
        Me.Label30.Location = New System.Drawing.Point(26, 75)
        Me.Label30.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label30.Name = "Label30"
        Me.Label30.Size = New System.Drawing.Size(67, 20)
        Me.Label30.TabIndex = 44
        Me.Label30.Text = "Subject "
        '
        'tbAttachment
        '
        Me.tbAttachment.Controls.Add(Me.dgvAttachment)
        Me.tbAttachment.Location = New System.Drawing.Point(4, 29)
        Me.tbAttachment.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbAttachment.Name = "tbAttachment"
        Me.tbAttachment.Size = New System.Drawing.Size(1332, 739)
        Me.tbAttachment.TabIndex = 8
        Me.tbAttachment.Text = "Attachements"
        Me.tbAttachment.UseVisualStyleBackColor = True
        '
        'dgvAttachment
        '
        Me.dgvAttachment.AllowUserToAddRows = False
        Me.dgvAttachment.AllowUserToDeleteRows = False
        Me.dgvAttachment.AllowUserToResizeRows = False
        Me.dgvAttachment.Anchor = CType((((System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom) _
            Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.dgvAttachment.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.dgvAttachment.Columns.AddRange(New System.Windows.Forms.DataGridViewColumn() {Me.FileName, Me.Disposition, Me.MimeType})
        Me.dgvAttachment.Location = New System.Drawing.Point(0, 5)
        Me.dgvAttachment.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.dgvAttachment.Name = "dgvAttachment"
        Me.dgvAttachment.RowHeadersWidth = 62
        Me.dgvAttachment.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dgvAttachment.ShowEditingIcon = False
        Me.dgvAttachment.Size = New System.Drawing.Size(1131, 689)
        Me.dgvAttachment.TabIndex = 1
        '
        'FileName
        '
        Me.FileName.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill
        Me.FileName.DataPropertyName = "FileName"
        Me.FileName.HeaderText = "File Name"
        Me.FileName.MinimumWidth = 8
        Me.FileName.Name = "FileName"
        Me.FileName.ReadOnly = True
        '
        'Disposition
        '
        Me.Disposition.DataPropertyName = "Disposition"
        Me.Disposition.HeaderText = "Disposition"
        Me.Disposition.MinimumWidth = 8
        Me.Disposition.Name = "Disposition"
        Me.Disposition.ReadOnly = True
        Me.Disposition.Width = 175
        '
        'MimeType
        '
        Me.MimeType.DataPropertyName = "MimeType"
        Me.MimeType.HeaderText = "Myme Type"
        Me.MimeType.MinimumWidth = 8
        Me.MimeType.Name = "MimeType"
        Me.MimeType.ReadOnly = True
        Me.MimeType.Width = 175
        '
        'tbAbout
        '
        Me.tbAbout.Controls.Add(Me.Label38)
        Me.tbAbout.Controls.Add(Me.Label33)
        Me.tbAbout.Controls.Add(Me.Label32)
        Me.tbAbout.Location = New System.Drawing.Point(4, 29)
        Me.tbAbout.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbAbout.Name = "tbAbout"
        Me.tbAbout.Padding = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.tbAbout.Size = New System.Drawing.Size(1332, 739)
        Me.tbAbout.TabIndex = 9
        Me.tbAbout.Text = "À propos"
        Me.tbAbout.UseVisualStyleBackColor = True
        '
        'Label38
        '
        Me.Label38.AutoSize = True
        Me.Label38.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.75!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label38.Location = New System.Drawing.Point(436, 274)
        Me.Label38.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label38.Name = "Label38"
        Me.Label38.Size = New System.Drawing.Size(132, 25)
        Me.Label38.TabIndex = 2
        Me.Label38.Text = "Server SMTP"
        '
        'Label33
        '
        Me.Label33.AutoSize = True
        Me.Label33.Location = New System.Drawing.Point(525, 325)
        Me.Label33.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label33.Name = "Label33"
        Me.Label33.Size = New System.Drawing.Size(31, 20)
        Me.Label33.TabIndex = 1
        Me.Label33.Text = "1.0"
        '
        'Label32
        '
        Me.Label32.AutoSize = True
        Me.Label32.Location = New System.Drawing.Point(450, 325)
        Me.Label32.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label32.Name = "Label32"
        Me.Label32.Size = New System.Drawing.Size(67, 20)
        Me.Label32.TabIndex = 0
        Me.Label32.Text = "Version:"
        '
        'Button1
        '
        Me.Button1.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.Button1.Location = New System.Drawing.Point(1239, 834)
        Me.Button1.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.Button1.Name = "Button1"
        Me.Button1.Size = New System.Drawing.Size(112, 35)
        Me.Button1.TabIndex = 22
        Me.Button1.Text = "Fermer"
        Me.Button1.UseVisualStyleBackColor = True
        '
        'Timer1
        '
        Me.Timer1.Interval = 1000
        '
        'Label31
        '
        Me.Label31.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
        Me.Label31.AutoSize = True
        Me.Label31.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.0!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label31.Location = New System.Drawing.Point(20, 842)
        Me.Label31.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label31.Name = "Label31"
        Me.Label31.Size = New System.Drawing.Size(231, 22)
        Me.Label31.TabIndex = 23
        Me.Label31.Text = "Courriel sélectionné (Id):"
        '
        'lblCurrentEmailId
        '
        Me.lblCurrentEmailId.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
        Me.lblCurrentEmailId.AutoSize = True
        Me.lblCurrentEmailId.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.0!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.lblCurrentEmailId.Location = New System.Drawing.Point(264, 842)
        Me.lblCurrentEmailId.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.lblCurrentEmailId.Name = "lblCurrentEmailId"
        Me.lblCurrentEmailId.Size = New System.Drawing.Size(28, 22)
        Me.lblCurrentEmailId.TabIndex = 24
        Me.lblCurrentEmailId.Text = "-1"
        '
        'Label39
        '
        Me.Label39.AutoSize = True
        Me.Label39.Location = New System.Drawing.Point(12, 14)
        Me.Label39.Name = "Label39"
        Me.Label39.Size = New System.Drawing.Size(52, 20)
        Me.Label39.TabIndex = 6
        Me.Label39.Text = "Filtre: "
        '
        'txtFiltre
        '
        Me.txtFiltre.Location = New System.Drawing.Point(70, 11)
        Me.txtFiltre.MaxLength = 300
        Me.txtFiltre.Name = "txtFiltre"
        Me.txtFiltre.Size = New System.Drawing.Size(365, 26)
        Me.txtFiltre.TabIndex = 7
        '
        'btnSet
        '
        Me.btnSet.Location = New System.Drawing.Point(480, 11)
        Me.btnSet.Name = "btnSet"
        Me.btnSet.Size = New System.Drawing.Size(50, 28)
        Me.btnSet.TabIndex = 8
        Me.btnSet.Text = "Set"
        Me.btnSet.UseVisualStyleBackColor = True
        '
        'btnX
        '
        Me.btnX.Location = New System.Drawing.Point(441, 11)
        Me.btnX.Name = "btnX"
        Me.btnX.Size = New System.Drawing.Size(33, 28)
        Me.btnX.TabIndex = 9
        Me.btnX.Text = "X"
        Me.btnX.UseVisualStyleBackColor = True
        '
        'Form1
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(9.0!, 20.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(1376, 875)
        Me.Controls.Add(Me.lblCurrentEmailId)
        Me.Controls.Add(Me.Label31)
        Me.Controls.Add(Me.Button1)
        Me.Controls.Add(Me.TabControl1)
        Me.Controls.Add(Me.MenuStrip1)
        Me.Icon = CType(resources.GetObject("$this.Icon"), System.Drawing.Icon)
        Me.MainMenuStrip = Me.MenuStrip1
        Me.Margin = New System.Windows.Forms.Padding(4, 5, 4, 5)
        Me.MinimumSize = New System.Drawing.Size(1110, 871)
        Me.Name = "Form1"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Service SMTP"
        Me.TopMost = True
        Me.MenuStrip1.ResumeLayout(False)
        Me.MenuStrip1.PerformLayout()
        Me.TabControl1.ResumeLayout(False)
        Me.tbStatus.ResumeLayout(False)
        Me.GroupBox2.ResumeLayout(False)
        Me.GroupBox2.PerformLayout()
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.tbEvents.ResumeLayout(False)
        Me.tbEvents.PerformLayout()
        Me.tbError.ResumeLayout(False)
        Me.tbError.PerformLayout()
        Me.tbGridMail.ResumeLayout(False)
        Me.tbGridMail.PerformLayout()
        CType(Me.dvListMail, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tbGridError.ResumeLayout(False)
        CType(Me.dvListError, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tbSource.ResumeLayout(False)
        Me.tbSource.PerformLayout()
        Me.tbHTML.ResumeLayout(False)
        Me.tbHTML.PerformLayout()
        Me.tbText.ResumeLayout(False)
        Me.tbText.PerformLayout()
        Me.tbParser.ResumeLayout(False)
        Me.tbParser.PerformLayout()
        Me.tbAttachment.ResumeLayout(False)
        CType(Me.dgvAttachment, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tbAbout.ResumeLayout(False)
        Me.tbAbout.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents txtLogEvent As System.Windows.Forms.TextBox
    Friend WithEvents MenuStrip1 As System.Windows.Forms.MenuStrip
    Friend WithEvents AjustementToolStripMenuItem As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents btnDelEvents As System.Windows.Forms.Button
    Friend WithEvents TabControl1 As Windows.Forms.TabControl
    Friend WithEvents tbStatus As Windows.Forms.TabPage
    Friend WithEvents tbEvents As Windows.Forms.TabPage
    Friend WithEvents tbError As Windows.Forms.TabPage
    Friend WithEvents txtlogError As Windows.Forms.TextBox
    Friend WithEvents btnDelError As Windows.Forms.Button
    Friend WithEvents lblThreadSMTPInputStarted As Windows.Forms.Label
    Friend WithEvents Label7 As Windows.Forms.Label
    Friend WithEvents lblLastDomainName As Windows.Forms.Label
    Friend WithEvents Label6 As Windows.Forms.Label
    Friend WithEvents lblLastRecipient As Windows.Forms.Label
    Friend WithEvents Label5 As Windows.Forms.Label
    Friend WithEvents lblMailSizeInput As Windows.Forms.Label
    Friend WithEvents Label4 As Windows.Forms.Label
    Friend WithEvents lblStatusSMTPStepInput As Windows.Forms.Label
    Friend WithEvents Label2 As Windows.Forms.Label
    Friend WithEvents lblCounterEmailInput As Windows.Forms.Label
    Friend WithEvents Label1 As Windows.Forms.Label
    Friend WithEvents lblSMTPClientIP As Windows.Forms.Label
    Friend WithEvents Label9 As Windows.Forms.Label
    Friend WithEvents lblThreadSMTPLastReceived As Windows.Forms.Label
    Friend WithEvents Label8 As Windows.Forms.Label
    Friend WithEvents Button1 As Windows.Forms.Button
    Friend WithEvents Timer1 As Windows.Forms.Timer
    Friend WithEvents tbGridMail As Windows.Forms.TabPage
    Friend WithEvents dvListMail As Windows.Forms.DataGridView
    Friend WithEvents btnRefresh As Windows.Forms.Button
    Friend WithEvents tbSource As Windows.Forms.TabPage
    Friend WithEvents tbHTML As Windows.Forms.TabPage
    Friend WithEvents tbText As Windows.Forms.TabPage
    Friend WithEvents tbParser As Windows.Forms.TabPage
    Friend WithEvents txtMail As Windows.Forms.TextBox
    Friend WithEvents txtHTML As Windows.Forms.TextBox
    Friend WithEvents txtText As Windows.Forms.TextBox
    Friend WithEvents lblIP As Windows.Forms.Label
    Friend WithEvents Label23 As Windows.Forms.Label
    Friend WithEvents lblDomaine As Windows.Forms.Label
    Friend WithEvents Label22 As Windows.Forms.Label
    Friend WithEvents lblRCPT As Windows.Forms.Label
    Friend WithEvents Label20 As Windows.Forms.Label
    Friend WithEvents lblErrorParsing As Windows.Forms.Label
    Friend WithEvents lblResentMessageId As Windows.Forms.Label
    Friend WithEvents lblMessageId As Windows.Forms.Label
    Friend WithEvents lblXPriority As Windows.Forms.Label
    Friend WithEvents lblImportance As Windows.Forms.Label
    Friend WithEvents lblInReplyTo As Windows.Forms.Label
    Friend WithEvents lblTo As Windows.Forms.Label
    Friend WithEvents lblSender As Windows.Forms.Label
    Friend WithEvents lblResentTo As Windows.Forms.Label
    Friend WithEvents lblResentSender As Windows.Forms.Label
    Friend WithEvents lblResentReplyTo As Windows.Forms.Label
    Friend WithEvents lblResentFrom As Windows.Forms.Label
    Friend WithEvents lblResentCc As Windows.Forms.Label
    Friend WithEvents lblResentBcc As Windows.Forms.Label
    Friend WithEvents lblReplyTo As Windows.Forms.Label
    Friend WithEvents lblCC As Windows.Forms.Label
    Friend WithEvents lblBCC As Windows.Forms.Label
    Friend WithEvents lblFrom As Windows.Forms.Label
    Friend WithEvents lblSubject As Windows.Forms.Label
    Friend WithEvents Label18 As Windows.Forms.Label
    Friend WithEvents Label19 As Windows.Forms.Label
    Friend WithEvents Label16 As Windows.Forms.Label
    Friend WithEvents Label17 As Windows.Forms.Label
    Friend WithEvents Label15 As Windows.Forms.Label
    Friend WithEvents Label14 As Windows.Forms.Label
    Friend WithEvents Label12 As Windows.Forms.Label
    Friend WithEvents Label13 As Windows.Forms.Label
    Friend WithEvents Label10 As Windows.Forms.Label
    Friend WithEvents Label11 As Windows.Forms.Label
    Friend WithEvents Label3 As Windows.Forms.Label
    Friend WithEvents Label21 As Windows.Forms.Label
    Friend WithEvents Label24 As Windows.Forms.Label
    Friend WithEvents Label25 As Windows.Forms.Label
    Friend WithEvents Label26 As Windows.Forms.Label
    Friend WithEvents Label27 As Windows.Forms.Label
    Friend WithEvents Label28 As Windows.Forms.Label
    Friend WithEvents Label29 As Windows.Forms.Label
    Friend WithEvents Label30 As Windows.Forms.Label
    Friend WithEvents tbAttachment As Windows.Forms.TabPage
    Friend WithEvents dgvAttachment As Windows.Forms.DataGridView
    Friend WithEvents FileName As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents Disposition As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents MimeType As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents Label31 As Windows.Forms.Label
    Friend WithEvents lblCurrentEmailId As Windows.Forms.Label
    Friend WithEvents lblSMTPStep As Windows.Forms.Label
    Friend WithEvents Label36 As Windows.Forms.Label
    Friend WithEvents Label35 As Windows.Forms.Label
    Friend WithEvents lblNbSendMail As Windows.Forms.Label
    Friend WithEvents Label34 As Windows.Forms.Label
    Friend WithEvents lblSendStep As Windows.Forms.Label
    Friend WithEvents Label37 As Windows.Forms.Label
    Friend WithEvents lblLastSend As Windows.Forms.Label
    Friend WithEvents lblSendFrom As Windows.Forms.Label
    Friend WithEvents lblSendTo As Windows.Forms.Label
    Friend WithEvents GroupBox2 As Windows.Forms.GroupBox
    Friend WithEvents GroupBox1 As Windows.Forms.GroupBox
    Friend WithEvents tbAbout As Windows.Forms.TabPage
    Friend WithEvents Label38 As Windows.Forms.Label
    Friend WithEvents Label33 As Windows.Forms.Label
    Friend WithEvents Label32 As Windows.Forms.Label
    Friend WithEvents tbGridError As Windows.Forms.TabPage
    Friend WithEvents lblMessageError As Windows.Forms.Label
    Friend WithEvents dvListError As Windows.Forms.DataGridView
    Friend WithEvents DataGridViewTextBoxColumn1 As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents DataGridViewTextBoxColumn4 As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents DataGridViewTextBoxColumn3 As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents DataGridViewTextBoxColumn5 As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents dCreated As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents btnResend As Windows.Forms.Button
    Friend WithEvents Id As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents RCPT As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents sTo As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents Retry As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents SendAt As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents Received As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents Sended As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents tosend As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents SendWithSuccess As Windows.Forms.DataGridViewTextBoxColumn
    Friend WithEvents btnX As Windows.Forms.Button
    Friend WithEvents btnSet As Windows.Forms.Button
    Friend WithEvents txtFiltre As Windows.Forms.TextBox
    Friend WithEvents Label39 As Windows.Forms.Label
End Class
