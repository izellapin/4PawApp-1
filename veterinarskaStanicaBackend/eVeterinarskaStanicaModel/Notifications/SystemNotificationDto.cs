using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Notifications
{
    public class SystemNotificationDto
    {
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Severity { get; set; } = "info"; // info|warn|error
        // Additional fields used by services
        public string? NotificationType { get; set; }
        public string? Priority { get; set; }
        public string? ActionUrl { get; set; }
        public string? ActionText { get; set; }
        public List<string> UserEmails { get; set; } = new();
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}


