using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;
using eVeterinarskaStanicaModel.Notifications;
using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eVeterinarskaStanicaServices
{
    /// <summary>
    /// Extended service class that adds RabbitMQ notification functionality to ServiceService
    /// This demonstrates how to integrate RabbitMQ notifications similar to CineVibe project
    /// </summary>
    public class ServiceExtendedService : ServiceService
    {
        private readonly INotificationPublisherService _notificationPublisher;
        private readonly ILogger<ServiceExtendedService> _logger;
        private readonly ApplicationDbContext _context;

        public ServiceExtendedService(
            ApplicationDbContext context,
            INotificationPublisherService notificationPublisher,
            ILogger<ServiceExtendedService> logger) : base(context)
        {
            _context = context;
            _notificationPublisher = notificationPublisher;
            _logger = logger;
        }

        /// <summary>
        /// Creates a new service and sends RabbitMQ notification to interested users
        /// This is similar to how CineVibe sends movie notifications
        /// </summary>
        public async Task<ServiceResult<Service>> CreateServiceWithNotificationAsync(ServiceInsertRequest request)
        {
            try
            {
                // Create the service using base functionality
                var service = new Service
                {
                    Name = request.Name,
                    Description = request.Description,
                    Price = request.Price,
                    CategoryId = request.CategoryId,
                    Code = request.Code,
                    RequiresAppointment = request.RequiresAppointment,
                    DurationMinutes = request.DurationMinutes,
                    IsActive = request.IsActive,
                    IsFeatured = request.IsFeatured,
                    ImageUrl = request.ImageUrl,
                    PreparationInstructions = request.PreparationInstructions,
                    PostCareInstructions = request.PostCareInstructions
                };

                _context.Services.Add(service);
                await _context.SaveChangesAsync();

                // Load the service with category for notifications
                var serviceEntity = await _context.Services
                    .Include(s => s.Category)
                    .FirstOrDefaultAsync(s => s.Id == service.Id);

                if (serviceEntity != null)
                {
                    // Get emails of users who might be interested in this service
                    // This is similar to how CineVibe gets user emails for movie notifications
                    var userEmails = await GetInterestedUserEmails(serviceEntity);

                    if (userEmails.Any())
                    {
                        // Create service notification DTO (similar to MovieNotificationDto in CineVibe)
                        var serviceNotificationDto = new ServiceNotificationDto
                        {
                            ServiceId = serviceEntity.Id,
                            ServiceName = serviceEntity.Name,
                            Description = serviceEntity.Description ?? "A new veterinary service is now available!",
                            Price = serviceEntity.Price,
                            Category = serviceEntity.Category?.Name ?? "General",
                            IsNew = true,
                            IsPromotional = serviceEntity.IsFeatured,
                            ImageUrl = serviceEntity.ImageUrl,
                            UserEmails = userEmails
                        };

                        // Publish to RabbitMQ (similar to CineVibe's bus.PubSub.PublishAsync)
                        await _notificationPublisher.PublishServiceNotificationAsync(serviceNotificationDto, userEmails);
                        
                        _logger.LogInformation($"Service notification published for service {serviceEntity.Name} to {userEmails.Count} users");
                    }
                }

                return ServiceResult<Service>.SuccessResult(serviceEntity ?? service);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to create service with notification: {ex.Message}");
                return ServiceResult<Service>.ErrorResult($"Failed to create service: {ex.Message}");
            }
        }

        /// <summary>
        /// Updates a service and sends promotional notifications if it becomes featured
        /// </summary>
        public async Task<ServiceResult<Service>> UpdateServiceWithNotificationAsync(int id, ServiceInsertRequest request, bool sendPromotionalNotification = false)
        {
            try
            {
                var existingService = await _context.Services
                    .Include(s => s.Category)
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (existingService == null)
                {
                    return ServiceResult<Service>.ErrorResult("Service not found");
                }

                var wasFeatured = existingService.IsFeatured;

                // Update service properties
                existingService.Name = request.Name;
                existingService.Description = request.Description;
                existingService.Price = request.Price;
                existingService.CategoryId = request.CategoryId;
                existingService.Code = request.Code;
                existingService.RequiresAppointment = request.RequiresAppointment;
                existingService.DurationMinutes = request.DurationMinutes;
                existingService.IsActive = request.IsActive;
                existingService.IsFeatured = request.IsFeatured;
                existingService.ImageUrl = request.ImageUrl;
                existingService.PreparationInstructions = request.PreparationInstructions;
                existingService.PostCareInstructions = request.PostCareInstructions;

                await _context.SaveChangesAsync();

                // Send promotional notification if service became featured or if explicitly requested
                if ((request.IsFeatured && !wasFeatured) || sendPromotionalNotification)
                {
                    var userEmails = await GetInterestedUserEmails(existingService);

                    if (userEmails.Any())
                    {
                        var serviceNotificationDto = new ServiceNotificationDto
                        {
                            ServiceId = existingService.Id,
                            ServiceName = existingService.Name,
                            Description = existingService.Description ?? "Check out this featured veterinary service!",
                            Price = existingService.Price,
                            Category = existingService.Category?.Name ?? "General",
                            IsNew = false,
                            IsPromotional = true,
                            DiscountPercentage = 15, // Example discount
                            PromotionEndDate = DateTime.UtcNow.AddDays(30),
                            ImageUrl = existingService.ImageUrl,
                            UserEmails = userEmails
                        };

                        await _notificationPublisher.PublishServiceNotificationAsync(serviceNotificationDto, userEmails);
                        _logger.LogInformation($"Promotional notification sent for service {existingService.Name}");
                    }
                }

                return ServiceResult<Service>.SuccessResult(existingService);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to update service with notification: {ex.Message}");
                return ServiceResult<Service>.ErrorResult($"Failed to update service: {ex.Message}");
            }
        }

        /// <summary>
        /// Gets emails of users who might be interested in this service
        /// This is similar to how CineVibe gets user emails based on preferences
        /// </summary>
        private async Task<List<string>> GetInterestedUserEmails(Service service)
        {
            try
            {
                // Get all active pet owners (they are most likely to be interested in services)
                var userEmails = await _context.Users
                    .Where(u => u.Role == UserRole.PetOwner && u.IsActive)
                    .Select(u => u.Email)
                    .ToListAsync();

                // You can extend this logic to be more sophisticated:
                // - Users who have pets of certain types
                // - Users who have used similar services before
                // - Users who have subscribed to notifications for this category
                // - Users in specific geographic areas

                // Example of more targeted approach:
                if (service.CategoryId > 0)
                {
                    // Get users who have appointments in this category
                    var categorySpecificUsers = await _context.Appointments
                        .Include(a => a.Service)
                        .Where(a => a.Service.CategoryId == service.CategoryId)
                        .Select(a => a.Pet.PetOwner.Email)
                        .Distinct()
                        .ToListAsync();

                    // Combine and deduplicate
                    userEmails.AddRange(categorySpecificUsers);
                    userEmails = userEmails.Distinct().ToList();
                }

                return userEmails;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get interested user emails");
                return new List<string>();
            }
        }

        /// <summary>
        /// Sends a system-wide service announcement
        /// </summary>
        public async Task<ServiceResult> SendServiceAnnouncementAsync(int serviceId, string title, string message, List<int>? targetUserIds = null)
        {
            try
            {
                var service = await _context.Services
                    .Include(s => s.Category)
                    .FirstOrDefaultAsync(s => s.Id == serviceId);

                if (service == null)
                {
                    return ServiceResult.ErrorResult("Service not found");
                }

                List<string> userEmails;

                if (targetUserIds != null && targetUserIds.Any())
                {
                    // Send to specific users
                    userEmails = await _context.Users
                        .Where(u => targetUserIds.Contains(u.Id))
                        .Select(u => u.Email)
                        .ToListAsync();
                }
                else
                {
                    // Send to all interested users
                    userEmails = await GetInterestedUserEmails(service);
                }

                if (userEmails.Any())
                {
                    var systemNotificationDto = new SystemNotificationDto
                    {
                        Title = title,
                        Message = message,
                        NotificationType = "Service Announcement",
                        Priority = "Normal",
                        ActionUrl = $"/services/{service.Id}",
                        ActionText = "View Service",
                        UserEmails = userEmails
                    };

                    await _notificationPublisher.PublishSystemNotificationAsync(systemNotificationDto, userEmails);
                    _logger.LogInformation($"Service announcement sent for {service.Name} to {userEmails.Count} users");
                }

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send service announcement: {ex.Message}");
                return ServiceResult.ErrorResult($"Failed to send announcement: {ex.Message}");
            }
        }
    }
}

