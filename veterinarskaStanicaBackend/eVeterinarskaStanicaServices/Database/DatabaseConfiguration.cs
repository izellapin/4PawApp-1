using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Mapster;
using MapsterMapper;

namespace eVeterinarskaStanicaServices.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString));

            // Add Mapster
            var config = new TypeAdapterConfig();
            services.AddSingleton(config);
            services.AddScoped<IMapper, ServiceMapper>();

            // Add Services
            services.AddScoped<IHashingService, HashingService>();
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<ICategoryService, CategoryService>();
            services.AddScoped<iServiceService, ServiceService>();
            services.AddScoped<IDataSeederService, DataSeederService>();
            services.AddScoped<IEmailService, EmailService>();
            services.AddScoped<INotificationPublisherService, NotificationPublisherService>();
            // services.AddScoped<AsyncEmailTestService>(); // Commented out due to compilation issues
        }
    }
}
