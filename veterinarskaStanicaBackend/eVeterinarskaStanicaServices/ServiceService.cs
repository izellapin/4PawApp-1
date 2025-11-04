using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.SearchObjects;
using eVeterinarskaStanicaServices.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;

namespace eVeterinarskaStanicaServices
{
    public class ServiceService : iServiceService
    {
        private readonly ApplicationDbContext _context;

        public ServiceService(ApplicationDbContext context)
        {
            _context = context;
        }

        public List<Service> Get(ServiceSearchObject search)
        {
            var query = _context.Services
                .Include(s => s.Category)
                .AsQueryable();

            // Apply filters based on search object
            if (!string.IsNullOrEmpty(search.FTS))
                query = query.Where(s => s.Name.Contains(search.FTS) || 
                                        (s.Description != null && s.Description.Contains(search.FTS)) ||
                                        (s.Code != null && s.Code.Contains(search.FTS)));

            if (!string.IsNullOrEmpty(search.Code))
                query = query.Where(s => s.Code.Contains(search.Code));

            if (!string.IsNullOrEmpty(search.CodeGTE))
                query = query.Where(s => s.Code != null && s.Code.CompareTo(search.CodeGTE) >= 0);

            if (search.CategoryId.HasValue)
                query = query.Where(s => s.CategoryId == search.CategoryId.Value);

            if (search.RequiresAppointment.HasValue)
                query = query.Where(s => s.RequiresAppointment == search.RequiresAppointment.Value);

            if (search.IsActive.HasValue)
                query = query.Where(s => s.IsActive == search.IsActive.Value);

            if (search.IsFeatured.HasValue)
                query = query.Where(s => s.IsFeatured == search.IsFeatured.Value);

            if (search.MinPrice.HasValue)
                query = query.Where(s => s.Price >= search.MinPrice.Value);

            if (search.MaxPrice.HasValue)
                query = query.Where(s => s.Price <= search.MaxPrice.Value);

            if (!string.IsNullOrEmpty(search.ServiceType))
                query = query.Where(s => s.ServiceType != null && s.ServiceType.Contains(search.ServiceType));

            // Apply ordering
            if (!string.IsNullOrEmpty(search.OrderBy))
            {
                switch (search.OrderBy.ToLower())
                {
                    case "name":
                        query = search.IsDescending ? query.OrderByDescending(s => s.Name) : query.OrderBy(s => s.Name);
                        break;
                    case "price":
                        query = search.IsDescending ? query.OrderByDescending(s => s.Price) : query.OrderBy(s => s.Price);
                        break;
                    case "datecreated":
                        query = search.IsDescending ? query.OrderByDescending(s => s.DateCreated) : query.OrderBy(s => s.DateCreated);
                        break;
                    default:
                        query = query.OrderBy(s => s.Id);
                        break;
                }
            }
            else
            {
                query = query.OrderBy(s => s.Id);
            }

            // Apply pagination
            return query
                .Skip(search.Skip)
                .Take(search.Take)
                .ToList();
        }

        public Service Get(int id)
        {
            return _context.Services
                .Include(s => s.Category)
                .FirstOrDefault(s => s.Id == id);
        }
    }
}


