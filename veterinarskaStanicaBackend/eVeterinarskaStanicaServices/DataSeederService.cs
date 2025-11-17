using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaServices.Database;

namespace eVeterinarskaStanicaServices
{
    public class DataSeederService : IDataSeederService
    {
        private readonly ApplicationDbContext _context;
        private readonly IHashingService _hashingService;
        private readonly ILogger<DataSeederService> _logger;

        public DataSeederService(ApplicationDbContext context, IHashingService hashingService, ILogger<DataSeederService> logger)
        {
            _context = context;
            _hashingService = hashingService;
            _logger = logger;
        }

        public async Task SeedInitialDataAsync()
        {
            try
            {
                _logger.LogInformation("Starting initial data seeding...");

                // Ensure database is created
                await _context.Database.EnsureCreatedAsync();

                // Seed in order of dependencies
                await SeedAdminUserAsync();
                await SeedCategoriesAsync();
                await SeedServicesAsync();
                await SeedServiceSpeciesPricesAsync(); // Eksplicitno pozovi seeding cijena
                
                // Seed test data for appointments and pets
                await SeedTestDataAsync();

                _logger.LogInformation("Initial data seeding completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred during data seeding");
                throw;
            }
        }

        public async Task SeedAdminUserAsync()
        {
            try
            {
                // Check if admin user already exists
                var existingAdmin = await _context.Users
                    .FirstOrDefaultAsync(u => u.Role == UserRole.Admin);

                if (existingAdmin != null)
                {
                    _logger.LogInformation("Admin user already exists, skipping admin seeding");
                    return;
                }

                // Create default admin user
                var adminPassword = "Admin123!";
                var adminHash = _hashingService.HashPassword(adminPassword, out byte[] adminSalt);

                var adminUser = new User
                {
                    FirstName = "admin",
                    LastName = "admin",
                    Email = "izellapin@gmail.com",
                    Username = "admin",
                    PasswordHash = adminHash,
                    PasswordSalt = Convert.ToBase64String(adminSalt),
                    Role = UserRole.Admin,
                    IsActive = true,
                    IsEmailVerified = true,
                    DateCreated = DateTime.UtcNow
                };

                _context.Users.Add(adminUser);

                // Create a veterinarian user for testing
                var vetPassword = "Sifra123!";
                var vetHash = _hashingService.HashPassword(vetPassword, out byte[] vetSalt);

                var vetUser = new User
                {
                    FirstName = "Izel",
                    LastName = "User",
                    Email = "izel.repuh@edu.fit.ba",
                    Username = "drsmith",
                    PasswordHash = vetHash,
                    PasswordSalt = Convert.ToBase64String(vetSalt),
                    Role = UserRole.Veterinarian,
                    IsActive = true,
                    IsEmailVerified = true,
                    DateCreated = DateTime.UtcNow,
                    LicenseNumber = "VET-2024-001",
                    Specialization = "General Practice",
                    YearsOfExperience = 10,
                    Biography = "Experienced veterinarian with a passion for animal care.",
                    WorkStartTime = new TimeSpan(8, 0, 0), // 8:00 AM
                    WorkEndTime = new TimeSpan(18, 0, 0),  // 6:00 PM
                    WorkDays = "Monday,Tuesday,Wednesday,Thursday,Friday"
                };

                _context.Users.Add(vetUser);

                // Create a mobile user (pet owner) for testing
                var mobilePassword = "Mobile123!";
                var mobileHash = _hashingService.HashPassword(mobilePassword, out byte[] mobileSalt);

                var mobileUser = new User
                {
                    FirstName = "Jane",
                    LastName = "Doe",
                    Email = "petowner@email.com",
                    Username = "janedoe",
                    PasswordHash = mobileHash,
                    PasswordSalt = Convert.ToBase64String(mobileSalt),
                    Role = UserRole.PetOwner,
                    IsActive = true,
                    IsEmailVerified = true,
                    DateCreated = DateTime.UtcNow,
                    PhoneNumber = "+1234567890",
                    Address = "123 Pet Street, Animal City"
                };

                _context.Users.Add(mobileUser);

                await _context.SaveChangesAsync();

                _logger.LogInformation("Default users seeded successfully:");
                _logger.LogInformation("Admin - Email: izellapin@gmail.com, Password: Admin123!");
                _logger.LogInformation("Veterinarian - Email: izel.repuh@edu.fit.ba, Password: Vet123!");
                _logger.LogInformation("Pet Owner - Email: petowner@email.com, Password: Mobile123!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding admin user");
                throw;
            }
        }

