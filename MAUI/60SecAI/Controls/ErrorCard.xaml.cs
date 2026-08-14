namespace _60SecAI.Controls;

public partial class ErrorCard : ContentView
{
	public static readonly BindableProperty AccentProperty =
		BindableProperty.Create(nameof(Accent), typeof(Color), typeof(ErrorCard), Colors.Red);

	public static readonly BindableProperty IconBgProperty =
		BindableProperty.Create(nameof(IconBg), typeof(Color), typeof(ErrorCard), Colors.LightGray);

	public static readonly BindableProperty IconProperty =
		BindableProperty.Create(nameof(Icon), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty CodeProperty =
		BindableProperty.Create(nameof(Code), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty TypeTextProperty =
		BindableProperty.Create(nameof(TypeText), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty TypeBgProperty =
		BindableProperty.Create(nameof(TypeBg), typeof(Color), typeof(ErrorCard), Colors.LightGray);

	public static readonly BindableProperty TypeFgProperty =
		BindableProperty.Create(nameof(TypeFg), typeof(Color), typeof(ErrorCard), Colors.Gray);

	public static readonly BindableProperty CriticalProperty =
		BindableProperty.Create(nameof(Critical), typeof(bool), typeof(ErrorCard), true, propertyChanged: OnCriticalChanged);

	public static readonly BindableProperty TitleProperty =
		BindableProperty.Create(nameof(Title), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty SourceProperty =
		BindableProperty.Create(nameof(Source), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty AmountProperty =
		BindableProperty.Create(nameof(Amount), typeof(string), typeof(ErrorCard), string.Empty);

	public static readonly BindableProperty AccountProperty =
		BindableProperty.Create(nameof(Account), typeof(string), typeof(ErrorCard), string.Empty);

	public Color Accent { get => (Color)GetValue(AccentProperty); set => SetValue(AccentProperty, value); }
	public Color IconBg { get => (Color)GetValue(IconBgProperty); set => SetValue(IconBgProperty, value); }
	public string Icon { get => (string)GetValue(IconProperty); set => SetValue(IconProperty, value); }
	public string Code { get => (string)GetValue(CodeProperty); set => SetValue(CodeProperty, value); }
	public string TypeText { get => (string)GetValue(TypeTextProperty); set => SetValue(TypeTextProperty, value); }
	public Color TypeBg { get => (Color)GetValue(TypeBgProperty); set => SetValue(TypeBgProperty, value); }
	public Color TypeFg { get => (Color)GetValue(TypeFgProperty); set => SetValue(TypeFgProperty, value); }
	public bool Critical { get => (bool)GetValue(CriticalProperty); set => SetValue(CriticalProperty, value); }
	public string Title { get => (string)GetValue(TitleProperty); set => SetValue(TitleProperty, value); }
	public string Source { get => (string)GetValue(SourceProperty); set => SetValue(SourceProperty, value); }
	public string Amount { get => (string)GetValue(AmountProperty); set => SetValue(AmountProperty, value); }
	public string Account { get => (string)GetValue(AccountProperty); set => SetValue(AccountProperty, value); }

	public ErrorCard()
	{
		InitializeComponent();
		CritiqueBadge.IsVisible = Critical;
	}

	private static void OnCriticalChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is ErrorCard card)
		{
			card.CritiqueBadge.IsVisible = (bool)newValue;
		}
	}
}
