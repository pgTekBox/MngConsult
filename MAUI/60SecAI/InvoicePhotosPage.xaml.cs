using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using _60SecAI.Localization;
using _60SecAI.Services;

namespace _60SecAI;

/// <summary>
/// Liste des photos d'une facture (date/heure + vignette). Un toucher ouvre la
/// photo en plein écran. Présentée en modal via <see cref="ShowAsync"/>.
/// </summary>
public partial class InvoicePhotosPage : ContentPage
{
	private readonly int _invoiceId;
	private readonly SalesService _sales;
	private bool _loaded;

	public ObservableCollection<PhotoItem> Photos { get; } = [];

	private InvoicePhotosPage(int invoiceId, string subtitle)
	{
		InitializeComponent();
		_invoiceId = invoiceId;
		_sales = ServiceHelper.GetService<SalesService>();
		SubtitleLabel.Text = subtitle;
		EmptyLabel.Text = string.Empty; // évite le clignotement « Aucune photo » au chargement
		BindingContext = this;
	}

	/// <summary>Ouvre la liste des photos en modal.</summary>
	public static Task ShowAsync(INavigation nav, int invoiceId, string subtitle)
	{
		var page = new InvoicePhotosPage(invoiceId, subtitle);
		return nav.PushModalAsync(page);
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		if (_loaded)
		{
			return;
		}

		_loaded = true;
		await LoadAsync();
	}

	private async Task LoadAsync()
	{
		Busy.IsRunning = Busy.IsVisible = true;
		try
		{
			var metas = await _sales.GetInvoicePhotosAsync(_invoiceId);

			Photos.Clear();
			foreach (var m in metas)
			{
				Photos.Add(new PhotoItem
				{
					Id = m.Id,
					DateText = m.Created?.ToString("yyyy-MM-dd HH:mm") ?? string.Empty,
					SizeText = FormatSize(m.SizeBytes),
				});
			}

			// Télécharge les vignettes (le même blob sert au plein écran).
			foreach (var item in Photos)
			{
				var bytes = await _sales.GetInvoicePhotoContentAsync(_invoiceId, item.Id);
				if (bytes is { Length: > 0 })
				{
					item.Bytes = bytes;
					item.Thumb = ImageSource.FromStream(() => new MemoryStream(bytes));
				}
			}
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync(LocalizationResourceManager.Instance["PhotosTitle"], ex.Message, "OK");
		}
		finally
		{
			Busy.IsRunning = Busy.IsVisible = false;
			EmptyLabel.Text = LocalizationResourceManager.Instance["NoPhoto"];
		}
	}

	private static string FormatSize(int bytes)
	{
		if (bytes <= 0)
		{
			return string.Empty;
		}

		var kb = bytes / 1024.0;
		return kb >= 1024 ? $"{kb / 1024:0.0} Mo" : $"{Math.Round(kb)} Ko";
	}

	private async void OnPhotoTapped(object? sender, TappedEventArgs e)
	{
		if ((sender as BindableObject)?.BindingContext is not PhotoItem item || item.Bytes is null)
		{
			return;
		}

		await Navigation.PushModalAsync(BuildViewer(item.Bytes, item.DateText));
	}

	/// <summary>Page plein écran : image sur fond noir, toucher pour fermer.</summary>
	private static ContentPage BuildViewer(byte[] bytes, string title)
	{
		var image = new Image
		{
			Source = ImageSource.FromStream(() => new MemoryStream(bytes)),
			Aspect = Aspect.AspectFit,
		};

		var caption = new Label
		{
			Text = title,
			TextColor = Colors.White,
			FontSize = 13,
			HorizontalOptions = LayoutOptions.Center,
			Margin = new Thickness(0, 0, 0, 16),
			VerticalOptions = LayoutOptions.End,
		};

		var page = new ContentPage
		{
			BackgroundColor = Colors.Black,
			Content = new Grid { Children = { image, caption } },
		};

		var tap = new TapGestureRecognizer();
		tap.Tapped += async (_, _) => await page.Navigation.PopModalAsync();
		((Grid)page.Content).GestureRecognizers.Add(tap);

		return page;
	}

	private async void OnCancel(object? sender, TappedEventArgs e) => await Navigation.PopModalAsync();
}

/// <summary>Élément de la liste des photos (vignette chargée de façon asynchrone).</summary>
public partial class PhotoItem : ObservableObject
{
	public int Id { get; set; }

	public string DateText { get; set; } = string.Empty;

	public string SizeText { get; set; } = string.Empty;

	public byte[]? Bytes { get; set; }

	[ObservableProperty]
	private ImageSource? _thumb;
}
