namespace _60SecAI.Controls;

public partial class ServiceChip : ContentView
{
	public static readonly BindableProperty IconProperty =
		BindableProperty.Create(nameof(Icon), typeof(string), typeof(ServiceChip), string.Empty);

	public static readonly BindableProperty AccentProperty =
		BindableProperty.Create(nameof(Accent), typeof(Color), typeof(ServiceChip), Colors.Gray);

	public static readonly BindableProperty ServiceNameProperty =
		BindableProperty.Create(nameof(ServiceName), typeof(string), typeof(ServiceChip), string.Empty);

	public static readonly BindableProperty DurationProperty =
		BindableProperty.Create(nameof(Duration), typeof(string), typeof(ServiceChip), string.Empty);

	public string Icon { get => (string)GetValue(IconProperty); set => SetValue(IconProperty, value); }
	public Color Accent { get => (Color)GetValue(AccentProperty); set => SetValue(AccentProperty, value); }
	public string ServiceName { get => (string)GetValue(ServiceNameProperty); set => SetValue(ServiceNameProperty, value); }
	public string Duration { get => (string)GetValue(DurationProperty); set => SetValue(DurationProperty, value); }

	public ServiceChip()
	{
		InitializeComponent();
	}

	private async void OnTapped(object? sender, TappedEventArgs e)
	{
		if (Application.Current?.Windows.Count > 0 &&
			Application.Current.Windows[0].Page is Page page)
		{
			await page.DisplayAlertAsync("Services", $"{ServiceName} · {Duration}", "OK");
		}
	}
}
