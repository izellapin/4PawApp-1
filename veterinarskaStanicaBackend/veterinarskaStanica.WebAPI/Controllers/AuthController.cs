using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        /// <summary>
        /// Login endpoint for both Desktop Admin and Mobile User
        /// </summary>
        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.LoginAsync(request);
            
            if (!result.Success)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            // Set additional response headers based on client type
            if (request.ClientType == "Desktop")
            {
                Response.Headers["Client-Type"] = "Desktop";
            }
            else if (request.ClientType == "Mobile")
            {
                Response.Headers["Client-Type"] = "Mobile";
            }

            return Ok(result.Data);
        }

        /// <summary>
        /// Refresh access token
        /// </summary>
        [HttpPost("refresh")]
        public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] string refreshToken)
        {
            var result = await _authService.RefreshTokenAsync(refreshToken);
            
            if (!result.Success)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            return Ok(result.Data);
        }

        /// <summary>
        /// Logout and invalidate refresh token
        /// </summary>
        [HttpPost("logout")]
        [Authorize]
        public async Task<ActionResult> Logout([FromBody] string refreshToken)
        {
            var result = await _authService.LogoutAsync(refreshToken);
            
            if (!result.Success)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            return Ok(new { message = "Logged out successfully" });
        }

        /// <summary>
        /// Change password for authenticated user
        /// </summary>
        [HttpPost("change-password")]
        [Authorize]
        public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Invalid user token");
            }

            var result = await _authService.ChangePasswordAsync(userId, request.CurrentPassword, request.NewPassword);
            
            if (!result.Success)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            return Ok(new { message = "Password changed successfully" });
        }

        /// <summary>
        /// Get current user info (useful for token validation)
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult> GetCurrentUser()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Invalid user token");
            }

            var result = await _authService.GetUserByIdAsync(userId);
            if (!result.Success)
            {
                return NotFound(result.ErrorMessage);
            }

            var user = result.Data;
            return Ok(new
            {
                id = user.Id,
                firstName = user.FirstName,
                lastName = user.LastName,
                email = user.Email,
                phoneNumber = user.PhoneNumber,
                address = user.Address,
                role = (int)user.Role,
                isActive = user.IsActive,
                isEmailVerified = user.IsEmailVerified,
                // Veterinarian specific fields
                licenseNumber = user.LicenseNumber,
                specialization = user.Specialization,
                yearsOfExperience = user.YearsOfExperience,
                biography = user.Biography
            });
        }

        /// <summary>
        /// Update current user profile
        /// </summary>
        [HttpPut("me")]
        [Authorize]
        public async Task<ActionResult> UpdateCurrentUser([FromBody] UpdateProfileRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Invalid user token");
            }

            var result = await _authService.UpdateUserProfileAsync(userId, request);
            if (!result.Success)
            {
                return BadRequest(result.ErrorMessage);
            }

            return Ok(new { message = "Profile updated successfully" });
        }

        /// <summary>
        /// Validate token endpoint
        /// </summary>
        [HttpPost("validate")]
        public async Task<ActionResult> ValidateToken([FromBody] string token)
        {
            var isValid = await _authService.ValidateTokenAsync(token);
            return Ok(new { isValid });
        }

        /// <summary>
        /// Initiate 2FA login - sends verification code to email
        /// </summary>
        [HttpPost("login-2fa")]
        public async Task<ActionResult> InitiateTwoFactorLogin([FromBody] LoginRequest request)
        {
            var result = await _authService.InitiateTwoFactorLoginAsync(request);
            
            if (result.Success)
            {
                // Set additional response headers based on client type
                if (request.ClientType == "Desktop")
                {
                    Response.Headers.Append("Client-Type", "Desktop");
                }
                else if (request.ClientType == "Mobile")
                {
                    Response.Headers.Append("Client-Type", "Mobile");
                }

                return Ok(result.Data);
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Verify 2FA code and complete login
        /// </summary>
        [HttpPost("verify-2fa")]
        public async Task<ActionResult> VerifyTwoFactorCode([FromBody] Verify2FARequest request)
        {
            var result = await _authService.VerifyTwoFactorCodeAsync(request);
            
            if (result.Success)
            {
                // Set additional response headers based on client type
                if (request.ClientType == "Desktop")
                {
                    Response.Headers.Append("Client-Type", "Desktop");
                }
                else if (request.ClientType == "Mobile")
                {
                    Response.Headers.Append("Client-Type", "Mobile");
                }

                return Ok(result.Data);
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Resend 2FA verification code
        /// </summary>
        [HttpPost("resend-2fa")]
        public async Task<ActionResult> ResendTwoFactorCode([FromBody] ResendCodeRequest request)
        {
            var result = await _authService.ResendTwoFactorCodeAsync(request.Email);
            
            if (result.Success)
            {
                return Ok(new { message = "New verification code sent to your email" });
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Register new user (primarily for mobile app users - PetOwners)
        /// </summary>
        [HttpPost("register")]
        public async Task<ActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.RegisterAsync(request);
            
            if (result.Success)
            {
                return Ok(new { 
                    message = result.Data.Message,
                    id = result.Data.UserId
                });
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Verify email address with verification code
        /// </summary>
        [HttpPost("verify-email")]
        public async Task<ActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.VerifyEmailAsync(request);
            
            if (result.Success)
            {
                return Ok(new { message = "Email verified successfully! You can now login." });
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Verify email via clickable link (token in query string)
        /// </summary>
        [HttpGet("verify-email")]
        public async Task<ActionResult> VerifyEmailByToken([FromQuery] string token)
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                return BadRequest(new { message = "Missing token" });
            }

            var result = await _authService.VerifyEmailByTokenAsync(token);
            if (result.Success)
            {
                return Ok(new { message = "Email verified successfully! You can now login." });
            }

            return BadRequest(new { message = result.ErrorMessage });
        }

        /// <summary>
        /// Resend email verification code
        /// </summary>
        [HttpPost("resend-email-verification")]
        public async Task<ActionResult> ResendEmailVerificationCode([FromBody] ResendEmailVerificationRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _authService.ResendEmailVerificationCodeAsync(request.Email);
            
            if (result.Success)
            {
                return Ok(new { message = "New verification code sent to your email." });
            }

            return BadRequest(new { message = result.ErrorMessage });
        }
    }

    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class ResendCodeRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }

    public class ResendEmailVerificationRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
