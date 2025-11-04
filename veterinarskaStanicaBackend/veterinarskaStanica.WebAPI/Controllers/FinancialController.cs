using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using eVeterinarskaStanicaServices.Database;
using veterinarskaStanica.WebAPI.Authorization;
using eVeterinarskaStanicaModel;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/financial")]
    [Authorize]
    public class FinancialController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<FinancialController> _logger;

        public FinancialController(ApplicationDbContext context, ILogger<FinancialController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Dohvata finansijski izvještaj za admin panel
        /// </summary>
        /// <returns>AdminFinancialSummary sa dnevnim, mesečnim i godišnjim podacima</returns>
        /// <response code="200">Uspešno dohvaćeni finansijski podaci</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Admin)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("admin/financial-summary")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult<AdminFinancialSummary>> GetAdminFinancialSummary()
        {
            try
            {
                var today = DateTime.Today;
                var thisMonth = new DateTime(today.Year, today.Month, 1);
                var lastMonth = thisMonth.AddMonths(-1);
                var thisYear = new DateTime(today.Year, 1, 1);
                var lastYear = thisYear.AddYears(-1);

                // Dnevni prihod (danas)
                var todayRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate.Date == today && 
                               a.Status == AppointmentStatus.Completed)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var todayAppointments = await _context.Appointments
                    .CountAsync(a => a.AppointmentDate.Date == today);

                // Mesečni prihod
                var monthlyRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= thisMonth && 
                               a.Status == AppointmentStatus.Completed)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var lastMonthRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= lastMonth && 
                               a.AppointmentDate < thisMonth && 
                               a.Status == AppointmentStatus.Completed)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var monthlyGrowth = lastMonthRevenue > 0 ? 
                    ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0;

                // Prosečan termin - guard za prazne kolekcije
                var appointmentsWithCost = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed)
                    .ToListAsync();
                
                // DEBUG: Log database info
                _logger.LogInformation($"🔍 Database: {_context.Database.GetDbConnection().Database}");
                _logger.LogInformation($"🔍 Server: {_context.Database.GetDbConnection().DataSource}");
                _logger.LogInformation($"🔍 Completed status value: {(int)AppointmentStatus.Completed}");
                _logger.LogInformation($"🔍 Found {appointmentsWithCost.Count} appointments with Completed status and ActualCost");
                
                // DEBUG: Log all appointment statuses
                var allStatuses = await _context.Appointments
                    .GroupBy(a => a.Status)
                    .Select(g => new { Status = g.Key, Count = g.Count() })
                    .ToListAsync();
                _logger.LogInformation($"🔍 All appointment statuses: {string.Join(", ", allStatuses.Select(s => $"{s.Status}={s.Count}"))}");
                
                var avgAppointmentCost = 0.0m;
                if (appointmentsWithCost.Any())
                {
                    avgAppointmentCost = appointmentsWithCost.Average(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);
                }

                // Godišnji rast
                var thisYearRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= thisYear && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var lastYearRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= lastYear && a.AppointmentDate < thisYear && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var yearlyGrowth = lastYearRevenue > 0 ? 
                    ((thisYearRevenue - lastYearRevenue) / lastYearRevenue) * 100 : 0;

                // Prihod po danima (poslednih 30 dana)
                var dailyRevenue = new List<DailyRevenue>();
                
                // Debug: Proverim sve completed termine
                var allCompletedAppointments = await _context.Appointments
                    .Where(a => a.IsPaid)
                    .Select(a => new { a.AppointmentDate, Amount = (a.ActualCost ?? a.EstimatedCost) })
                    .ToListAsync();
                
                Console.WriteLine($"🔍 Total completed appointments: {allCompletedAppointments.Count}");
                foreach (var apt in allCompletedAppointments)
                {
                    Console.WriteLine($"📅 Appointment: {apt.AppointmentDate:yyyy-MM-dd} - Amount: {apt.Amount}");
                }
                
                for (int i = 59; i >= 0; i--)
                {
                    var date = today.AddDays(-i);
                    var revenue = await _context.Appointments
                        .Where(a => a.AppointmentDate.Date == date && 
                                   a.Status == AppointmentStatus.Completed)
                        .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);
                    
                    if (revenue > 0)
                    {
                        Console.WriteLine($"💰 Revenue for {date:yyyy-MM-dd}: {revenue}");
                    }
                    
                    dailyRevenue.Add(new DailyRevenue
                    {
                        Date = date,
                        Revenue = revenue
                    });
                }

                var revenueByService = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed)
                    .Select(a => new
                    {
                        Name = (a.Reason != null && a.Reason != "") ? a.Reason! :
                               (a.Service != null && a.Service.Name != null && a.Service.Name != "" ? a.Service.Name :
                                 (a.Type == AppointmentType.Checkup ? "Pregled" :
                                  a.Type == AppointmentType.Vaccination ? "Vakcinacija" :
                                  a.Type == AppointmentType.Surgery ? "Operacija" :
                                  a.Type == AppointmentType.Emergency ? "Hitno" :
                                  a.Type == AppointmentType.Grooming ? "Šišanje/Njega" :
                                  a.Type == AppointmentType.Dental ? "Stomatologija" :
                                  a.Type == AppointmentType.Consultation ? "Konsultacija" :
                                  /* AppointmentType.FollowUp */ "Kontrola")),
                        Amount = (a.ActualCost ?? a.EstimatedCost) ?? 0
                    })
                    .GroupBy(x => x.Name)
                    .Select(g => new RevenueByService
                    {
                        ServiceName = g.Key,
                        Revenue = g.Sum(i => i.Amount),
                        Count = g.Count()
                    })
                    .OrderByDescending(r => r.Revenue)
                    .ToListAsync();

                // Top klijenti
                var topClients = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed && 
                               a.ActualCost.HasValue)
                    .GroupBy(a => new { a.Pet.PetOwner.Id, a.Pet.PetOwner.FirstName, a.Pet.PetOwner.LastName })
                    .Select(g => new TopClient
                    {
                        Name = g.Key.FirstName + " " + g.Key.LastName,
                        TotalSpent = g.Sum(a => a.ActualCost ?? 0),
                        AppointmentCount = g.Count()
                    })
                    .OrderByDescending(c => c.TotalSpent)
                    .Take(10)
                    .ToListAsync();

                var summary = new AdminFinancialSummary
                {
                    DailyRevenue = todayRevenue,
                    DailyAppointments = todayAppointments,
                    MonthlyRevenue = monthlyRevenue,
                    MonthlyGrowthPercentage = (decimal)monthlyGrowth,
                    AverageAppointmentCost = avgAppointmentCost,
                    YearlyGrowthPercentage = (decimal)yearlyGrowth,
                    DailyRevenueData = dailyRevenue,
                    RevenueByService = revenueByService,
                    TopClients = topClients
                };

                return Ok(summary);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Greška pri dohvatanju finansijskih podataka: {ex.Message}");
            }
        }

        /// <summary>
        /// Dohvata statistike za trenutno ulogovanog veterinara
        /// </summary>
        /// <returns>VeterinarianStats sa dnevnim, mesečnim podacima i listom pacijenata</returns>
        /// <response code="200">Uspešno dohvaćene statistike</response>
        /// <response code="400">Nevaljan korisnik ID</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Veterinarian)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("veterinarian/my-stats")]
        [RoleRequired(UserRole.Veterinarian)]
        public async Task<ActionResult<VeterinarianStats>> GetVeterinarianStats()
        {
            int veterinarianId = 0; // Deklariši van try-catch bloka
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out veterinarianId))
                {
                    _logger.LogWarning("Invalid user ID claim: {UserIdClaim}", userIdClaim);
                    return BadRequest("Nevaljan korisnik ID");
                }

                _logger.LogInformation("🔍 Getting stats for veterinarian ID: {VeterinarianId}", veterinarianId);

                var today = DateTime.Today;
                var thisMonth = new DateTime(today.Year, today.Month, 1);

                // Termini danas
                var todayAppointments = await _context.Appointments
                    .CountAsync(a => a.VeterinarianId == veterinarianId && 
                                    a.AppointmentDate.Date == today);

                // Termini ovaj mesec
                var monthlyAppointments = await _context.Appointments
                    .CountAsync(a => a.VeterinarianId == veterinarianId && 
                                    a.AppointmentDate >= thisMonth);

                // Prihod ovaj mesec
                var monthlyRevenue = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && a.AppointmentDate >= thisMonth && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                // Prosečan termin - guard za prazne kolekcije
                var appointmentsWithCost = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && 
                               a.Status == AppointmentStatus.Completed && 
                               a.ActualCost.HasValue)
                    .ToListAsync();
                
                var avgAppointmentCost = 0.0m;
                if (appointmentsWithCost.Any())
                {
                    avgAppointmentCost = appointmentsWithCost.Average(a => a.ActualCost ?? 0);
                }

                // Pacijenti (jedinstveni AKTIVNI ljubimci) - popravka za null Pet referencu
                var uniquePatients = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && 
                               a.Pet != null && 
                               a.Pet.Status == PetStatus.Active)
                    .Select(a => a.PetId)
                    .Distinct()
                    .CountAsync();

                // Poslednji pacijenti (samo zadnja 3) - popravka za null Pet referencu
                var recentPatients = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && 
                               a.Pet != null && 
                               a.Pet.PetOwner != null)
                    .Include(a => a.Pet)
                        .ThenInclude(p => p.PetOwner)
                    .OrderByDescending(a => a.AppointmentDate)
                    .Select(a => new PatientInfo
                    {
                        Name = a.Pet.Name,
                        Species = a.Pet.Species,
                        LastVisit = a.AppointmentDate,
                        Owner = a.Pet.PetOwner.FirstName + " " + a.Pet.PetOwner.LastName
                    })
                    .Take(3)
                    .ToListAsync();

                // Prosječan rating veterinara - guard za prazne kolekcije
                var reviews = await _context.Reviews
                    .Where(r => r.VeterinarianId == veterinarianId && r.IsApproved)
                    .Select(r => r.Rating)
                    .ToListAsync();
                
                var averageRating = 0.0;
                var reviewCount = 0;
                
                if (reviews.Any())
                {
                    averageRating = reviews.Average();
                    reviewCount = reviews.Count;
                }

                var stats = new VeterinarianStats
                {
                    TodayAppointments = todayAppointments,
                    MonthlyAppointments = monthlyAppointments,
                    MonthlyRevenue = monthlyRevenue,
                    AverageAppointmentCost = avgAppointmentCost,
                    TotalPatients = uniquePatients,
                    RecentPatients = recentPatients,
                    AverageRating = Math.Round(averageRating, 1), // Zaokruži na 1 decimalu
                    ReviewCount = reviewCount
                };

                _logger.LogInformation("✅ Successfully loaded stats for veterinarian {VeterinarianId}: Today={Today}, Monthly={Monthly}, Revenue={Revenue}, Patients={Patients}", 
                    veterinarianId, todayAppointments, monthlyAppointments, monthlyRevenue, uniquePatients);

                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Error getting veterinarian stats for ID: {VeterinarianId}", veterinarianId);
                return StatusCode(500, $"Greška pri dohvatanju statistika: {ex.Message}");
            }
        }

        /// <summary>
        /// Dohvata dnevne termine za trenutno ulogovanog veterinara (poslednih 7 dana)
        /// </summary>
        /// <returns>Lista DailyRevenue sa brojem termina po danima</returns>
        /// <response code="200">Uspešno dohvaćeni dnevni termini</response>
        /// <response code="400">Nevaljan korisnik ID</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Veterinarian)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("veterinarian/daily-appointments")]
        [RoleRequired(UserRole.Veterinarian)]
        public async Task<ActionResult<List<DailyRevenue>>> GetVeterinarianDailyAppointments()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int veterinarianId))
                {
                    return BadRequest("Nevaljan korisnik ID");
                }

                var today = DateTime.Today;
                var dailyAppointments = new List<DailyRevenue>();

                // Poslednih 7 dana
                for (int i = 6; i >= 0; i--)
                {
                    var date = today.AddDays(-i);
                    var appointments = await _context.Appointments
                        .CountAsync(a => a.VeterinarianId == veterinarianId && 
                                        a.AppointmentDate.Date == date);
                    
                    dailyAppointments.Add(new DailyRevenue
                    {
                        Date = date,
                        Revenue = appointments * 150 // Aproksimacija na osnovu prosečne cene
                    });
                }

                return Ok(dailyAppointments);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Greška pri dohvatanju dnevnih termina: {ex.Message}");
            }
        }

        /// <summary>
        /// Dohvata ukupne prihode svih veterinara po uslugama za admin panel
        /// </summary>
        /// <returns>Lista RevenueByService sa ukupnim prihodima svih veterinara</returns>
        /// <response code="200">Uspešno dohvaćeni ukupni prihodi</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Admin)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("admin/revenue-by-services")]
        [RoleRequired(UserRole.Admin)]
        public async Task<ActionResult<List<RevenueByService>>> GetAdminRevenueByServices()
        {
            try
            {
                _logger.LogInformation("🔍 Getting revenue by services for all veterinarians (admin view)");

                // Grupisanje kao kod veterinara: Reason -> Service.Name -> Tip pregleda; bez limita i bez "Ostalo"
                var revenueByService = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed)
                    .Select(a => new
                    {
                        Name = (a.Reason != null && a.Reason != "") ? a.Reason! :
                               (a.Service != null && a.Service.Name != null && a.Service.Name != "" ? a.Service.Name :
                                 (a.Type == AppointmentType.Checkup ? "Pregled" :
                                  a.Type == AppointmentType.Vaccination ? "Vakcinacija" :
                                  a.Type == AppointmentType.Surgery ? "Operacija" :
                                  a.Type == AppointmentType.Emergency ? "Hitno" :
                                  a.Type == AppointmentType.Grooming ? "Šišanje/Njega" :
                                  a.Type == AppointmentType.Dental ? "Stomatologija" :
                                  a.Type == AppointmentType.Consultation ? "Konsultacija" :
                                  /* AppointmentType.FollowUp */ "Kontrola")),
                        Amount = (a.ActualCost ?? a.EstimatedCost) ?? 0
                    })
                    .GroupBy(x => x.Name)
                    .Select(g => new RevenueByService
                    {
                        ServiceName = g.Key,
                        Revenue = g.Sum(i => i.Amount),
                        Count = g.Count()
                    })
                    .OrderByDescending(r => r.Revenue)
                    .ToListAsync();

                return Ok(revenueByService);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting admin revenue by services");
                return StatusCode(500, $"Greška pri dohvatanju prihoda po uslugama: {ex.Message}");
            }
        }

        /// <summary>
        /// Dohvata top usluge za trenutno ulogovanog veterinara (ovaj mesec)
        /// </summary>
        /// <returns>Lista RevenueByService sa najpopularnijim uslugama</returns>
        /// <response code="200">Uspešno dohvaćene top usluge</response>
        /// <response code="400">Nevaljan korisnik ID</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Veterinarian)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("veterinarian/top-services")]
        [RoleRequired(UserRole.Veterinarian)]
        public async Task<ActionResult<List<RevenueByService>>> GetVeterinarianTopServices()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int veterinarianId))
                {
                    return BadRequest("Nevaljan korisnik ID");
                }

                // Uzmi SVE termine veterinara (ne samo ovaj mjesec)
                _logger.LogInformation($"🔍 Getting top services for veterinarian ID: {veterinarianId}");

                // Primarni pristup: uzmi potrebne podatke iz baze, pa grupiši u memoriji
                var rawItems = await _context.Appointments
                    .Where(a => a.VeterinarianId == veterinarianId && a.Status == AppointmentStatus.Completed)
                    .Select(a => new
                    {
                        ServiceName = a.Service != null ? a.Service.Name : null,
                        a.Reason,
                        a.Type,
                        Amount = (a.ActualCost ?? a.EstimatedCost) ?? 0
                    })
                    .ToListAsync();

                string MapType(AppointmentType t)
                {
                    return t == AppointmentType.Checkup ? "Pregled" :
                           t == AppointmentType.Vaccination ? "Vakcinacija" :
                           t == AppointmentType.Surgery ? "Operacija" :
                           t == AppointmentType.Emergency ? "Hitno" :
                           t == AppointmentType.Grooming ? "Šišanje/Njega" :
                           t == AppointmentType.Dental ? "Stomatologija" :
                           t == AppointmentType.Consultation ? "Konsultacija" :
                           t == AppointmentType.FollowUp ? "Kontrola" : t.ToString();
                }

                var topServices = rawItems
                    .Select(x => new
                    {
                        Name = !string.IsNullOrWhiteSpace(x.ServiceName)
                            ? x.ServiceName!
                            : (!string.IsNullOrWhiteSpace(x.Reason) ? x.Reason! : MapType(x.Type)),
                        x.Amount
                    })
                    .GroupBy(x => x.Name)
                    .Select(g => new RevenueByService
                    {
                        ServiceName = g.Key,
                        Revenue = g.Sum(i => i.Amount),
                        Count = g.Count()
                    })
                    .OrderByDescending(r => r.Revenue)
                    .Take(5)
                    .ToList();

                _logger.LogInformation($"📊 Found {topServices.Count} services with Service assigned");

                // Ako iz bilo kog razloga i dalje prazno, kao fallback grupiši po tipu
                if (topServices.Count == 0)
                {
                    _logger.LogInformation($"🔄 No categorized data, fallback by type...");
                    topServices = rawItems
                        .GroupBy(a => MapType(a.Type))
                        .Select(g => new RevenueByService
                        {
                            ServiceName = g.Key,
                            Revenue = g.Sum(a => a.Amount),
                            Count = g.Count()
                        })
                        .OrderByDescending(r => r.Revenue)
                        .Take(5)
                        .ToList();
                }
                
                // Ako postoji lista ali je ukupan prihod 0 (nema evidentiranih cijena),
                // koristi broj termina kao težinu da bi pie-chart bio šaren (umjesto 100% jedne kategorije)
                if (topServices.Count > 0 && topServices.Sum(s => s.Revenue) == 0)
                {
                    _logger.LogInformation("🔄 Total revenue is 0 for vet {VeterinarianId}, using counts as weights", veterinarianId);
                    topServices = topServices
                        .Select(s => new RevenueByService
                        {
                            ServiceName = s.ServiceName,
                            Revenue = s.Count, // koristi count kao pseudo-prihod
                            Count = s.Count
                        })
                        .ToList();
                }
                
                // Ako JOŠ UVIJEK nema, onda prikaži SVE termine (bilo koji status)
                if (topServices.Count == 0)
                {
                    _logger.LogInformation($"🔄 Still no data, showing ALL appointments...");
                    
                    topServices = await _context.Appointments
                        .Where(a => a.VeterinarianId == veterinarianId)
                        .GroupBy(a => a.Type)
                        .Select(g => new RevenueByService
                        {
                            ServiceName = g.Key == AppointmentType.Checkup ? "Pregled" :
                                         g.Key == AppointmentType.Vaccination ? "Vakcinacija" :
                                         g.Key == AppointmentType.Surgery ? "Operacija" :
                                         g.Key == AppointmentType.Emergency ? "Hitno" :
                                         g.Key == AppointmentType.Grooming ? "Šišanje/Njega" :
                                         g.Key == AppointmentType.Dental ? "Stomatologija" :
                                         g.Key == AppointmentType.Consultation ? "Konsultacija" :
                                         g.Key == AppointmentType.FollowUp ? "Kontrola" : "Ostalo",
                            Revenue = g.Sum(a => a.ActualCost ?? 0),
                            Count = g.Count()
                        })
                        .OrderByDescending(r => r.Count) // Sortiraj po broju, ne prihodu
                        .Take(5)
                        .ToListAsync();
                    
                    _logger.LogInformation($"📊 Found {topServices.Count} total appointments");
                }

                return Ok(topServices);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Greška pri dohvatanju top usluga: {ex.Message}");
            }
        }

        /// <summary>
        /// Generiše PDF finansijski izvještaj za admin panel
        /// </summary>
        /// <returns>PDF fajl sa finansijskim izvještajem</returns>
        /// <response code="200">Uspešno generisan PDF izvještaj</response>
        /// <response code="401">Neautorizovan pristup</response>
        /// <response code="403">Nedovoljne dozvole (samo Admin)</response>
        /// <response code="500">Greška na serveru</response>
        [HttpGet("admin/financial-report-pdf")]
        [RoleRequired(UserRole.Admin)]
        public async Task<IActionResult> GetFinancialReportPdf()
        {
            try
            {
                // Učitaj finansijske podatke
                var today = DateTime.Today;
                var thisMonth = new DateTime(today.Year, today.Month, 1);
                var lastMonth = thisMonth.AddMonths(-1);
                var thisYear = new DateTime(today.Year, 1, 1);
                var lastYear = thisYear.AddYears(-1);

                // Dnevni prihod
                var todayRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate.Date == today && 
                               a.Status == AppointmentStatus.Completed && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var todayAppointments = await _context.Appointments
                    .CountAsync(a => a.AppointmentDate.Date == today);

                // Mesečni prihod
                var monthlyRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= thisMonth && 
                               a.Status == AppointmentStatus.Completed && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var lastMonthRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= lastMonth && 
                               a.AppointmentDate < thisMonth && 
                               a.Status == AppointmentStatus.Completed && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var monthlyGrowth = lastMonthRevenue > 0 ? 
                    ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0;

                // Prosečan termin
                var appointmentsWithCost = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed && a.IsPaid)
                    .ToListAsync();
                
                var avgAppointmentCost = 0.0m;
                if (appointmentsWithCost.Any())
                {
                    avgAppointmentCost = appointmentsWithCost.Average(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);
                }

                // Godišnji prihod
                var thisYearRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= thisYear && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var lastYearRevenue = await _context.Appointments
                    .Where(a => a.AppointmentDate >= lastYear && a.AppointmentDate < thisYear && a.IsPaid)
                    .SumAsync(a => (a.ActualCost ?? a.EstimatedCost) ?? 0);

                var yearlyGrowth = lastYearRevenue > 0 ? 
                    ((thisYearRevenue - lastYearRevenue) / lastYearRevenue) * 100 : 0;

                // Prihod po uslugama
                var revenueByService = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed && a.IsPaid)
                    .Select(a => new
                    {
                        Name = (a.Reason != null && a.Reason != "") ? a.Reason! :
                               (a.Service != null && a.Service.Name != null && a.Service.Name != "" ? a.Service.Name :
                                 (a.Type == AppointmentType.Checkup ? "Pregled" :
                                  a.Type == AppointmentType.Vaccination ? "Vakcinacija" :
                                  a.Type == AppointmentType.Surgery ? "Operacija" :
                                  a.Type == AppointmentType.Emergency ? "Hitno" :
                                  a.Type == AppointmentType.Grooming ? "Šišanje/Njega" :
                                  a.Type == AppointmentType.Dental ? "Stomatologija" :
                                  a.Type == AppointmentType.Consultation ? "Konsultacija" :
                                  "Kontrola")),
                        Amount = (a.ActualCost ?? a.EstimatedCost) ?? 0
                    })
                    .GroupBy(x => x.Name)
                    .Select(g => new
                    {
                        ServiceName = g.Key,
                        Revenue = g.Sum(i => i.Amount),
                        Count = g.Count()
                    })
                    .OrderByDescending(r => r.Revenue)
                    .Take(10)
                    .ToListAsync();

                // Top klijenti
                var topClients = await _context.Appointments
                    .Where(a => a.Status == AppointmentStatus.Completed && a.IsPaid &&
                               a.ActualCost.HasValue)
                    .GroupBy(a => new { a.Pet.PetOwner.Id, a.Pet.PetOwner.FirstName, a.Pet.PetOwner.LastName })
                    .Select(g => new
                    {
                        Name = g.Key.FirstName + " " + g.Key.LastName,
                        TotalSpent = g.Sum(a => a.ActualCost ?? 0),
                        AppointmentCount = g.Count()
                    })
                    .OrderByDescending(c => c.TotalSpent)
                    .Take(10)
                    .ToListAsync();

                // Generiši PDF
                QuestPDF.Settings.License = LicenseType.Community;
                var pdfBytes = Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        page.Size(PageSizes.A4);
                        page.Margin(2, Unit.Centimetre);
                        page.DefaultTextStyle(x => x.FontSize(10));

                        page.Header()
                            .AlignCenter()
                            .Text("Finansijski izvještaj")
                            .FontSize(20)
                            .Bold()
                            .FontColor(Colors.Blue.Medium);

                        page.Content()
                            .PaddingVertical(1, Unit.Centimetre)
                            .Column(column =>
                            {
                                column.Spacing(20);

                                // Osnovni podaci
                                column.Item().Text($"Period: {thisMonth:dd.MM.yyyy} - {today:dd.MM.yyyy}")
                                    .FontSize(12)
                                    .Bold();

                                column.Item().Text($"Datum izvještaja: {DateTime.Now:dd.MM.yyyy HH:mm}")
                                    .FontSize(10)
                                    .FontColor(Colors.Grey.Medium);

                                // KPI kartice
                                column.Item().PaddingTop(10).Row(row =>
                                {
                                    row.ConstantItem(90).Text("Dnevni prihod:").FontSize(10);
                                    row.RelativeItem().Text($"{todayRevenue:N2} BAM").Bold();
                                    row.RelativeItem().Text($"{todayAppointments} termina").FontSize(9);
                                });

                                column.Item().Row(row =>
                                {
                                    row.ConstantItem(90).Text("Mesečni prihod:").FontSize(10);
                                    row.RelativeItem().Text($"{monthlyRevenue:N2} BAM").Bold();
                                    row.RelativeItem().Text($"Rast: {monthlyGrowth:F1}%").FontSize(9);
                                });

                                column.Item().Row(row =>
                                {
                                    row.ConstantItem(90).Text("Prosečan termin:").FontSize(10);
                                    row.RelativeItem().Text($"{avgAppointmentCost:N2} BAM").Bold();
                                });

                                column.Item().Row(row =>
                                {
                                    row.ConstantItem(90).Text("Godišnji prihod:").FontSize(10);
                                    row.RelativeItem().Text($"{thisYearRevenue:N2} BAM").Bold();
                                    row.RelativeItem().Text($"Rast: {yearlyGrowth:F1}%").FontSize(9);
                                });

                                // Prihod po uslugama
                                column.Item().PaddingTop(15).Text("Prihod po uslugama (Top 10)").FontSize(14).Bold();
                                column.Item().Table(table =>
                                {
                                    table.ColumnsDefinition(columns =>
                                    {
                                        columns.RelativeColumn(3);
                                        columns.RelativeColumn(2);
                                        columns.RelativeColumn(1);
                                    });

                                    table.Header(header =>
                                    {
                                        header.Cell().Element(CellStyle).Text("Usluga").Bold();
                                        header.Cell().Element(CellStyle).AlignRight().Text("Prihod (BAM)").Bold();
                                        header.Cell().Element(CellStyle).AlignRight().Text("Broj").Bold();
                                    });

                                    foreach (var service in revenueByService)
                                    {
                                        table.Cell().Element(CellStyle).Text(service.ServiceName);
                                        table.Cell().Element(CellStyle).AlignRight().Text($"{service.Revenue:N2}");
                                        table.Cell().Element(CellStyle).AlignRight().Text($"{service.Count}");
                                    }
                                });

                                // Top klijenti
                                column.Item().PaddingTop(15).Text("Top klijenti (Top 10)").FontSize(14).Bold();
                                column.Item().Table(table =>
                                {
                                    table.ColumnsDefinition(columns =>
                                    {
                                        columns.RelativeColumn(3);
                                        columns.RelativeColumn(2);
                                        columns.RelativeColumn(1);
                                    });

                                    table.Header(header =>
                                    {
                                        header.Cell().Element(CellStyle).Text("Klijent").Bold();
                                        header.Cell().Element(CellStyle).AlignRight().Text("Ukupno (BAM)").Bold();
                                        header.Cell().Element(CellStyle).AlignRight().Text("Termina").Bold();
                                    });

                                    foreach (var client in topClients)
                                    {
                                        table.Cell().Element(CellStyle).Text(client.Name);
                                        table.Cell().Element(CellStyle).AlignRight().Text($"{client.TotalSpent:N2}");
                                        table.Cell().Element(CellStyle).AlignRight().Text($"{client.AppointmentCount}");
                                    }
                                });
                            });

                        page.Footer()
                            .AlignCenter()
                            .Text(x =>
                            {
                                x.DefaultTextStyle(x => x.FontSize(9).FontColor(Colors.Grey.Medium));
                                x.Span("4Paw Veterinary Clinic");
                                x.Span(" - ");
                                x.Span($"Strana ");
                                x.CurrentPageNumber();
                                x.Span(" / ");
                                x.TotalPages();
                            });
                    });
                })
                .GeneratePdf();

                var fileName = $"Finansijski_izvjestaj_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";
                return File(pdfBytes, "application/pdf", fileName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška pri generisanju PDF izvještaja");
                return StatusCode(500, $"Greška pri generisanju PDF izvještaja: {ex.Message}");
            }
        }

        static IContainer CellStyle(IContainer container)
        {
            return container
                .Border(1)
                .BorderColor(Colors.Grey.Lighten2)
                .Padding(8)
                .Background(Colors.White);
        }
    }

    // Response modeli
    public class AdminFinancialSummary
    {
        public decimal DailyRevenue { get; set; }
        public int DailyAppointments { get; set; }
        public decimal MonthlyRevenue { get; set; }
        public decimal MonthlyGrowthPercentage { get; set; }
        public decimal AverageAppointmentCost { get; set; }
        public decimal YearlyGrowthPercentage { get; set; }
        public List<DailyRevenue> DailyRevenueData { get; set; } = new();
        public List<RevenueByService> RevenueByService { get; set; } = new();
        public List<TopClient> TopClients { get; set; } = new();
    }

    public class VeterinarianStats
    {
        public int TodayAppointments { get; set; }
        public int MonthlyAppointments { get; set; }
        public decimal MonthlyRevenue { get; set; }
        public decimal AverageAppointmentCost { get; set; }
        public int TotalPatients { get; set; }
        public List<PatientInfo> RecentPatients { get; set; } = new();
        public double AverageRating { get; set; } // Prosječan rating (1-5)
        public int ReviewCount { get; set; } // Broj review-ova
    }

    public class DailyRevenue
    {
        public DateTime Date { get; set; }
        public decimal Revenue { get; set; }
    }

    public class RevenueByService
    {
        public string ServiceName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }

    public class TopClient
    {
        public string Name { get; set; } = string.Empty;
        public decimal TotalSpent { get; set; }
        public int AppointmentCount { get; set; }
    }

    public class PatientInfo
    {
        public string Name { get; set; } = string.Empty;
        public string Species { get; set; } = string.Empty;
        public DateTime LastVisit { get; set; }
        public string Owner { get; set; } = string.Empty;
    }
}
