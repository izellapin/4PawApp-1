using System;

namespace eVeterinarskaStanicaModel.Responses
{
    public class AuthResponse
    {
        public int UserId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public UserRole Role { get; set; }
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime TokenExpiration { get; set; }
        public bool IsActive { get; set; }
        public bool IsEmailVerified { get; set; }

        // Role-specific permissions
        public string[] Permissions { get; set; } = Array.Empty<string>();
    }
}
