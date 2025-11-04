using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace eVeterinarskaStanicaServices.Database
{
    public class ApplicationDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
    {
        public ApplicationDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
            // Connection string za development
            optionsBuilder.UseSqlServer(
                "Server=localhost,1402;Database=4PawDB;User Id=sa;Password=YourStrongPassword123!;TrustServerCertificate=True;Encrypt=True;");

            return new ApplicationDbContext(optionsBuilder.Options);
        }
    }
}

