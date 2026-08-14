namespace _60SecAI.Controls;

public partial class PaymentRow : ContentView
{
	public static readonly BindableProperty DayProperty =
		BindableProperty.Create(nameof(Day), typeof(string), typeof(PaymentRow), string.Empty);

	public static readonly BindableProperty MonthProperty =
		BindableProperty.Create(nameof(Month), typeof(string), typeof(PaymentRow), string.Empty);

	public static readonly BindableProperty PayerProperty =
		BindableProperty.Create(nameof(Payer), typeof(string), typeof(PaymentRow), string.Empty);

	public static readonly BindableProperty AmountProperty =
		BindableProperty.Create(nameof(Amount), typeof(string), typeof(PaymentRow), string.Empty);

	public static readonly BindableProperty DetailProperty =
		BindableProperty.Create(nameof(Detail), typeof(string), typeof(PaymentRow), string.Empty);

	public static readonly BindableProperty CategoryProperty =
		BindableProperty.Create(nameof(Category), typeof(string), typeof(PaymentRow), "Gouv.");

	public static readonly BindableProperty DelayTextProperty =
		BindableProperty.Create(nameof(DelayText), typeof(string), typeof(PaymentRow), "3–5 j ouv.");

	public string Day { get => (string)GetValue(DayProperty); set => SetValue(DayProperty, value); }
	public string Month { get => (string)GetValue(MonthProperty); set => SetValue(MonthProperty, value); }
	public string Payer { get => (string)GetValue(PayerProperty); set => SetValue(PayerProperty, value); }
	public string Amount { get => (string)GetValue(AmountProperty); set => SetValue(AmountProperty, value); }
	public string Detail { get => (string)GetValue(DetailProperty); set => SetValue(DetailProperty, value); }
	public string Category { get => (string)GetValue(CategoryProperty); set => SetValue(CategoryProperty, value); }
	public string DelayText { get => (string)GetValue(DelayTextProperty); set => SetValue(DelayTextProperty, value); }

	public PaymentRow()
	{
		InitializeComponent();
	}

	private async void OnPayTapped(object? sender, TappedEventArgs e)
	{
		if (Application.Current?.Windows.Count > 0 &&
			Application.Current.Windows[0].Page is Page page)
		{
			await page.DisplayAlertAsync("AI Payment", $"Payer {Payer} — {Amount}.", "OK");
		}
	}
}
