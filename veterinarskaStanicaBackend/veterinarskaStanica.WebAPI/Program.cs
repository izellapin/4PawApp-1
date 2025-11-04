using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

namespace veterinarskaStanica.WebAPI
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            
            // Configure Kestrel to listen on all interfaces for development
            builder.WebHost.UseUrls("http://0.0.0.0:5160");

            // Add services to the container.
            var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
            builder.Services.AddDatabaseServices(connectionString);

            builder.Services.AddTransient<iServiceService, ServiceService>();
            builder.Services.AddScoped<IAuthService, AuthService>();

            // ===== JWT Authentication (no fallbacks, consistent UTF8) =====
            var jwtSecret = builder.Configuration["JWT:Secret"];
            if (string.IsNullOrWhiteSpace(jwtSecret))
            {
                throw new InvalidOperationException("JWT:Secret is not configured.");
            }

            var keyBytes = Encoding.UTF8.GetBytes(jwtSecret);
            var signingKey = new SymmetricSecurityKey(keyBytes);

            builder.Services
                .AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
                })
                .AddJwtBearer(options =>
                {
                    options.RequireHttpsMetadata = false; // set true in production behind HTTPS
                    options.SaveToken = true;
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = signingKey,

                        // Keep issuer/audience disabled for now since you don't set them when issuing the token.
                        // If you add them later, set these to true and configure ValidIssuer/ValidAudience.
                        ValidateIssuer = false,
                        ValidateAudience = false,

                        // Be strict on time drift
                        ClockSkew = TimeSpan.Zero,

                        // Ensure only HS256 is accepted (matches your token issuing code)
                        ValidAlgorithms = new[] { SecurityAlgorithms.HmacSha256 },

                        // Explicit for clarity
                        ValidateLifetime = true
                    };
                });

            builder.Services.AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
                    options.JsonSerializerOptions.WriteIndented = true;
                    // Remove JsonStringEnumConverter to send enum values as numbers
                    // options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
                });

            // ===== CORS =====
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });
            });

            // ===== Swagger/OpenAPI =====
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "Veterinary Clinic API",
                    Version = "v1",
                    Description = "API for Veterinary Clinic Management System"
                });
                
                // Exclude ErrorController from Swagger
                c.DocInclusionPredicate((docName, apiDesc) =>
                {
                    return !apiDesc.ActionDescriptor.RouteValues.ContainsKey("controller") ||
                           apiDesc.ActionDescriptor.RouteValues["controller"] != "Error";
                });

                // JWT Bearer security so the "Authorize" button appears in Swagger UI
                // Define JWT as ApiKey to ensure the Authorize button shows up across Swagger UI versions
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "JWT Authorization header. Format: Bearer {token}",
                    Name = "Authorization",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey
                });

                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            // ===== Health checks =====
            builder.Services.AddHealthChecks();

            // ===== RabbitMQ Background Service (optional) =====
            var rabbitMQEnabled = builder.Configuration.GetValue<bool>("RabbitMQ:Enabled", true);
            if (rabbitMQEnabled)
            {
                builder.Services.AddHostedService<NotificationSubscriberService>();
            }

            var app = builder.Build();

            // Apply pending migrations and seed data
            using (var scope = app.Services.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                try
                {
                    context.Database.Migrate();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Migration warning: {ex.Message}");
                    // Ako već postoje tabele, ignorisiš
                }

                try
                {
                    var seeder = scope.ServiceProvider.GetRequiredService<IDataSeederService>();
                    await seeder.SeedInitialDataAsync();
                }
                catch (Exception ex)
                {
                    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "Error occurred during data seeding, but application will continue");
                }
            }

            // ===== HTTP pipeline =====
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            // app.UseHttpsRedirection(); // Disabled for development to allow HTTP connections

            // Add exception handler for better error logging
            app.UseExceptionHandler("/error");

            app.UseCors("AllowAll");

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapHealthChecks("/health");
            app.MapControllers();

            app.Run();
        }
    }
}
