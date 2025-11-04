using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaServices.Database;
using veterinarskaStanica.WebAPI.Authorization;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.DTOs;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using eVeterinarskaStanicaModel.Requests;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AppointmentsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AppointmentsController> _logger;

        public AppointmentsController(ApplicationDbContext context, ILogger<AppointmentsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: api/Appointments
        [HttpGet]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<IEnumerable<AppointmentDto>>> GetAppointments()
        {
            try
            {
                // Get current user ID and role
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userRoleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
                
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int currentUserId))
                {
                    return Unauthorized("User ID not found in token");
                }

                var query = _context.Appointments.AsQueryable();

                // Filter by role: Admin sees all, Veterinarian sees only their own
                if (userRoleClaim == "Veterinarian")
                {
                    _logger.LogInformation($"🔍 Filtering appointments for Veterinarian ID: {currentUserId}");
                    query = query.Where(a => a.VeterinarianId == currentUserId);
                }
                else
                {
                    _logger.LogInformation($"🔍 Admin user - returning all appointments");
                }

                var appointments = await query
                    .Select(a => new AppointmentDto
                    {
                        Id = a.Id,
                        AppointmentNumber = a.AppointmentNumber,
                        AppointmentDate = a.AppointmentDate,
                        StartTime = a.StartTime.ToString(@"hh\:mm"),
                        EndTime = a.EndTime.ToString(@"hh\:mm"),
                        Type = (int)a.Type,
                        Status = (int)a.Status,
                        PetName = a.Pet.Name,
                        OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                        VeterinarianName = $"{a.Veterinarian.FirstName} {a.Veterinarian.LastName}",
                        ServiceName = a.Service != null ? a.Service.Name : null,
                        EstimatedCost = a.EstimatedCost,
                        ActualCost = a.ActualCost,
                        IsPaid = a.IsPaid,
                        PaymentDate = a.PaymentDate,
                        PaymentMethod = a.PaymentMethod,
                        PaymentTransactionId = a.PaymentTransactionId,
                        Reason = a.Reason,
                        Notes = a.Notes
                    })
                    .OrderByDescending(a => a.AppointmentDate)
                    .Take(50) // Ograniči na 50 rezultata
                    .ToListAsync();

                _logger.LogInformation($"✅ Returning {appointments.Count} appointments");
                return Ok(appointments);
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Error getting appointments: {ex.Message}");
                return BadRequest($"Greška: {ex.Message}");
            }
        }


        // GET: api/Appointments/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Appointment>> GetAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                    .ThenInclude(p => p.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.Id == id);

            if (appointment == null)
            {
                return NotFound();
            }

            return Ok(appointment);
        }

        // GET: api/Appointments/veterinarian/my
        [HttpGet("veterinarian/my")]
        [RoleRequired(UserRole.Veterinarian)]
        public async Task<ActionResult<IEnumerable<AppointmentDto>>> GetMyAppointments()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int veterinarianId))
            {
                return BadRequest("Nevaljan korisnik ID");
            }

            var appointments = await _context.Appointments
                .Where(a => a.VeterinarianId == veterinarianId)
                .Select(a => new AppointmentDto
                {
                    Id = a.Id,
                    AppointmentNumber = a.AppointmentNumber,
                    AppointmentDate = a.AppointmentDate,
                    StartTime = a.StartTime.ToString(@"hh\:mm"),
                    EndTime = a.EndTime.ToString(@"hh\:mm"),
                    Type = (int)a.Type,
                    Status = (int)a.Status,
                    PetName = a.Pet.Name,
                    OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                    ServiceName = a.Service != null ? a.Service.Name : null,
                    EstimatedCost = a.EstimatedCost,
                    ActualCost = a.ActualCost,
                    IsPaid = a.IsPaid,
                    PaymentDate = a.PaymentDate,
                    PaymentMethod = a.PaymentMethod,
                    PaymentTransactionId = a.PaymentTransactionId,
                    Reason = a.Reason,
                    Notes = a.Notes
                })
                .OrderByDescending(a => a.AppointmentDate)
                .ToListAsync();

            return Ok(appointments);
        }


        // GET: api/Appointments/user/5
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetAppointmentsByUser(int userId)
        {
            var appointments = await _context.Appointments
                .Include(a => a.Pet)
                .Include(a => a.Pet.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service)
                .Where(a => a.Pet.PetOwnerId == userId)
                .Select(a => new
                {
                    a.Id,
                    a.AppointmentNumber,
                    a.AppointmentDate,
                    StartTime = a.StartTime.ToString(@"hh\:mm"),
                    EndTime = a.EndTime.ToString(@"hh\:mm"),
                    Type = (int)a.Type,
                    Status = (int)a.Status,
                    PetName = a.Pet.Name,
                    VeterinarianId = a.VeterinarianId,
                    OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                    VeterinarianName = $"{a.Veterinarian.FirstName} {a.Veterinarian.LastName}",
                    ServiceName = a.Service != null ? a.Service.Name : null,
                    a.EstimatedCost,
                    a.ActualCost,
                    a.Reason,
                    a.Notes
                })
                .OrderByDescending(a => a.AppointmentDate)
                .ToListAsync();

            return Ok(appointments);
        }

        // GET: api/Appointments/available-slots?veterinarianId=1&date=2025-10-20
        [HttpGet("available-slots")]
        public async Task<ActionResult<IEnumerable<string>>> GetAvailableTimeSlots(
            [FromQuery] int veterinarianId, 
            [FromQuery] string date)
        {
            if (!DateTime.TryParse(date, out DateTime appointmentDate))
            {
                return BadRequest("Invalid date format");
            }

            // Define working hours (9 AM to 5 PM)
            var workingHours = new List<string>
            {
                "09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
                "12:00", "12:30", "13:00", "13:30", "14:00", "14:30",
                "15:00", "15:30", "16:00", "16:30", "17:00"
            };

            // Get existing appointments for this veterinarian on this date
            var existingAppointments = await _context.Appointments
                .Where(a => a.VeterinarianId == veterinarianId && 
                           a.AppointmentDate.Date == appointmentDate.Date &&
                           a.Status != AppointmentStatus.Cancelled)
                .Select(a => a.StartTime.ToString(@"hh\:mm"))
                .ToListAsync();

            // Filter out booked time slots
            var availableSlots = workingHours
                .Where(time => !existingAppointments.Contains(time))
                .ToList();

            return Ok(availableSlots);
        }

        // GET: api/Appointments/pet/5
        [HttpGet("pet/{petId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetAppointmentsByPet(int petId)
        {
            var appointments = await _context.Appointments
                .Where(a => a.PetId == petId)
                .Select(a => new
                {
                    a.Id,
                    a.AppointmentNumber,
                    a.AppointmentDate,
                    StartTime = a.StartTime.ToString(@"hh\:mm"),
                    EndTime = a.EndTime.ToString(@"hh\:mm"),
                    Type = (int)a.Type,
                    Status = (int)a.Status,
                    PetName = a.Pet.Name,
                    OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                    VeterinarianName = $"{a.Veterinarian.FirstName} {a.Veterinarian.LastName}",
                    ServiceName = a.Service != null ? a.Service.Name : null,
                    a.EstimatedCost,
                    a.ActualCost,
                    a.Reason,
                    a.Notes
                })
                .OrderByDescending(a => a.AppointmentDate)
                .ToListAsync();

            return Ok(appointments);
        }

        // POST: api/Appointments
        [HttpPost]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian, UserRole.PetOwner)]
        public async Task<ActionResult<Appointment>> CreateAppointment(AppointmentCreateRequest request)
        {
            // Debug logging
            _logger.LogInformation("🔍 CreateAppointment called with:");
            _logger.LogInformation("  AppointmentDate: {AppointmentDate}", request.AppointmentDate);
            _logger.LogInformation("  StartTime: '{StartTime}'", request.StartTime);
            _logger.LogInformation("  EndTime: '{EndTime}'", request.EndTime);
            _logger.LogInformation("  Type: {Type}", request.Type);
            _logger.LogInformation("  PetId: {PetId}", request.PetId);
            _logger.LogInformation("  VeterinarianId: {VeterinarianId}", request.VeterinarianId);
            _logger.LogInformation("  ServiceId: {ServiceId}", request.ServiceId);
            _logger.LogInformation("  Reason: '{Reason}'", request.Reason);
            _logger.LogInformation("  EstimatedCost: {EstimatedCost}", request.EstimatedCost);
            
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("❌ ModelState is invalid:");
                foreach (var key in ModelState.Keys)
                {
                    var errors = ModelState[key].Errors;
                    if (errors.Any())
                    {
                        _logger.LogWarning("  {Key}: {Errors}", key, string.Join(", ", errors.Select(e => e.ErrorMessage ?? e.Exception?.Message)));
                    }
                }
                
                var errorList = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? e.Exception?.Message : e.ErrorMessage)
                    .Where(m => !string.IsNullOrWhiteSpace(m))
                    .ToList();
                var message = errorList.Count > 0 ? string.Join("; ", errorList) : "Neispravni podaci.";
                return BadRequest(message);
            }

            // Provjeri da li pet postoji
            var pet = await _context.Pets.FindAsync(request.PetId);
            if (pet == null)
            {
                return BadRequest("Ljubimac nije pronađen");
            }

            // Provjeri da li veterinar postoji
            var veterinarian = await _context.Users.FindAsync(request.VeterinarianId);
            if (veterinarian == null || veterinarian.Role != UserRole.Veterinarian)
            {
                return BadRequest("Veterinar nije pronađen");
            }

            // Generiši appointment number
            var appointmentNumber = $"APT-{DateTime.Now:yyyyMMdd}-{DateTime.Now.Ticks % 10000:D4}";

            // Parsiraj vrijeme HH:mm
            TimeSpan startTime, endTime;
            try
            {
                _logger.LogInformation("🕐 Backend time parsing:");
                _logger.LogInformation("  StartTime string: '{StartTime}' (length: {StartTimeLength})", request.StartTime, request.StartTime.Length);
                _logger.LogInformation("  EndTime string: '{EndTime}' (length: {EndTimeLength})", request.EndTime, request.EndTime.Length);
                
                // Handle both HH:mm and HH:mm:ss formats
                var startTimeStr = request.StartTime.Length > 5 ? request.StartTime.Substring(0, 5) : request.StartTime;
                var endTimeStr = request.EndTime.Length > 5 ? request.EndTime.Substring(0, 5) : request.EndTime;
                
                startTime = TimeSpan.Parse(startTimeStr);
                endTime = TimeSpan.Parse(endTimeStr);
                
                _logger.LogInformation("✅ Parsed successfully:");
                _logger.LogInformation("  StartTime: {StartTime}", startTime);
                _logger.LogInformation("  EndTime: {EndTime}", endTime);
            }
            catch (FormatException ex)
            {
                _logger.LogError("❌ Time parsing failed: {ErrorMessage}", ex.Message);
                return BadRequest("Neispravan format vremena. Koristite HH:mm (npr. 22:15).");
            }

            var appointment = new Appointment
            {
                AppointmentNumber = appointmentNumber,
                AppointmentDate = request.AppointmentDate,
                StartTime = startTime,
                EndTime = endTime,
                Type = request.Type,
                Status = AppointmentStatus.Scheduled,
                Reason = request.Reason,
                Notes = request.Notes,
                EstimatedCost = request.EstimatedCost,
                PetId = request.PetId,
                VeterinarianId = request.VeterinarianId,
                ServiceId = request.ServiceId,
                DateCreated = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            // Ako nema EstimatedCost, ali ima ServiceId, uzmi cenu iz Service
            if (!appointment.EstimatedCost.HasValue && appointment.ServiceId.HasValue)
            {
                var service = await _context.Services.FindAsync(appointment.ServiceId.Value);
                if (service != null && service.Price > 0)
                {
                    appointment.EstimatedCost = service.Price;
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"💰 Set EstimatedCost to {service.Price} from Service.Price for appointment {appointment.Id}");
                }
            }

            // Dohvati kreirani appointment sa svim podacima
            var createdAppointment = await _context.Appointments
                .Include(a => a.Pet)
                .ThenInclude(p => p.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.Id == appointment.Id);

            return CreatedAtAction(nameof(GetAppointment), new { id = appointment.Id }, createdAppointment);
        }

        // PUT: api/Appointments/5
        [HttpPut("{id}")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<ActionResult<Appointment>> UpdateAppointment(int id, AppointmentUpdateRequest request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? e.Exception?.Message : e.ErrorMessage)
                    .Where(m => !string.IsNullOrWhiteSpace(m))
                    .ToList();
                var message = errors.Count > 0 ? string.Join("; ", errors) : "Neispravni podaci.";
                return BadRequest(message);
            }

            var appointment = await _context.Appointments.FindAsync(id);
            if (appointment == null)
            {
                return NotFound();
            }

            // Ažuriraj polja
            appointment.AppointmentDate = request.AppointmentDate ?? appointment.AppointmentDate;
            if (!string.IsNullOrWhiteSpace(request.StartTime))
            {
                try
                {
                    appointment.StartTime = TimeSpan.ParseExact(request.StartTime!, @"HH\:mm", CultureInfo.InvariantCulture);
                }
                catch (FormatException)
                {
                    return BadRequest("Neispravan format vremena za StartTime. Koristite HH:mm (npr. 10:05).");
                }
            }
            if (!string.IsNullOrWhiteSpace(request.EndTime))
            {
                try
                {
                    appointment.EndTime = TimeSpan.ParseExact(request.EndTime!, @"HH\:mm", CultureInfo.InvariantCulture);
                }
                catch (FormatException)
                {
                    return BadRequest("Neispravan format vremena za EndTime. Koristite HH:mm (npr. 11:30).");
                }
            }
            appointment.Type = request.Type ?? appointment.Type;
            appointment.Status = request.Status ?? appointment.Status;
            appointment.Reason = request.Reason ?? appointment.Reason;
            appointment.Notes = request.Notes ?? appointment.Notes;
            appointment.EstimatedCost = request.EstimatedCost ?? appointment.EstimatedCost;
            appointment.ActualCost = request.ActualCost ?? appointment.ActualCost;
            appointment.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Dohvati ažurirani appointment sa svim podacima
            var updatedAppointment = await _context.Appointments
                .Include(a => a.Pet)
                .ThenInclude(p => p.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service)
                .FirstOrDefaultAsync(a => a.Id == appointment.Id);

            return Ok(updatedAppointment);
        }

        // PATCH: api/Appointments/5/complete
        [HttpPatch("{id}/complete")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian)]
        public async Task<IActionResult> CompleteAppointment(int id, [FromBody] CompleteAppointmentRequest request)
        {
            var appointment = await _context.Appointments.FindAsync(id);
            if (appointment == null)
            {
                return NotFound();
            }

            appointment.Status = AppointmentStatus.Completed;
            appointment.ActualCost = request.ActualCost;
            appointment.Notes = string.IsNullOrEmpty(request.Notes) ? appointment.Notes : request.Notes;
            appointment.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PATCH: api/Appointments/5/cancel
        [HttpPatch("{id}/cancel")]
        public async Task<IActionResult> CancelAppointment(int id)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Pet)
                .ThenInclude(p => p.PetOwner)
                .FirstOrDefaultAsync(a => a.Id == id);
                
            if (appointment == null)
            {
                return NotFound();
            }

            // Get current user ID
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized();
            }

            // Get user role
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                return Unauthorized();
            }

            // Check permissions: Admin/Veterinarian can cancel any appointment, PetOwner can only cancel their own
            if (userRole == UserRole.Admin || userRole == UserRole.Veterinarian)
            {
                // Staff can cancel any appointment
            }
            else if (userRole == UserRole.PetOwner)
            {
                // PetOwner can only cancel their own appointments
                if (appointment.Pet.PetOwnerId != userId)
                {
                    return Forbid();
                }
            }
            else
            {
                return Forbid();
            }

            appointment.Status = AppointmentStatus.Cancelled;
            appointment.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PATCH: api/Appointments/5/mark-paid
        [HttpPatch("{id}/mark-paid")]
        [RoleRequired(UserRole.Admin, UserRole.Veterinarian, UserRole.PetOwner)]
        public async Task<ActionResult<Appointment>> MarkPaid(int id, [FromBody] MarkPaidRequest request)
        {
            var appointment = await _context.Appointments.FindAsync(id);

            if (appointment == null)
            {
                return NotFound();
            }

            // Označi kao plaćeno i završi termin
            appointment.IsPaid = true;
            appointment.PaymentDate = DateTime.UtcNow;
            appointment.PaymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod) ? "Stripe" : request.PaymentMethod;
            appointment.PaymentTransactionId = request.PaymentTransactionId;
            // Kada je plaćeno, smatramo termin završenim radi izvještaja
            appointment.Status = AppointmentStatus.Completed;

            // Ako nema actual cost, postavi ga
            if (!appointment.ActualCost.HasValue)
            {
                // Prvo pokušaj iz request.Amount
                if (request.Amount.HasValue)
                {
                    appointment.ActualCost = request.Amount.Value;
                }
                // Ako nema Amount, pokušaj iz Service.Price
                else if (appointment.ServiceId.HasValue)
                {
                    var service = await _context.Services.FindAsync(appointment.ServiceId.Value);
                    if (service != null && service.Price > 0)
                    {
                        appointment.ActualCost = service.Price;
                    }
                }
                // Na kraju, koristi EstimatedCost ako postoji
                else if (appointment.EstimatedCost.HasValue)
                {
                    appointment.ActualCost = appointment.EstimatedCost;
                }
            }

            await _context.SaveChangesAsync();

            return Ok(appointment);
        }


        // DELETE: api/Appointments/5
        [HttpDelete("{id}")]
        [RoleRequired(UserRole.Admin)]
        public async Task<IActionResult> DeleteAppointment(int id)
        {
            var appointment = await _context.Appointments.FindAsync(id);
            if (appointment == null)
            {
                return NotFound();
            }

            appointment.Status = AppointmentStatus.Cancelled;
            appointment.DateModified = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }
    }

    // Request modeli
    public class MarkPaidRequest
    {
        [StringLength(100)]
        public string? PaymentMethod { get; set; }
        [StringLength(100)]
        public string? PaymentTransactionId { get; set; }
        public decimal? Amount { get; set; }
    }

    public class AppointmentCreateRequest
    {
        [Required]
        public DateTime AppointmentDate { get; set; }

        [Required]
        public string StartTime { get; set; } = string.Empty; // HH:mm

        [Required]
        public string EndTime { get; set; } = string.Empty; // HH:mm

        [Required]
        public AppointmentType Type { get; set; }

        [StringLength(1000)]
        public string? Reason { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Range(0, 10000)]
        public decimal? EstimatedCost { get; set; }

        [Required]
        public int PetId { get; set; }

        [Required]
        public int VeterinarianId { get; set; }

        public int? ServiceId { get; set; }
    }

    public class AppointmentUpdateRequest
    {
        public DateTime? AppointmentDate { get; set; }
        public string? StartTime { get; set; } // HH:mm
        public string? EndTime { get; set; } // HH:mm
        public AppointmentType? Type { get; set; }
        public AppointmentStatus? Status { get; set; }

        [StringLength(1000)]
        public string? Reason { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Range(0, 10000)]
        public decimal? EstimatedCost { get; set; }

        [Range(0, 10000)]
        public decimal? ActualCost { get; set; }
    }

    public class CompleteAppointmentRequest
    {
        [Required]
        [Range(0, 10000)]
        public decimal ActualCost { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }
    }
}
