namespace _60SecAI.Controls;

public partial class KpiCard : ContentView
{
	public static readonly BindableProperty TitleProperty =
		BindableProperty.Create(nameof(Title), typeof(string), typeof(KpiCard), string.Empty);

	public static readonly BindableProperty ValueProperty =
		BindableProperty.Create(nameof(Value), typeof(string), typeof(KpiCard), string.Empty);

	public static readonly BindableProperty IconProperty =
		BindableProperty.Create(nameof(Icon), typeof(string), typeof(KpiCard), string.Empty, propertyChanged: OnVisualChanged);

	public static readonly BindableProperty IconBgProperty =
		BindableProperty.Create(nameof(IconBg), typeof(Color), typeof(KpiCard), Colors.Transparent);

	public static readonly BindableProperty DeltaProperty =
		BindableProperty.Create(nameof(Delta), typeof(string), typeof(KpiCard), string.Empty, propertyChanged: OnVisualChanged);

	public static readonly BindableProperty SubtitleProperty =
		BindableProperty.Create(nameof(Subtitle), typeof(string), typeof(KpiCard), string.Empty, propertyChanged: OnVisualChanged);

	public static readonly BindableProperty HealthProperty =
		BindableProperty.Create(nameof(Health), typeof(string), typeof(KpiCard), string.Empty);

	public static readonly BindableProperty HealthKindProperty =
		BindableProperty.Create(nameof(HealthKind), typeof(string), typeof(KpiCard), "good", propertyChanged: OnVisualChanged);

	public string Title { get => (string)GetValue(TitleProperty); set => SetValue(TitleProperty, value); }
	public string Value { get => (string)GetValue(ValueProperty); set => SetValue(ValueProperty, value); }
	public string Icon { get => (string)GetValue(IconProperty); set => SetValue(IconProperty, value); }
	public Color IconBg { get => (Color)GetValue(IconBgProperty); set => SetValue(IconBgProperty, value); }
	public string Delta { get => (string)GetValue(DeltaProperty); set => SetValue(DeltaProperty, value); }
	public string Subtitle { get => (string)GetValue(SubtitleProperty); set => SetValue(SubtitleProperty, value); }
	public string Health { get => (string)GetValue(HealthProperty); set => SetValue(HealthProperty, value); }
	public string HealthKind { get => (string)GetValue(HealthKindProperty); set => SetValue(HealthKindProperty, value); }

	public KpiCard()
	{
		InitializeComponent();
		UpdateVisual();
	}

	private static void OnVisualChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is KpiCard card)
		{
			card.UpdateVisual();
		}
	}

	private void UpdateVisual()
	{
		IconBadge.IsVisible = !string.IsNullOrEmpty(Icon);
		DeltaLabel.IsVisible = !string.IsNullOrEmpty(Delta);
		SubtitleLabel.IsVisible = !string.IsNullOrEmpty(Subtitle);

		var (bg, fg, icon) = HealthKind switch
		{
			"watch" => ("#FEF6E7", "#B9770E", "⚠"),
			"alert" => ("#FDECEC", "#C0392B", "⚠"),
			_ => ("#E7F7EF", "#1E8449", "✓"),
		};

		HealthBadge.BackgroundColor = Color.FromArgb(bg);
		HealthIcon.Text = icon;
		HealthIcon.TextColor = Color.FromArgb(fg);
		HealthLabel.TextColor = Color.FromArgb(fg);
	}
}
