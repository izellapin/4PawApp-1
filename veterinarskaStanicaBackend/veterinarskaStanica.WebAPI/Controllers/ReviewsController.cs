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
        /// Dobijanje svih review-ova (samo Admin)
        /// OVO MORA BITI PRVO da bi izbegli konflikt sa drugim rutama
        /// </summary>
        [HttpGet("all")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult<List<ReviewDto>>> GetAllReviews()
        {
            try
            {
                _logger.LogInformation("🔍 [GET ALL REVIEWS] Request started");
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
                        UserName = r.User != null ? r.User.FirstName + " " + r.User.LastName : null
                    })
                    .ToListAsync();

                _logger.LogInformation("✅ [GET ALL REVIEWS] Retrieved {Count} reviews", reviews.Count);
                return Ok(reviews);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [GET ALL REVIEWS] Error getting all reviews: {Message}", ex.Message);
                return StatusCode(500, $"Greška pri dohvatanju review-ova: {ex.Message}");
            }
        }

        /// <summary>
        /// Dobijanje svih review-ova koje je trenutni korisnik ostavio
        /// OVO MORA BITI PRVO da bi izbegli konflikt sa {id} rutom
        /// </summary>
        [HttpGet("my-reviews")]
        [RoleRequired(UserRole.PetOwner)]
        public async Task<ActionResult<List<ReviewDto>>> GetMyReviews()
        {
            try
            {
                _logger.LogInformation("🔍 [GET MY REVIEWS] Request started");
                
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
                var emailClaim = User.FindFirst(ClaimTypes.Email)?.Value;
                
                _logger.LogInformation("🔍 [GET MY REVIEWS] User claims - UserId: {UserId}, Role: {Role}, Email: {Email}", 
                    userIdClaim, roleClaim, emailClaim);
                
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    _logger.LogWarning("❌ [GET MY REVIEWS] Invalid user ID claim: {UserIdClaim}", userIdClaim);
                    return BadRequest("Nevaljan korisnik ID");
                }

                _logger.LogInformation("🔍 [GET MY REVIEWS] Querying reviews for userId: {UserId}", userId);
                
                // First, let's check how many reviews exist for this user
                var totalReviewsCount = await _context.Set<Review>()
                    .Where(r => r.UserId == userId)
                    .CountAsync();
                
                _logger.LogInformation("🔍 [GET MY REVIEWS] Total reviews in database for user {UserId}: {Count}", userId, totalReviewsCount);

                var reviews = await _context.Set<Review>()
                    .Where(r => r.UserId == userId)
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
                        UserName = null // Ne prikazujemo korisničko ime jer je to korisnik sam
                    })
                    .ToListAsync();

                _logger.LogInformation("✅ [GET MY REVIEWS] Retrieved {Count} reviews for user {UserId}", reviews.Count, userId);
                
                // Log details about each review
                foreach (var review in reviews)
                {
                    _logger.LogInformation("📋 [GET MY REVIEWS] Review ID: {ReviewId}, Veterinarian: {VeterinarianName}, Rating: {Rating}, Date: {DateCreated}", 
                        review.Id, review.VeterinarianName, review.Rating, review.DateCreated);
                }
                
                if (reviews.Count == 0 && totalReviewsCount > 0)
                {
                    _logger.LogWarning("⚠️ [GET MY REVIEWS] Query returned 0 reviews but database has {TotalCount} reviews for user {UserId}. Possible Include issue.", 
                        totalReviewsCount, userId);
                }
                
                return Ok(reviews);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [GET MY REVIEWS] Error getting my reviews: {Message}", ex.Message);
                return StatusCode(500, $"Greška pri dohvatanju review-ova: {ex.Message}");
            }
        }

        /// <summary>
        /// Brisanje sopstvene recenzije (PetOwner može brisati samo svoje recenzije)
        /// OVO MORA BITI PRVO da bi izbegli konflikt sa {id} rutom
        /// </summary>
        [HttpDelete("my/{id}")]
        [RoleRequired(UserRole.PetOwner)]
        public async Task<ActionResult> DeleteMyReview(int id)
        {
            _logger.LogInformation("🚀 [DELETE MY REVIEW] ========== ENDPOINT REACHED ==========");
            _logger.LogInformation("🚀 [DELETE MY REVIEW] Review ID: {ReviewId}", id);
            _logger.LogInformation("🚀 [DELETE MY REVIEW] User: {User}", User?.Identity?.Name);
            _logger.LogInformation("🚀 [DELETE MY REVIEW] IsAuthenticated: {IsAuth}", User?.Identity?.IsAuthenticated);
            _logger.LogInformation("🚀 [DELETE MY REVIEW] Request Path: {Path}", HttpContext.Request.Path);
            _logger.LogInformation("🚀 [DELETE MY REVIEW] Request Method: {Method}", HttpContext.Request.Method);
            
            try
            {
                _logger.LogInformation("🗑️ [DELETE MY REVIEW] Attempting to delete review with ID: {ReviewId}", id);
                
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    _logger.LogWarning("❌ [DELETE MY REVIEW] Invalid user ID claim: {UserIdClaim}", userIdClaim);
                    return BadRequest("Nevaljan korisnik ID");
                }

                var review = await _context.Set<Review>().FindAsync(id);
                if (review == null)
                {
                    _logger.LogWarning("❌ [DELETE MY REVIEW] Review with ID {ReviewId} not found", id);
                    return NotFound("Review nije pronađen");
                }

                // Proveri da li je ovo recenzija trenutnog korisnika
                if (review.UserId != userId)
                {
                    _logger.LogWarning("❌ [DELETE MY REVIEW] User {UserId} attempted to delete review {ReviewId} owned by user {ReviewUserId}", 
                        userId, id, review.UserId);
                    return Forbid("Možete obrisati samo svoje recenzije");
                }

                _logger.LogInformation("🔍 [DELETE MY REVIEW] Found review - UserId: {UserId}, VeterinarianId: {VeterinarianId}, Rating: {Rating}", 
                    review.UserId, review.VeterinarianId, review.Rating);

                _logger.LogInformation("🗑️ [DELETE MY REVIEW] Removing review from context...");
                _context.Set<Review>().Remove(review);
                
                _logger.LogInformation("💾 [DELETE MY REVIEW] Saving changes to database...");
                var rowsAffected = await _context.SaveChangesAsync();
                
                _logger.LogInformation("✅ [DELETE MY REVIEW] Review {ReviewId} deleted successfully by user {UserId}. Rows affected: {RowsAffected}", 
                    id, userId, rowsAffected);
                
                // Double-check that review is actually deleted
                var verifyDeleted = await _context.Set<Review>().FindAsync(id);
                if (verifyDeleted != null)
                {
                    _logger.LogError("❌ [DELETE MY REVIEW] CRITICAL: Review {ReviewId} still exists after deletion! Rows affected: {RowsAffected}", id, rowsAffected);
                }
                else
                {
                    _logger.LogInformation("✅ [DELETE MY REVIEW] Verified: Review {ReviewId} successfully deleted from database", id);
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DELETE MY REVIEW] Error deleting review {ReviewId}: {Message}", id, ex.Message);
                return StatusCode(500, $"Greška pri brisanju review-a: {ex.Message}");
            }
        }

        /// <summary>
        /// Brisanje review-a (admin)
        /// </summary>
        [HttpDelete("{id}")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult> DeleteReview(int id)
        {
            try
            {
                _logger.LogInformation("🗑️ [DELETE REVIEW] Attempting to delete review with ID: {ReviewId}", id);
                
                var review = await _context.Set<Review>().FindAsync(id);
                if (review == null)
                {
                    _logger.LogWarning("❌ [DELETE REVIEW] Review with ID {ReviewId} not found", id);
                    return NotFound("Review nije pronađen");
                }

                _logger.LogInformation("🔍 [DELETE REVIEW] Found review - UserId: {UserId}, VeterinarianId: {VeterinarianId}, Rating: {Rating}", 
                    review.UserId, review.VeterinarianId, review.Rating);

                _context.Set<Review>().Remove(review);
                var rowsAffected = await _context.SaveChangesAsync();
                
                _logger.LogInformation("✅ [DELETE REVIEW] Review {ReviewId} deleted successfully. Rows affected: {RowsAffected}", id, rowsAffected);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DELETE REVIEW] Error deleting review {ReviewId}: {Message}", id, ex.Message);
                return StatusCode(500, $"Greška pri brisanju review-a: {ex.Message}");
            }
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
                _logger.LogInformation("📝 [CREATE REVIEW] Starting review creation - VeterinarianId: {VeterinarianId}, Rating: {Rating}, Title: {Title}", 
                    veterinarianId, request.Rating, request.Title);
                
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    _logger.LogWarning("❌ [CREATE REVIEW] Invalid user ID claim: {UserIdClaim}", userIdClaim);
                    return BadRequest("Nevaljan korisnik ID");
                }

                _logger.LogInformation("🔍 [CREATE REVIEW] UserId: {UserId}, VeterinarianId: {VeterinarianId}", userId, veterinarianId);

                // Provjeri da li veterinar postoji
                var veterinarian = await _context.Users
                    .FirstOrDefaultAsync(u => u.Id == veterinarianId && u.Role == UserRole.Veterinarian);
                
                if (veterinarian == null)
                {
                    _logger.LogWarning("❌ [CREATE REVIEW] Veterinarian {VeterinarianId} not found", veterinarianId);
                    return NotFound("Veterinar nije pronađen");
                }

                _logger.LogInformation("✅ [CREATE REVIEW] Veterinarian found: {VeterinarianName}", 
                    veterinarian.FirstName + " " + veterinarian.LastName);

                // Ako je prosleđen AppointmentId, koristi ga za validaciju
                if (request.AppointmentId.HasValue)
                {
                    var appointment = await _context.Appointments
                        .Include(a => a.Pet)
                        .FirstOrDefaultAsync(a => a.Id == request.AppointmentId.Value);

                    if (appointment == null)
                    {
                        _logger.LogWarning("❌ [CREATE REVIEW] Appointment {AppointmentId} not found", request.AppointmentId.Value);
                        return BadRequest("Termin nije pronađen");
                    }

                    // Proveri da li termin pripada ovom korisniku i veterinaru
                    if (appointment.Pet.PetOwnerId != userId)
                    {
                        _logger.LogWarning("❌ [CREATE REVIEW] Appointment {AppointmentId} does not belong to user {UserId}", 
                            request.AppointmentId.Value, userId);
                        return BadRequest("Termin ne pripada vama");
                    }

                    if (appointment.VeterinarianId != veterinarianId)
                    {
                        _logger.LogWarning("❌ [CREATE REVIEW] Appointment {AppointmentId} does not belong to veterinarian {VeterinarianId}", 
                            request.AppointmentId.Value, veterinarianId);
                        return BadRequest("Termin ne pripada ovom veterinaru");
                    }

                    // Proveri da li je termin završen ili prošao
                    if (appointment.Status != AppointmentStatus.Completed && 
                        !appointment.IsPaid && 
                        appointment.AppointmentDate >= DateTime.UtcNow)
                    {
                        _logger.LogWarning("❌ [CREATE REVIEW] Appointment {AppointmentId} is not completed or has not passed yet", 
                            request.AppointmentId.Value);
                        return BadRequest("Ne možete ocjeniti termin koji još nije završen");
                    }

                    // Proveri da li već postoji recenzija za taj termin
                    var existingReviewForAppointment = await _context.Set<Review>()
                        .FirstOrDefaultAsync(r => r.AppointmentId == request.AppointmentId.Value && r.UserId == userId);

                    if (existingReviewForAppointment != null)
                    {
                        _logger.LogWarning("⚠️ [CREATE REVIEW] User {UserId} already has review {ReviewId} for appointment {AppointmentId}", 
                            userId, existingReviewForAppointment.Id, request.AppointmentId.Value);
                        return BadRequest("Već ste ocjenili ovaj termin");
                    }

                    _logger.LogInformation("✅ [CREATE REVIEW] Appointment {AppointmentId} validated for user {UserId} and veterinarian {VeterinarianId}", 
                        request.AppointmentId.Value, userId, veterinarianId);
                }
                else
                {
                    // Ako nije prosleđen AppointmentId, proveri da li je korisnik bio kod ovog veterinara (završen ili plaćen ili prošao termin)
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
                        _logger.LogWarning("❌ [CREATE REVIEW] User {UserId} has not visited veterinarian {VeterinarianId}", userId, veterinarianId);
                        return BadRequest("Ne možete ocjeniti veterinara kod kojeg niste bili");
                    }

                    _logger.LogInformation("✅ [CREATE REVIEW] User {UserId} has visited veterinarian {VeterinarianId}", userId, veterinarianId);
                }

                // Kreiraj novi review

                // Kreiraj novi review
                var review = new Review
                {
                    VeterinarianId = veterinarianId,
                    UserId = userId,
                    AppointmentId = request.AppointmentId, // Vezano za specifičan termin
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
                var rowsAffected = await _context.SaveChangesAsync();

                _logger.LogInformation("✅ [CREATE REVIEW] Review created successfully - ReviewId: {ReviewId}, VeterinarianId: {VeterinarianId}, UserId: {UserId}, Rating: {Rating}, RowsAffected: {RowsAffected}", 
                    review.Id, veterinarianId, userId, review.Rating, rowsAffected);

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
        /// Proverava da li trenutni korisnik ima review za veterinara
        /// </summary>
        [HttpGet("veterinarian/{veterinarianId}/has-review")]
        [RoleRequired(UserRole.PetOwner)]
        public async Task<ActionResult<bool>> HasReviewForVeterinarian(int veterinarianId)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return BadRequest("Nevaljan korisnik ID");
                }

                var hasReview = await _context.Set<Review>()
                    .AnyAsync(r => r.VeterinarianId == veterinarianId && r.UserId == userId);

                return Ok(hasReview);
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error checking review: {ex.Message}");
                return StatusCode(500, $"Greška pri proveri review-a: {ex.Message}");
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
        public int? AppointmentId { get; set; } // ID termina za koji se ostavlja recenzija
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

