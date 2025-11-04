using System;

namespace eVeterinarskaStanicaModel.Notifications
{
    public class UserRegistrationNotificationDto
    {
        public int UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
        public string? WelcomeMessage { get; set; }
    }
}


