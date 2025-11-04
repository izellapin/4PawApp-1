using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Notifications
{
    public class SystemNotification
    {
        // Original payload container used by publisher/subscriber
        public SystemNotificationDto? Notification { get; set; }

        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string? NotificationType { get; set; }
        public string? Priority { get; set; }
        public string? ActionUrl { get; set; }
        public string? ActionText { get; set; }
        public List<string> UserEmails { get; set; } = new();
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Convenience factory: SystemNotification.Create(...)
        public static SystemNotification Create(
            string title,
            string message,
            IEnumerable<string>? userEmails = null,
            string? notificationType = null,
            string? priority = null,
            string? actionUrl = null,
            string? actionText = null)
        {
            var n = new SystemNotification
            {
                Title = title,
                Message = message,
                NotificationType = notificationType,
                Priority = priority,
                ActionUrl = actionUrl,
                ActionText = actionText
            };
            if (userEmails != null)
            {
                n.UserEmails.AddRange(userEmails);
            }
            return n;
        }
    }
}


