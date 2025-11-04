using System;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel
{
    public class Favorite
    {
        [Key]
        public int Id { get; set; }

        public DateTime DateAdded { get; set; } = DateTime.UtcNow;

        [StringLength(500)]
        public string? Notes { get; set; }

        // Foreign Keys
        public int UserId { get; set; }
        public int ServiceId { get; set; }

        // Navigation Properties
        public virtual User User { get; set; }
        public virtual Service Service { get; set; }
    }
}
