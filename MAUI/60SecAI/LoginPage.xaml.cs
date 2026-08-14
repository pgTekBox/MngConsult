using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

public partial class LoginPage : ContentPage
{
	public LoginPage()
	{
		InitializeComponent();
		BindingContext = ServiceHelper.GetService<LoginViewModel>();
	}
}
