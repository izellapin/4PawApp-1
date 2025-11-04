using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum OrderStatus
    {
        Pending = 1,
        Confirmed = 2,
        InProgress = 3,
        Completed = 4,
        Cancelled = 5,
        Refunded = 6,
        PartiallyCompleted = 7
    }

    public enum OrderType
    {
        ServiceOrder = 1,        // For veterinary services
        AppointmentBooking = 2   // For appointment-based services
    }

    public class Order
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string OrderNumber { get; set; } = string.Empty;

        public DateTime OrderDate { get; set; } = DateTime.UtcNow;

        public OrderType Type { get; set; } = OrderType.ServiceOrder;

        public OrderStatus Status { get; set; } = OrderStatus.Pending;

        [Column(TypeName = "decimal(18,2)")]
        public decimal SubTotal { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TaxAmount { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal DiscountAmount { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }

        // Veterinary-specific fields
        public int? PetId { get; set; } // For pet-specific orders

        public int? AppointmentId { get; set; } // Link to appointment if applicable

        public DateTime? ServiceDate { get; set; } // When the service was/will be provided

        public DateTime? CompletedDate { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        // Foreign Keys
        public int UserId { get; set; }

        // Navigation Properties
        public virtual User User { get; set; }
        public virtual Pet? Pet { get; set; }
        public virtual Appointment? Appointment { get; set; }
        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<OrderCoupon> OrderCoupons { get; set; } = new List<OrderCoupon>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
