using System;

namespace eVeterinarskaStanicaModel.Responses
{
    public class ServiceResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? ShortDescription { get; set; }
        public decimal Price { get; set; }
        public decimal? DiscountPrice { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsActive { get; set; }
        public bool IsFeatured { get; set; }
        public int DurationMinutes { get; set; }
        public bool RequiresAppointment { get; set; }
        public string? ServiceType { get; set; }
        public string? AgeGroup { get; set; }
        public bool RequiresFasting { get; set; }
        public string? PreparationInstructions { get; set; }
        public string? PostCareInstructions { get; set; }
        public DateTime DateCreated { get; set; }
        public DateTime? DateModified { get; set; }
        
        // Navigation Properties
        public int CategoryId { get; set; }
        public string? CategoryName { get; set; }
        
        // Statistics
        public decimal? AverageRating { get; set; }
        public int ReviewCount { get; set; }
        public int ReservationCount { get; set; }
    }
}
