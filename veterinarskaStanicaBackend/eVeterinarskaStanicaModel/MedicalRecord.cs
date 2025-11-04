using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum MedicalRecordType
    {
        Examination = 1,
        Vaccination = 2,
        Surgery = 3,
        Treatment = 4,
        Prescription = 5,
        LabResult = 6,
        Diagnosis = 7,
        Note = 8
    }

    public class MedicalRecord
    {
        [Key]
        public int Id { get; set; }

        public MedicalRecordType Type { get; set; }

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [StringLength(2000)]
        public string? Description { get; set; }

        [StringLength(500)]
        public string? Diagnosis { get; set; }

        [StringLength(1000)]
        public string? Treatment { get; set; }

        [StringLength(1000)]
        public string? Prescription { get; set; }

        [StringLength(500)]
        public string? Symptoms { get; set; }

        public decimal? Temperature { get; set; }

        public decimal? Weight { get; set; }

        [StringLength(100)]
        public string? HeartRate { get; set; }

        [StringLength(100)]
        public string? BloodPressure { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? Cost { get; set; }

        public DateTime RecordDate { get; set; } = DateTime.UtcNow;

        public DateTime? NextVisitDate { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        // Foreign Keys
        public int PetId { get; set; }
        public int VeterinarianId { get; set; }
        public int? AppointmentId { get; set; }

        // Navigation Properties
        public virtual Pet Pet { get; set; }
        public virtual User Veterinarian { get; set; }
        public virtual Appointment? Appointment { get; set; }
        public virtual ICollection<Prescription> Prescriptions { get; set; } = new List<Prescription>();
    }
}
