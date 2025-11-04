using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class CategoryInsertRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(200)]
        public string? ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        // Veterinary-specific fields
        [StringLength(200)]
        public string? TargetSpecies { get; set; }

        [StringLength(100)]
        public string? CategoryType { get; set; }

        public int SortOrder { get; set; } = 0;

        [StringLength(50)]
        public string? IconClass { get; set; }

        [StringLength(7)]
        public string? ColorCode { get; set; }

        // Parent category for hierarchical structure
        public int? ParentCategoryId { get; set; }
    }
}
