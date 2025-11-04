using System;

namespace eVeterinarskaStanicaModel.Notifications
{
    public class UserSummary
    {
        public int Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? VerificationCode { get; set; }

        public static implicit operator UserSummary(UserRegistrationNotificationDto dto)
        {
            return new UserSummary
            {
                Id = dto.UserId,
                Email = dto.Email,
                FirstName = dto.FirstName,
                LastName = dto.LastName
            };
        }
    }

    public class UserRegistrationNotification
    {
        // Some services access notification.User.* so provide nested summary
        public UserSummary User { get; set; } = new();
        public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    }
}


