using _60SecAI;
using _60SecAI.Localization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

public partial class LoginViewModel : BaseViewModel
{
	private static readonly Color ActiveLang = Color.FromArgb("#ECE4FB");

	private readonly AuthService _auth;

	[ObservableProperty]
	private string _username = string.Empty;

	[ObservableProperty]
	private string _password = string.Empty;

	[ObservableProperty]
	private bool _isPasswordHidden = true;

	[ObservableProperty] private Color _frBg = Colors.Transparent;
	[ObservableProperty] private Color _enBg = Colors.Transparent;
	[ObservableProperty] private Color _esBg = Colors.Transparent;

	public LoginViewModel(AuthService auth)
	{
		_auth = auth;
		UpdateLanguageHighlight();
	}

	[RelayCommand]
	private void SetLanguage(string language)
	{
		LocalizationResourceManager.Instance.SetLanguage(language);
		ErrorMessage = null;
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
	private async Task LoginAsync()
	{
		if (IsBusy)
		{
			return;
		}

		IsBusy = true;
		ErrorMessage = null;

		try
		{
			var result = await _auth.LoginAsync(Username.Trim(), Password);
			if (result is not null)
			{
				await Shell.Current.GoToAsync(nameof(DashboardPage));
			}
			else
			{
				ErrorMessage = LocalizationResourceManager.Instance["ErrorInvalid"];
			}
		}
		catch (Exception)
		{
			ErrorMessage = LocalizationResourceManager.Instance["ErrorServer"];
		}
		finally
		{
			IsBusy = false;
		}
	}

	[RelayCommand]
	private void TogglePasswordVisibility() => IsPasswordHidden = !IsPasswordHidden;

	[RelayCommand]
	private async Task ForgotPasswordAsync()
	{
		if (Application.Current?.Windows.Count > 0 &&
			Application.Current.Windows[0].Page is Page page)
		{
			await page.DisplayAlertAsync("60 Sec AI", LocalizationResourceManager.Instance["ForgotInfo"], "OK");
		}
	}
}
