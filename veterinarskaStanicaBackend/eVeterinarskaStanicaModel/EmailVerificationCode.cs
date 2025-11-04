using System;

namespace eVeterinarskaStanicaModel
{
    public class EmailVerificationCode
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Code { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
        public bool IsUsed { get; set; }
        public DateTime? UsedAt { get; set; }
        public string? IpAddress { get; set; }
        public string? UserAgent { get; set; }
        public int FailedAttempts { get; set; }

        // Navigation properties
        public User User { get; set; } = null!;
    }
}

