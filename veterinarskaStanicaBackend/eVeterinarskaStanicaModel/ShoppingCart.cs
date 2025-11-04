using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class ShoppingCart
    {
        [Key]
        public int Id { get; set; }

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime DateModified { get; set; } = DateTime.UtcNow;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }

        public int ItemCount { get; set; }

        // Foreign Keys
        public int UserId { get; set; }

        // Navigation Properties
        public virtual User User { get; set; }
        public virtual ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
    }

    public class CartItem
    {
        [Key]
        public int Id { get; set; }

        public int Quantity { get; set; } = 1;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        public DateTime DateAdded { get; set; } = DateTime.UtcNow;

        [StringLength(500)]
        public string? Notes { get; set; }

        // For reservations
        public DateTime? PreferredDate { get; set; }
        public TimeSpan? PreferredTime { get; set; }

        // Foreign Keys
        public int CartId { get; set; }
        public int ServiceId { get; set; }
        public int? PetId { get; set; }

        // Navigation Properties
        public virtual ShoppingCart Cart { get; set; }
        public virtual Service Service { get; set; }
        public virtual Pet? Pet { get; set; }
    }
}