        public async Task SeedCategoriesAsync()
        {
            try
            {
                // Clear existing services first to avoid foreign key constraint issues
                if (await _context.Services.AnyAsync())
                {
                    _logger.LogInformation("Clearing existing services to update with new data");
                    _context.Services.RemoveRange(_context.Services);
                    await _context.SaveChangesAsync();
                }

                // Clear existing categories to update with new data
                if (await _context.Categories.AnyAsync())
                {
                    _logger.LogInformation("Clearing existing categories to update with new data");
                    _context.Categories.RemoveRange(_context.Categories);
                    await _context.SaveChangesAsync();
                }

                var categories = new[]
                {
                    new Category
                    {
                        Name = "Prevencija i zdravlje",
                        Description = "Preventivna njega i zdravstvene usluge",
                        CategoryType = "Medicinski",
                        TargetSpecies = "Svi",
                        IsActive = true,
                        DateCreated = DateTime.UtcNow,
                        SortOrder = 1
                    },
                    new Category
                    {
                        Name = "Hitna pomoć",
                        Description = "Hitne i urgentne veterinarske usluge",
                        CategoryType = "Hitno",
                        TargetSpecies = "Svi",
                        IsActive = true,
                        DateCreated = DateTime.UtcNow,
                        SortOrder = 2
                    },
                    new Category
                    {
                        Name = "Hirurgija",
                        Description = "Hirurški zahvati i operacije",
                        CategoryType = "Hirurški",
                        TargetSpecies = "Svi",
                        IsActive = true,
                        DateCreated = DateTime.UtcNow,
                        SortOrder = 3
                    },
                    new Category
                    {
                        Name = "Stomatologija",
                        Description = "Čišćenje zuba i usluge oralnog zdravlja",
                        CategoryType = "Medicinski",
                        TargetSpecies = "Svi",
                        IsActive = true,
                        DateCreated = DateTime.UtcNow,
                        SortOrder = 4
                    },
                    new Category
                    {
                        Name = "Čišćenje",
                        Description = "Čišćenje ljubimaca i higijenske usluge",
                        CategoryType = "Čišćenje",
                        TargetSpecies = "Svi",
                        IsActive = true,
                        DateCreated = DateTime.UtcNow,
                        SortOrder = 5
                    }
                };

                _context.Categories.AddRange(categories);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Seeded {categories.Length} categories successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding categories");
                throw;
            }
        }

        public async Task SeedServiceSpeciesPricesAsync()
        {
            try
            {
                _logger.LogInformation("Starting ServiceSpeciesPrices seeding...");

                // Uzmi sve usluge
                var services = await _context.Services.ToListAsync();
                if (services.Count == 0)
                {
                    _logger.LogWarning("No services found. Skipping ServiceSpeciesPrices seeding.");
                    return;
                }

                var species = new[] { "Pas", "Mačka", "Ptica", "Zec", "Glodar" };
                var addedCount = 0;
                var updatedCount = 0;

                foreach (var service in services)
                {
                    foreach (var speciesName in species)
                    {
                        // Provjeri da li već postoji
                        var existing = await _context.ServiceSpeciesPrices
                            .FirstOrDefaultAsync(ssp => ssp.ServiceId == service.Id && ssp.Species == speciesName);

                        if (existing != null)
                        {
                            // Ažuriraj postojeći ako je cijena drugačija
                            decimal newPrice = GetPriceForServiceAndSpecies(service.Name, speciesName, service.Price);
                            if (existing.Price != newPrice)
                            {
                                existing.Price = newPrice;
                                existing.DateModified = DateTime.UtcNow;
                                updatedCount++;
                            }
                        }
                        else
                        {
                            // Dodaj novi
                            decimal price = GetPriceForServiceAndSpecies(service.Name, speciesName, service.Price);
                            _context.ServiceSpeciesPrices.Add(new ServiceSpeciesPrice
                            {
                                ServiceId = service.Id,
                                Species = speciesName,
                                Price = price,
                                DateCreated = DateTime.UtcNow
                            });
                            addedCount++;
                        }
                    }
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"ServiceSpeciesPrices seeding completed. Added: {addedCount}, Updated: {updatedCount}, Total: {await _context.ServiceSpeciesPrices.CountAsync()}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding ServiceSpeciesPrices");
                throw;
            }
        }

