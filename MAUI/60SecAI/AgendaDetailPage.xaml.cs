namespace _60SecAI;

public partial class AgendaDetailPage : ContentPage
{
	public AgendaDetailPage()
	{
		InitializeComponent();
	}

	private void OnViewToggle(object? sender, TappedEventArgs e)
	{
		var isJournee = (e.Parameter as string) == "Journée";

		ViewJournee.BackgroundColor = isJournee
			? (Application.Current?.RequestedTheme == AppTheme.Dark ? Color.FromArgb("#3A3450") : Colors.White)
			: Colors.Transparent;
		ViewJourneeLabel.TextColor = isJournee ? Color.FromArgb("#3B5BDB") : Color.FromArgb("#6E6E6E");

		ViewSemaine.BackgroundColor = isJournee
			? Colors.Transparent
			: (Application.Current?.RequestedTheme == AppTheme.Dark ? Color.FromArgb("#3A3450") : Colors.White);
		ViewSemaineLabel.TextColor = isJournee ? Color.FromArgb("#6E6E6E") : Color.FromArgb("#3B5BDB");
	}

	private async void OnAddAppointmentClicked(object? sender, EventArgs e)
		=> await Shell.Current.GoToAsync(nameof(NewAppointmentPage));

	private async void OnPrevDay(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("Agenda", "Jour précédent.", "OK");

	private async void OnNextDay(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("Agenda", "Jour suivant.", "OK");
}
