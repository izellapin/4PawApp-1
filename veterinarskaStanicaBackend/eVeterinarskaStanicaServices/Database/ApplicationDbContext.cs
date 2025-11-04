using Microsoft.EntityFrameworkCore;
using eVeterinarskaStanicaModel;

namespace eVeterinarskaStanicaServices.Database
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // DbSets
        public DbSet<User> Users { get; set; }
        public DbSet<Service> Services { get; set; }
        public DbSet<Asset> Assets { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Payment> Payments { get; set; }
        
        // Veterinary-specific DbSets
        public DbSet<Pet> Pets { get; set; }
        public DbSet<Appointment> Appointments { get; set; }
        public DbSet<MedicalRecord> MedicalRecords { get; set; }
        public DbSet<Prescription> Prescriptions { get; set; }
        
        // 2FA DbSet
        public DbSet<TwoFactorCode> TwoFactorCodes { get; set; }
        
        // Notifications DbSet
        public DbSet<Notification> Notifications { get; set; }
        
        // Email verification DbSet
        public DbSet<EmailVerificationCode> EmailVerificationCodes { get; set; }
        
        // Reviews DbSet
        public DbSet<Review> Reviews { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Email).HasMaxLength(150);
                entity.Property(e => e.Username).HasMaxLength(20);
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20);
                entity.Property(e => e.Address).HasMaxLength(200);
                // Role is now an enum, no max length needed

                // Create unique indexes
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasIndex(e => e.Username).IsUnique();

                // Configure relationships
                entity.HasMany(u => u.Orders)
                    .WithOne(o => o.User)
                    .HasForeignKey(o => o.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Veterinary navigation properties
                entity.HasMany(u => u.Pets)
                    .WithOne(p => p.PetOwner)
                    .HasForeignKey(p => p.PetOwnerId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(u => u.VeterinarianAppointments)
                    .WithOne(a => a.Veterinarian)
                    .HasForeignKey(a => a.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(u => u.MedicalRecords)
                    .WithOne(mr => mr.Veterinarian)
                    .HasForeignKey(mr => mr.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure Service entity
            modelBuilder.Entity<Service>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).HasMaxLength(200);
                entity.Property(e => e.Code).HasMaxLength(50);
                entity.Property(e => e.Description).HasMaxLength(1000);
                entity.Property(e => e.ShortDescription).HasMaxLength(500);
                entity.Property(e => e.ImageUrl).HasMaxLength(500);
                entity.Property(e => e.Price).HasColumnType("decimal(18,2)");
                entity.Property(e => e.DiscountPrice).HasColumnType("decimal(18,2)");
                entity.Property(e => e.ServiceType).HasMaxLength(100);

                // Create unique index for service code
                entity.HasIndex(e => e.Code).IsUnique();

                // Configure relationships
                entity.HasOne(s => s.Category)
                    .WithMany(c => c.Services)
                    .HasForeignKey(s => s.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(s => s.OrderItems)
                    .WithOne(oi => oi.Service)
                    .HasForeignKey(oi => oi.ServiceId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(s => s.Assets)
                    .WithOne(a => a.Service)
                    .HasForeignKey(a => a.ServiceId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(s => s.Appointments)
                    .WithOne(a => a.Service)
                    .HasForeignKey(a => a.ServiceId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasMany(s => s.Reviews)
                    .WithOne(r => r.Service)
                    .HasForeignKey(r => r.ServiceId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure Asset entity
            modelBuilder.Entity<Asset>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.FileName).HasMaxLength(200);
                entity.Property(e => e.FileType).HasMaxLength(50);
                entity.Property(e => e.Description).HasMaxLength(500);

                entity.HasOne(a => a.Service)
                    .WithMany(s => s.Assets)
                    .HasForeignKey(a => a.ServiceId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Category entity
            modelBuilder.Entity<Category>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).HasMaxLength(100);
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.Property(e => e.ImageUrl).HasMaxLength(200);

                // Self-referencing relationship
                entity.HasOne(c => c.ParentCategory)
                    .WithMany(c => c.SubCategories)
                    .HasForeignKey(c => c.ParentCategoryId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(c => c.Services)
                    .WithOne(s => s.Category)
                    .HasForeignKey(s => s.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure Order entity
            modelBuilder.Entity<Order>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.OrderNumber).HasMaxLength(20);
                entity.Property(e => e.SubTotal).HasColumnType("decimal(18,2)");
                entity.Property(e => e.TaxAmount).HasColumnType("decimal(18,2)");
                entity.Property(e => e.DiscountAmount).HasColumnType("decimal(18,2)");
                entity.Property(e => e.TotalAmount).HasColumnType("decimal(18,2)");

                // Create unique index for order number
                entity.HasIndex(e => e.OrderNumber).IsUnique();

                // Configure relationships
                entity.HasOne(o => o.User)
                    .WithMany(u => u.Orders)
                    .HasForeignKey(o => o.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(o => o.Pet)
                    .WithMany()
                    .HasForeignKey(o => o.PetId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(o => o.Appointment)
                    .WithMany()
                    .HasForeignKey(o => o.AppointmentId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasMany(o => o.OrderItems)
                    .WithOne(oi => oi.Order)
                    .HasForeignKey(oi => oi.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(o => o.Payments)
                    .WithOne(p => p.Order)
                    .HasForeignKey(p => p.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasMany(o => o.Reviews)
                    .WithOne(r => r.Order)
                    .HasForeignKey(r => r.OrderId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure OrderItem entity
            modelBuilder.Entity<OrderItem>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.UnitPrice).HasColumnType("decimal(18,2)");
                entity.Property(e => e.TotalPrice).HasColumnType("decimal(18,2)");

                entity.HasOne(oi => oi.Order)
                    .WithMany(o => o.OrderItems)
                    .HasForeignKey(oi => oi.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(oi => oi.Service)
                    .WithMany(s => s.OrderItems)
                    .HasForeignKey(oi => oi.ServiceId)
                    .OnDelete(DeleteBehavior.Restrict);
            });



            // Configure Payment entity
            modelBuilder.Entity<Payment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.TransactionId).HasMaxLength(50);
                entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Notes).HasMaxLength(500);
                entity.Property(e => e.PaymentGatewayTransactionId).HasMaxLength(100);

                // Create unique index for transaction ID
                entity.HasIndex(e => e.TransactionId).IsUnique();

                entity.HasOne(p => p.Order)
                    .WithMany(o => o.Payments)
                    .HasForeignKey(p => p.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);
            });



            // Configure Pet entity
            modelBuilder.Entity<Pet>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).HasMaxLength(100);
                entity.Property(e => e.Species).HasMaxLength(50);
                entity.Property(e => e.Breed).HasMaxLength(50);
                entity.Property(e => e.Color).HasMaxLength(50);
                entity.Property(e => e.MicrochipNumber).HasMaxLength(50);
                entity.Property(e => e.Notes).HasMaxLength(1000);
                entity.Property(e => e.PhotoUrl).HasMaxLength(500);

                entity.HasOne(p => p.PetOwner)
                    .WithMany(u => u.Pets)
                    .HasForeignKey(p => p.PetOwnerId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(p => p.Appointments)
                    .WithOne(a => a.Pet)
                    .HasForeignKey(a => a.PetId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasMany(p => p.MedicalRecords)
                    .WithOne(mr => mr.Pet)
                    .HasForeignKey(mr => mr.PetId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure Appointment entity
            modelBuilder.Entity<Appointment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.AppointmentNumber).HasMaxLength(20);
                entity.Property(e => e.Reason).HasMaxLength(1000);
                entity.Property(e => e.Notes).HasMaxLength(1000);
                entity.Property(e => e.EstimatedCost).HasColumnType("decimal(18,2)");
                entity.Property(e => e.ActualCost).HasColumnType("decimal(18,2)");

                entity.HasIndex(e => e.AppointmentNumber).IsUnique();

                entity.HasOne(a => a.Pet)
                    .WithMany(p => p.Appointments)
                    .HasForeignKey(a => a.PetId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(a => a.Veterinarian)
                    .WithMany(u => u.VeterinarianAppointments)
                    .HasForeignKey(a => a.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(a => a.Service)
                    .WithMany(s => s.Appointments)
                    .HasForeignKey(a => a.ServiceId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasMany(a => a.MedicalRecords)
                    .WithOne(mr => mr.Appointment)
                    .HasForeignKey(mr => mr.AppointmentId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure MedicalRecord entity
            modelBuilder.Entity<MedicalRecord>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).HasMaxLength(200);
                entity.Property(e => e.Description).HasMaxLength(2000);
                entity.Property(e => e.Diagnosis).HasMaxLength(500);
                entity.Property(e => e.Treatment).HasMaxLength(1000);
                entity.Property(e => e.Prescription).HasMaxLength(1000);
                entity.Property(e => e.Symptoms).HasMaxLength(500);
                entity.Property(e => e.HeartRate).HasMaxLength(100);
                entity.Property(e => e.BloodPressure).HasMaxLength(100);
                entity.Property(e => e.Cost).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Notes).HasMaxLength(1000);

                entity.HasOne(mr => mr.Pet)
                    .WithMany(p => p.MedicalRecords)
                    .HasForeignKey(mr => mr.PetId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(mr => mr.Veterinarian)
                    .WithMany(u => u.MedicalRecords)
                    .HasForeignKey(mr => mr.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(mr => mr.Appointment)
                    .WithMany(a => a.MedicalRecords)
                    .HasForeignKey(mr => mr.AppointmentId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasMany(mr => mr.Prescriptions)
                    .WithOne(p => p.MedicalRecord)
                    .HasForeignKey(p => p.MedicalRecordId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Prescription entity
            modelBuilder.Entity<Prescription>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.MedicationName).HasMaxLength(200);
                entity.Property(e => e.Dosage).HasMaxLength(100);
                entity.Property(e => e.Instructions).HasMaxLength(200);
                entity.Property(e => e.Cost).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Notes).HasMaxLength(500);

                entity.HasOne(p => p.MedicalRecord)
                    .WithMany(mr => mr.Prescriptions)
                    .HasForeignKey(p => p.MedicalRecordId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(p => p.Pet)
                    .WithMany()
                    .HasForeignKey(p => p.PetId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(p => p.Veterinarian)
                    .WithMany()
                    .HasForeignKey(p => p.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure TwoFactorCode entity
            modelBuilder.Entity<TwoFactorCode>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Code).HasMaxLength(6);
                entity.Property(e => e.ClientType).HasMaxLength(50);
                entity.Property(e => e.IpAddress).HasMaxLength(100);

                entity.HasOne(tfc => tfc.User)
                    .WithMany()
                    .HasForeignKey(tfc => tfc.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Index for faster lookups
                entity.HasIndex(e => new { e.UserId, e.Code });
                entity.HasIndex(e => e.CreatedAt);
            });

            // Configure EmailVerificationCode entity
            modelBuilder.Entity<EmailVerificationCode>(entity =>
            {
                entity.HasKey(e => e.Id);
                // Switch to link-based token: allow longer URL-safe token
                entity.Property(e => e.Code).HasMaxLength(128);
                entity.Property(e => e.IpAddress).HasMaxLength(100);
                entity.Property(e => e.UserAgent).HasMaxLength(500);

                entity.HasOne(evc => evc.User)
                    .WithMany()
                    .HasForeignKey(evc => evc.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Index for faster lookups
                entity.HasIndex(e => new { e.UserId, e.Code });
                entity.HasIndex(e => e.CreatedAt);
            });

            // Configure Review entity
            modelBuilder.Entity<Review>(entity =>
            {
                entity.ToTable("Review"); // Eksplicitno postavi ime tabele
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).HasMaxLength(100);
                entity.Property(e => e.Comment).HasMaxLength(2000);
                entity.Property(e => e.PetName).HasMaxLength(100);
                entity.Property(e => e.PetSpecies).HasMaxLength(50);

                // Configure foreign key properties explicitly
                entity.Property(e => e.UserId).IsRequired();
                entity.Property(e => e.VeterinarianId).IsRequired(false);
                entity.Property(e => e.ServiceId).IsRequired(false);
                entity.Property(e => e.OrderId).IsRequired(false);

                // Configure relationship: Review -> User (koji je ostavio review)
                entity.HasOne(r => r.User)
                    .WithMany(u => u.Reviews)
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Configure relationship: Review -> Veterinarian (User koji se ocjenjuje)
                entity.HasOne(r => r.Veterinarian)
                    .WithMany()
                    .HasForeignKey(r => r.VeterinarianId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Configure relationship: Review -> Service (opcionalno)
                entity.HasOne(r => r.Service)
                    .WithMany()
                    .HasForeignKey(r => r.ServiceId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Configure relationship: Review -> Order (opcionalno)
                entity.HasOne(r => r.Order)
                    .WithMany()
                    .HasForeignKey(r => r.OrderId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Indexes for faster lookups
                entity.HasIndex(e => e.VeterinarianId);
                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => e.ServiceId);
                entity.HasIndex(e => e.IsApproved);
            });
        }
    }
}
