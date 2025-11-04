using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class OrderItem
    {
        [Key]
        public int Id { get; set; }

        public int Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        // Foreign Keys
        public int OrderId { get; set; }
        public int ServiceId { get; set; }

        // Navigation Properties
        public virtual Order Order { get; set; }
        public virtual Service Service { get; set; }
    }
}
