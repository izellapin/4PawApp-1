using System;
using System.Threading;
using System.Threading.Tasks;
using EasyNetQ;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using eVeterinarskaStanicaModel.Notifications;

namespace eVeterinarskaStanicaServices
{
    public class NotificationSubscriberService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationSubscriberService> _logger;
        private readonly IConfiguration _configuration;
        private IBus? _bus;

        public NotificationSubscriberService(
            IServiceProvider serviceProvider,
            ILogger<NotificationSubscriberService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await Task.Delay(5000, stoppingToken);

            try
            {
                InitializeRabbitMQ();
                SubscribeToNotifications();
                _logger.LogInformation("NotificationSubscriberService started successfully");

                while (!stoppingToken.IsCancellationRequested)
                {
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in NotificationSubscriberService");
            }
        }

        private void InitializeRabbitMQ()
        {
            try
            {
                var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                _bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");
                _logger.LogInformation("RabbitMQ connection established");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize RabbitMQ connection");
                throw;
            }
        }

        private void SubscribeToNotifications()
        {
            if (_bus == null) return;

            _bus.PubSub.SubscribeAsync<AppointmentNotification>("4paw_appointment_notifications", 
                async appointmentNotification => await ProcessAppointmentNotification(appointmentNotification));

            _bus.PubSub.SubscribeAsync<ServiceNotification>("4paw_service_notifications", 
                async serviceNotification => await ProcessServiceNotification(serviceNotification));

            _bus.PubSub.SubscribeAsync<UserRegistrationNotification>("4paw_user_registration_notifications", 
                async userNotification => await ProcessUserRegistrationNotification(userNotification));

            _logger.LogInformation("Subscribed to all notification types");
        }

        private async Task ProcessAppointmentNotification(AppointmentNotification appointmentNotification)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                var appointment = appointmentNotification.Appointment;
                _logger.LogInformation($"Processing appointment notification for appointment {appointment.AppointmentId}");

                foreach (var email in appointment.UserEmails)
                {
                    var subject = appointment.AppointmentType switch
                    {
                        "Confirmation" => $"Appointment Confirmed - 4Paw Veterinary Clinic",
                        "Reminder" => $"Appointment Reminder - 4Paw Veterinary Clinic",
                        "Cancellation" => $"Appointment Cancelled - 4Paw Veterinary Clinic",
                        _ => $"Appointment Update - 4Paw Veterinary Clinic"
                    };

                    var body = GenerateAppointmentEmailBody(appointment);
                    await emailService.SendEmailAsync(email, subject, body);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing appointment notification");
            }
        }

        private async Task ProcessServiceNotification(ServiceNotification serviceNotification)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                var service = serviceNotification.Service;
                foreach (var email in service.UserEmails)
                {
                    var subject = $"Service Update - {service.ServiceName}";
                    var body = GenerateServiceEmailBody(service);
                    await emailService.SendEmailAsync(email, subject, body);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing service notification");
            }
        }

        private async Task ProcessUserRegistrationNotification(UserRegistrationNotification userNotification)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                var user = userNotification.User;
                
                // Send verification code email instead of welcome email
                var emailSent = await emailService.SendEmailVerificationCodeAsync(
                    user.Email, 
                    user.VerificationCode,
                    $"{user.FirstName} {user.LastName}".Trim()
                );
                
                if (emailSent)
                {
                    _logger.LogInformation("Email verification code sent to {Email}", user.Email);
                }
                else
                {
                    _logger.LogWarning("Failed to send verification code to {Email}", user.Email);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing user registration notification");
            }
        }

        private string GenerateAppointmentEmailBody(AppointmentNotificationDto appointment)
        {
            return $@"
<h2>Appointment {appointment.AppointmentType}</h2>
<p>Hello {appointment.OwnerName},</p>
<p>Pet: {appointment.PetName} ({appointment.PetType})</p>
<p>Service: {appointment.ServiceName}</p>
<p>Date: {appointment.AppointmentDate:dd/MM/yyyy HH:mm}</p>
<p>Veterinarian: {appointment.VeterinarianName}</p>
<p>Price: {appointment.ServicePrice:C}</p>";
        }

        private string GenerateServiceEmailBody(ServiceNotificationDto service)
        {
            return $@"
<h2>{service.ServiceName}</h2>
<p>Category: {service.Category}</p>
<p>Description: {service.Description}</p>
<p>Price: {service.Price:C}</p>";
        }

        private string GenerateWelcomeEmailBody(UserRegistrationNotificationDto user)
        {
            return $@"
<h2>Welcome to 4Paw Veterinary Clinic!</h2>
<p>Hello {user.FirstName} {user.LastName},</p>
<p>Welcome to our veterinary clinic. Your registration was successful!</p>
<p>{user.WelcomeMessage}</p>";
        }

        public override void Dispose()
        {
            _bus?.Dispose();
            base.Dispose();
        }
    }
}


