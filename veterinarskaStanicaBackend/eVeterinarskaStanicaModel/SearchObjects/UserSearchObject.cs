using System;

namespace eVeterinarskaStanicaModel.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Username { get; set; }
        public string? FTS { get; set; } // FULL TEXT SEARCH
        public UserRole? Role { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsEmailVerified { get; set; }
        
        // Veterinarian-specific search
        public string? Specialization { get; set; }
        public int? MinYearsOfExperience { get; set; }
        public int? MaxYearsOfExperience { get; set; }
        
        // Date range search
        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }
    }
}
