using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class RegisterRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(3)]
        [MaxLength(20)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [Compare("Password", ErrorMessage = "Password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Phone]
        public string? PhoneNumber { get; set; }

        [MaxLength(200)]
        public string? Address { get; set; }

        /// <summary>
        /// Client type: Desktop, Mobile
        /// </summary>
        public string ClientType { get; set; } = "Mobile";

        /// <summary>
        /// For mobile users, this will be PetOwner
        /// For desktop users, this will be set by admin
        /// </summary>
        public UserRole Role { get; set; } = UserRole.PetOwner;
    }
}

