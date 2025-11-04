using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class LoginRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        // Optional: Specify client type for different token configurations
        public string? ClientType { get; set; } // "Desktop", "Mobile"
    }
}
