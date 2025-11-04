using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class ServiceInsertRequest
    {
        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Code { get; set; } = string.Empty;

        [StringLength(1000)]
        public string? Description { get; set; }

        [StringLength(500)]
        public string? ShortDescription { get; set; }

        [Required]
        public decimal Price { get; set; }

        public decimal? DiscountPrice { get; set; }

        [StringLength(500)]
        public string? ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        public bool IsFeatured { get; set; } = false;

        public int DurationMinutes { get; set; } = 30;

        public bool RequiresAppointment { get; set; } = true;

        [StringLength(100)]
        public string? ServiceType { get; set; }

        [StringLength(100)]
        public string? AgeGroup { get; set; }

        public bool RequiresFasting { get; set; } = false;

        [StringLength(500)]
        public string? PreparationInstructions { get; set; }

        [StringLength(500)]
        public string? PostCareInstructions { get; set; }

        [Required]
        public int CategoryId { get; set; }
    }
}
