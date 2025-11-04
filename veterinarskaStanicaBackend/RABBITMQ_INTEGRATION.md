# 🐰 RabbitMQ Asinhroni Email Integration - 4Paw Veterinary Clinic

## Pregled

Ova implementacija dodaje RabbitMQ podršku za asinhrone emailove u 4Paw veterinarsku kliniku, po uzoru na [CineVibe projekat](https://github.com/nadinerizvanovic/CineVibe/blob/main/CineVibe/CineVibe.Services/Services/MovieService.cs).

## 🚀 Ključne funkcionalnosti

- ✅ **Asinhroni emailovi** - Ne blokira HTTP response
- ✅ **RabbitMQ integracija** sa EasyNetQ bibliotekom
- ✅ **Automatski retry** mehanizam za neispravne emailove
- ✅ **Različiti tipovi notifikacija**: Appointment, Service, User Registration, System
- ✅ **Docker podrška** sa RabbitMQ Management UI
- ✅ **Skalabilnost** - Dodavanje više consumer-a po potrebi

## 📁 Struktura fajlova

```
eVeterinarskaStanicaModel/Notifications/
├── AppointmentNotificationDto.cs    # DTO za appointment notifikacije
├── ServiceNotificationDto.cs        # DTO za service notifikacije  
├── UserRegistrationNotificationDto.cs # DTO za registracije
└── NotificationMessage.cs           # Base message klase

eVeterinarskaStanicaServices/
├── NotificationPublisherService.cs  # Publisher (šalje poruke)
├── NotificationSubscriberService.cs # Consumer (prima i procesira)
├── ServiceExtendedService.cs        # Primer integracije
└── Examples/
    ├── RabbitMQServiceExample.cs    # Primer korišćenja
    └── ControllerUsageExample.cs    # Controller primer
```

## 🛠️ Setup i instalacija

### 1. Dodavanje paketa

```bash
cd eVeterinarskaStanicaServices
dotnet add package EasyNetQ
dotnet add package Microsoft.Extensions.Hosting
```

### 2. Konfiguracija (appsettings.json)

```json
{
  "RabbitMQ": {
    "Host": "localhost",
    "Port": 5672,
    "Username": "guest", 
    "Password": "guest",
    "VirtualHost": "/",
    "Enabled": true
  }
}
```

### 3. Docker pokretanje

```bash
# Pokretanje RabbitMQ-a
docker-compose up rabbitmq -d

# Ili ceo sistem
docker-compose up -d
```

**RabbitMQ Management UI:** `http://localhost:15672` (admin/admin123)

## 📝 Korišćenje - CineVibe Pattern

### Osnovna implementacija (kao u CineVibe)

```csharp
public async Task<ServiceResult<Service>> CreateServiceAsync(ServiceInsertRequest request)
{
    try
    {
        // 1. Kreiranje entiteta (kao movie u CineVibe)
        var service = new Service { /* properties */ };
        _context.Services.Add(service);
        await _context.SaveChangesAsync();

        // 2. Učitavanje sa related data
        var serviceEntity = await _context.Services
            .Include(s => s.Category)
            .FirstOrDefaultAsync(s => s.Id == service.Id);

        // 3. Dobijanje korisničkih emailova
        var userEmails = await _context.Users
            .Where(u => u.Role == UserRole.PetOwner && u.IsActive)
            .Select(u => u.Email)
            .ToListAsync();

        // 4. CineVibe pattern - provera da li postoje podaci
        if (serviceEntity != null && userEmails.Any())
        {
            // 5. Setup RabbitMQ connection (interno u NotificationPublisherService)
            // U CineVibe: using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

            // 6. Kreiranje notification DTO (kao MovieNotificationDto)
            var serviceNotificationDto = new ServiceNotificationDto
            {
                ServiceId = serviceEntity.Id,
                ServiceName = serviceEntity.Name,
                Description = serviceEntity.Description ?? "New service available!",
                Price = serviceEntity.Price,
                Category = serviceEntity.Category?.Name ?? "General",
                IsNew = true,
                UserEmails = userEmails
            };

            // 7. Publishing (kao u CineVibe: await bus.PubSub.PublishAsync(movieNotification))
            await _notificationPublisher.PublishServiceNotificationAsync(serviceNotificationDto, userEmails);
        }

        return ServiceResult<Service>.SuccessResult(serviceEntity);
    }
    catch (Exception ex)
    {
        // 8. CineVibe pattern - log error ali ne prekidaj glavnu operaciju
        _logger.LogError(ex, $"Failed to send service notification: {ex.Message}");
        return ServiceResult<Service>.ErrorResult($"Service created but notification failed: {ex.Message}");
    }
}
```

### Controller implementacija

```csharp
[HttpPost]
public async Task<IActionResult> CreateService([FromBody] ServiceInsertRequest request)
{
    // Direktno korišćenje CineVibe pattern-a
    var result = await _serviceExtendedService.CreateServiceWithNotificationAsync(request);
    
    if (result.Success)
    {
        return Ok(new { message = "Service created and notifications sent!", service = result.Data });
    }
    
    return BadRequest(new { message = result.ErrorMessage });
}
```

## 🔄 Tipovi notifikacija

### 1. Service Notifications (kao Movie u CineVibe)

```csharp
// Novi servis
await _notificationPublisher.PublishServiceNotificationAsync(new ServiceNotificationDto
{
    ServiceName = "Pet Vaccination",
    Description = "Complete vaccination package",
    IsNew = true,
    UserEmails = userEmails
}, userEmails);

// Promocija
await _notificationPublisher.PublishServiceNotificationAsync(new ServiceNotificationDto
{
    ServiceName = "Pet Grooming",
    IsPromotional = true,
    DiscountPercentage = 25,
    UserEmails = userEmails
}, userEmails);
```

### 2. Appointment Notifications

```csharp
await _notificationPublisher.PublishAppointmentNotificationAsync(new AppointmentNotificationDto
{
    AppointmentType = "Confirmation", // "Reminder", "Cancellation"
    AppointmentDate = DateTime.Now.AddDays(1),
    ServiceName = "Pet Checkup",
    PetName = "Bella",
    OwnerName = "John Doe",
    UserEmails = new List<string> { "john@example.com" }
}, new List<string> { "john@example.com" });
```

### 3. User Registration (kao u CineVibe za nove korisnike)

```csharp
await _notificationPublisher.PublishUserRegistrationNotificationAsync(new UserRegistrationNotificationDto
{
    FirstName = "Ana",
    LastName = "Petrović",
    Email = "ana@example.com",
    WelcomeMessage = "Welcome to 4Paw Veterinary Clinic!",
    AdminEmails = adminEmails
});
```

## 🔧 Napredne funkcionalnosti

### Targeting specifičnih korisnika

```csharp
// Samo vlasnici određenih tipova kućnih ljubimaca
var dogOwners = await _context.Pets
    .Where(p => p.Species == "Dog")
    .Select(p => p.User.Email)
    .Distinct()
    .ToListAsync();

await _notificationPublisher.PublishServiceNotificationAsync(serviceDto, dogOwners);
```

### Scheduled notifications

```csharp
// Appointment reminder (24h unapred)
var appointmentReminders = await _context.Appointments
    .Where(a => a.AppointmentDate.Date == DateTime.Today.AddDays(1))
    .Include(a => a.User)
    .Include(a => a.Service)
    .ToListAsync();

foreach (var appointment in appointmentReminders)
{
    await _notificationPublisher.PublishAppointmentNotificationAsync(new AppointmentNotificationDto
    {
        AppointmentType = "Reminder",
        // ... ostali podaci
    }, new List<string> { appointment.User.Email });
}
```

## 📊 Monitoring i debugging

### RabbitMQ Management UI
- URL: `http://localhost:15672`
- Username: `admin`
- Password: `admin123`

### Logovi
```csharp
_logger.LogInformation($"Service notification published for {serviceEntity.Name} to {userEmails.Count} recipients");
_logger.LogError(ex, "Failed to publish service notification");
```

### Health checks
```csharp
// Dodano u Program.cs
builder.Services.AddHealthChecks();
app.MapHealthChecks("/health");
```

## 🐛 Troubleshooting

### RabbitMQ connection problemi
```bash
# Provera da li RabbitMQ radi
docker ps | grep rabbitmq

# Logovi
docker logs veterinary-rabbitmq

# Restart
docker-compose restart rabbitmq
```

### Email delivery problemi
- Proveri Consumer service logove
- Proveri RabbitMQ queue-ove u Management UI
- Proveri email konfiguraciju u appsettings.json

## 🔄 Skaliranje

### Više consumer-a
```csharp
// Program.cs
builder.Services.AddHostedService<NotificationSubscriberService>();
builder.Services.AddHostedService<NotificationSubscriberService>(); // Drugi instance
```

### Load balancing
- Dodaj više API instanci u docker-compose.yml
- RabbitMQ automatski distribuira poruke između consumer-a

## 📚 Reference

- **CineVibe projekat**: [MovieService.cs](https://github.com/nadinerizvanovic/CineVibe/blob/main/CineVibe/CineVibe.Services/Services/MovieService.cs)
- **EasyNetQ dokumentacija**: [EasyNetQ GitHub](https://github.com/EasyNetQ/EasyNetQ)
- **RabbitMQ dokumentacija**: [RabbitMQ.com](https://www.rabbitmq.com/)

---

**Napomena**: Ova implementacija prati isti pattern kao CineVibe projekat - kreiranje entiteta, dobijanje korisničkih emailova, kreiranje notification DTO-a i publishing preko RabbitMQ-a.
















