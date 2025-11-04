using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eVeterinarskaStanicaModel
{
    public enum UserRole
    {
        PetOwner = 1,
        Veterinarian = 2,
        VetTechnician = 3,
        Receptionist = 4,
        Admin = 5
    }

    public class User
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [StringLength(100)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [EmailAddress]
        [StringLength(150)]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [StringLength(20)]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string PasswordHash { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string PasswordSalt { get; set; } = string.Empty;
        
        [StringLength(20)]
        public string? PhoneNumber { get; set; }
        
        [StringLength(200)]
        public string? Address { get; set; }
        
        public DateTime DateCreated { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastLoginDate { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public bool IsEmailVerified { get; set; } = false;
        
        public UserRole Role { get; set; } = UserRole.PetOwner;

        // Veterinarian-specific fields
        [StringLength(100)]
        public string? LicenseNumber { get; set; }

        [StringLength(200)]
        public string? Specialization { get; set; }

        public int? YearsOfExperience { get; set; }

        [StringLength(500)]
        public string? Biography { get; set; }

        // Working hours for veterinarians/staff
        public TimeSpan? WorkStartTime { get; set; }
        public TimeSpan? WorkEndTime { get; set; }

        [StringLength(100)]
        public string? WorkDays { get; set; } // e.g., "Monday,Tuesday,Wednesday,Thursday,Friday"

        // Navigation Properties
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        
        // Veterinary-specific navigation properties
        public virtual ICollection<Pet> Pets { get; set; } = new List<Pet>(); // For pet owners
        public virtual ICollection<Appointment> VeterinarianAppointments { get; set; } = new List<Appointment>(); // For veterinarians
        public virtual ICollection<MedicalRecord> MedicalRecords { get; set; } = new List<MedicalRecord>(); // For veterinarians
        
        // E-commerce navigation properties
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        
        [InverseProperty("User")]
        public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        
        [InverseProperty("Veterinarian")]
        public virtual ICollection<Reservation> VeterinarianReservations { get; set; } = new List<Reservation>(); // For veterinarians
        
        public virtual ShoppingCart? ShoppingCart { get; set; }
        public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public virtual ICollection<ServiceAvailability> ServiceAvailabilities { get; set; } = new List<ServiceAvailability>(); // For veterinarians
    }
}