        public async Task SeedServicesAsync()
        {
            try
            {
                // Services are already cleared in SeedCategoriesAsync

                // Get categories for foreign key references (use FirstOrDefault to avoid crashes)
                var wellnessCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Prevencija i zdravlje");
                var emergencyCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Hitna pomoć");
                var surgeryCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Hirurgija");
                var dentalCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Stomatologija");
                var groomingCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Čišćenje");

                // If categories don't exist, use the first available category or create a default one
                var defaultCategory = wellnessCategory ?? emergencyCategory ?? surgeryCategory ?? dentalCategory ?? groomingCategory;
                if (defaultCategory == null)
                {
                    // Get any existing category
                    defaultCategory = await _context.Categories.FirstOrDefaultAsync();
                    if (defaultCategory == null)
                    {
                        _logger.LogWarning("No categories found for services. Skipping service seeding.");
                        return;
                    }
                }

                // Use default category for missing ones
                wellnessCategory ??= defaultCategory;
                emergencyCategory ??= defaultCategory;
                surgeryCategory ??= defaultCategory;
                dentalCategory ??= defaultCategory;
                groomingCategory ??= defaultCategory;

                var services = new[]
                {
                    // Wellness services
                    new Service
                    {
                        Name = "Godišnji pregled",
                        Code = "WELLNESS-001",
                        Description = "Sveobuhvatan godišnji zdravstveni pregled vašeg ljubimca",
                        ShortDescription = "Kompletni zdravstveni pregled",
                        Price = 75.00m,
                        DurationMinutes = 45,
                        RequiresAppointment = true,
                        ServiceType = "Pregled",
                        AgeGroup = "Svi",
                        CategoryId = wellnessCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    },
                    new Service
                    {
                        Name = "Vakcinacija",
                        Code = "WELLNESS-002",
                        Description = "Osnovne vakcine za zaštitu vašeg ljubimca od bolesti",
                        ShortDescription = "Osnovne vakcine",
                        Price = 120.00m,
                        DurationMinutes = 30,
                        RequiresAppointment = true,
                        ServiceType = "Vakcinacija",
                        AgeGroup = "Svi",
                        CategoryId = wellnessCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    },
                    // Emergency services
                    new Service
                    {
                        Name = "Hitna pomoć",
                        Code = "EMERGENCY-001",
                        Description = "Hitna veterinarska konsultacija za urgentne slučajeve",
                        ShortDescription = "Hitna veterinarska pomoć",
                        Price = 150.00m,
                        DurationMinutes = 60,
                        RequiresAppointment = false,
                        ServiceType = "Hitno",
                        AgeGroup = "Svi",
                        CategoryId = emergencyCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    },
                    // Surgery services
                    new Service
                    {
                        Name = "Sterilizacija",
                        Code = "SURGERY-001",
                        Description = "Hirurška sterilizacija ljubimca",
                        ShortDescription = "Operacija sterilizacije",
                        Price = 300.00m,
                        DurationMinutes = 120,
                        RequiresAppointment = true,
                        RequiresFasting = true,
                        ServiceType = "Hirurgija",
                        AgeGroup = "Odrasli",
                        PreparationInstructions = "Gladovanje 12 sati prije operacije",
                        PostCareInstructions = "Držati rez suvim i pratiti 10-14 dana",
                        CategoryId = surgeryCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    },
                    // Dental services
                    new Service
                    {
                        Name = "Čišćenje zuba",
                        Code = "DENTAL-001",
                        Description = "Profesionalno čišćenje zuba i procjena oralnog zdravlja",
                        ShortDescription = "Čišćenje zuba",
                        Price = 200.00m,
                        DurationMinutes = 90,
                        RequiresAppointment = true,
                        RequiresFasting = true,
                        ServiceType = "Stomatologija",
                        AgeGroup = "Odrasli",
                        PreparationInstructions = "Gladovanje 8 sati prije procedure",
                        CategoryId = dentalCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    },
                    // Grooming services
                    new Service
                    {
                        Name = "Kompletno čišćenje",
                        Code = "GROOMING-001",
                        Description = "Kompletna usluga čišćenja uključujući kupanje, šišanje noktiju i stilizovanje",
                        ShortDescription = "Kompletno čišćenje",
                        Price = 80.00m,
                        DurationMinutes = 120,
                        RequiresAppointment = true,
                        ServiceType = "Čišćenje",
                        AgeGroup = "Svi",
                        CategoryId = groomingCategory.Id,
                        IsActive = true,
                        DateCreated = DateTime.UtcNow
                    }
                };

                // Provjeri da li već postoje usluge
                var existingServices = await _context.Services.ToListAsync();
                
                if (existingServices.Count == 0)
                {
                    _context.Services.AddRange(services);
                    await _context.SaveChangesAsync();
                    existingServices = services.ToList();
                }
                else
                {
                    // Ako već postoje usluge, koristi postojeće
                    _logger.LogInformation($"Found {existingServices.Count} existing services, using them for species prices");
                }

                // Cijene će se dodati u SeedServiceSpeciesPricesAsync metodi

                _logger.LogInformation($"Service seeding completed. Total services: {existingServices.Count}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding services");
                throw;
            }
        }

