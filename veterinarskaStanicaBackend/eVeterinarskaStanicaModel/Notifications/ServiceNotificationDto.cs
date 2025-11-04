using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Notifications
{
    /// <summary>
    /// DTO for service-related notifications sent via RabbitMQ
    /// </summary>
    public class ServiceNotificationDto
    {
        public int ServiceId { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Category { get; set; } = string.Empty;
        public bool IsNew { get; set; }
        public bool IsPromotional { get; set; }
        public decimal? DiscountPercentage { get; set; }
        public DateTime? PromotionEndDate { get; set; }
        public string? ImageUrl { get; set; }
        public List<string> UserEmails { get; set; } = new();
        
        // For targeted notifications
        public List<int>? TargetUserIds { get; set; }
        public List<string>? TargetUserRoles { get; set; } // "PetOwner", "Veterinarian", etc.
    }

    /// <summary>
    /// Wrapper class for RabbitMQ publishing
    /// </summary>
    public class ServiceNotification
    {
        public ServiceNotificationDto Service { get; set; } = new();
    }
}