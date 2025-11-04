using System.Threading.Tasks;

namespace eVeterinarskaStanicaServices
{
    public interface IDataSeederService
    {
        Task SeedInitialDataAsync();
        Task SeedAdminUserAsync();
        Task SeedCategoriesAsync();
        Task SeedServicesAsync();
    }
}
