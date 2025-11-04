using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class PetInsertRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Species { get; set; } = string.Empty; // Pas, Mačka, Ptica, itd.

        [StringLength(50)]
        public string? Breed { get; set; }

        [StringLength(10)]
        public string? Gender { get; set; } // Muški, Ženski

        public DateTime? DateOfBirth { get; set; }

        [Range(0, 200)]
        public decimal? Weight { get; set; } // u kg

        [StringLength(20)]
        public string? Color { get; set; }

        [StringLength(500)]
        public string? MedicalHistory { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        public bool IsActive { get; set; } = true;

        [Required]
        public int OwnerId { get; set; }
    }

    public class PetUpdateRequest
    {
        [StringLength(100)]
        public string? Name { get; set; }

        [StringLength(50)]
        public string? Species { get; set; }

        [StringLength(50)]
        public string? Breed { get; set; }

        [StringLength(10)]
        public string? Gender { get; set; }

        public DateTime? DateOfBirth { get; set; }

        [Range(0, 200)]
        public decimal? Weight { get; set; }

        [StringLength(20)]
        public string? Color { get; set; }

        [StringLength(500)]
        public string? MedicalHistory { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        public bool? IsActive { get; set; }
    }
}
