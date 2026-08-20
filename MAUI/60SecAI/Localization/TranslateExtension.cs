namespace _60SecAI.Localization;

/// <summary>Extension XAML : <c>{loc:Translate MaClef}</c> → texte traduit qui se met à jour au changement de langue.</summary>
[ContentProperty(nameof(Key))]
public class TranslateExtension : IMarkupExtension<BindingBase>
{
	public string Key { get; set; } = string.Empty;

	public BindingBase ProvideValue(IServiceProvider serviceProvider) => new Binding
	{
		Mode = BindingMode.OneWay,
		Path = $"[{Key}]",
		Source = LocalizationResourceManager.Instance,
	};

	object IMarkupExtension.ProvideValue(IServiceProvider serviceProvider)
		=> ProvideValue(serviceProvider);
}
