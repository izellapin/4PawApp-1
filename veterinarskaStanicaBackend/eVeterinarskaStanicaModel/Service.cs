using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class Service
    {
        [Key]
        public int Id { get; set; }

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

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? DiscountPrice { get; set; }

        [StringLength(500)]
        public string? ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        public bool IsFeatured { get; set; } = false;

        // Duration in minutes
        public int DurationMinutes { get; set; } = 30;

        // Requires appointment or walk-in allowed
        public bool RequiresAppointment { get; set; } = true;

        // Veterinary-specific fields
        [StringLength(100)]
        public string? ServiceType { get; set; } // e.g., "Cleaning Tooth", "Full Wellness", "Vaccination", "Surgery", "Grooming"

        [StringLength(100)]
        public string? AgeGroup { get; set; } // e.g., "Puppy/Kitten", "Adult", "Senior", "All"

        public bool RequiresFasting { get; set; } = false;

        [StringLength(500)]
        public string? PreparationInstructions { get; set; }

        [StringLength(500)]
        public string? PostCareInstructions { get; set; }

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime? DateModified { get; set; }

        // Foreign Keys
        public int CategoryId { get; set; }

        // Navigation Properties
        public virtual Category Category { get; set; }
        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
        public virtual ICollection<Asset> Assets { get; set; } = new List<Asset>();
        public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public virtual ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
        public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public virtual ICollection<ServiceAvailability> ServiceAvailabilities { get; set; } = new List<ServiceAvailability>();
    }
}