        private decimal GetPriceForServiceAndSpecies(string serviceName, string speciesName, decimal defaultPrice)
        {
            return serviceName switch
            {
                "Godišnji pregled" => speciesName switch
                {
                    "Pas" => 75.00m,
                    "Mačka" => 70.00m,
                    "Ptica" => 60.00m,
                    "Zec" => 65.00m,
                    "Glodar" => 55.00m,
                    _ => defaultPrice
                },
                "Vakcinacija" => speciesName switch
                {
                    "Pas" => 120.00m,
                    "Mačka" => 110.00m,
                    "Ptica" => 100.00m,
                    "Zec" => 90.00m,
                    "Glodar" => 85.00m,
                    _ => defaultPrice
                },
                "Hitna pomoć" => speciesName switch
                {
                    "Pas" => 150.00m,
                    "Mačka" => 140.00m,
                    "Ptica" => 130.00m,
                    "Zec" => 125.00m,
                    "Glodar" => 120.00m,
                    _ => defaultPrice
                },
                "Sterilizacija" => speciesName switch
                {
                    "Pas" => 300.00m,
                    "Mačka" => 280.00m,
                    "Ptica" => 250.00m,
                    "Zec" => 200.00m,
                    "Glodar" => 180.00m,
                    _ => defaultPrice
                },
                "Čišćenje zuba" => speciesName switch
                {
                    "Pas" => 200.00m,
                    "Mačka" => 180.00m,
                    "Ptica" => 150.00m,
                    "Zec" => 120.00m,
                    "Glodar" => 100.00m,
                    _ => defaultPrice
                },
                "Kompletno čišćenje" => speciesName switch
                {
                    "Pas" => 80.00m,
                    "Mačka" => 75.00m,
                    "Ptica" => 70.00m,
                    "Zec" => 60.00m,
                    "Glodar" => 55.00m,
                    _ => defaultPrice
                },
                _ => defaultPrice
            };
        }

