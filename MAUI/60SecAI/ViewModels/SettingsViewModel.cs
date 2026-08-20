using _60SecAI;
using _60SecAI.Localization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

public partial class SettingsViewModel : BaseViewModel
{
	private static readonly Color ActiveLang = Color.FromArgb("#ECE4FB");

	private readonly AuthService _auth;

	[ObservableProperty] private Color _frBg = Colors.Transparent;
	[ObservableProperty] private Color _enBg = Colors.Transparent;
	[ObservableProperty] private Color _esBg = Colors.Transparent;

	public SettingsViewModel(AuthService auth)
	{
		_auth = auth;
		UpdateLanguageHighlight();
	}

	[RelayCommand]
	private void SetLanguage(string language)
	{
		LocalizationResourceManager.Instance.SetLanguage(language);
		UpdateLanguageHighlight();
	}

	private void UpdateLanguageHighlight()
	{
		var lang = LocalizationResourceManager.Instance.CurrentLanguage;
		FrBg = lang == "fr" ? ActiveLang : Colors.Transparent;
		EnBg = lang == "en" ? ActiveLang : Colors.Transparent;
		EsBg = lang == "es" ? ActiveLang : Colors.Transparent;
	}

	[RelayCommand]
	private async Task LogoutAsync()
	{
		_auth.Logout();
		await Shell.Current.GoToAsync("//LoginPage");
	}
}
