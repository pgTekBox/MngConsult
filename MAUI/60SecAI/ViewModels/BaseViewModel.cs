using CommunityToolkit.Mvvm.ComponentModel;

namespace _60SecAI.ViewModels;

/// <summary>Base commune à tous les ViewModels (état occupé + message d'erreur).</summary>
public partial class BaseViewModel : ObservableObject
{
	[ObservableProperty]
	private bool _isBusy;

	[ObservableProperty]
	private string? _errorMessage;

	public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

	partial void OnErrorMessageChanged(string? value) => OnPropertyChanged(nameof(HasError));
}
