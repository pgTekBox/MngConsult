namespace _60SecAI;

public partial class NewAppointmentPage : ContentPage
{
	public NewAppointmentPage()
	{
		InitializeComponent();
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");

	private async void OnSaveClicked(object? sender, EventArgs e)
	{
		var client = string.IsNullOrWhiteSpace(ClientEntry.Text) ? "Client" : ClientEntry.Text.Trim();
		await DisplayAlertAsync("Agenda", $"Rendez-vous ajouté pour {client}.", "OK");
		await Shell.Current.GoToAsync("..");
	}
}
