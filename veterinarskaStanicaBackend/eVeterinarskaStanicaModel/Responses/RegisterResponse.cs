using System;

namespace eVeterinarskaStanicaModel.Responses
{
    public class RegisterResponse
    {
        public int UserId { get; set; }
        public string Message { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public DateTime DateCreated { get; set; }
    }
}
