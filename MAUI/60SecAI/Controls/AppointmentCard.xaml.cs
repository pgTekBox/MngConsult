namespace _60SecAI.Controls;

public partial class AppointmentCard : ContentView
{
	public static readonly BindableProperty AccentProperty =
		BindableProperty.Create(nameof(Accent), typeof(Color), typeof(AppointmentCard), Colors.MediumPurple);

	public static readonly BindableProperty AvatarBgProperty =
		BindableProperty.Create(nameof(AvatarBg), typeof(Color), typeof(AppointmentCard), Colors.LightGray);

	public static readonly BindableProperty AvatarProperty =
		BindableProperty.Create(nameof(Avatar), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty PersonNameProperty =
		BindableProperty.Create(nameof(PersonName), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty TradeProperty =
		BindableProperty.Create(nameof(Trade), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty StatusProperty =
		BindableProperty.Create(nameof(Status), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty TimeProperty =
		BindableProperty.Create(nameof(Time), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty TimeRangeProperty =
		BindableProperty.Create(nameof(TimeRange), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty DurationProperty =
		BindableProperty.Create(nameof(Duration), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty ExtraProperty =
		BindableProperty.Create(nameof(Extra), typeof(string), typeof(AppointmentCard), string.Empty);

	public static readonly BindableProperty ShowActionsProperty =
		BindableProperty.Create(nameof(ShowActions), typeof(bool), typeof(AppointmentCard), true);

	public Color Accent { get => (Color)GetValue(AccentProperty); set => SetValue(AccentProperty, value); }
	public Color AvatarBg { get => (Color)GetValue(AvatarBgProperty); set => SetValue(AvatarBgProperty, value); }
	public string Avatar { get => (string)GetValue(AvatarProperty); set => SetValue(AvatarProperty, value); }
	public string PersonName { get => (string)GetValue(PersonNameProperty); set => SetValue(PersonNameProperty, value); }
	public string Trade { get => (string)GetValue(TradeProperty); set => SetValue(TradeProperty, value); }
	public string Status { get => (string)GetValue(StatusProperty); set => SetValue(StatusProperty, value); }
	public string Time { get => (string)GetValue(TimeProperty); set => SetValue(TimeProperty, value); }
	public string TimeRange { get => (string)GetValue(TimeRangeProperty); set => SetValue(TimeRangeProperty, value); }
	public string Duration { get => (string)GetValue(DurationProperty); set => SetValue(DurationProperty, value); }
	public string Extra { get => (string)GetValue(ExtraProperty); set => SetValue(ExtraProperty, value); }
	public bool ShowActions { get => (bool)GetValue(ShowActionsProperty); set => SetValue(ShowActionsProperty, value); }

	public AppointmentCard()
	{
		InitializeComponent();
	}

	private Task AlertAsync(string message)
	{
		if (Application.Current?.Windows.Count > 0 &&
			Application.Current.Windows[0].Page is Page page)
		{
			return page.DisplayAlertAsync("Agenda", message, "OK");
		}

		return Task.CompletedTask;
	}

	private async void OnFactureTapped(object? sender, TappedEventArgs e)
		=> await AlertAsync($"Facture — {PersonName}.");

	private async void OnPayerTapped(object? sender, TappedEventArgs e)
		=> await AlertAsync($"Payer — {PersonName}.");
}
