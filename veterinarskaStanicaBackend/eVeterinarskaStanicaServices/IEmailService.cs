using System.Threading.Tasks;

namespace eVeterinarskaStanicaServices
{
    public interface IEmailService
    {
        /// <summary>
        /// Send 2FA verification code to user's email
        /// </summary>
        /// <param name="email">User's email address</param>
        /// <param name="code">6-digit verification code</param>
        /// <param name="userName">User's name for personalization</param>
        /// <returns>True if email sent successfully</returns>
        Task<bool> Send2FACodeAsync(string email, string code, string userName);

        /// <summary>
        /// Send general email
        /// </summary>
        /// <param name="to">Recipient email</param>
        /// <param name="subject">Email subject</param>
        /// <param name="body">Email body (HTML)</param>
        /// <returns>True if email sent successfully</returns>
        Task<bool> SendEmailAsync(string to, string subject, string body);

        /// <summary>
        /// Send password reset email
        /// </summary>
        /// <param name="email">User's email</param>
        /// <param name="resetToken">Password reset token</param>
        /// <param name="userName">User's name</param>
        /// <returns>True if email sent successfully</returns>
        Task<bool> SendPasswordResetAsync(string email, string resetToken, string userName);

        /// <summary>
        /// Send email verification code for registration
        /// </summary>
        /// <param name="email">User's email address</param>
        /// <param name="code">6-digit verification code</param>
        /// <param name="userName">User's name for personalization</param>
        /// <returns>True if email sent successfully</returns>
        Task<bool> SendEmailVerificationCodeAsync(string email, string code, string userName);

        /// <summary>
        /// Send email verification link instead of numeric code
        /// </summary>
        /// <param name="email">User's email address</param>
        /// <param name="token">Secure verification token</param>
        /// <param name="userName">User's name for personalization</param>
        /// <returns>True if email sent successfully</returns>
        Task<bool> SendEmailVerificationLinkAsync(string email, string token, string userName);
    }
}
