using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class UpdateProfileRequest
    {
        [StringLength(50)]
        public string? FirstName { get; set; }

        [StringLength(50)]
        public string? LastName { get; set; }

        [EmailAddress]
        [StringLength(100)]
        public string? Email { get; set; }

        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        // Veterinarian specific fields
        [StringLength(50)]
        public string? LicenseNumber { get; set; }

        [StringLength(100)]
        public string? Specialization { get; set; }

        [Range(0, 50)]
        public int? YearsOfExperience { get; set; }

        [StringLength(1000)]
        public string? Biography { get; set; }

        // Password change
        [StringLength(100, MinimumLength = 6)]
        public string? Password { get; set; }
    }
}







