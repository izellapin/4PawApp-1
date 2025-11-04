using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel
{
    public class Category
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(200)]
        public string? ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        // Veterinary-specific fields
        [StringLength(200)]
        public string? TargetSpecies { get; set; } // e.g., "Dogs,Cats", "Birds", "All"

        [StringLength(100)]
        public string? CategoryType { get; set; } // e.g., "Medical", "Surgical", "Preventive", "Grooming", "Emergency"

        public int SortOrder { get; set; } = 0; // For ordering categories in display

        [StringLength(50)]
        public string? IconClass { get; set; } // CSS class for category icon

        [StringLength(7)]
        public string? ColorCode { get; set; } // Hex color code for category

        // Self-referencing for parent-child categories
        public int? ParentCategoryId { get; set; }

        // Navigation Properties
        public virtual Category? ParentCategory { get; set; }
        public virtual ICollection<Category> SubCategories { get; set; } = new List<Category>();
        public virtual ICollection<Service> Services { get; set; } = new List<Service>();
    }
}
