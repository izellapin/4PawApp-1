using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EasyNetQ;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Notifications;
using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;

namespace eVeterinarskaStanicaServices
{
    public interface INotificationPublisherService
    {
        Task PublishAppointmentNotificationAsync(AppointmentNotificationDto appointmentDto, List<string> userEmails);
        Task PublishServiceNotificationAsync(ServiceNotificationDto serviceDto, List<string> userEmails);
        Task PublishUserRegistrationNotificationAsync(UserRegistrationNotificationDto userDto);
        Task PublishSystemNotificationAsync(SystemNotificationDto notificationDto, List<string> userEmails);
        Task PublishEmailNotificationAsync(EmailNotificationMessage emailMessage);
    }

    public class NotificationPublisherService : INotificationPublisherService
    {
        private readonly ILogger<NotificationPublisherService> _logger;
        private readonly IConfiguration _configuration;
        private readonly ApplicationDbContext _context;

        public NotificationPublisherService(
            ILogger<NotificationPublisherService> logger,
            IConfiguration configuration,
            ApplicationDbContext context)
        {
            _logger = logger;
            _configuration = configuration;
            _context = context;
        }

        public async Task PublishAppointmentNotificationAsync(AppointmentNotificationDto appointmentDto, List<string> userEmails)
        {
            try
            {
                if (appointmentDto != null && userEmails.Any())
                {
                    // Setup RabbitMQ connection
                    var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                    var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                    var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                    var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                    using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                    appointmentDto.UserEmails = userEmails;

                    var appointmentNotification = new AppointmentNotification
                    {
                        Appointment = appointmentDto
                    };

                    await bus.PubSub.PublishAsync(appointmentNotification);
                    _logger.LogInformation($"Published appointment notification for appointment {appointmentDto.AppointmentId}");

                    // Save to database for tracking
                    await SaveNotificationToDatabase(appointmentDto.AppointmentType, 
                        $"Appointment {appointmentDto.AppointmentType}", 
                        $"Appointment for {appointmentDto.PetName} on {appointmentDto.AppointmentDate:dd/MM/yyyy HH:mm}",
                        userEmails);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to publish appointment notification: {ex.Message}");
            }
        }

        public async Task PublishServiceNotificationAsync(ServiceNotificationDto serviceDto, List<string> userEmails)
        {
            try
            {
                if (serviceDto != null && userEmails.Any())
                {
                    var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                    var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                    var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                    var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                    using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                    serviceDto.UserEmails = userEmails;

                    var serviceNotification = new ServiceNotification
                    {
                        Service = serviceDto
                    };

                    await bus.PubSub.PublishAsync(serviceNotification);
                    _logger.LogInformation($"Published service notification for service {serviceDto.ServiceName}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to publish service notification: {ex.Message}");
            }
        }

        public async Task PublishUserRegistrationNotificationAsync(UserRegistrationNotificationDto userDto)
        {
            try
            {
                if (userDto != null)
                {
                    var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                    var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                    var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                    var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                    using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                    var userRegistrationNotification = new UserRegistrationNotification
                    {
                        User = userDto
                    };

                    await bus.PubSub.PublishAsync(userRegistrationNotification);
                    _logger.LogInformation($"Published user registration notification for user {userDto.Email}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to publish user registration notification: {ex.Message}");
            }
        }

        public async Task PublishSystemNotificationAsync(SystemNotificationDto notificationDto, List<string> userEmails)
        {
            try
            {
                if (notificationDto != null && userEmails.Any())
                {
                    var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                    var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                    var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                    var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                    using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                    notificationDto.UserEmails = userEmails;

                    var systemNotification = new SystemNotification
                    {
                        Notification = notificationDto
                    };

                    await bus.PubSub.PublishAsync(systemNotification);
                    _logger.LogInformation($"Published system notification '{notificationDto.Title}'");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to publish system notification: {ex.Message}");
            }
        }

        public async Task PublishEmailNotificationAsync(EmailNotificationMessage emailMessage)
        {
            try
            {
                if (emailMessage != null && emailMessage.ToEmails.Any())
                {
                    var host = _configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
                    var username = _configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
                    var password = _configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
                    var virtualhost = _configuration["RabbitMQ:VirtualHost"] ?? Environment.GetEnvironmentVariable("RABBITMQ_VIRTUALHOST") ?? "/";

                    using var bus = RabbitHutch.CreateBus($"host={host};virtualHost={virtualhost};username={username};password={password}");

                    await bus.PubSub.PublishAsync(emailMessage);
                    _logger.LogInformation($"Published email notification '{emailMessage.Subject}'");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to publish email notification: {ex.Message}");
            }
        }

        private async Task SaveNotificationToDatabase(string type, string title, string message, List<string> userEmails)
        {
            try
            {
                var users = await _context.Users
                    .Where(u => userEmails.Contains(u.Email))
                    .Select(u => new { u.Id, u.Email })
                    .ToListAsync();

                foreach (var user in users)
                {
                    var notification = new Notification
                    {
                        Title = title,
                        Message = message,
                        Type = GetNotificationType(type),
                        Status = NotificationStatus.Sent,
                        DateCreated = DateTime.UtcNow,
                        DateSent = DateTime.UtcNow,
                        SendEmail = true,
                        UserId = user.Id
                    };

                    _context.Notifications.Add(notification);
                }

                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save notification to database");
            }
        }

        private NotificationType GetNotificationType(string type)
        {
            return type.ToLower() switch
            {
                "appointment confirmation" => NotificationType.AppointmentConfirmation,
                "appointment reminder" => NotificationType.AppointmentReminder,
                "appointment cancellation" => NotificationType.AppointmentCancellation,
                "new service" => NotificationType.OrderUpdate,
                "promotional offer" => NotificationType.PromotionalOffer,
                _ => NotificationType.SystemAlert
            };
        }
    }
}