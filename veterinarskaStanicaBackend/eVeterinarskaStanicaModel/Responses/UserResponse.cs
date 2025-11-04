using System;

namespace eVeterinarskaStanicaModel.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public DateTime DateCreated { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public bool IsActive { get; set; }
        public bool IsEmailVerified { get; set; }
        public string Role { get; set; } = string.Empty;
        
        // Veterinarian-specific fields (only shown if user is veterinarian)
        public string? LicenseNumber { get; set; }
        public string? Specialization { get; set; }
        public int? YearsOfExperience { get; set; }
        public string? Biography { get; set; }
        public TimeSpan? WorkStartTime { get; set; }
        public TimeSpan? WorkEndTime { get; set; }
        public string? WorkDays { get; set; }
    }
}
