using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum PaymentStatus
    {
        Pending = 1,
        Processing = 2,
        Completed = 3,
        Failed = 4,
        Cancelled = 5,
        Refunded = 6
    }

    public enum PaymentMethod
    {
        Cash = 1,
        CreditCard = 2,
        DebitCard = 3,
        BankTransfer = 4,
        Insurance = 5,
        PetInsurance = 6,
        Stripe = 7,
        PayPal = 8
    }

    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string TransactionId { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public PaymentMethod PaymentMethod { get; set; }

        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;

        public DateTime? ProcessedDate { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        [StringLength(100)]
        public string? PaymentGatewayTransactionId { get; set; }

        // Stripe-specific fields
        [StringLength(100)]
        public string? StripePaymentIntentId { get; set; }

        [StringLength(100)]
        public string? StripeChargeId { get; set; }

        [StringLength(50)]
        public string? StripeCustomerId { get; set; }

        [StringLength(100)]
        public string? PaymentMethodId { get; set; } // Stripe payment method ID

        [StringLength(10)]
        public string? Currency { get; set; } = "USD";

        // Refund information
        [Column(TypeName = "decimal(18,2)")]
        public decimal? RefundAmount { get; set; }

        public DateTime? RefundDate { get; set; }

        [StringLength(200)]
        public string? RefundReason { get; set; }

        // Foreign Keys
        public int OrderId { get; set; }

        // Navigation Properties
        public virtual Order Order { get; set; }
    }
}
