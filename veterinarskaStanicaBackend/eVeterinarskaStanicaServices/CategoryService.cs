using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.SearchObjects;
using System.Linq;
using System;
using MapsterMapper;
using eVeterinarskaStanicaModel;

namespace eVeterinarskaStanicaServices
{
    public class CategoryService : BaseService<CategoryResponse, CategorySearchObject, Category>, ICategoryService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public CategoryService(ApplicationDbContext context, IMapper mapper) : base(context)
        {
            _context = context;
            _mapper = mapper;
        }

        protected override CategoryResponse MapToResponse(Category entity)
        {
            return _mapper.Map<CategoryResponse>(entity);
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(c => c.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(c => c.Name.Contains(search.FTS) || c.Description.Contains(search.FTS));
            }
            return query;
        }

        public async Task<Category?> GetCategoryEntityByIdAsync(int id)
        {
            return await _context.Categories.FindAsync(id);
        }

        public async Task<bool> CategoryExistsAsync(int id)
        {
            return await _context.Categories.AnyAsync(c => c.Id == id);
        }

        public async Task<bool> CategoryNameExistsAsync(string name, int? excludeId = null)
        {
            var query = _context.Categories.Where(c => c.Name == name);
            if (excludeId.HasValue)
                query = query.Where(c => c.Id != excludeId.Value);
            return await query.AnyAsync();
        }

        public async Task<IEnumerable<CategoryResponse>> GetTopLevelCategoriesAsync()
        {
            var categories = await _context.Categories
                .Where(c => c.ParentCategoryId == null)
                .ToListAsync();
            return _mapper.Map<List<CategoryResponse>>(categories);
        }

        public async Task<IEnumerable<CategoryResponse>> GetSubCategoriesAsync(int parentId)
        {
            var categories = await _context.Categories
                .Where(c => c.ParentCategoryId == parentId)
                .ToListAsync();
            return _mapper.Map<List<CategoryResponse>>(categories);
        }

        public async Task<ServiceResult<CategoryResponse>> InsertAsync(CategoryInsertRequest request)
        {
            try
            {
                var category = new Category
                {
                    Name = request.Name,
                    Description = request.Description,
                    ParentCategoryId = request.ParentCategoryId,
                    DateCreated = DateTime.UtcNow,
                    IsActive = true
                };

                _context.Categories.Add(category);
                await _context.SaveChangesAsync();

                return ServiceResult<CategoryResponse>.SuccessResult(_mapper.Map<CategoryResponse>(category));
            }
            catch (Exception ex)
            {
                return ServiceResult<CategoryResponse>.ErrorResult($"Error creating category: {ex.Message}");
            }
        }

        public async Task<ServiceResult<CategoryResponse>> UpdateAsync(int id, CategoryUpdateRequest request)
        {
            try
            {
                var category = await _context.Categories.FindAsync(id);
                if (category == null)
                {
                    return ServiceResult<CategoryResponse>.ErrorResult("Category not found");
                }

                if (!string.IsNullOrEmpty(request.Name))
                    category.Name = request.Name;
                if (!string.IsNullOrEmpty(request.Description))
                    category.Description = request.Description;
                if (request.ParentCategoryId.HasValue)
                    category.ParentCategoryId = request.ParentCategoryId.Value;
                if (request.IsActive.HasValue)
                    category.IsActive = request.IsActive.Value;

                await _context.SaveChangesAsync();

                return ServiceResult<CategoryResponse>.SuccessResult(_mapper.Map<CategoryResponse>(category));
            }
            catch (Exception ex)
            {
                return ServiceResult<CategoryResponse>.ErrorResult($"Error updating category: {ex.Message}");
            }
        }

        public async Task<ServiceResult> DeleteAsync(int id)
        {
            try
            {
                var category = await _context.Categories.FindAsync(id);
                if (category == null)
                {
                    return ServiceResult.ErrorResult("Category not found");
                }

                _context.Categories.Remove(category);
                await _context.SaveChangesAsync();

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error deleting category: {ex.Message}");
            }
        }

        public async Task<CategoryResponse?> GetCategoryTreeAsync(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return null;
            }
            return _mapper.Map<CategoryResponse>(category);
        }

        public async Task<ServiceResult> ActivateCategoryAsync(int id)
        {
            try
            {
                var category = await _context.Categories.FindAsync(id);
                if (category == null)
                {
                    return ServiceResult.ErrorResult("Category not found");
                }

                category.IsActive = true;
                await _context.SaveChangesAsync();

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error activating category: {ex.Message}");
            }
        }

        public async Task<ServiceResult> DeactivateCategoryAsync(int id)
        {
            try
            {
                var category = await _context.Categories.FindAsync(id);
                if (category == null)
                {
                    return ServiceResult.ErrorResult("Category not found");
                }

                category.IsActive = false;
                await _context.SaveChangesAsync();

                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error deactivating category: {ex.Message}");
            }
        }
    }
}
