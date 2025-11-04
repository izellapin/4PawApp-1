using System;

namespace eVeterinarskaStanicaModel.Responses
{
    public class Login2FAResponse
    {
        public bool RequiresTwoFactor { get; set; } = true;
        public string Message { get; set; } = string.Empty;
        public int UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public DateTime CodeExpiresAt { get; set; }
        public int RemainingAttempts { get; set; } = 3;
    }
}
