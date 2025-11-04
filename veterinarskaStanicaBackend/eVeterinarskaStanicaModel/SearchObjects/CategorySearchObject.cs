using System;

namespace eVeterinarskaStanicaModel.SearchObjects
{
    public class CategorySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public bool? IsActive { get; set; }
        public string? TargetSpecies { get; set; }
        public string? CategoryType { get; set; }
        public int? ParentCategoryId { get; set; }
        public bool? HasParent { get; set; } // Filter for top-level or sub-categories
        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }
        public string? FTS { get; set; } // FULL TEXT SEARCH
        public string? SearchTerm { get; set; } // General search across name and description
    }
}
