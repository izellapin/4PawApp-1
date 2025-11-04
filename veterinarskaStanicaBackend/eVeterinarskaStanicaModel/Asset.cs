using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public class Asset
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(200)]
        public string FileName { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string FileType { get; set; } = string.Empty;

        [Required]
        public string Base64Data { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime? DateModified { get; set; }

        // Foreign Key
        public int ServiceId { get; set; }

        // Navigation Property
        public virtual Service Service { get; set; }
    }
}
