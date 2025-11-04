using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;

namespace eVeterinarskaStanicaServices
{
    public interface ICategoryService : ICRUDService<CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>
    {
        Task<Category?> GetCategoryEntityByIdAsync(int id);
        Task<bool> CategoryExistsAsync(int id);
        Task<bool> CategoryNameExistsAsync(string name, int? excludeId = null);
        Task<IEnumerable<CategoryResponse>> GetTopLevelCategoriesAsync();
        Task<IEnumerable<CategoryResponse>> GetSubCategoriesAsync(int parentId);
        Task<CategoryResponse?> GetCategoryTreeAsync(int id);
        Task<ServiceResult> ActivateCategoryAsync(int id);
        Task<ServiceResult> DeactivateCategoryAsync(int id);
    }
}
