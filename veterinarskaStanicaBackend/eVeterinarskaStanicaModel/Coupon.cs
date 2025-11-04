using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum CouponType
    {
        Percentage = 1,
        FixedAmount = 2,
        FreeService = 3
    }

    public class Coupon
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string Code { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        public CouponType Type { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal DiscountValue { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? MinimumOrderAmount { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? MaximumDiscountAmount { get; set; }

        public DateTime ValidFrom { get; set; }

        public DateTime ValidTo { get; set; }

        public int? UsageLimit { get; set; }

        public int UsedCount { get; set; } = 0;

        public int? UsageLimitPerUser { get; set; }

        public bool IsActive { get; set; } = true;

        public bool IsFirstTimeCustomerOnly { get; set; } = false;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        // Veterinary-specific
        [StringLength(200)]
        public string? ApplicableServices { get; set; } // Comma-separated service IDs or categories

        [StringLength(100)]
        public string? ApplicableSpecies { get; set; } // Dogs, Cats, etc.

        // Navigation Properties
        public virtual ICollection<OrderCoupon> OrderCoupons { get; set; } = new List<OrderCoupon>();
    }

    public class OrderCoupon
    {
        [Key]
        public int Id { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal DiscountAmount { get; set; }

        public DateTime DateUsed { get; set; } = DateTime.UtcNow;

        // Foreign Keys
        public int OrderId { get; set; }
        public int CouponId { get; set; }

        // Navigation Properties
        public virtual Order Order { get; set; }
        public virtual Coupon Coupon { get; set; }
    }
}
