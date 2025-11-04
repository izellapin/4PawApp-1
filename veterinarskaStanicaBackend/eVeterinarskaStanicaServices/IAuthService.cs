using System.Threading.Tasks;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;

namespace eVeterinarskaStanicaServices
{
    public interface IAuthService
    {
        Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request);
        Task<ServiceResult<AuthResponse>> RefreshTokenAsync(string refreshToken);
        Task<ServiceResult> LogoutAsync(string refreshToken);
        Task<ServiceResult> ChangePasswordAsync(int userId, string currentPassword, string newPassword);
        Task<bool> ValidateTokenAsync(string token);
        string[] GetRolePermissions(UserRole role);
        
        // Registration Methods
        Task<ServiceResult<RegisterResponse>> RegisterAsync(RegisterRequest request);
        Task<ServiceResult> VerifyEmailAsync(VerifyEmailRequest request);
        Task<ServiceResult> VerifyEmailByTokenAsync(string token);
        Task<ServiceResult> ResendEmailVerificationCodeAsync(string email);
        
        // 2FA Methods
        Task<ServiceResult<Login2FAResponse>> InitiateTwoFactorLoginAsync(LoginRequest request);
        Task<ServiceResult<AuthResponse>> VerifyTwoFactorCodeAsync(Verify2FARequest request);
        Task<ServiceResult> ResendTwoFactorCodeAsync(string email);
        
        // Profile Management
        Task<ServiceResult<User>> GetUserByIdAsync(int userId);
        Task<ServiceResult> UpdateUserProfileAsync(int userId, UpdateProfileRequest request);
    }
}
