using eVeterinarskaStanicaModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using veterinarskaStanica.WebAPI.Authorization;
using eVeterinarskaStanicaServices.Database;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReviewsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ReviewsController> _logger;

        public ReviewsController(ApplicationDbContext context, ILogger<ReviewsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Svi review-i (admin), uključujući ime korisnika i veterinara
        /// </summary>
        [HttpGet("all")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult<List<ReviewDto>>> GetAllReviews()
        {
            var reviews = await _context.Set<Review>()
                .Include(r => r.User)
                .Include(r => r.Veterinarian)
                .OrderByDescending(r => r.DateCreated)
                .Select(r => new ReviewDto
                {
                    Id = r.Id,
                    Rating = r.Rating,
                    Title = r.Title,
                    Comment = r.Comment,
                    DateCreated = r.DateCreated,
                    IsVerifiedPurchase = r.IsVerifiedPurchase,
                    IsApproved = r.IsApproved,
                    PetName = r.PetName,
                    PetSpecies = r.PetSpecies,
                    VeterinarianName = r.Veterinarian != null ? r.Veterinarian.FirstName + " " + r.Veterinarian.LastName : null,
                    UserName = r.User.FirstName + " " + r.User.LastName
                })
                .ToListAsync();

            return Ok(reviews);
        }

        /// <summary>
        /// Brisanje review-a (admin)
        /// </summary>
        [HttpDelete("{id}")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult> DeleteReview(int id)
        {
            var review = await _context.Set<Review>().FindAsync(id);
            if (review == null) return NotFound();

            _context.Set<Review>().Remove(review);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        /// <summary>
        /// Kreiranje review-a za veterinara (samo PetOwner može ocjenjivati)
        /// </summary>
        [HttpPost("veterinarian/{veterinarianId}")]
        [RoleRequired(UserRole.PetOwner)]
        public async Task<ActionResult<ReviewDto>> CreateVeterinarianReview(
            int veterinarianId, 
            [FromBody] CreateReviewRequest request)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return BadRequest("Nevaljan korisnik ID");
                }

                // Provjeri da li veterinar postoji
                var veterinarian = await _context.Users
                    .FirstOrDefaultAsync(u => u.Id == veterinarianId && u.Role == UserRole.Veterinarian);
                
                if (veterinarian == null)
                {
                    return NotFound("Veterinar nije pronađen");
                }

                // Provjeri da li je korisnik bio kod ovog veterinara (završen ili plaćen ili prošao termin)
                var hasVisited = await _context.Appointments
                    .AnyAsync(a => a.VeterinarianId == veterinarianId &&
                                   a.Pet.PetOwnerId == userId &&
                                   (
                                       a.Status == AppointmentStatus.Completed ||
                                       a.IsPaid ||
                                       a.AppointmentDate < DateTime.UtcNow
                                   ));

                if (!hasVisited)
                {
                    return BadRequest("Ne možete ocjeniti veterinara kod kojeg niste bili");
                }

                // Provjeri da li je već ostavio review za ovog veterinara
                var existingReview = await _context.Set<Review>()
                    .FirstOrDefaultAsync(r => r.VeterinarianId == veterinarianId && r.UserId == userId);

                if (existingReview != null)
                {
                    return BadRequest("Već ste ocjenili ovog veterinara");
                }

                // Kreiraj novi review
                var review = new Review
                {
                    VeterinarianId = veterinarianId,
                    UserId = userId,
                    Rating = request.Rating,
                    Title = request.Title,
                    Comment = request.Comment,
                    PetName = request.PetName,
                    PetSpecies = request.PetSpecies,
                    DateCreated = DateTime.UtcNow,
                    IsVerifiedPurchase = true, // Jer smo provjerili da ima završen termin
                    // Odmah prikaži ocjene u statistikama veterinara
                    IsApproved = true
                };

                _context.Set<Review>().Add(review);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"✅ Review created for veterinarian {veterinarianId} by user {userId}");

                var dto = new ReviewDto
                {
                    Id = review.Id,
                    Rating = review.Rating,
                    Title = review.Title,
                    Comment = review.Comment,
                    DateCreated = review.DateCreated,
                    IsVerifiedPurchase = review.IsVerifiedPurchase,
                    IsApproved = review.IsApproved,
                    PetName = review.PetName,
                    PetSpecies = review.PetSpecies,
                    VeterinarianName = veterinarian.FirstName + " " + veterinarian.LastName,
                    UserName = "Anonimno" // Za privatnost
                };

                return Ok(dto);
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error creating review: {ex.Message}");
                return StatusCode(500, $"Greška pri kreiranju review-a: {ex.Message}");
            }
        }

        /// <summary>
        /// Dobijanje svih review-ova za veterinara (samo odobreni)
        /// </summary>
        [HttpGet("veterinarian/{veterinarianId}")]
        [AllowAnonymous]
        public async Task<ActionResult<List<ReviewDto>>> GetVeterinarianReviews(int veterinarianId)
        {
            try
            {
                var reviews = await _context.Set<Review>()
                    .Where(r => r.VeterinarianId == veterinarianId && r.IsApproved)
                    .Include(r => r.User)
                    .OrderByDescending(r => r.DateCreated)
                    .Select(r => new ReviewDto
                    {
                        Id = r.Id,
                        Rating = r.Rating,
                        Title = r.Title,
                        Comment = r.Comment,
                        DateCreated = r.DateCreated,
                        IsVerifiedPurchase = r.IsVerifiedPurchase,
                        IsApproved = r.IsApproved,
                        PetName = r.PetName,
                        PetSpecies = r.PetSpecies,
                        UserName = r.User.FirstName.Substring(0, 1) + "***" // Djelimična privatnost
                    })
                    .ToListAsync();

                return Ok(reviews);
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error getting reviews: {ex.Message}");
                return StatusCode(500, $"Greška pri dohvatanju review-ova: {ex.Message}");
            }
        }

        /// <summary>
        /// Odobravanje review-a (samo Admin)
        /// </summary>
        [HttpPatch("{id}/approve")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult> ApproveReview(int id)
        {
            try
            {
                var review = await _context.Set<Review>().FindAsync(id);
                if (review == null)
                {
                    return NotFound("Review nije pronađen");
                }

                review.IsApproved = true;
                await _context.SaveChangesAsync();

                _logger.LogInformation($"✅ Review {id} approved");
                return Ok("Review je odobren");
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error approving review: {ex.Message}");
                return StatusCode(500, $"Greška pri odobravanju review-a: {ex.Message}");
            }
        }

        /// <summary>
        /// Dobijanje svih pending review-ova (samo Admin)
        /// </summary>
        [HttpGet("pending")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult<List<ReviewDto>>> GetPendingReviews()
        {
            try
            {
                var reviews = await _context.Set<Review>()
                    .Where(r => !r.IsApproved)
                    .Include(r => r.User)
                    .Include(r => r.Veterinarian)
                    .OrderByDescending(r => r.DateCreated)
                    .Select(r => new ReviewDto
                    {
                        Id = r.Id,
                        Rating = r.Rating,
                        Title = r.Title,
                        Comment = r.Comment,
                        DateCreated = r.DateCreated,
                        IsVerifiedPurchase = r.IsVerifiedPurchase,
                        IsApproved = r.IsApproved,
                        PetName = r.PetName,
                        PetSpecies = r.PetSpecies,
                        VeterinarianName = r.Veterinarian!.FirstName + " " + r.Veterinarian.LastName,
                        UserName = r.User.FirstName + " " + r.User.LastName
                    })
                    .ToListAsync();

                return Ok(reviews);
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error getting pending reviews: {ex.Message}");
                return StatusCode(500, $"Greška pri dohvatanju pending review-ova: {ex.Message}");
            }
        }
    }

    // DTOs
    public class CreateReviewRequest
    {
        public int Rating { get; set; } // 1-5
        public string? Title { get; set; }
        public string? Comment { get; set; }
        public string? PetName { get; set; }
        public string? PetSpecies { get; set; }
    }

    public class ReviewDto
    {
        public int Id { get; set; }
        public int Rating { get; set; }
        public string? Title { get; set; }
        public string? Comment { get; set; }
        public DateTime DateCreated { get; set; }
        public bool IsVerifiedPurchase { get; set; }
        public bool IsApproved { get; set; }
        public string? PetName { get; set; }
        public string? PetSpecies { get; set; }
        public string? VeterinarianName { get; set; }
        public string? UserName { get; set; }
    }
}

