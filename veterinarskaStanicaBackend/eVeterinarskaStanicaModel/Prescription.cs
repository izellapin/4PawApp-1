using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class Prescription
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(200)]
        public string MedicationName { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Dosage { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Instructions { get; set; } = string.Empty;

        public int Quantity { get; set; }

        public int DurationDays { get; set; }

        public DateTime StartDate { get; set; } = DateTime.UtcNow;

        public DateTime EndDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? Cost { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        // Foreign Keys
        public int MedicalRecordId { get; set; }
        public int PetId { get; set; }
        public int VeterinarianId { get; set; }

        // Navigation Properties
        public virtual MedicalRecord MedicalRecord { get; set; }
        public virtual Pet Pet { get; set; }
        public virtual User Veterinarian { get; set; }
    }
}
