using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaServices.Database;
using veterinarskaStanica.WebAPI.Authorization;
using eVeterinarskaStanicaModel;
using System.Security.Claims;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AdminController> _logger;

        public AdminController(ApplicationDbContext context, ILogger<AdminController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // POST: api/Admin/seed-service-species-prices
        [HttpPost("seed-service-species-prices")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult> SeedServiceSpeciesPrices()
        {
            try
            {
                _logger.LogInformation("Starting manual seeding of ServiceSpeciesPrices...");

                // Provjeri da li već postoje podaci
                var existingCount = await _context.ServiceSpeciesPrices.CountAsync();
                if (existingCount > 0)
                {
                    _logger.LogInformation($"Found {existingCount} existing ServiceSpeciesPrices. Will update/add missing ones.");
                }

                // Uzmi sve usluge
                var services = await _context.Services.ToListAsync();
                if (services.Count == 0)
                {
                    return BadRequest("Nema usluga u bazi. Prvo dodaj usluge.");
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
                            // Ažuriraj postojeći
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

                _logger.LogInformation($"ServiceSpeciesPrices seeding completed. Added: {addedCount}, Updated: {updatedCount}");

                return Ok(new
                {
                    message = "ServiceSpeciesPrices uspješno dodane/ažurirane",
                    added = addedCount,
                    updated = updatedCount,
                    total = await _context.ServiceSpeciesPrices.CountAsync()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding ServiceSpeciesPrices");
                return StatusCode(500, new { error = $"Greška: {ex.Message}" });
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
    }
}

