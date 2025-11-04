using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class Verify2FARequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(6, MinimumLength = 6)]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Code must be exactly 6 digits")]
        public string Code { get; set; } = string.Empty;

        public string ClientType { get; set; } = "Desktop"; // "Desktop" or "Mobile"
    }
}
