
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.Notifications;
using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace eVeterinarskaStanicaServices
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IHashingService _hashingService;
        private readonly IConfiguration _configuration;
        private readonly IUserService _userService;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthService> _logger;
        private readonly INotificationPublisherService _notificationPublisher;

        public AuthService(
            ApplicationDbContext context,
            IHashingService hashingService,
            IConfiguration configuration,
            IUserService userService,
            IEmailService emailService,
            ILogger<AuthService> logger,
            INotificationPublisherService notificationPublisher)
        {
            _context = context;
            _hashingService = hashingService;
            _configuration = configuration;
            _userService = userService;
            _emailService = emailService;
            _logger = logger;
            _notificationPublisher = notificationPublisher;
        }

        public async Task<ServiceResult<AuthResponse>> LoginAsync(LoginRequest request)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

                if (user == null)
                    return ServiceResult<AuthResponse>.ErrorResult("Invalid email or password");

                if (!_hashingService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
                    return ServiceResult<AuthResponse>.ErrorResult("Invalid email or password");

                // Send email verification only for mobile users (not for desktop/veterinarians)
                // Also check if we already sent a verification code recently (within last 5 minutes)
                var recentCode = await _context.EmailVerificationCodes
                    .FirstOrDefaultAsync(e => e.UserId == user.Id && 
                                             !e.IsUsed && 
                                             e.CreatedAt > DateTime.UtcNow.AddMinutes(-5));
                
                var isMobileClient = string.IsNullOrEmpty(request.ClientType) || 
                                   request.ClientType.Equals("Mobile", StringComparison.OrdinalIgnoreCase);
                
                if (!user.IsEmailVerified)
                {
                    try
                    {
                        // Only send/resend if we haven't sent one very recently
                        if (recentCode == null)
                        {
                            var verificationCode = GenerateEmailVerificationToken();
                        var expirationMinutes = int.Parse(_configuration["EmailVerification:CodeExpirationMinutes"] ?? "30");
                        var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

                        // Check if verification code already exists
                        var existingCode = await _context.EmailVerificationCodes
                            .FirstOrDefaultAsync(e => e.UserId == user.Id && !e.IsUsed);

                        if (existingCode != null)
                        {
                            existingCode.Code = verificationCode;
                            existingCode.CreatedAt = DateTime.UtcNow;
                            existingCode.ExpiresAt = expiresAt;
                            existingCode.FailedAttempts = 0;
                        }
                        else
                        {
                            var emailVerification = new EmailVerificationCode
                            {
                                UserId = user.Id,
                                Code = verificationCode,
                                CreatedAt = DateTime.UtcNow,
                                ExpiresAt = expiresAt,
                                IsUsed = false,
                                FailedAttempts = 0
                            };
                            _context.EmailVerificationCodes.Add(emailVerification);
                        }

                        await _context.SaveChangesAsync();

                            var emailSent = await _emailService.SendEmailVerificationLinkAsync(
                            user.Email,
                            verificationCode,
                            $"{user.FirstName} {user.LastName}".Trim()
                        );

                        if (emailSent)
                                _logger?.LogInformation("Email verification link sent to {Email} on login", user.Email);
                        else
                                _logger?.LogWarning("Failed to send email verification link to {Email} on login", user.Email);
                        }
                    }
                    catch (Exception emailEx)
                    {
                        _logger?.LogError(emailEx, "Failed to send email verification to {Email} on first login", user.Email);
                    }

                    // Block mobile login until email is verified
                    return ServiceResult<AuthResponse>.ErrorResult("Email not verified. We've sent you a verification link.");
                }

                // Generate tokens
                var accessToken = GenerateAccessToken(user);
                var refreshToken = GenerateRefreshToken();

                user.LastLoginDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                var expirationHours = int.Parse(_configuration["JWT:ExpirationHours"] ?? "1");

                var response = new AuthResponse
                {
                    UserId = user.Id,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Email = user.Email,
                    Username = user.Username,
                    Role = user.Role,
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    TokenExpiration = DateTime.UtcNow.AddHours(expirationHours),
                    IsActive = user.IsActive,
                    IsEmailVerified = user.IsEmailVerified,
                    Permissions = GetRolePermissions(user.Role)
                };

                return ServiceResult<AuthResponse>.SuccessResult(response);
            }
            catch (Exception ex)
            {
                return ServiceResult<AuthResponse>.ErrorResult($"Login failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult<AuthResponse>> RefreshTokenAsync(string refreshToken)
        {
            await Task.CompletedTask;
            return ServiceResult<AuthResponse>.ErrorResult("Refresh token implementation needed");
        }

        public async Task<ServiceResult> LogoutAsync(string refreshToken)
        {
            await Task.CompletedTask;
            return ServiceResult.SuccessResult();
        }

        public async Task<ServiceResult> ChangePasswordAsync(int userId, string currentPassword, string newPassword)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                    return ServiceResult.ErrorResult("User not found");

                if (!_hashingService.VerifyPassword(currentPassword, user.PasswordHash, user.PasswordSalt))
                    return ServiceResult.ErrorResult("Current password is incorrect");

                var newHash = _hashingService.HashPassword(newPassword, out byte[] newSalt);
                user.PasswordHash = newHash;
                user.PasswordSalt = Convert.ToBase64String(newSalt);

                await _context.SaveChangesAsync();
                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Password change failed: {ex.Message}");
            }
        }

        public async Task<bool> ValidateTokenAsync(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();

                var secret = _configuration["JWT:Secret"];
                if (string.IsNullOrWhiteSpace(secret))
                    return false;

                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));

                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = key,
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ValidAlgorithms = new[] { SecurityAlgorithms.HmacSha256 },
                    ClockSkew = TimeSpan.Zero,
                    ValidateLifetime = true
                }, out _);

                return true;
            }
            catch
            {
                return false;
            }
        }

        public string[] GetRolePermissions(UserRole role)
        {
            return role switch
            {
                UserRole.Admin => new[]
                {
                    "users.create", "users.read", "users.update", "users.delete",
                    "pets.create", "pets.read", "pets.update", "pets.delete",
                    "appointments.create", "appointments.read", "appointments.update", "appointments.delete",
                    "services.create", "services.read", "services.update", "services.delete",
                    "categories.create", "categories.read", "categories.update", "categories.delete",
                    "orders.create", "orders.read", "orders.update", "orders.delete",
                    "reports.read", "settings.update", "system.admin"
                },
                UserRole.Veterinarian => new[]
                {
                    "pets.read", "pets.update",
                    "appointments.read", "appointments.update",
                    "medical-records.create", "medical-records.read", "medical-records.update",
                    "prescriptions.create", "prescriptions.read", "prescriptions.update",
                    "services.read", "users.read"
                },
                UserRole.VetTechnician => new[]
                {
                    "pets.read", "pets.update",
                    "appointments.read", "appointments.update",
                    "medical-records.read", "services.read"
                },
                UserRole.Receptionist => new[]
                {
                    "appointments.create", "appointments.read", "appointments.update",
                    "users.create", "users.read", "users.update",
                    "pets.create", "pets.read", "pets.update",
                    "services.read", "orders.create", "orders.read"
                },
                UserRole.PetOwner => new[]
                {
                    "pets.read", "appointments.create", "appointments.read",
                    "services.read", "orders.create", "orders.read",
                    "profile.update", "favorites.manage"
                },
                _ => Array.Empty<string>()
            };
        }

        private string GenerateAccessToken(User user)
        {
            var secret = _configuration["JWT:Secret"];
            if (string.IsNullOrWhiteSpace(secret))
                throw new InvalidOperationException("JWT:Secret is not configured.");

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, user.Username),
                new(ClaimTypes.GivenName, user.FirstName),
                new(ClaimTypes.Surname, user.LastName),
                new(ClaimTypes.Role, user.Role.ToString()),
                new("user_id", user.Id.ToString()),
                new("role_id", ((int)user.Role).ToString())
            };

            var permissions = GetRolePermissions(user.Role);
            claims.AddRange(permissions.Select(p => new Claim("permission", p)));

            var expirationHours = int.Parse(_configuration["JWT:ExpirationHours"] ?? "1");

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(expirationHours),
                SigningCredentials = creds
                // If you later enable issuer/audience validation, add:
                // Issuer = _configuration["JWT:Issuer"],
                // Audience = _configuration["JWT:Audience"]
            };

            var handler = new JwtSecurityTokenHandler();
            var token = handler.CreateToken(tokenDescriptor);
            return handler.WriteToken(token);
        }

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        public async Task<ServiceResult<Login2FAResponse>> InitiateTwoFactorLoginAsync(LoginRequest request)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

                if (user == null)
                    return ServiceResult<Login2FAResponse>.ErrorResult("Invalid email or password");

                if (!_hashingService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
                    return ServiceResult<Login2FAResponse>.ErrorResult("Invalid email or password");

                var code = GenerateTwoFactorCode();
                var expirationMinutes = int.Parse(_configuration["TwoFactor:CodeExpirationMinutes"] ?? "10");
                var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

                var oldCodes = await _context.TwoFactorCodes
                    .Where(tfc => tfc.UserId == user.Id)
                    .ToListAsync();
                _context.TwoFactorCodes.RemoveRange(oldCodes);

                var twoFactorCode = new TwoFactorCode
                {
                    UserId = user.Id,
                    Code = code,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = expiresAt,
                    ClientType = request.ClientType,
                    IsUsed = false
                };

                _context.TwoFactorCodes.Add(twoFactorCode);
                await _context.SaveChangesAsync();

                var emailSent = await _emailService.Send2FACodeAsync(
                    user.Email,
                    code,
                    $"{user.FirstName} {user.LastName}".Trim()
                );

                if (!emailSent)
                    return ServiceResult<Login2FAResponse>.ErrorResult("Failed to send verification code. Please try again.");

                var response = new Login2FAResponse
                {
                    RequiresTwoFactor = true,
                    Message = "Verification code sent to your email. Please check your inbox.",
                    UserId = user.Id,
                    Email = user.Email,
                    CodeExpiresAt = expiresAt,
                    RemainingAttempts = int.Parse(_configuration["TwoFactor:MaxFailedAttempts"] ?? "3")
                };

                return ServiceResult<Login2FAResponse>.SuccessResult(response);
            }
            catch (Exception ex)
            {
                return ServiceResult<Login2FAResponse>.ErrorResult($"Login failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult<AuthResponse>> VerifyTwoFactorCodeAsync(Verify2FARequest request)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

                if (user == null)
                    return ServiceResult<AuthResponse>.ErrorResult("Invalid verification attempt");

                var twoFactorCode = await _context.TwoFactorCodes
                    .FirstOrDefaultAsync(tfc =>
                        tfc.UserId == user.Id &&
                        tfc.Code == request.Code &&
                        !tfc.IsUsed &&
                        tfc.ExpiresAt > DateTime.UtcNow);

                if (twoFactorCode == null)
                {
                    var userCodes = await _context.TwoFactorCodes
                        .Where(tfc => tfc.UserId == user.Id && !tfc.IsUsed)
                        .ToListAsync();

                    foreach (var code in userCodes)
                        code.FailedAttempts++;

                    await _context.SaveChangesAsync();

                    return ServiceResult<AuthResponse>.ErrorResult("Invalid or expired verification code");
                }

                twoFactorCode.IsUsed = true;
                twoFactorCode.UsedAt = DateTime.UtcNow;

                user.LastLoginDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                var accessToken = GenerateAccessToken(user);
                var refreshToken = GenerateRefreshToken();
                var expirationHours = int.Parse(_configuration["JWT:ExpirationHours"] ?? "1");

                var response = new AuthResponse
                {
                    UserId = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role,
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    TokenExpiration = DateTime.UtcNow.AddHours(expirationHours),
                    IsActive = user.IsActive,
                    IsEmailVerified = user.IsEmailVerified,
                    Permissions = GetRolePermissions(user.Role)
                };

                return ServiceResult<AuthResponse>.SuccessResult(response);
            }
            catch (Exception ex)
            {
                return ServiceResult<AuthResponse>.ErrorResult($"Verification failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult> ResendTwoFactorCodeAsync(string email)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

                if (user == null)
                    return ServiceResult.ErrorResult("User not found");

                var cooldownMinutes = int.Parse(_configuration["TwoFactor:ResendCooldownMinutes"] ?? "1");
                var recentCode = await _context.TwoFactorCodes
                    .Where(tfc => tfc.UserId == user.Id &&
                                  tfc.CreatedAt > DateTime.UtcNow.AddMinutes(-cooldownMinutes))
                    .OrderByDescending(tfc => tfc.CreatedAt)
                    .FirstOrDefaultAsync();

                if (recentCode != null)
                {
                    var remainingTime = recentCode.CreatedAt.AddMinutes(cooldownMinutes) - DateTime.UtcNow;
                    return ServiceResult.ErrorResult($"Please wait {remainingTime.TotalSeconds:F0} seconds before requesting a new code");
                }

                var code = GenerateTwoFactorCode();
                var expirationMinutes = int.Parse(_configuration["TwoFactor:CodeExpirationMinutes"] ?? "10");
                var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

                var oldCodes = await _context.TwoFactorCodes
                    .Where(tfc => tfc.UserId == user.Id && !tfc.IsUsed)
                    .ToListAsync();
                _context.TwoFactorCodes.RemoveRange(oldCodes);

                var twoFactorCode = new TwoFactorCode
                {
                    UserId = user.Id,
                    Code = code,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = expiresAt,
                    IsUsed = false
                };

                _context.TwoFactorCodes.Add(twoFactorCode);
                await _context.SaveChangesAsync();

                var emailSent = await _emailService.Send2FACodeAsync(
                    user.Email,
                    code,
                    $"{user.FirstName} {user.LastName}".Trim()
                );

                if (!emailSent)
                    return ServiceResult.ErrorResult("Failed to send verification code. Please try again.");

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Failed to resend code: {ex.Message}");
            }
        }

        private string GenerateTwoFactorCode()
        {
            var random = new Random();
            return random.Next(100000, 999999).ToString();
        }

        public async Task<ServiceResult<RegisterResponse>> RegisterAsync(RegisterRequest request)
        {
            try
            {
                var existingUserByEmail = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email);
                if (existingUserByEmail != null)
                    return ServiceResult<RegisterResponse>.ErrorResult("User with this email already exists");

                var existingUserByUsername = await _context.Users
                    .FirstOrDefaultAsync(u => u.Username == request.Username);
                if (existingUserByUsername != null)
                    return ServiceResult<RegisterResponse>.ErrorResult("Username is already taken");

                var hashedPassword = _hashingService.HashPassword(request.Password, out byte[] salt);

                var newUser = new User
                {
                    Email = request.Email,
                    Username = request.Username,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    PhoneNumber = request.PhoneNumber,
                    Address = request.Address,
                    PasswordHash = hashedPassword,
                    PasswordSalt = Convert.ToBase64String(salt),
                    Role = request.Role,
                    IsActive = true,
                    IsEmailVerified = false,
                    DateCreated = DateTime.UtcNow,
                    LastLoginDate = null
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                var verificationCode = GenerateEmailVerificationToken();
                var expirationMinutes = int.Parse(_configuration["EmailVerification:CodeExpirationMinutes"] ?? "30");
                var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

                var emailVerification = new EmailVerificationCode
                {
                    UserId = newUser.Id,
                    Code = verificationCode,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = expiresAt,
                    IsUsed = false,
                    FailedAttempts = 0
                };

                _context.EmailVerificationCodes.Add(emailVerification);
                await _context.SaveChangesAsync();

                // Send verification link immediately after registration
                try
                {
                    var emailSent = await _emailService.SendEmailVerificationLinkAsync(
                        newUser.Email,
                        verificationCode,
                        $"{newUser.FirstName} {newUser.LastName}".Trim()
                    );

                    if (emailSent)
                        _logger?.LogInformation("Verification link email sent to {Email}", newUser.Email);
                    else
                        _logger?.LogWarning("Verification link email failed for {Email}", newUser.Email);
                }
                catch (Exception emailEx)
                {
                    _logger?.LogError(emailEx, "Failed to send verification link to {Email}", newUser.Email);
                }

                return ServiceResult<RegisterResponse>.SuccessResult(new RegisterResponse
                {
                    UserId = newUser.Id,
                    Message = "Registration successful! You can now log in.",
                    Email = newUser.Email,
                    FirstName = newUser.FirstName,
                    LastName = newUser.LastName,
                    DateCreated = newUser.DateCreated
                });
            }
            catch (Exception ex)
            {
                var innerException = ex.InnerException?.Message ?? "No inner exception";
                var fullError = $"Registration failed: {ex.Message}. Inner: {innerException}";
                _logger?.LogError(ex, "Registration error for {Email}: {Error}", request.Email, fullError);

                return ServiceResult<RegisterResponse>.ErrorResult($"Registration failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult> VerifyEmailAsync(VerifyEmailRequest request)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

                if (user == null)
                    return ServiceResult.ErrorResult("User not found");

                if (user.IsEmailVerified)
                    return ServiceResult.ErrorResult("Email is already verified");

                var verificationCode = await _context.EmailVerificationCodes
                    .FirstOrDefaultAsync(evc =>
                        evc.UserId == user.Id &&
                        evc.Code == request.Code &&
                        !evc.IsUsed &&
                        evc.ExpiresAt > DateTime.UtcNow);

                if (verificationCode == null)
                {
                    var userCodes = await _context.EmailVerificationCodes
                        .Where(evc => evc.UserId == user.Id && !evc.IsUsed)
                        .ToListAsync();

                    foreach (var code in userCodes)
                        code.FailedAttempts++;

                    await _context.SaveChangesAsync();

                    return ServiceResult.ErrorResult("Invalid or expired verification code");
                }

                verificationCode.IsUsed = true;
                verificationCode.UsedAt = DateTime.UtcNow;
                user.IsEmailVerified = true;

                await _context.SaveChangesAsync();

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Email verification failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult> VerifyEmailByTokenAsync(string token)
        {
            try
            {
                var record = await _context.EmailVerificationCodes
                    .Include(e => e.User)
                    .FirstOrDefaultAsync(e => e.Code == token && !e.IsUsed && e.ExpiresAt > DateTime.UtcNow);

                if (record == null)
                {
                    return ServiceResult.ErrorResult("Invalid or expired verification link");
                }

                record.IsUsed = true;
                record.UsedAt = DateTime.UtcNow;
                record.User.IsEmailVerified = true;
                await _context.SaveChangesAsync();

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Email verification failed: {ex.Message}");
            }
        }

        public async Task<ServiceResult> ResendEmailVerificationCodeAsync(string email)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

                if (user == null)
                    return ServiceResult.ErrorResult("User not found");

                if (user.IsEmailVerified)
                    return ServiceResult.ErrorResult("Email is already verified");

                var cooldownMinutes = int.Parse(_configuration["EmailVerification:ResendCooldownMinutes"] ?? "2");
                var recentCode = await _context.EmailVerificationCodes
                    .Where(evc => evc.UserId == user.Id &&
                                  evc.CreatedAt > DateTime.UtcNow.AddMinutes(-cooldownMinutes))
                    .OrderByDescending(evc => evc.CreatedAt)
                    .FirstOrDefaultAsync();

                if (recentCode != null)
                {
                    var remainingTime = recentCode.CreatedAt.AddMinutes(cooldownMinutes) - DateTime.UtcNow;
                    return ServiceResult.ErrorResult($"Please wait {remainingTime.TotalSeconds:F0} seconds before requesting a new code");
                }

                var verificationCode = GenerateEmailVerificationToken();
                var expirationMinutes = int.Parse(_configuration["EmailVerification:CodeExpirationMinutes"] ?? "30");
                var expiresAt = DateTime.UtcNow.AddMinutes(expirationMinutes);

                var oldCodes = await _context.EmailVerificationCodes
                    .Where(evc => evc.UserId == user.Id && !evc.IsUsed)
                    .ToListAsync();
                _context.EmailVerificationCodes.RemoveRange(oldCodes);

                var emailVerification = new EmailVerificationCode
                {
                    UserId = user.Id,
                    Code = verificationCode,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = expiresAt,
                    IsUsed = false,
                    FailedAttempts = 0
                };

                _context.EmailVerificationCodes.Add(emailVerification);
                await _context.SaveChangesAsync();

                var emailSent = await _emailService.SendEmailVerificationLinkAsync(
                    user.Email,
                    verificationCode,
                    $"{user.FirstName} {user.LastName}".Trim()
                );

                if (!emailSent)
                    return ServiceResult.ErrorResult("Failed to send verification email. Please try again.");

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Failed to resend verification code: {ex.Message}");
            }
        }

        private string GenerateEmailVerificationCode()
        {
            var random = new Random();
            return random.Next(100000, 999999).ToString();
        }

        private string GenerateEmailVerificationToken()
        {
            var bytes = new byte[32];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            return Convert.ToBase64String(bytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .TrimEnd('=');
        }

        public async Task<ServiceResult<User>> GetUserByIdAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                if (user == null)
                {
                    return ServiceResult<User>.ErrorResult("User not found");
                }

                return ServiceResult<User>.SuccessResult(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by ID {UserId}", userId);
                return ServiceResult<User>.ErrorResult("Error retrieving user");
            }
        }

        public async Task<ServiceResult> UpdateUserProfileAsync(int userId, UpdateProfileRequest request)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                if (user == null)
                {
                    return ServiceResult.ErrorResult("User not found");
                }

                // Update basic fields if provided
                if (!string.IsNullOrEmpty(request.FirstName))
                    user.FirstName = request.FirstName;
                
                if (!string.IsNullOrEmpty(request.LastName))
                    user.LastName = request.LastName;
                
                if (!string.IsNullOrEmpty(request.Email))
                {
                    // Check if email is already taken by another user
                    var existingUser = await _context.Users
                        .FirstOrDefaultAsync(u => u.Email == request.Email && u.Id != userId);
                    if (existingUser != null)
                    {
                        return ServiceResult.ErrorResult("Email is already taken");
                    }
                    user.Email = request.Email;
                }
                
                if (!string.IsNullOrEmpty(request.PhoneNumber))
                    user.PhoneNumber = request.PhoneNumber;
                
                if (!string.IsNullOrEmpty(request.Address))
                    user.Address = request.Address;

                // Update veterinarian specific fields if user is a veterinarian
                if (user.Role == UserRole.Veterinarian)
                {
                    if (!string.IsNullOrEmpty(request.LicenseNumber))
                        user.LicenseNumber = request.LicenseNumber;
                    
                    if (!string.IsNullOrEmpty(request.Specialization))
                        user.Specialization = request.Specialization;
                    
                    if (request.YearsOfExperience.HasValue)
                        user.YearsOfExperience = request.YearsOfExperience.Value;
                    
                    if (!string.IsNullOrEmpty(request.Biography))
                        user.Biography = request.Biography;
                }

                // Update password if provided
                if (!string.IsNullOrEmpty(request.Password))
                {
                    byte[] salt;
                    user.PasswordHash = _hashingService.HashPassword(request.Password, out salt);
                    user.PasswordSalt = Convert.ToBase64String(salt);
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation("User profile updated successfully for user {UserId}", userId);
                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user profile for user {UserId}", userId);
                return ServiceResult.ErrorResult("Error updating profile");
            }
        }
    }
}
