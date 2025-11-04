using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Notifications
{
    /// <summary>
    /// DTO for appointment-related notifications sent via RabbitMQ
    /// </summary>
    public class AppointmentNotificationDto
    {
        public int AppointmentId { get; set; }
        public string AppointmentType { get; set; } = string.Empty; // "Confirmation", "Reminder", "Cancellation"
        public DateTime AppointmentDate { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string ServiceDescription { get; set; } = string.Empty;
        public decimal ServicePrice { get; set; }
        public string VeterinarianName { get; set; } = string.Empty;
        public string PetName { get; set; } = string.Empty;
        public string PetType { get; set; } = string.Empty;
        public string OwnerName { get; set; } = string.Empty;
        public string OwnerEmail { get; set; } = string.Empty;
        public string OwnerPhone { get; set; } = string.Empty;
        public string? SpecialInstructions { get; set; }
        public string? CancellationReason { get; set; }
        public List<string> UserEmails { get; set; } = new();
    }

    /// <summary>
    /// Wrapper class for RabbitMQ publishing
    /// </summary>
    public class AppointmentNotification
    {
        public AppointmentNotificationDto Appointment { get; set; } = new();
    }
}