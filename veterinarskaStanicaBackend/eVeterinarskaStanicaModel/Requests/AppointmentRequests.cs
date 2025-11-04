using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class AppointmentInsertRequest
    {
        [Required]
        public DateTime AppointmentDate { get; set; }

        [Required]
        public string StartTime { get; set; } = string.Empty; // HH:mm

        [Required]
        public string EndTime { get; set; } = string.Empty; // HH:mm

        [Required]
        public AppointmentType Type { get; set; }

        public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;

        [StringLength(1000)]
        public string? Reason { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Range(0, 10000)]
        public decimal? EstimatedCost { get; set; }

        [Range(0, 10000)]
        public decimal? ActualCost { get; set; }

        [Required]
        public int PetId { get; set; }

        [Required]
        public int VeterinarianId { get; set; }

        public int? ServiceId { get; set; }
    }

    public class AppointmentUpdateRequest
    {
        public DateTime? AppointmentDate { get; set; }

        public string? StartTime { get; set; } // HH:mm

        public string? EndTime { get; set; } // HH:mm

        public AppointmentType? Type { get; set; }

        public AppointmentStatus? Status { get; set; }

        [StringLength(1000)]
        public string? Reason { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Range(0, 10000)]
        public decimal? EstimatedCost { get; set; }

        [Range(0, 10000)]
        public decimal? ActualCost { get; set; }

        public int? PetId { get; set; }

        public int? VeterinarianId { get; set; }

        public int? ServiceId { get; set; }
    }
}
