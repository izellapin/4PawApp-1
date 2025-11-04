using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel
{
    public enum NotificationType
    {
        AppointmentReminder = 1,
        AppointmentConfirmation = 2,
        AppointmentCancellation = 3,
        PaymentConfirmation = 4,
        OrderUpdate = 5,
        PromotionalOffer = 6,
        SystemAlert = 7,
        ReviewRequest = 8,
        VaccinationReminder = 9,
        FollowUpReminder = 10
    }

    public enum NotificationStatus
    {
        Pending = 1,
        Sent = 2,
        Delivered = 3,
        Read = 4,
        Failed = 5
    }

    public class Notification
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Message { get; set; } = string.Empty;

        public NotificationType Type { get; set; }

        public NotificationStatus Status { get; set; } = NotificationStatus.Pending;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime? DateSent { get; set; }

        public DateTime? DateRead { get; set; }

        public DateTime? ScheduledDate { get; set; } // For scheduled notifications

        public bool SendEmail { get; set; } = true;

        public bool SendSms { get; set; } = false;

        public bool SendPush { get; set; } = true;

        [StringLength(500)]
        public string? ActionUrl { get; set; } // URL to navigate when clicked

        [StringLength(100)]
        public string? ActionText { get; set; } // Button text

        // Foreign Keys
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public int? OrderId { get; set; }
        public int? PetId { get; set; }

        // Navigation Properties
        public virtual User User { get; set; }
        public virtual Reservation? Reservation { get; set; }
        public virtual Order? Order { get; set; }
        public virtual Pet? Pet { get; set; }
    }
}
