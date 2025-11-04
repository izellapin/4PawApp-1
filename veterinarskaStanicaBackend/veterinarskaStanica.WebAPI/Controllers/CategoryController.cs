using Microsoft.AspNetCore.Mvc;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoryController : ControllerBase
    {
        private readonly ICategoryService _categoryService;

        public CategoryController(ICategoryService categoryService)
        {
            _categoryService = categoryService;
        }

        // GET: api/Category
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CategoryResponse>>> GetCategories([FromQuery] CategorySearchObject? searchObject = null)
        {
            var search = searchObject ?? new CategorySearchObject();
            var categories = await _categoryService.GetAsync(search);
            return Ok(categories);
        }

        // GET: api/Category/5
        [HttpGet("{id}")]
        public async Task<ActionResult<CategoryResponse>> GetCategory(int id)
        {
            var category = await _categoryService.GetByIdAsync(id);

            if (category == null)
            {
                return NotFound();
            }

            return Ok(category);
        }

        // GET: api/Category/top-level
        [HttpGet("top-level")]
        public async Task<ActionResult<IEnumerable<CategoryResponse>>> GetTopLevelCategories()
        {
            var categories = await _categoryService.GetTopLevelCategoriesAsync();
            return Ok(categories);
        }

        // GET: api/Category/5/subcategories
        [HttpGet("{id}/subcategories")]
        public async Task<ActionResult<IEnumerable<CategoryResponse>>> GetSubCategories(int id)
        {
            var categories = await _categoryService.GetSubCategoriesAsync(id);
            return Ok(categories);
        }

        // GET: api/Category/5/tree
        [HttpGet("{id}/tree")]
        public async Task<ActionResult<CategoryResponse>> GetCategoryTree(int id)
        {
            var categoryTree = await _categoryService.GetCategoryTreeAsync(id);

            if (categoryTree == null)
            {
                return NotFound();
            }

            return Ok(categoryTree);
        }

        // POST: api/Category
        //[HttpPost]
        //public async Task<ActionResult<CategoryResponse>> CreateCategory(CategoryInsertRequest request)
        //{
        //    var result = await _categoryService.InsertAsync(request);
        //    
        //    if (!result.Success)
        //    {
        //        return BadRequest(result.ErrorMessage);
        //    }
        //    
        //    return CreatedAtAction(nameof(GetCategory), new { id = result.Data!.Id }, result.Data);
        //}

        // PUT: api/Category/5
        [HttpPut("{id}")]
        public async Task<ActionResult<CategoryResponse>> UpdateCategory(int id, CategoryUpdateRequest request)
        {
            var result = await _categoryService.UpdateAsync(id, request);
            
            if (!result.Success)
            {
                if (result.ErrorMessage == "Category not found")
                {
                    return NotFound(result.ErrorMessage);
                }
                return BadRequest(result.ErrorMessage);
            }
            
            return Ok(result.Data);
        }

        // DELETE: api/Category/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var result = await _categoryService.DeleteAsync(id);
            
            if (!result.Success)
            {
                if (result.ErrorMessage == "Category not found")
                {
                    return NotFound(result.ErrorMessage);
                }
                return BadRequest(result.ErrorMessage);
            }
            
            return NoContent();
        }

        // PATCH: api/Category/5/activate
        [HttpPatch("{id}/activate")]
        public async Task<IActionResult> ActivateCategory(int id)
        {
            var result = await _categoryService.ActivateCategoryAsync(id);
            
            if (!result.Success)
            {
                if (result.ErrorMessage == "Category not found")
                {
                    return NotFound(result.ErrorMessage);
                }
                return BadRequest(result.ErrorMessage);
            }
            
            return NoContent();
        }

        // PATCH: api/Category/5/deactivate
        [HttpPatch("{id}/deactivate")]
        public async Task<IActionResult> DeactivateCategory(int id)
        {
            var result = await _categoryService.DeactivateCategoryAsync(id);
            
            if (!result.Success)
            {
                if (result.ErrorMessage == "Category not found")
                {
                    return NotFound(result.ErrorMessage);
                }
                return BadRequest(result.ErrorMessage);
            }
            
            return NoContent();
        }

        // GET: api/Category/exists/name/{name}
        [HttpGet("exists/name/{name}")]
        public async Task<ActionResult<bool>> CheckCategoryNameExists(string name, [FromQuery] int? excludeId = null)
        {
            var exists = await _categoryService.CategoryNameExistsAsync(name, excludeId);
            return Ok(new { exists });
        }
    }
}
