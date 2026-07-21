<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfReceiptEditPopup.aspx.vb" Inherits="MngConsul.wbfReceiptEditPopup" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register Src="~/Controls/ucReceiptEdit.ascx" TagPrefix="uc" TagName="ReceiptEdit" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>60Sec-AI</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href="css/listvew.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"
            EnablePartialRendering="true" AsyncPostBackTimeout="300" />
        <uc:ReceiptEdit runat="server" ID="ReceiptEdit1" />
    </form>
</body>
</html>
