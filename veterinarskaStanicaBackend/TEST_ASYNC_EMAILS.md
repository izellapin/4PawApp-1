# 📧 Testiranje Asinhronih Emailova - 4Paw Veterinary Clinic

## 🚀 Brzi Start

### 1. Pokretanje sistema
```bash
# Pokretanje RabbitMQ-a
docker-compose up rabbitmq -d

# Pokretanje API-ja
dotnet run --project veterinarskaStanica.WebAPI

# Ili ceo sistem
docker-compose up -d
```

### 2. Testiranje preko PowerShell skript-a
```powershell
# Svi testovi
.\test-async-emails.ps1 -Email "your@email.com" -TestType "all"

# Jedan test
.\test-async-emails.ps1 -Email "your@email.com" -TestType "service"
```

### 3. Testiranje preko API endpoint-a
```bash
# Osnovni test
curl "http://localhost:5160/api/AsyncEmailTest/service?email=your@email.com"

# Performance test
curl "http://localhost:5160/api/AsyncEmailTest/performance?email=your@email.com"
```

## 📋 Dostupni testovi

### 1. **Appointment Notification Test**
```
GET /api/AsyncEmailTest/appointment?email=your@email.com
```
- Testira appointment notifikacije
- Šalje test appointment confirmation email

### 2. **Service Notification Test (CineVibe Pattern)**
```
GET /api/AsyncEmailTest/service?email=your@email.com
```
- Testira service notifikacije po CineVibe uzoru
- Simulira kreiranje novog servisa i slanje notifikacija

### 3. **User Registration Test**
```
GET /api/AsyncEmailTest/registration?email=your@email.com
```
- Testira welcome email za nove korisnike
- Simulira registraciju novog korisnika

### 4. **System Notification Test**
```
GET /api/AsyncEmailTest/system?email=your@email.com
```
- Testira sistemske notifikacije
- Opšte sistemske poruke

### 5. **Performance Test**
```
GET /api/AsyncEmailTest/performance?email=your@email.com
```
- **Ključni test za asinhroni rad!**
- Meri brzinu API response-a
- Trebalo bi biti **< 100ms** jer je asinhrono

### 6. **Bulk Test**
```
GET /api/AsyncEmailTest/bulk?email=your@email.com&count=5
```
- Šalje više emailova odjednom
- Testira performanse pri bulk slanju

### 7. **Comprehensive Test**
```
GET /api/AsyncEmailTest/all?email=your@email.com
```
- Pokreće sve testove redom
- Najbolji za kompletnu proveru

## 🔍 Kako proveriti da rade asinhroni emailovi

### ✅ **1. Brzina API Response-a**
```bash
# Ovaj zahtev treba da bude BRZE (< 100ms)
time curl "http://localhost:5160/api/AsyncEmailTest/performance?email=test@example.com"
```
**Očekivano**: Response za < 100ms
**Ako je sporo**: Emailovi se šalju sinhrono (problem)

### ✅ **2. RabbitMQ Management UI**
Idite na: `http://localhost:15672` (admin/admin123)

**Proverite**:
- **Queues tab**: Trebalo bi da vidite queue-ove:
  - `4paw_appointment_notifications`
  - `4paw_service_notifications`
  - `4paw_user_registration_notifications`
  - `4paw_system_notifications`

- **Messages**: Broj poruka u queue-ovima
- **Consumers**: Trebalo bi da bude 1 consumer po queue-u

### ✅ **3. Application Logovi**
Tražite u console output-u:

```
✅ GOOD - Async working:
[INFO] Published service notification for Test Service to 1 recipients
[INFO] Processing service notification for Test Service
[INFO] Email sent successfully to test@example.com

❌ BAD - Sync (blocking):
[ERROR] RabbitMQ connection failed
[INFO] Sending email directly via EmailService (fallback)
```

### ✅ **4. Email Inbox**
- Proverite da li stižu emailovi
- Emailovi mogu stići sa kašnjenjem (to je OK)
- Važno je da API response bude brz

## 🐛 Troubleshooting

### Problem: API response spor (> 1000ms)
```bash
# Proveri da li RabbitMQ radi
docker ps | grep rabbitmq

# Restart RabbitMQ
docker-compose restart rabbitmq

# Proveri logove
docker logs veterinary-rabbitmq
```

### Problem: Nema poruka u RabbitMQ queue-ovima
```bash
# Proveri da li je NotificationSubscriberService pokrenuto
# U application logovima tražiti:
# "NotificationSubscriberService started successfully"
# "Subscribed to all notification types"
```

### Problem: Poruke u queue-u ali ne procesiraju se
```bash
# Proveri Consumer service
# U logovima tražiti:
# "Processing appointment notification for appointment X"
# "Email sent successfully to user@example.com"
```

### Problem: RabbitMQ connection error
```json
// Proveri appsettings.json
{
  "RabbitMQ": {
    "Host": "localhost",
    "Username": "guest",
    "Password": "guest",
    "VirtualHost": "/",
    "Enabled": true
  }
}
```

## 📊 Performance Benchmarks

### Asinhroni (RabbitMQ) - OČEKIVANO
```
Service Creation API: ~50-100ms
Email Processing: Background (async)
User Experience: Instant response
```

### Sinhroni (Direct EmailService) - LOŠE
```
Service Creation API: ~2000-5000ms  
Email Processing: Blocks API
User Experience: Slow response
```

## 🎯 Test Scenarios

### Scenario 1: Novi korisnik se registruje
```powershell
.\test-async-emails.ps1 -Email "newuser@test.com" -TestType "registration"
```
**Očekivano**: 
- Brz API response
- Welcome email stiže u inbox
- RabbitMQ queue pokazuje processed message

### Scenario 2: Kreiranje novog servisa (CineVibe pattern)
```powershell
.\test-async-emails.ps1 -Email "petowner@test.com" -TestType "service"  
```
**Očekivano**:
- API odgovara odmah (< 100ms)
- Service notification email stiže
- Prati CineVibe pattern (if entity != null && userEmails.Any())

### Scenario 3: Bulk notifications
```powershell
.\test-async-emails.ps1 -Email "test@test.com" -TestType "bulk"
```
**Očekivano**:
- API i dalje brz uprkos bulk slanju
- Svi emailovi se procesiraju u background-u
- RabbitMQ queue pokazuje sve poruke

## 💡 Dodatni testovi

### Manual API test
```bash
# Test info endpoint
curl http://localhost:5160/api/AsyncEmailTest/info

# Health check
curl http://localhost:5160/api/AsyncEmailTest/health
```

### Direct RabbitMQ test
```bash
# Proveri RabbitMQ API
curl -u admin:admin123 http://localhost:15672/api/overview

# Lista queue-ova
curl -u admin:admin123 http://localhost:15672/api/queues
```

---

## 🏆 Success Criteria

Asinhroni emailovi rade ako:
1. ✅ API response < 100ms
2. ✅ RabbitMQ queue-ovi postoje i procesiraju poruke  
3. ✅ Emailovi stižu u inbox
4. ✅ Application logovi pokazuju async processing
5. ✅ Sistem radi i pri bulk slanju

**Ako sve ovo radi - vaši asinhroni emailovi su uspešno implementirani! 🎉**
















