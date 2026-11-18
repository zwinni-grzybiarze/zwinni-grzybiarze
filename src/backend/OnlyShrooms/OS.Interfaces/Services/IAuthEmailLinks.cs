namespace OS.Interfaces.Services;

public interface IAuthEmailLinks
{
    string ConfirmEmailApiUrl(string rawToken);
    string ResetPasswordFrontendUrl(string rawToken);
}
