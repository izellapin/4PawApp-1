using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaServices.Database;
using veterinarskaStanica.WebAPI.Authorization;
using eVeterinarskaStanicaModel;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PetsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<PetsController> _logger;

        public PetsController(ApplicationDbContext context, ILogger<PetsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: api/Pets
        [HttpGet]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<IEnumerable<Pet>>> GetPets()
        {
            // Get current user role
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                return Unauthorized();
            }

            var petsQuery = _context.Pets
                .Include(p => p.PetOwner)
                .Where(p => p.Status == PetStatus.Active);

            if (userRole == UserRole.Admin)
            {
                // Admin vidi sve pacijente
                var pets = await petsQuery
                    .OrderBy(p => p.Name)
                    .ToListAsync();
                return Ok(pets);
            }
            else if (userRole == UserRole.Veterinarian)
            {
                // Get current user ID
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int veterinarianId))
                {
                    return Unauthorized();
                }

                _logger.LogInformation($"🔍 Veterinarian ID: {veterinarianId} requesting pets");

                // Veterinar vidi pacijente koji su imali termine sa njim ILI koje je on dodao
                var petIdsFromAppointments = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && a.Pet != null && a.Pet.Status == PetStatus.Active)
                    .Select(a => a.PetId)
                    .Distinct()
                    .ToListAsync();

                // Veterinar vidi pacijente koje je dodao ILI s kojima ima termine
                var petIdsFromCreated = await _context.Pets
                    .Where(p => p.Status == PetStatus.Active && p.CreatedBy == veterinarianId)
                    .Select(p => p.Id)
                    .ToListAsync();

                // Kombinuj oba skupa
                var allPetIds = petIdsFromAppointments.Union(petIdsFromCreated).ToList();

                _logger.LogInformation($"🔍 Found {petIdsFromAppointments.Count} pets from appointments and {petIdsFromCreated.Count} pets created by veterinarian {veterinarianId}");
                _logger.LogInformation($"🔍 Total unique pet IDs for veterinarian {veterinarianId}: [{string.Join(", ", allPetIds)}]");

                var pets = await petsQuery
                    .Where(p => allPetIds.Contains(p.Id))
                    .OrderBy(p => p.Name)
                    .ToListAsync();

                _logger.LogInformation($"🔍 Returning {pets.Count} pets for veterinarian {veterinarianId}");
                return Ok(pets);
            }

            return Forbid();
        }

        // GET: api/Pets/all
        [HttpGet("all")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<IEnumerable<Pet>>> GetAllPets()
        {
            // Get current user role
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                return Unauthorized();
            }

            var petsQuery = _context.Pets
                .Include(p => p.PetOwner)
                .Where(p => p.Status == PetStatus.Active);

            if (userRole == UserRole.Admin)
            {
                // Admin vidi sve pacijente
                var pets = await petsQuery
                    .OrderBy(p => p.Name)
                    .ToListAsync();
                return Ok(pets);
            }
            else if (userRole == UserRole.Veterinarian)
            {
                // Veterinar vidi sve pacijente (bez filtriranja)
                var pets = await petsQuery
                    .OrderBy(p => p.Name)
                    .ToListAsync();
                return Ok(pets);
            }

            return Forbid();
        }

        // GET: api/Pets/5
        [HttpGet("{id:int}")]
        public async Task<ActionResult<Pet>> GetPet(int id)
        {
            var pet = await _context.Pets
                .Include(p => p.PetOwner)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (pet == null)
            {
                return NotFound();
            }

            return Ok(pet);
        }

        // GET: api/Pets/owner/5
        [HttpGet("owner/{ownerId}")]
        public async Task<ActionResult<IEnumerable<Pet>>> GetPetsByOwner(int ownerId)
        {
            var pets = await _context.Pets
                .Include(p => p.PetOwner)
                .Where(p => p.PetOwnerId == ownerId && p.Status == PetStatus.Active)
                .OrderBy(p => p.Name)
                .ToListAsync();

            return Ok(pets);
        }

        // POST: api/Pets
        [HttpPost]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<Pet>> CreatePet(PetCreateRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Provjeri da li vlasnik postoji
            var owner = await _context.Users.FindAsync(request.PetOwnerId);
            if (owner == null)
            {
                return BadRequest("Vlasnik nije pronađen");
            }

            // Get current user ID (veterinar ili admin koji dodaje pacijenta)
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int createdBy))
            {
                return Unauthorized();
            }

            var pet = new Pet
            {
                Name = request.Name,
                Species = request.Species,
                Breed = request.Breed,
                Gender = request.Gender,
                DateOfBirth = request.DateOfBirth,
                Weight = request.Weight,
                Color = request.Color,
                PetOwnerId = request.PetOwnerId,
                Status = PetStatus.Active,
                DateCreated = DateTime.UtcNow,
                CreatedBy = createdBy
            };

            _context.Pets.Add(pet);
            await _context.SaveChangesAsync();

            // Dohvati kreirani pet sa owner podacima
            var createdPet = await _context.Pets
                .Include(p => p.PetOwner)
                .FirstOrDefaultAsync(p => p.Id == pet.Id);

            return CreatedAtAction(nameof(GetPet), new { id = pet.Id }, createdPet);
        }

        // GET: api/Pets/my
        [HttpGet("my")]
        public async Task<ActionResult<IEnumerable<Pet>>> GetMyPets()
        {
            // Get current user ID from token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Nevaljan korisnik ID");
            }

            var pets = await _context.Pets
                .Include(p => p.PetOwner)
                .Where(p => p.PetOwnerId == userId && p.Status == PetStatus.Active)
                .OrderBy(p => p.Name)
                .ToListAsync();

            return Ok(pets);
        }

        // POST: api/Pets/my
        [HttpPost("my")]
        public async Task<ActionResult<Pet>> CreateMyPet(PetCreateRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Get current user ID from token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Nevaljan korisnik ID");
            }

            // Set the pet owner to current user
            request.PetOwnerId = userId;

            var pet = new Pet
            {
                Name = request.Name,
                Species = request.Species,
                Breed = request.Breed,
                Gender = request.Gender,
                DateOfBirth = request.DateOfBirth,
                Color = request.Color,
                Weight = request.Weight,
                MicrochipNumber = request.MicrochipNumber,
                Status = PetStatus.Active,
                Notes = request.Notes,
                DateCreated = DateTime.UtcNow,
                PetOwnerId = request.PetOwnerId
            };

            _context.Pets.Add(pet);
            await _context.SaveChangesAsync();

            // Dohvati kreirani pet sa owner podacima
            var createdPet = await _context.Pets
                .Include(p => p.PetOwner)
                .FirstOrDefaultAsync(p => p.Id == pet.Id);

            return CreatedAtAction(nameof(GetPet), new { id = pet.Id }, createdPet);
        }

        // PUT: api/Pets/5
        [HttpPut("{id}")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<Pet>> UpdatePet(int id, PetUpdateRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var pet = await _context.Pets.FindAsync(id);
            if (pet == null)
            {
                return NotFound();
            }

            // Get current user role and ID
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                return Unauthorized();
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            // Check permissions
            if (userRole == UserRole.Admin)
            {
                // Admin može da ažurira sve pacijente
            }
            else if (userRole == UserRole.Veterinarian)
            {
                // Veterinar može da ažurira samo pacijente koji su imali termine sa njim
                var hasAppointment = await _context.Appointments
                    .AnyAsync(a => a.PetId == pet.Id && a.VeterinarianId == userId);
                
                if (!hasAppointment)
                {
                    return Forbid();
                }
            }
            else
            {
                return Forbid();
            }

            // Ažuriraj polja
            pet.Name = request.Name ?? pet.Name;
            pet.Species = request.Species ?? pet.Species;
            pet.Breed = request.Breed ?? pet.Breed;
            pet.Gender = request.Gender ?? pet.Gender;
            pet.DateOfBirth = request.DateOfBirth ?? pet.DateOfBirth;
            pet.Weight = request.Weight ?? pet.Weight;
            pet.Color = request.Color ?? pet.Color;
            pet.MicrochipNumber = request.MicrochipNumber ?? pet.MicrochipNumber;
            pet.Notes = request.Notes ?? pet.Notes;
            pet.Status = request.Status ?? pet.Status;
            pet.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Dohvati ažurirani pet sa owner podacima
            var updatedPet = await _context.Pets
                .Include(p => p.PetOwner)
                .FirstOrDefaultAsync(p => p.Id == pet.Id);

            return Ok(updatedPet);
        }

        // DELETE: api/Pets/5
        [HttpDelete("{id}")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<IActionResult> DeletePet(int id)
        {
            var pet = await _context.Pets.FindAsync(id);
            if (pet == null)
            {
                return NotFound();
            }

            // Get current user role and ID
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                return Unauthorized();
            }

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            // Check permissions
            if (userRole == UserRole.Admin)
            {
                // Admin može da briše sve pacijente
            }
            else if (userRole == UserRole.Veterinarian)
            {
                // Veterinar može da briše samo pacijente koji su imali termine sa njim
                var hasAppointment = await _context.Appointments
                    .AnyAsync(a => a.PetId == pet.Id && a.VeterinarianId == userId);
                
                if (!hasAppointment)
                {
                    return Forbid();
                }
            }
            else
            {
                return Forbid();
            }

            // Soft delete - označava kao neaktivan
            pet.Status = PetStatus.Inactive;
            pet.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/Pets/my/5
        [HttpDelete("my/{id}")]
        public async Task<IActionResult> DeleteMyPet(int id)
        {
            // Get current user ID from token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Nevaljan korisnik ID");
            }

            var pet = await _context.Pets.FindAsync(id);
            if (pet == null)
            {
                return NotFound();
            }

            // Provjeri da li je korisnik vlasnik ljubimca
            if (pet.PetOwnerId != userId)
            {
                return Forbid();
            }

            // Soft delete - označava kao neaktivan
            pet.Status = PetStatus.Inactive;
            pet.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/Pets/my/5
        [HttpPut("my/{id}")]
        public async Task<ActionResult<Pet>> UpdateMyPet(int id, PetUpdateRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Get current user ID from token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return BadRequest("Nevaljan korisnik ID");
            }

            var pet = await _context.Pets.FindAsync(id);
            if (pet == null)
            {
                return NotFound();
            }

            // Provjeri da li je korisnik vlasnik ljubimca
            if (pet.PetOwnerId != userId)
            {
                return Forbid();
            }

            // Ažuriraj polja
            pet.Name = request.Name ?? pet.Name;
            pet.Species = request.Species ?? pet.Species;
            pet.Breed = request.Breed ?? pet.Breed;
            pet.Gender = request.Gender ?? pet.Gender;
            pet.DateOfBirth = request.DateOfBirth ?? pet.DateOfBirth;
            pet.Weight = request.Weight ?? pet.Weight;
            pet.Color = request.Color ?? pet.Color;
            pet.MicrochipNumber = request.MicrochipNumber ?? pet.MicrochipNumber;
            pet.Notes = request.Notes ?? pet.Notes;
            pet.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Dohvati ažurirani pet sa owner podacima
            var updatedPet = await _context.Pets
                .Include(p => p.PetOwner)
                .FirstOrDefaultAsync(p => p.Id == pet.Id);

            return Ok(updatedPet);
        }
    }

    // Request modeli
    public class PetCreateRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Species { get; set; } = string.Empty;

        [StringLength(50)]
        public string? Breed { get; set; }

        public PetGender Gender { get; set; }

        public DateTime? DateOfBirth { get; set; }

        [Range(0, 200)]
        public decimal? Weight { get; set; }

        [StringLength(20)]
        public string? Color { get; set; }

        [StringLength(50)]
        public string? MicrochipNumber { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Required]
        public int PetOwnerId { get; set; }
    }

    public class PetUpdateRequest
    {
        [StringLength(100)]
        public string? Name { get; set; }

        [StringLength(50)]
        public string? Species { get; set; }

        [StringLength(50)]
        public string? Breed { get; set; }

        public PetGender? Gender { get; set; }

        public DateTime? DateOfBirth { get; set; }

        [Range(0, 200)]
        public decimal? Weight { get; set; }

        [StringLength(20)]
        public string? Color { get; set; }

        [StringLength(50)]
        public string? MicrochipNumber { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        public PetStatus? Status { get; set; }
    }
}
