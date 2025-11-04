using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class TwoFactorCode
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [StringLength(6)]
        public string Code { get; set; } = string.Empty;

        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public DateTime ExpiresAt { get; set; }

        public bool IsUsed { get; set; } = false;

        public DateTime? UsedAt { get; set; }

        [StringLength(50)]
        public string? ClientType { get; set; } // "Desktop" or "Mobile"

        [StringLength(100)]
        public string? IpAddress { get; set; }

        public int FailedAttempts { get; set; } = 0;

        // Navigation property
        [ForeignKey(nameof(UserId))]
        public virtual User User { get; set; } = null!;

        // Helper properties
        [NotMapped]
        public bool IsExpired => DateTime.UtcNow > ExpiresAt;

        [NotMapped]
        public bool IsValid => !IsUsed && !IsExpired;

        [NotMapped]
        public TimeSpan TimeRemaining => IsExpired ? TimeSpan.Zero : ExpiresAt - DateTime.UtcNow;
    }
}
