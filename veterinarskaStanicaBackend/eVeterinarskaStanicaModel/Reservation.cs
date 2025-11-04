using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum ReservationStatus
    {
        Pending = 1,
        Confirmed = 2,
        InProgress = 3,
        Completed = 4,
        Cancelled = 5,
        NoShow = 6
    }

    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string ReservationNumber { get; set; } = string.Empty;

        public DateTime ReservationDate { get; set; }

        public TimeSpan StartTime { get; set; }

        public TimeSpan EndTime { get; set; }

        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        [StringLength(1000)]
        public string? Notes { get; set; }

        [StringLength(500)]
        public string? ReasonForVisit { get; set; }

        public bool IsEmergency { get; set; } = false;

        [Column(TypeName = "decimal(18,2)")]
        public decimal? TotalCost { get; set; }

        // Foreign Keys
        public int UserId { get; set; }
        public int ServiceId { get; set; }
        public int? PetId { get; set; }
        public int? VeterinarianId { get; set; }

        // Navigation Properties
        public virtual User User { get; set; }
        public virtual Service Service { get; set; }
        public virtual Pet? Pet { get; set; }
        
        [ForeignKey("VeterinarianId")]
        public virtual User? Veterinarian { get; set; }
    }
}
