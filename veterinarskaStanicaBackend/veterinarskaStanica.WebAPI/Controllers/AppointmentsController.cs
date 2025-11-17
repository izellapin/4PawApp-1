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
                    .Include(a => a.Pet)
                    .ThenInclude(p => p.PetOwner)
                    .Include(a => a.Veterinarian)
                    .Include(a => a.Service) // Eksplicitno učitaj Service
                    .OrderByDescending(a => a.AppointmentDate)
                    .Take(50) // Ograniči na 50 rezultata
                    .ToListAsync();

                // Mapiraj na DTO nakon učitavanja
                var appointmentDtos = appointments.Select((a, index) => {
                    string? serviceName = null;
                    
                    // Debug logging za prvi appointment
                    if (index == 0 && appointments.Count > 0)
                    {
                        _logger.LogInformation($"🔍 Debug Appointment {a.Id}:");
                        _logger.LogInformation($"   Reason: '{a.Reason}' (IsNullOrEmpty: {string.IsNullOrEmpty(a.Reason)})");
                        _logger.LogInformation($"   Service: {(a.Service != null ? $"Name='{a.Service.Name}'" : "NULL")}");
                        _logger.LogInformation($"   Type: {a.Type}");
                    }
                    
                    if (!string.IsNullOrEmpty(a.Reason))
                    {
                        serviceName = a.Reason;
                        if (index == 0 && appointments.Count > 0)
                            _logger.LogInformation($"   ✅ Using Reason: '{serviceName}'");
                    }
                    else if (a.Service != null && !string.IsNullOrEmpty(a.Service.Name))
                    {
                        serviceName = a.Service.Name;
                        if (index == 0 && appointments.Count > 0)
                            _logger.LogInformation($"   ✅ Using Service.Name: '{serviceName}'");
                    }
                    else
                    {
                        serviceName = a.Type switch
                        {
                            AppointmentType.Checkup => "Godišnji pregled",
                            AppointmentType.Vaccination => "Vakcinacija",
                            AppointmentType.Surgery => "Sterilizacija",
                            AppointmentType.Emergency => "Hitna pomoć",
                            AppointmentType.Grooming => "Kompletno čišćenje",
                            AppointmentType.Dental => "Čišćenje zuba",
                            AppointmentType.Consultation => "Konsultacija",
                            AppointmentType.FollowUp => "Kontrola",
                            _ => null
                        };
                        if (index == 0 && appointments.Count > 0)
                            _logger.LogInformation($"   ✅ Using Type mapping: '{serviceName}'");
                    }
                    
                    var dto = new AppointmentDto
                    {
                        Id = a.Id,
                        AppointmentNumber = a.AppointmentNumber,
                        AppointmentDate = a.AppointmentDate,
                        StartTime = a.StartTime.ToString(@"hh\:mm"),
                        EndTime = a.EndTime.ToString(@"hh\:mm"),
                        Type = (int)a.Type,
                        Status = (int)a.Status,
                        PetId = a.PetId, // Eksplicitno postavi PetId
                        PetName = a.Pet.Name,
                        VeterinarianId = a.VeterinarianId,
                        OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                        VeterinarianName = $"{a.Veterinarian.FirstName} {a.Veterinarian.LastName}",
                        ServiceId = a.ServiceId,
                        ServiceName = serviceName,
                        EstimatedCost = a.EstimatedCost,
                        ActualCost = a.ActualCost,
                        IsPaid = a.IsPaid,
                        PaymentDate = a.PaymentDate,
                        PaymentMethod = a.PaymentMethod,
                        PaymentTransactionId = a.PaymentTransactionId,
                        Reason = a.Reason,
                        Notes = a.Notes
                    };
                    
                    // Debug: Provjeri da li je PetId postavljen
                    if (index == 0 && appointments.Count > 0)
                    {
                        _logger.LogInformation($"🔍 [DEBUG] Created DTO for appointment {a.Id}: PetId = {dto.PetId}, PetName = {dto.PetName}");
                    }
                    
                    return dto;
                }).ToList();

                _logger.LogInformation($"✅ Returning {appointmentDtos.Count} appointments");
                _logger.LogInformation($"📋 Service names: {string.Join(", ", appointmentDtos.Where(a => !string.IsNullOrEmpty(a.ServiceName)).Select(a => a.ServiceName))}");
                _logger.LogInformation($"⚠️ Appointments without ServiceName: {appointmentDtos.Count(a => string.IsNullOrEmpty(a.ServiceName))}");
                
                // Debug: Log first appointment DTO to verify PetId is set
                if (appointmentDtos.Count > 0)
                {
                    var firstDto = appointmentDtos[0];
                    _logger.LogInformation($"🔍 [DEBUG] ===== FIRST APPOINTMENT DTO DEBUG =====");
                    _logger.LogInformation($"🔍 [DEBUG] Id: {firstDto.Id}");
                    _logger.LogInformation($"🔍 [DEBUG] PetId: {firstDto.PetId}");
                    _logger.LogInformation($"🔍 [DEBUG] PetName: {firstDto.PetName}");
                    _logger.LogInformation($"🔍 [DEBUG] VeterinarianId: {firstDto.VeterinarianId}");
                    _logger.LogInformation($"🔍 [DEBUG] ServiceId: {firstDto.ServiceId}");
                    
                    // Serialize first DTO to JSON to see what's actually being sent
                    var jsonOptions = new System.Text.Json.JsonSerializerOptions 
                    { 
                        PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
                        WriteIndented = true 
                    };
                    var json = System.Text.Json.JsonSerializer.Serialize(firstDto, jsonOptions);
                    _logger.LogInformation($"🔍 [DEBUG] Serialized JSON (first 1000 chars):");
                    _logger.LogInformation(json.Substring(0, Math.Min(1000, json.Length)));
                    _logger.LogInformation($"🔍 [DEBUG] ===== END DEBUG =====");
                }
                
                return Ok(appointmentDtos);
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
                .Include(a => a.Pet)
                .ThenInclude(p => p.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service) // Eksplicitno učitaj Service
                .OrderByDescending(a => a.AppointmentDate)
                .ToListAsync();

            // Mapiraj na DTO nakon učitavanja
            var appointmentDtos = appointments.Select(a => new AppointmentDto
            {
                Id = a.Id,
                AppointmentNumber = a.AppointmentNumber,
                AppointmentDate = a.AppointmentDate,
                StartTime = a.StartTime.ToString(@"hh\:mm"),
                EndTime = a.EndTime.ToString(@"hh\:mm"),
                Type = (int)a.Type,
                Status = (int)a.Status,
                PetId = a.PetId,
                PetName = a.Pet.Name,
                VeterinarianId = a.VeterinarianId,
                OwnerName = $"{a.Pet.PetOwner.FirstName} {a.Pet.PetOwner.LastName}",
                VeterinarianName = $"{a.Veterinarian.FirstName} {a.Veterinarian.LastName}",
                ServiceId = a.ServiceId,
                ServiceName = !string.IsNullOrEmpty(a.Reason) 
                    ? a.Reason 
                    : (a.Service != null && !string.IsNullOrEmpty(a.Service.Name) 
                        ? a.Service.Name 
                        : (a.Type == AppointmentType.Checkup ? "Godišnji pregled" :
                           a.Type == AppointmentType.Vaccination ? "Vakcinacija" :
                           a.Type == AppointmentType.Surgery ? "Sterilizacija" :
                           a.Type == AppointmentType.Emergency ? "Hitna pomoć" :
                           a.Type == AppointmentType.Grooming ? "Kompletno čišćenje" :
                           a.Type == AppointmentType.Dental ? "Čišćenje zuba" :
                           a.Type == AppointmentType.Consultation ? "Konsultacija" :
                           a.Type == AppointmentType.FollowUp ? "Kontrola" : null)),
                EstimatedCost = a.EstimatedCost,
                ActualCost = a.ActualCost,
                IsPaid = a.IsPaid,
                PaymentDate = a.PaymentDate,
                PaymentMethod = a.PaymentMethod,
                PaymentTransactionId = a.PaymentTransactionId,
                Reason = a.Reason,
                Notes = a.Notes
            }).ToList();

            return Ok(appointmentDtos);
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
                    ServiceName = !string.IsNullOrEmpty(a.Reason) 
                        ? a.Reason 
                        : (a.Service != null && !string.IsNullOrEmpty(a.Service.Name) 
                            ? a.Service.Name 
                            : null),
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
                .Include(a => a.Pet)
                .ThenInclude(p => p.PetOwner)
                .Include(a => a.Veterinarian)
                .Include(a => a.Service)
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
                    ServiceName = !string.IsNullOrEmpty(a.Reason) 
                        ? a.Reason 
                        : (a.Service != null && !string.IsNullOrEmpty(a.Service.Name) 
                            ? a.Service.Name 
                            : null),
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
            var startTime = DateTime.UtcNow;
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userEmailClaim = User.FindFirst(ClaimTypes.Email)?.Value;
            var userRoleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = Request.Headers["User-Agent"].ToString();

            _logger.LogInformation("💳 [MARK PAID] ========== PAYMENT REQUEST STARTED ==========");
            _logger.LogInformation("💳 [MARK PAID] Timestamp: {Timestamp}", startTime);
            _logger.LogInformation("💳 [MARK PAID] Appointment ID: {AppointmentId}", id);
            _logger.LogInformation("💳 [MARK PAID] User ID: {UserId}, Email: {UserEmail}, Role: {UserRole}", 
                userIdClaim, userEmailClaim, userRoleClaim);
            _logger.LogInformation("💳 [MARK PAID] Client IP: {ClientIp}, User-Agent: {UserAgent}", clientIp, userAgent);
            _logger.LogInformation("💳 [MARK PAID] Request data - PaymentMethod: {PaymentMethod}, TransactionId: {TransactionId}, Amount: {Amount}",
                request.PaymentMethod ?? "null", request.PaymentTransactionId ?? "null", request.Amount?.ToString() ?? "null");

            try
            {
                // Load appointment with related entities for detailed logging
                var appointment = await _context.Appointments
                    .Include(a => a.Pet)
                        .ThenInclude(p => p.PetOwner)
                    .Include(a => a.Veterinarian)
                    .Include(a => a.Service)
                    .FirstOrDefaultAsync(a => a.Id == id);

                if (appointment == null)
                {
                    _logger.LogWarning("💳 [MARK PAID] ❌ Appointment not found: {AppointmentId}", id);
                    return NotFound();
                }

                var currentStatus = appointment.Status;
                var currentIsPaid = appointment.IsPaid;
                
                _logger.LogInformation("💳 [MARK PAID] ✅ Appointment found - ID: {AppointmentId}", appointment.Id);
                _logger.LogInformation("💳 [MARK PAID] Appointment Details:");
                _logger.LogInformation("   - Status: {CurrentStatus} -> {NewStatus}", currentStatus, AppointmentStatus.Completed);
                _logger.LogInformation("   - IsPaid: {CurrentIsPaid} -> true", currentIsPaid);
                _logger.LogInformation("   - Appointment Date: {AppointmentDate}", appointment.AppointmentDate);
                _logger.LogInformation("   - Appointment Number: {AppointmentNumber}", appointment.AppointmentNumber);
                _logger.LogInformation("   - Estimated Cost: {EstimatedCost}", appointment.EstimatedCost?.ToString() ?? "null");
                _logger.LogInformation("   - Actual Cost (before): {ActualCost}", appointment.ActualCost?.ToString() ?? "null");
                
                if (appointment.Pet != null)
                {
                    _logger.LogInformation("   - Pet: {PetName} (ID: {PetId})", appointment.Pet.Name, appointment.Pet.Id);
                    if (appointment.Pet.PetOwner != null)
                    {
                        _logger.LogInformation("   - Owner: {OwnerName} (ID: {OwnerId}, Email: {OwnerEmail})", 
                            $"{appointment.Pet.PetOwner.FirstName} {appointment.Pet.PetOwner.LastName}",
                            appointment.Pet.PetOwnerId, appointment.Pet.PetOwner.Email);
                    }
                }
                
                if (appointment.Veterinarian != null)
                {
                    _logger.LogInformation("   - Veterinarian: {VetName} (ID: {VetId}, Email: {VetEmail})", 
                        $"{appointment.Veterinarian.FirstName} {appointment.Veterinarian.LastName}",
                        appointment.VeterinarianId, appointment.Veterinarian.Email);
                }
                
                if (appointment.Service != null)
                {
                    _logger.LogInformation("   - Service: {ServiceName} (ID: {ServiceId}, Price: {ServicePrice})", 
                        appointment.Service.Name, appointment.ServiceId, appointment.Service.Price);
                }
                else if (appointment.ServiceId.HasValue)
                {
                    _logger.LogWarning("💳 [MARK PAID] ⚠️ Service ID {ServiceId} specified but Service entity not found", appointment.ServiceId.Value);
                }

                // Označi kao plaćeno i završi termin
                var previousStatus = appointment.Status;
                var previousIsPaid = appointment.IsPaid;
                var previousPaymentMethod = appointment.PaymentMethod;
                var previousTransactionId = appointment.PaymentTransactionId;
                
                appointment.IsPaid = true;
                appointment.PaymentDate = DateTime.UtcNow;
                appointment.PaymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod) ? "Stripe" : request.PaymentMethod;
                appointment.PaymentTransactionId = request.PaymentTransactionId;
                // Kada je plaćeno, smatramo termin završenim radi izvještaja
                appointment.Status = AppointmentStatus.Completed;

                _logger.LogInformation("💳 [MARK PAID] 📝 Updating appointment payment fields:");
                _logger.LogInformation("   - IsPaid: {PreviousIsPaid} -> {NewIsPaid}", previousIsPaid, appointment.IsPaid);
                _logger.LogInformation("   - PaymentDate: null -> {PaymentDate}", appointment.PaymentDate);
                _logger.LogInformation("   - PaymentMethod: {PreviousPaymentMethod} -> {NewPaymentMethod}", 
                    previousPaymentMethod ?? "null", appointment.PaymentMethod);
                _logger.LogInformation("   - PaymentTransactionId: {PreviousTransactionId} -> {NewTransactionId}", 
                    previousTransactionId ?? "null", appointment.PaymentTransactionId ?? "null");
                _logger.LogInformation("   - Status: {PreviousStatus} -> {NewStatus}", previousStatus, appointment.Status);

                // Ako nema actual cost, postavi ga
                if (!appointment.ActualCost.HasValue)
                {
                    _logger.LogInformation("💳 [MARK PAID] 💰 ActualCost not set, attempting to determine it...");
                    var actualCostSet = false;
                    
                    // Prvo pokušaj iz request.Amount
                    if (request.Amount.HasValue && request.Amount.Value > 0)
                    {
                        appointment.ActualCost = request.Amount.Value;
                        _logger.LogInformation("💳 [MARK PAID] ✅ Set ActualCost from request.Amount: {Amount} KM", request.Amount.Value);
                        actualCostSet = true;
                    }
                    // Ako nema Amount, pokušaj iz Service.Price
                    else if (appointment.ServiceId.HasValue)
                    {
                        _logger.LogInformation("💳 [MARK PAID] 🔍 Attempting to get price from Service ID: {ServiceId}", appointment.ServiceId.Value);
                        var service = await _context.Services.FindAsync(appointment.ServiceId.Value);
                        if (service != null && service.Price > 0)
                        {
                            appointment.ActualCost = service.Price;
                            _logger.LogInformation("💳 [MARK PAID] ✅ Set ActualCost from Service.Price: {Price} KM (Service: {ServiceName})", 
                                service.Price, service.Name);
                            actualCostSet = true;
                        }
                        else
                        {
                            _logger.LogWarning("💳 [MARK PAID] ⚠️ Service not found or price is 0 for ServiceId: {ServiceId}", appointment.ServiceId.Value);
                        }
                    }
                    // Na kraju, koristi EstimatedCost ako postoji
                    else if (appointment.EstimatedCost.HasValue && appointment.EstimatedCost.Value > 0)
                    {
                        appointment.ActualCost = appointment.EstimatedCost;
                        _logger.LogInformation("💳 [MARK PAID] ✅ Set ActualCost from EstimatedCost: {EstimatedCost} KM", appointment.EstimatedCost.Value);
                        actualCostSet = true;
                    }
                    else
                    {
                        _logger.LogWarning("💳 [MARK PAID] ⚠️ Could not determine ActualCost - no Amount, ServiceId, or EstimatedCost available");
                        _logger.LogWarning("💳 [MARK PAID] ⚠️ Request.Amount: {Amount}, ServiceId: {ServiceId}, EstimatedCost: {EstimatedCost}",
                            request.Amount?.ToString() ?? "null", 
                            appointment.ServiceId?.ToString() ?? "null", 
                            appointment.EstimatedCost?.ToString() ?? "null");
                    }
                    
                    if (!actualCostSet)
                    {
                        _logger.LogError("💳 [MARK PAID] ❌ CRITICAL: ActualCost could not be determined! Payment may be incomplete.");
                    }
                }
                else
                {
                    _logger.LogInformation("💳 [MARK PAID] ✅ ActualCost already set: {ActualCost} KM", appointment.ActualCost.Value);
                }

                _logger.LogInformation("💳 [MARK PAID] 💾 Saving changes to database...");
                var saveStartTime = DateTime.UtcNow;
                
                try
                {
                    await _context.SaveChangesAsync();
                    var saveDuration = (DateTime.UtcNow - saveStartTime).TotalMilliseconds;
                    
                    _logger.LogInformation("💳 [MARK PAID] ✅ Database save completed in {Duration}ms", saveDuration);
                    _logger.LogInformation("💳 [MARK PAID] ✅ Appointment marked as paid successfully!");
                    _logger.LogInformation("💳 [MARK PAID] Final Appointment State:");
                    _logger.LogInformation("   - ID: {AppointmentId}", appointment.Id);
                    _logger.LogInformation("   - IsPaid: {IsPaid}", appointment.IsPaid);
                    _logger.LogInformation("   - PaymentDate: {PaymentDate}", appointment.PaymentDate);
                    _logger.LogInformation("   - PaymentMethod: {PaymentMethod}", appointment.PaymentMethod);
                    _logger.LogInformation("   - PaymentTransactionId: {TransactionId}", appointment.PaymentTransactionId ?? "null");
                    _logger.LogInformation("   - Status: {Status}", appointment.Status);
                    _logger.LogInformation("   - ActualCost: {ActualCost} KM", appointment.ActualCost?.ToString() ?? "null");
                    _logger.LogInformation("   - EstimatedCost: {EstimatedCost} KM", appointment.EstimatedCost?.ToString() ?? "null");
                    
                    var totalDuration = (DateTime.UtcNow - startTime).TotalMilliseconds;
                    _logger.LogInformation("💳 [MARK PAID] ⏱️ Total request duration: {Duration}ms", totalDuration);
                    _logger.LogInformation("💳 [MARK PAID] ========== PAYMENT REQUEST COMPLETED SUCCESSFULLY ==========");

                    return Ok(appointment);
                }
                catch (DbUpdateException dbEx)
                {
                    _logger.LogError(dbEx, "💳 [MARK PAID] ❌ Database update error - AppointmentId: {AppointmentId}", id);
                    _logger.LogError("💳 [MARK PAID] ❌ Database error details: {Message}", dbEx.Message);
                    if (dbEx.InnerException != null)
                    {
                        _logger.LogError("💳 [MARK PAID] ❌ Inner exception: {InnerMessage}", dbEx.InnerException.Message);
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                var errorDuration = (DateTime.UtcNow - startTime).TotalMilliseconds;
                _logger.LogError(ex, "💳 [MARK PAID] ❌ ========== PAYMENT REQUEST FAILED ==========");
                _logger.LogError("💳 [MARK PAID] ❌ Error marking appointment as paid - AppointmentId: {AppointmentId}", id);
                _logger.LogError("💳 [MARK PAID] ❌ Error type: {ErrorType}", ex.GetType().Name);
                _logger.LogError("💳 [MARK PAID] ❌ Error message: {ErrorMessage}", ex.Message);
                _logger.LogError("💳 [MARK PAID] ❌ Stack trace: {StackTrace}", ex.StackTrace);
                _logger.LogError("💳 [MARK PAID] ❌ Request duration before error: {Duration}ms", errorDuration);
                _logger.LogError("💳 [MARK PAID] ❌ =================================================");
                throw;
            }
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
