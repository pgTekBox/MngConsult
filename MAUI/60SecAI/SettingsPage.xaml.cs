using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

public partial class SettingsPage : ContentPage
{
	public SettingsPage()
	{
		InitializeComponent();
		BindingContext = ServiceHelper.GetService<SettingsViewModel>();
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");
}
