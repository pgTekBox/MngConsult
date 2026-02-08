using CommunityToolkit.Mvvm.Input;
using prjPhoto.Models;

namespace prjPhoto.PageModels
{
    public interface IProjectTaskPageModel
    {
        IAsyncRelayCommand<ProjectTask> NavigateToTaskCommand { get; }
        bool IsBusy { get; }
    }
}