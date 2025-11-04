using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Responses
{
    public class CategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsActive { get; set; }
        public DateTime DateCreated { get; set; }
        
        // Veterinary-specific fields
        public string? TargetSpecies { get; set; }
        public string? CategoryType { get; set; }
        public int SortOrder { get; set; }
        public string? IconClass { get; set; }
        public string? ColorCode { get; set; }
        
        // Hierarchical structure
        public int? ParentCategoryId { get; set; }
        public string? ParentCategoryName { get; set; }
        public List<CategoryResponse> SubCategories { get; set; } = new List<CategoryResponse>();
        
        // Statistics
        public int ServiceCount { get; set; } // Number of services in this category
        public int TotalSubCategoriesCount { get; set; } // Number of subcategories
    }
}
