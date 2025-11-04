using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class UserInsertRequest
    {
        [Required]
        [StringLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(150)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 6)]
        public string Password { get; set; } = string.Empty;

        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        public UserRole Role { get; set; } = UserRole.PetOwner;

        // Veterinarian-specific fields
        [StringLength(100)]
        public string? LicenseNumber { get; set; }

        [StringLength(200)]
        public string? Specialization { get; set; }

        public int? YearsOfExperience { get; set; }

        [StringLength(500)]
        public string? Biography { get; set; }
    }
}
