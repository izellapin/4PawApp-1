using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum AppointmentStatus
    {
        Scheduled = 1,
        Confirmed = 2,
        InProgress = 3,
        Completed = 4,
        Cancelled = 5,
        NoShow = 6,
        Rescheduled = 7
    }

    public enum AppointmentType
    {
        Checkup = 1,
        Vaccination = 2,
        Surgery = 3,
        Emergency = 4,
        Grooming = 5,
        Dental = 6,
        Consultation = 7,
        FollowUp = 8
    }

    public class Appointment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string AppointmentNumber { get; set; } = string.Empty;

        public DateTime AppointmentDate { get; set; }

        public TimeSpan StartTime { get; set; }

        public TimeSpan EndTime { get; set; }

        public AppointmentType Type { get; set; }

        public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;

        [StringLength(1000)]
        public string? Reason { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? EstimatedCost { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? ActualCost { get; set; }

        // Payment tracking
        public bool IsPaid { get; set; } = false;
        
        public DateTime? PaymentDate { get; set; }
        
        [StringLength(100)]
        public string? PaymentMethod { get; set; } // "Stripe", "Cash", "Card", etc.
        
        [StringLength(100)]
        public string? PaymentTransactionId { get; set; } // Stripe payment intent ID

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime? DateModified { get; set; }

        // Foreign Keys
        public int PetId { get; set; }
        public int VeterinarianId { get; set; }
        public int? ServiceId { get; set; } // Optional - if appointment is for a specific service

        // Navigation Properties
        public virtual Pet Pet { get; set; }
        public virtual User Veterinarian { get; set; }
        public virtual Service? Service { get; set; }
        public virtual ICollection<MedicalRecord> MedicalRecords { get; set; } = new List<MedicalRecord>();
    }
}
