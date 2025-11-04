using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Notifications
{
    /// <summary>
    /// Base notification message for all RabbitMQ communications
    /// </summary>
    public class NotificationMessage
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Type { get; set; } = string.Empty; // "Email", "SMS", "Push", "InApp"
        public string Subject { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string Priority { get; set; } = "Normal"; // "Low", "Normal", "High", "Critical"
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ScheduledAt { get; set; }
        public int RetryCount { get; set; } = 0;
        public int MaxRetries { get; set; } = 3;
        public Dictionary<string, object> Metadata { get; set; } = new();
        
        // Recipients
        public List<string> ToEmails { get; set; } = new();
        public List<string> ToPhones { get; set; } = new();
        public List<int> ToUserIds { get; set; } = new();
        
        // Template information
        public string? TemplateName { get; set; }
        public Dictionary<string, object>? TemplateData { get; set; }
    }

    /// <summary>
    /// Email-specific notification message
    /// </summary>
    public class EmailNotificationMessage : NotificationMessage
    {
        public string FromEmail { get; set; } = string.Empty;
        public string FromName { get; set; } = string.Empty;
        public bool IsHtml { get; set; } = true;
        public List<string>? CcEmails { get; set; }
        public List<string>? BccEmails { get; set; }
        public List<EmailAttachment>? Attachments { get; set; }

        public EmailNotificationMessage()
        {
            Type = "Email";
        }
    }

    /// <summary>
    /// Email attachment information
    /// </summary>
    public class EmailAttachment
    {
        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = string.Empty;
        public byte[] Data { get; set; } = Array.Empty<byte>();
        public string? ContentId { get; set; } // For inline images
    }

    /// <summary>
    /// Push notification message
    /// </summary>
    public class PushNotificationMessage : NotificationMessage
    {
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Icon { get; set; }
        public string? Image { get; set; }
        public Dictionary<string, string>? Data { get; set; }
        public List<string> DeviceTokens { get; set; } = new();

        public PushNotificationMessage()
        {
            Type = "Push";
        }
    }
}