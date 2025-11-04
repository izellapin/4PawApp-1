using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class UserUpdateRequest
    {
        [StringLength(100)]
        public string? FirstName { get; set; }

        [StringLength(100)]
        public string? LastName { get; set; }

        [EmailAddress]
        [StringLength(150)]
        public string? Email { get; set; }

        [StringLength(20)]
        public string? Username { get; set; }

        [StringLength(100)]
        public string? Password { get; set; }

        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        public UserRole? Role { get; set; }

        public bool? IsActive { get; set; }

        // Veterinarian-specific fields
        [StringLength(100)]
        public string? LicenseNumber { get; set; }

        [StringLength(200)]
        public string? Specialization { get; set; }

        public int? YearsOfExperience { get; set; }

        [StringLength(500)]
        public string? Biography { get; set; }

        public TimeSpan? WorkStartTime { get; set; }

        public TimeSpan? WorkEndTime { get; set; }

        [StringLength(100)]
        public string? WorkDays { get; set; }
    }
}
