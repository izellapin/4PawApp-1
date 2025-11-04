using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eVeterinarskaStanicaModel
{
    public enum PetGender
    {
        Male = 1,
        Female = 2,
    }

    public enum PetStatus
    {
        Active = 1,
        Inactive = 2,
        Deceased = 3
    }

    public class Pet
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Species { get; set; } = string.Empty; // Dog, Cat, Bird, etc.

        [StringLength(50)]
        public string? Breed { get; set; }

        public PetGender Gender { get; set; }

        public DateTime? DateOfBirth { get; set; }

        [StringLength(50)]
        public string? Color { get; set; }

        public decimal? Weight { get; set; } // in kg

        [StringLength(50)]
        public string? MicrochipNumber { get; set; }

        public PetStatus Status { get; set; } = PetStatus.Active;

        [StringLength(1000)]
        public string? Notes { get; set; }

        [StringLength(500)]
        public string? PhotoUrl { get; set; }

        public DateTime DateCreated { get; set; } = DateTime.UtcNow;

        public DateTime? DateModified { get; set; }

        // Foreign Keys
        public int PetOwnerId { get; set; }
        
        // Ko je dodao pacijenta (veterinar ili admin)
        public int? CreatedBy { get; set; }

        // Navigation Properties
        public virtual User PetOwner { get; set; }
        public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        public virtual ICollection<MedicalRecord> MedicalRecords { get; set; } = new List<MedicalRecord>();
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public virtual ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
