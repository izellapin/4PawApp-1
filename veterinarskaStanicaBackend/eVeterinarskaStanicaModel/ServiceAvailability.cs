using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel
{
    public enum DayOfWeekEnum
    {
        Sunday = 0,
        Monday = 1,
        Tuesday = 2,
        Wednesday = 3,
        Thursday = 4,
        Friday = 5,
        Saturday = 6
    }

    public class ServiceAvailability
    {
        [Key]
        public int Id { get; set; }

        public DayOfWeekEnum DayOfWeek { get; set; }

        public TimeSpan StartTime { get; set; }

        public TimeSpan EndTime { get; set; }

        public bool IsAvailable { get; set; } = true;

        public int MaxAppointments { get; set; } = 1;

        public int SlotDurationMinutes { get; set; } = 30;

        // Special dates (holidays, vacations, etc.)
        public DateTime? SpecificDate { get; set; }

        public bool IsSpecialDate { get; set; } = false; // Override for specific dates

        [StringLength(200)]
        public string? Notes { get; set; }

        // Foreign Keys
        public int? ServiceId { get; set; } // If null, applies to all services
        public int? VeterinarianId { get; set; } // If null, applies to all vets

        // Navigation Properties
        public virtual Service? Service { get; set; }
        public virtual User? Veterinarian { get; set; }
    }

    public class TimeSlot
    {
        [Key]
        public int Id { get; set; }

        public DateTime Date { get; set; }

        public TimeSpan StartTime { get; set; }

        public TimeSpan EndTime { get; set; }

        public bool IsBooked { get; set; } = false;

        public bool IsBlocked { get; set; } = false; // Manually blocked

        [StringLength(200)]
        public string? BlockReason { get; set; }

        // Foreign Keys
        public int? ServiceId { get; set; }
        public int? VeterinarianId { get; set; }
        public int? ReservationId { get; set; }

        // Navigation Properties
        public virtual Service? Service { get; set; }
        public virtual User? Veterinarian { get; set; }
        public virtual Reservation? Reservation { get; set; }
    }
}
