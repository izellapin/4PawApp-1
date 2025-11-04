using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using eVeterinarskaStanicaServices.Database;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;

namespace eVeterinarskaStanicaServices
{
    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : class where TEntity : class
    {
        private readonly ApplicationDbContext _context;

        public BaseService(ApplicationDbContext context)
        {
            _context = context;
        }



        public virtual async Task<List<T>> GetAsync(TSearch search)
        {
            var query = _context.Set<TEntity>().AsQueryable();

            // Apply filters if search object is provided
            if (search != null)
            {
                query = ApplyFilter(query, search);
            }

            var list = await query.ToListAsync();
            return list.Select(MapToResponse).ToList();
        }


        public virtual async Task<T?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                return null;
            }
            return MapToResponse(entity);
        }


        protected abstract T MapToResponse(TEntity entity);
        

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            // Default implementation - no filtering
            return query;
        }


    }
}
