using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.SearchObjects;
using eVeterinarskaStanicaServices.Database;
using System.Diagnostics;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServiceController : ControllerBase
    {
        private readonly iServiceService _serviceService;
        private readonly ApplicationDbContext _context;

        public ServiceController(iServiceService serviceService, ApplicationDbContext context)
        {
            _serviceService = serviceService;
            _context = context;
        }

        // Helper metoda za normalizaciju naziva vrste
        private string NormalizeSpecies(string species)
        {
            if (string.IsNullOrWhiteSpace(species))
                return string.Empty;

            var normalized = species.Trim();
            var normalizedLower = normalized
                .ToLowerInvariant()
                .Replace("č", "c")
                .Replace("ć", "c")
                .Replace("š", "s")
                .Replace("đ", "dj")
                .Replace("ž", "z");

            return normalizedLower switch
            {
                "macka" => "Mačka",
                "pas" => "Pas",
                "ptica" => "Ptica",
                "papagaj" => "Ptica",
                "papiga" => "Ptica",
                "zec" => "Zec",
                "glodar" => "Glodar",
                _ => normalized
            };
        }

        // GET: api/Service
        [HttpGet]
        public ActionResult<IEnumerable<Service>> GetServices([FromQuery] ServiceSearchObject? searchObject = null, [FromQuery] string? species = null)
        {
            // Ako je navedena vrsta, učitaj sve usluge direktno iz baze (bez paginacije)
            if (!string.IsNullOrEmpty(species))
            {
                // Normalizuj species string (trim, case-insensitive i mapiranje varijanti)
                var normalizedSpecies = NormalizeSpecies(species);
                Debug.WriteLine($"[GetServices] Requested species: '{species}' -> Normalized: '{normalizedSpecies}'");
                
                // Učitaj sve cijene za tu vrstu direktno iz baze
                // Prvo učitamo sve cijene u memoriju, zatim filtriramo jer EF ne može prevesti StringComparison u SQL
                var allSpeciesPrices = _context.ServiceSpeciesPrices
                    .ToList() // Učitaj sve u memoriju prvo
                    .Where(ssp => string.Equals(ssp.Species.Trim(), normalizedSpecies, StringComparison.OrdinalIgnoreCase))
                    .ToList();
                
                Debug.WriteLine($"[GetServices] Found {allSpeciesPrices.Count} prices for species '{normalizedSpecies}'");
                
                // Učitaj sve usluge koje imaju cijene za tu vrstu
                var serviceIds = allSpeciesPrices.Select(ssp => ssp.ServiceId).Distinct().ToList();
                var services = _context.Services
                    .Include(s => s.Category)
                    .Where(s => serviceIds.Contains(s.Id) && (s.IsActive == true))
                    .ToList();
                
                Debug.WriteLine($"[GetServices] Found {services.Count} services with prices for species '{normalizedSpecies}'");
                
                // Napravi dictionary za brzo pronalaženje cijena
                var speciesPrices = allSpeciesPrices
                    .ToDictionary(ssp => ssp.ServiceId, ssp => new { ssp.Price, ssp.DiscountPrice });
                
                var servicesWithPrices = services.Select(s => new
                {
                    s.Id,
                    s.Name,
                    s.Code,
                    s.Description,
                    s.ShortDescription,
                    Price = speciesPrices.ContainsKey(s.Id) ? (decimal?)speciesPrices[s.Id].Price : null,
                    DiscountPrice = speciesPrices.ContainsKey(s.Id) ? speciesPrices[s.Id].DiscountPrice : null,
                    s.ImageUrl,
                    s.IsActive,
                    s.IsFeatured,
                    s.DurationMinutes,
                    s.RequiresAppointment,
                    s.ServiceType,
                    s.AgeGroup,
                    s.RequiresFasting,
                    s.PreparationInstructions,
                    s.PostCareInstructions,
                    s.CategoryId,
                    Category = s.Category
                }).Where(s => s.Price != null).ToList(); // Filtriraj samo usluge koje imaju cijenu za tu vrstu
                
                return Ok(servicesWithPrices);
            }
            
            // Bez species parametra - vrati usluge bez Price (cijene se učitavaju samo iz ServiceSpeciesPrices)
            var search = searchObject ?? new ServiceSearchObject();
            var servicesResult = _serviceService.Get(search);
            var servicesWithoutPrice = servicesResult.Select(s => new
            {
                s.Id,
                s.Name,
                s.Code,
                s.Description,
                s.ShortDescription,
                Price = (decimal?)null, // Ne vraćaj Price iz Services tabele
                DiscountPrice = (decimal?)null,
                s.ImageUrl,
                s.IsActive,
                s.IsFeatured,
                s.DurationMinutes,
                s.RequiresAppointment,
                s.ServiceType,
                s.AgeGroup,
                s.RequiresFasting,
                s.PreparationInstructions,
                s.PostCareInstructions,
                s.CategoryId,
                Category = s.Category
            }).ToList();
            
            return Ok(servicesWithoutPrice);
        }

        // GET: api/Service/5
        [HttpGet("{id}")]
        public ActionResult<Service> GetService(int id, [FromQuery] string? species = null)
        {
            var service = _serviceService.Get(id);

            if (service == null)
            {
                return NotFound();
            }

            // Ako je navedena vrsta, vrati uslugu sa cijenom za tu vrstu
            if (!string.IsNullOrEmpty(species))
            {
                // Normalizuj species string (trim, case-insensitive i mapiranje varijanti)
                var normalizedSpecies = NormalizeSpecies(species);
                
                // Učitaj sve cijene za ovu uslugu i filtriraj u memoriji
                var allSpeciesPrices = _context.ServiceSpeciesPrices
                    .Where(ssp => ssp.ServiceId == id)
                    .ToList();
                
                var speciesPrice = allSpeciesPrices
                    .FirstOrDefault(ssp => ssp.Species.Trim().Equals(normalizedSpecies, StringComparison.OrdinalIgnoreCase));
                
                if (speciesPrice != null)
                {
                    return Ok(new
                    {
                        service.Id,
                        service.Name,
                        service.Code,
                        service.Description,
                        service.ShortDescription,
                        Price = speciesPrice.Price,
                        DiscountPrice = speciesPrice.DiscountPrice,
                        service.ImageUrl,
                        service.IsActive,
                        service.IsFeatured,
                        service.DurationMinutes,
                        service.RequiresAppointment,
                        service.ServiceType,
                        service.AgeGroup,
                        service.RequiresFasting,
                        service.PreparationInstructions,
                        service.PostCareInstructions,
                        service.CategoryId,
                        Category = service.Category
                    });
                }
                else
                {
                    // Nema cijene za tu vrstu - vrati uslugu bez Price
                    return Ok(new
                    {
                        service.Id,
                        service.Name,
                        service.Code,
                        service.Description,
                        service.ShortDescription,
                        Price = (decimal?)null,
                        DiscountPrice = (decimal?)null,
                        service.ImageUrl,
                        service.IsActive,
                        service.IsFeatured,
                        service.DurationMinutes,
                        service.RequiresAppointment,
                        service.ServiceType,
                        service.AgeGroup,
                        service.RequiresFasting,
                        service.PreparationInstructions,
                        service.PostCareInstructions,
                        service.CategoryId,
                        Category = service.Category
                    });
                }
            }

            // Bez species parametra - vrati uslugu bez Price (cijene se učitavaju samo iz ServiceSpeciesPrices)
            return Ok(new
            {
                service.Id,
                service.Name,
                service.Code,
                service.Description,
                service.ShortDescription,
                Price = (decimal?)null, // Ne vraćaj Price iz Services tabele
                DiscountPrice = (decimal?)null,
                service.ImageUrl,
                service.IsActive,
                service.IsFeatured,
                service.DurationMinutes,
                service.RequiresAppointment,
                service.ServiceType,
                service.AgeGroup,
                service.RequiresFasting,
                service.PreparationInstructions,
                service.PostCareInstructions,
                service.CategoryId,
                Category = service.Category
            });
        }

        // GET: api/Service/species/{species}
        [HttpGet("species/{species}")]
        public async Task<ActionResult<IEnumerable<object>>> GetServicesBySpecies(string species)
        {
            var normalizedSpecies = NormalizeSpecies(species);
            
            var services = await _context.Services
                .Include(s => s.Category)
                .Include(s => s.ServiceSpeciesPrices)
                .Where(s => s.IsActive)
                .ToListAsync();

            var servicesWithPrices = services
                .Select(s => new
                {
                    Service = s,
                    SpeciesPrice = s.ServiceSpeciesPrices
                        .ToList()
                        .FirstOrDefault(ssp => ssp.Species.Trim().Equals(normalizedSpecies, StringComparison.OrdinalIgnoreCase))
                })
                .Where(x => x.SpeciesPrice != null)
                .Select(x => new
                {
                    x.Service.Id,
                    x.Service.Name,
                    x.Service.Code,
                    x.Service.Description,
                    x.Service.ShortDescription,
                    Price = x.SpeciesPrice!.Price,
                    DiscountPrice = x.SpeciesPrice.DiscountPrice,
                    x.Service.ImageUrl,
                    x.Service.IsActive,
                    x.Service.IsFeatured,
                    x.Service.DurationMinutes,
                    x.Service.RequiresAppointment,
                    x.Service.ServiceType,
                    x.Service.AgeGroup,
                    x.Service.RequiresFasting,
                    x.Service.PreparationInstructions,
                    x.Service.PostCareInstructions,
                    x.Service.CategoryId,
                    Category = x.Service.Category != null ? new { x.Service.Category.Id, x.Service.Category.Name } : null
                })
                .ToList();

            return Ok(servicesWithPrices);
        }
    }
}