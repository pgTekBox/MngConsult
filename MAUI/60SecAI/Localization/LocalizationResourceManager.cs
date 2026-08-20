using System.ComponentModel;
using System.Globalization;

namespace _60SecAI.Localization;

/// <summary>
/// Gestionnaire de langue courant. Expose un indexeur <c>this[key]</c> lié dans le XAML
/// via l'extension <see cref="TranslateExtension"/>. Le changement de langue rafraîchit
/// automatiquement toutes les liaisons et persiste le choix.
/// </summary>
public class LocalizationResourceManager : INotifyPropertyChanged
{
	private const string PrefKey = "app_language";

	public static LocalizationResourceManager Instance { get; } = new();

	public string CurrentLanguage { get; private set; }

	private LocalizationResourceManager()
	{
		CurrentLanguage = Preferences.Default.Get(PrefKey, "fr");
		ApplyCulture(CurrentLanguage);
	}

	public string this[string key] => AppStrings.Get(CurrentLanguage, key);

	public void SetLanguage(string language)
	{
		if (string.IsNullOrWhiteSpace(language) || language == CurrentLanguage)
		{
			return;
		}

		CurrentLanguage = language;
		Preferences.Default.Set(PrefKey, language);
		ApplyCulture(language);

		// null => rafraîchit toutes les liaisons (dont l'indexeur).
		PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
	}

	private static void ApplyCulture(string language)
	{
		try
		{
			var culture = CultureInfo.GetCultureInfo(language);
			CultureInfo.CurrentUICulture = culture;
		}
		catch (CultureNotFoundException)
		{
			// Langue inconnue : on ignore.
		}
	}

	public event PropertyChangedEventHandler? PropertyChanged;
}