        public async Task SeedTestDataAsync()
        {
            try
            {
                _logger.LogInformation("Seeding test data...");

                // Get admin user (veterinarian)
                var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == UserRole.Admin);
                if (adminUser == null)
                {
                    _logger.LogWarning("Admin user not found, skipping test data seeding");
                    return;
                }

                // Create a test pet owner
                var testOwner = await _context.Users.FirstOrDefaultAsync(u => u.Email == "testowner@test.com");
                if (testOwner == null)
                {
                    byte[] salt;
                    var hash = _hashingService.HashPassword("test123", out salt);
                    
                    testOwner = new User
                    {
                        FirstName = "Marko",
                        LastName = "Petrović",
                        Email = "testowner@test.com",
                        Username = "testowner",
                        PhoneNumber = "+381601234567",
                        PasswordHash = hash,
                        PasswordSalt = Convert.ToBase64String(salt),
                        Role = UserRole.PetOwner,
                        IsActive = true,
                        IsEmailVerified = true,
                        DateCreated = DateTime.UtcNow
                    };
                    _context.Users.Add(testOwner);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"Created test owner with ID: {testOwner.Id}");
                }
                else
                {
                    _logger.LogInformation($"Test owner already exists with ID: {testOwner.Id}");
                    // Update existing user to ensure IsEmailVerified is true
                    testOwner.IsEmailVerified = true;
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"Force updated test owner IsEmailVerified to true");
                }

                // Create a test pet
                var testPet = await _context.Pets.FirstOrDefaultAsync(p => p.Name == "Rex");
                if (testPet == null)
                {
                    _logger.LogInformation($"Creating Rex pet for owner ID: {testOwner.Id}");
                    testPet = new Pet
                    {
                        Name = "Rex",
                        Species = "Pas",
                        Breed = "Nemački ovčar",
                        Gender = PetGender.Male,
                        DateOfBirth = DateTime.UtcNow.AddYears(-3),
                        Color = "Crn",
                        Weight = 35.5m,
                        MicrochipNumber = "123456789012345",
                        Status = PetStatus.Active,
                        Notes = "Test pas za demonstraciju",
                        DateCreated = DateTime.UtcNow,
                        PetOwnerId = testOwner.Id
                    };
                    _context.Pets.Add(testPet);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"Rex pet created successfully with ID: {testPet.Id}");
                }
                else
                {
                    _logger.LogInformation($"Rex pet already exists with ID: {testPet.Id}, Owner ID: {testPet.PetOwnerId}");
                    // Ensure Rex is Active - force update
                    testPet.Status = PetStatus.Active;
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"Force updated Rex status to Active");
                }

                // Create a test appointment for today
                var today = DateTime.Today;
                var existingAppointment = await _context.Appointments
                    .FirstOrDefaultAsync(a => a.PetId == testPet.Id && a.AppointmentDate.Date == today);
                
                if (existingAppointment == null)
                {
                    var testAppointment = new Appointment
                    {
                        AppointmentNumber = $"APT-{DateTime.Now:yyyyMMdd}-001",
                        AppointmentDate = today,
                        StartTime = new TimeSpan(10, 0, 0), // 10:00
                        EndTime = new TimeSpan(11, 0, 0),   // 11:00
                        Type = AppointmentType.Checkup,
                        Status = AppointmentStatus.Confirmed,
                        Reason = "Redovni pregled",
                        Notes = "Test termin za demonstraciju",
                        EstimatedCost = 2500.00m,
                        DateCreated = DateTime.UtcNow,
                        PetId = testPet.Id,
                        VeterinarianId = adminUser.Id
                    };
                    _context.Appointments.Add(testAppointment);
                    await _context.SaveChangesAsync();
                    
                    _logger.LogInformation("Test appointment created successfully");
                }

                _logger.LogInformation("Test data seeding completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding test data");
                throw;
            }
        }
    }
}
