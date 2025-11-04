using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel.Requests
{
    public class CategoryUpdateRequest
    {
        [StringLength(100)]
        public string? Name { get; set; }

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(200)]
        public string? ImageUrl { get; set; }

        public bool? IsActive { get; set; }

        // Veterinary-specific fields
        [StringLength(200)]
        public string? TargetSpecies { get; set; }

        [StringLength(100)]
        public string? CategoryType { get; set; }

        public int? SortOrder { get; set; }

        [StringLength(50)]
        public string? IconClass { get; set; }

        [StringLength(7)]
        public string? ColorCode { get; set; }

        // Parent category for hierarchical structure
        public int? ParentCategoryId { get; set; }
    }
}
