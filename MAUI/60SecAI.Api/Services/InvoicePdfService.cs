using System.Data;
using System.Globalization;
using System.Text;
using Microsoft.Data.SqlClient;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace _60SecAI.Api.Services;

/// <summary>
/// Génère (QuestPDF) et enregistre le PDF d'une facture — port fidèle de
/// clsGenerateInvoicePDF + InvoicePdfBuilder du site web (prjMngConsul).
/// Charge via s0115GetInvoiceForPdf, enregistre via s0116SaveInvoicePdf.
/// </summary>
public sealed class InvoicePdfService
{
	private readonly string _connectionString;

	public InvoicePdfService(IConfiguration configuration)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
	}

	/// <summary>Génère le PDF et le stocke dans T060Document (s0116). Retourne true si généré.</summary>
	public async Task<bool> GenerateAndSaveAsync(int invoiceId)
	{
		var inv = await LoadInvoiceForPdfAsync(invoiceId);
		if (inv is null)
		{
			return false;
		}

		var pdfBytes = InvoicePdfBuilder.Build(inv);
		var fileName = "Invoice_" + inv.InvoiceNumber + ".pdf";

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();
		await using var cmd = new SqlCommand("s0116SaveInvoicePdf", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@InvoiceId", invoiceId);
		cmd.Parameters.Add(new SqlParameter("@PdfData", SqlDbType.VarBinary, -1) { Value = pdfBytes });
		cmd.Parameters.AddWithValue("@FileName", fileName);
		await cmd.ExecuteNonQueryAsync();
		return true;
	}

	private async Task<InvoiceData?> LoadInvoiceForPdfAsync(int invoiceId)
	{
		var ds = new DataSet();
		await using (var conn = new SqlConnection(_connectionString))
		{
			await using var cmd = new SqlCommand("s0115GetInvoiceForPdf", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@InvoiceId", invoiceId);
			using var da = new SqlDataAdapter(cmd);
			da.Fill(ds);
		}

		if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
		{
			return null;
		}

		var r = ds.Tables[0].Rows[0];
		var inv = new InvoiceData();

		// === Émetteur : infos réelles de la compagnie (colonnes Co*) ===
		inv.CompanyName = ColStr(r, "CoName");

		var coTrade = ColStr(r, "CoTradeName");
		inv.CompanyTagline = coTrade != "" && !coTrade.Equals(inv.CompanyName, StringComparison.OrdinalIgnoreCase) ? coTrade : "";

		var coAddr1 = ColStr(r, "CoAddr1");
		var coAddr2 = ColStr(r, "CoAddr2");
		inv.CompanyAddressLine1 = coAddr2 != "" ? (coAddr1 + (coAddr1 != "" ? ", " : "") + coAddr2) : coAddr1;

		var coL2 = new StringBuilder();
		var coCity = ColStr(r, "CoCity");
		var coProv = ColStr(r, "CoProvince");
		var coPostal = ColStr(r, "CoPostal");
		if (coCity != "") coL2.Append(coCity);
		if (coProv != "") coL2.Append(coL2.Length > 0 ? ", " : "").Append(coProv);
		if (coPostal != "") coL2.Append(coL2.Length > 0 ? " " : "").Append(coPostal);
		inv.CompanyAddressLine2 = coL2.ToString();

		inv.CompanyPhone = ColStr(r, "CoPhone");
		inv.CompanyEmail = ColStr(r, "CoEmail");

		var coGst = ColStr(r, "CoGstNo");
		var coHst = ColStr(r, "CoHstNo");
		inv.CompanyTpsNumber = coGst != "" ? coGst : coHst;
		inv.CompanyTvqNumber = ColStr(r, "CoQstNo");

		inv.PaymentTerms = ColStr(r, "CoPaymentTerms");
		inv.Notes = ColStr(r, "CoNotes");

		if (r.Table.Columns.Contains("CoLogo") && !r.IsNull("CoLogo"))
		{
			inv.LogoBytes = (byte[])r["CoLogo"];
		}

		// === Facture ===
		inv.InvoiceNumber = r["DocumentNumber"] is DBNull ? invoiceId.ToString() : r["DocumentNumber"].ToString()!;
		inv.IssueDate = r["DocumentDate"] is DBNull ? DateTime.Now.Date : Convert.ToDateTime(r["DocumentDate"]);
		inv.DueDate = r["DueDate"] is DBNull ? inv.IssueDate.AddDays(30) : Convert.ToDateTime(r["DueDate"]);

		// === Client ===
		inv.CustomerName = r["Name"] is DBNull ? "" : r["Name"].ToString()!;
		inv.CustomerAddressLine1 = r["Address1"] is DBNull ? "" : r["Address1"].ToString()!;

		var line2 = new StringBuilder();
		if (r["City"] is not DBNull) line2.Append(r["City"]);
		if (r["State"] is not DBNull) line2.Append(", ").Append(r["State"]);
		if (r["PostalCode"] is not DBNull) line2.Append(' ').Append(r["PostalCode"]);
		inv.CustomerAddressLine2 = line2.ToString();

		inv.CustomerPhone = r["Phone"] is DBNull ? "" : r["Phone"].ToString()!;
		inv.CustomerEmail = r["Email"] is DBNull ? "" : r["Email"].ToString()!;

		// === Totaux ===
		inv.SubTotal = r["SubTotal"] is DBNull ? 0m : Convert.ToDecimal(r["SubTotal"]);
		inv.Tps = r["TPS"] is DBNull ? 0m : Convert.ToDecimal(r["TPS"]);
		inv.Tvq = r["TVQ"] is DBNull ? 0m : Convert.ToDecimal(r["TVQ"]);
		inv.Total = r["Total"] is DBNull ? 0m : Convert.ToDecimal(r["Total"]);

		// === État de paiement (tampon PAYÉ) ===
		if (ds.Tables[0].Columns.Contains("ResteAPayer"))
		{
			var reste = r["ResteAPayer"] is DBNull ? inv.Total : Convert.ToDecimal(r["ResteAPayer"]);
			inv.IsPaid = reste <= 0m && inv.Total > 0m;
		}
		else if (ds.Tables[0].Columns.Contains("IsPaid"))
		{
			inv.IsPaid = r["IsPaid"] is not DBNull && Convert.ToBoolean(r["IsPaid"]);
		}

		// === Lignes (table 2) ===
		if (ds.Tables.Count >= 2)
		{
			foreach (DataRow rl in ds.Tables[1].Rows)
			{
				var productName = rl["ProductName"] is DBNull ? "" : rl["ProductName"].ToString()!;
				var description = rl["Description"] is DBNull ? "" : rl["Description"].ToString()!;
				inv.Items.Add(new InvoiceLine
				{
					Description = string.IsNullOrEmpty(productName) ? description : productName,
					SubDescription = description,
					Qty = rl["Qty"] is DBNull ? 1m : Convert.ToDecimal(rl["Qty"]),
					UnitPrice = rl["UnitPrice"] is DBNull ? 0m : Convert.ToDecimal(rl["UnitPrice"]),
					Amount = rl["Amount"] is DBNull ? 0m : Convert.ToDecimal(rl["Amount"]),
				});
			}
		}

		return inv;
	}

	private static string ColStr(DataRow r, string col)
	{
		if (r is null || !r.Table.Columns.Contains(col) || r.IsNull(col))
		{
			return "";
		}

		return r[col].ToString()!.Trim();
	}
}

// ============================================================
// Modèles de données (port de InvoicePdfBuilder.vb)
// ============================================================
public sealed class InvoiceData
{
	public string CompanyName { get; set; } = "";
	public string CompanyTagline { get; set; } = "";
	public byte[]? LogoBytes { get; set; }
	public string CompanyAddressLine1 { get; set; } = "";
	public string CompanyAddressLine2 { get; set; } = "";
	public string CompanyPhone { get; set; } = "";
	public string CompanyEmail { get; set; } = "";
	public string CompanyTpsNumber { get; set; } = "";
	public string CompanyTvqNumber { get; set; } = "";

	public string InvoiceNumber { get; set; } = "";
	public DateTime IssueDate { get; set; }
	public DateTime DueDate { get; set; }

	public string CustomerName { get; set; } = "";
	public string CustomerAddressLine1 { get; set; } = "";
	public string CustomerAddressLine2 { get; set; } = "";
	public string CustomerPhone { get; set; } = "";
	public string CustomerEmail { get; set; } = "";

	public List<InvoiceLine> Items { get; } = new();

	public decimal SubTotal { get; set; }
	public decimal TpsRate { get; set; } = 5m;
	public decimal Tps { get; set; }
	public decimal TvqRate { get; set; } = 9.975m;
	public decimal Tvq { get; set; }
	public decimal Total { get; set; }

	public string PaymentTerms { get; set; } = "";
	public string Notes { get; set; } = "";
	public bool IsPaid { get; set; }
}

public sealed class InvoiceLine
{
	public string Description { get; set; } = "";
	public string SubDescription { get; set; } = "";
	public decimal Qty { get; set; }
	public decimal UnitPrice { get; set; }
	public decimal Amount { get; set; }
}

// ============================================================
// Constructeur PDF (port QuestPDF de InvoicePdfBuilder.vb)
// ============================================================
public static class InvoicePdfBuilder
{
	private const string ClrPrimary = "#2563eb";
	private const string ClrSecondary = "#06b6d4";
	private const string ClrText = "#0f172a";
	private const string ClrTextMuted = "#64748b";
	private const string ClrTextLight = "#475569";
	private const string ClrBgLight = "#f8fafc";
	private const string ClrBgAccent = "#eff6ff";
	private const string ClrLine = "#e2e8f0";
	private const string ClrNoteBg = "#ecfeff";
	private const string ClrNoteText = "#0e7490";
	private const string ClrLineDark = "#cbd5e1";
	private const string ClrWhite = "#ffffff";
	private const string ClrStamp = "#dc2626";

	private static readonly CultureInfo Ca = CultureInfo.GetCultureInfo("fr-CA");

	public static byte[] Build(InvoiceData invoice)
	{
		return Document.Create(container =>
		{
			container.Page(page =>
			{
				page.Size(PageSizes.Letter);
				page.Margin(40);
				page.PageColor(ClrWhite);
				page.DefaultTextStyle(x => x.FontSize(10).FontFamily("Arial").FontColor(ClrText));

				page.Content().Element(c => ComposeBody(c, invoice));
				page.Footer().Element(c => ComposeFooter(c, invoice));
			});
		}).GeneratePdf();
	}

	private static void ComposeBody(IContainer container, InvoiceData inv)
	{
		container.Column(col =>
		{
			col.Spacing(14);

			if (inv.IsPaid)
			{
				col.Item().Height(0).Element(stampSlot =>
					stampSlot.OffsetX(120).OffsetY(280).Element(ComposePaidStamp));
			}

			ComposeHeader(col, inv);
			ComposeMetaCards(col, inv);
			ComposeClientCards(col, inv);
			ComposeItemsTable(col, inv);
			ComposeTotals(col, inv);

			if (!string.IsNullOrEmpty(inv.PaymentTerms))
			{
				ComposeNote(col, "CONDITIONS DE PAIEMENT", inv.PaymentTerms);
			}
			if (!string.IsNullOrEmpty(inv.Notes))
			{
				ComposeNote(col, "NOTES", inv.Notes);
			}
		});
	}

	private static void ComposeHeader(ColumnDescriptor col, InvoiceData inv)
	{
		col.Item().BorderBottom(3).BorderColor(ClrPrimary).PaddingBottom(15).Row(row =>
		{
			row.RelativeItem().Row(brandRow =>
			{
				if (inv.LogoBytes is { Length: > 0 })
				{
					brandRow.AutoItem().Width(50).Height(50).AlignCenter().AlignMiddle()
						.Image(inv.LogoBytes).FitArea();
				}
				else
				{
					brandRow.AutoItem().Width(50).Height(50).Background(ClrPrimary).AlignCenter().AlignMiddle()
						.Text(GetInitial(inv.CompanyName)).FontSize(24).FontColor(ClrWhite).Bold();
				}

				brandRow.ConstantItem(12);

				brandRow.RelativeItem().AlignMiddle().Column(c =>
				{
					c.Item().Text(inv.CompanyName).FontSize(16).Bold();
					c.Item().Text(inv.CompanyTagline).FontSize(10).FontColor(ClrTextMuted);
				});
			});

			row.AutoItem().AlignRight().Column(c =>
			{
				c.Item().AlignRight().Text("FACTURE").FontSize(28).Bold().FontColor(ClrPrimary);
				c.Item().AlignRight().Text("N° " + inv.InvoiceNumber).FontSize(11).FontColor(ClrTextMuted);
			});
		});
	}

	private static void ComposeMetaCards(ColumnDescriptor col, InvoiceData inv)
	{
		col.Item().Row(row =>
		{
			row.Spacing(10);
			row.RelativeItem().Element(c => BuildMetaCard(c, "DATE D'ÉMISSION", inv.IssueDate.ToString("yyyy-MM-dd"), false));
			row.RelativeItem().Element(c => BuildMetaCard(c, "DATE D'ÉCHÉANCE", inv.DueDate.ToString("yyyy-MM-dd"), false));
			row.RelativeItem().Element(c => BuildMetaCard(c, "MONTANT DÛ", inv.Total.ToString("C", Ca), true));
		});
	}

	private static void BuildMetaCard(IContainer container, string label, string value, bool accent)
	{
		var bg = accent ? ClrBgAccent : ClrWhite;
		var valueColor = accent ? ClrPrimary : ClrText;

		container.Background(bg).Border(0.5f).BorderColor(ClrLine).Padding(12).Column(c =>
		{
			c.Item().Text(label).FontSize(9).FontColor(ClrTextMuted).Bold();
			c.Item().PaddingTop(3).Text(value).FontSize(13).Bold().FontColor(valueColor);
		});
	}

	private static void ComposeClientCards(ColumnDescriptor col, InvoiceData inv)
	{
		col.Item().Row(row =>
		{
			row.Spacing(15);

			row.RelativeItem().Background(ClrBgLight).Padding(14).Column(c =>
			{
				c.Item().Text("FACTURÉ PAR").FontSize(9).FontColor(ClrTextMuted).Bold();
				c.Item().PaddingTop(4).Text(inv.CompanyName).FontSize(13).Bold();
				c.Item().Text(inv.CompanyAddressLine1).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CompanyAddressLine2))
					c.Item().Text(inv.CompanyAddressLine2).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CompanyPhone))
					c.Item().Text(inv.CompanyPhone).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CompanyEmail))
					c.Item().Text(inv.CompanyEmail).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CompanyTpsNumber))
					c.Item().PaddingTop(6).Text("TPS : " + inv.CompanyTpsNumber).FontSize(9).FontColor(ClrTextMuted);
				if (!string.IsNullOrEmpty(inv.CompanyTvqNumber))
					c.Item().Text("TVQ : " + inv.CompanyTvqNumber).FontSize(9).FontColor(ClrTextMuted);
			});

			row.RelativeItem().Background(ClrBgLight).Padding(14).Column(c =>
			{
				c.Item().Text("FACTURÉ À").FontSize(9).FontColor(ClrTextMuted).Bold();
				c.Item().PaddingTop(4).Text(inv.CustomerName).FontSize(13).Bold();
				if (!string.IsNullOrEmpty(inv.CustomerAddressLine1))
					c.Item().Text(inv.CustomerAddressLine1).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CustomerAddressLine2))
					c.Item().Text(inv.CustomerAddressLine2).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CustomerPhone))
					c.Item().Text(inv.CustomerPhone).FontSize(10).FontColor(ClrTextLight);
				if (!string.IsNullOrEmpty(inv.CustomerEmail))
					c.Item().Text(inv.CustomerEmail).FontSize(10).FontColor(ClrTextLight);
			});
		});
	}

	private static void ComposeItemsTable(ColumnDescriptor col, InvoiceData inv)
	{
		col.Item().Table(table =>
		{
			table.ColumnsDefinition(cols =>
			{
				cols.RelativeColumn(5);
				cols.RelativeColumn(1);
				cols.RelativeColumn(2);
				cols.RelativeColumn(2);
			});

			table.Header(header =>
			{
				header.Cell().Background(ClrPrimary).Padding(10).Text("DESCRIPTION").FontSize(10).Bold().FontColor(ClrWhite);
				header.Cell().Background(ClrPrimary).Padding(10).AlignCenter().Text("QTÉ").FontSize(10).Bold().FontColor(ClrWhite);
				header.Cell().Background(ClrPrimary).Padding(10).AlignRight().Text("PRIX").FontSize(10).Bold().FontColor(ClrWhite);
				header.Cell().Background(ClrPrimary).Padding(10).AlignRight().Text("MONTANT").FontSize(10).Bold().FontColor(ClrWhite);
			});

			for (var i = 0; i < inv.Items.Count; i++)
			{
				var line = inv.Items[i];
				var bg = i % 2 == 0 ? ClrWhite : ClrBgLight;

				table.Cell().Background(bg).Padding(10).Column(c =>
				{
					c.Item().Text(line.Description).FontSize(11).Bold();
					if (!string.IsNullOrEmpty(line.SubDescription))
						c.Item().PaddingTop(2).Text(line.SubDescription).FontSize(9).FontColor(ClrTextMuted);
				});

				table.Cell().Background(bg).Padding(10).AlignCenter().AlignMiddle().Text(line.Qty.ToString("0.##")).FontSize(11);
				table.Cell().Background(bg).Padding(10).AlignRight().AlignMiddle().Text(line.UnitPrice.ToString("C", Ca)).FontSize(11);
				table.Cell().Background(bg).Padding(10).AlignRight().AlignMiddle().Text(line.Amount.ToString("C", Ca)).FontSize(11).Bold();
			}
		});
	}

	private static void ComposeTotals(ColumnDescriptor col, InvoiceData inv)
	{
		col.Item().AlignRight().Width(280).Background(ClrBgLight).Padding(14).Column(c =>
		{
			BuildTotalLine(c, "Sous-total", inv.SubTotal);

			if (inv.Tps > 0)
				BuildTotalLine(c, "TPS (" + inv.TpsRate.ToString("0.###", Ca) + " %)", inv.Tps);
			if (inv.Tvq > 0)
				BuildTotalLine(c, "TVQ (" + inv.TvqRate.ToString("0.###", Ca) + " %)", inv.Tvq);

			c.Item().PaddingVertical(6).LineHorizontal(0.5f).LineColor(ClrLineDark);

			c.Item().Background(ClrPrimary).Padding(10).Row(row =>
			{
				row.RelativeItem().Text("TOTAL").FontSize(11).Bold().FontColor(ClrWhite);
				row.AutoItem().Text(inv.Total.ToString("C", Ca)).FontSize(15).Bold().FontColor(ClrWhite);
			});
		});
	}

	private static void BuildTotalLine(ColumnDescriptor c, string label, decimal value)
	{
		c.Item().PaddingVertical(2).Row(row =>
		{
			row.RelativeItem().Text(label).FontSize(11).FontColor(ClrTextLight);
			row.AutoItem().Text(value.ToString("C", Ca)).FontSize(11).Bold();
		});
	}

	private static void ComposeNote(ColumnDescriptor col, string title, string body)
	{
		col.Item().BorderLeft(3).BorderColor(ClrSecondary).Background(ClrNoteBg).Padding(10).Column(c =>
		{
			if (!string.IsNullOrEmpty(title))
			{
				c.Item().Text(title).FontSize(9).Bold().FontColor(ClrNoteText);
				c.Item().PaddingTop(3);
			}
			c.Item().Text(body).FontSize(10).FontColor(ClrNoteText);
		});
	}

	private static void ComposePaidStamp(IContainer container)
	{
		container.Rotate(-22).Width(280).Height(120)
			.Border(4).BorderColor(ClrStamp).Padding(10).AlignCenter().AlignMiddle()
			.Text("PAYÉ").FontSize(90).Bold().FontColor(ClrStamp).LetterSpacing(0.05f);
	}

	private static void ComposeFooter(IContainer container, InvoiceData inv)
	{
		container.BorderTop(0.5f).BorderColor(ClrLine).PaddingTop(10).AlignCenter().Text(text =>
		{
			text.DefaultTextStyle(x => x.FontSize(9).FontColor(ClrTextMuted));
			text.Span(inv.CompanyName);
			if (!string.IsNullOrEmpty(inv.CompanyAddressLine1))
				text.Span(" — " + inv.CompanyAddressLine1);
			if (!string.IsNullOrEmpty(inv.CompanyEmail))
				text.Span(" — " + inv.CompanyEmail);
			text.Span(" — Page ");
			text.CurrentPageNumber();
			text.Span(" / ");
			text.TotalPages();
		});
	}

	private static string GetInitial(string s) => string.IsNullOrEmpty(s) ? "?" : s.Substring(0, 1).ToUpper();
}
