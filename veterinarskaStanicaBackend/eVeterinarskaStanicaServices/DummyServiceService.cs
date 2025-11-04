using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace eVeterinarskaStanicaServices
{
    public class DummyServiceService : iServiceService
    {
        public virtual List<Service> Get(ServiceSearchObject search)
        {
            List<Service> services = new List<Service>();
            services.Add(new Service()
            {
                Id = 1,
                Code = "CONSULT",
                Name = "Godišnji pregled",
                Description = "Sveobuhvatan godišnji zdravstveni pregled vašeg ljubimca",
                ShortDescription = "Kompletni zdravstveni pregled",
                Price = 75.00m,
                ServiceType = "Pregled",
                DurationMinutes = 45,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 1
            });
            
            services.Add(new Service()
            {
                Id = 2,
                Code = "VACC",
                Name = "Vakcinacija",
                Description = "Osnovne vakcine za zaštitu vašeg ljubimca od bolesti",
                ShortDescription = "Osnovne vakcine",
                Price = 120.00m,
                ServiceType = "Vakcinacija",
                DurationMinutes = 30,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 1
            });

            services.Add(new Service()
            {
                Id = 3,
                Code = "GROOM",
                Name = "Kompletno čišćenje",
                Description = "Kompletna usluga čišćenja uključujući kupanje, šišanje noktiju i stilizovanje",
                ShortDescription = "Kompletno čišćenje",
                Price = 80.00m,
                ServiceType = "Čišćenje",
                DurationMinutes = 120,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 2
            });

            services.Add(new Service()
            {
                Id = 4,
                Code = "EMERG",
                Name = "Hitna pomoć",
                Description = "Hitna veterinarska konsultacija za urgentne slučajeve",
                ShortDescription = "Hitna veterinarska pomoć",
                Price = 150.00m,
                ServiceType = "Hitno",
                DurationMinutes = 60,
                RequiresAppointment = false,
                IsActive = true,
                CategoryId = 3
            });

            services.Add(new Service()
            {
                Id = 5,
                Code = "SURG",
                Name = "Sterilizacija",
                Description = "Hirurška sterilizacija ljubimca",
                ShortDescription = "Operacija sterilizacije",
                Price = 300.00m,
                ServiceType = "Hirurgija",
                DurationMinutes = 120,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 4
            });

            services.Add(new Service()
            {
                Id = 6,
                Code = "DENTAL",
                Name = "Čišćenje zuba",
                Description = "Profesionalno čišćenje zuba i procjena oralnog zdravlja",
                ShortDescription = "Čišćenje zuba",
                Price = 200.00m,
                ServiceType = "Stomatologija",
                DurationMinutes = 90,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 5
            });

            var queryable = services.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search?.Code))
            {
                queryable = queryable.Where(x => x.Code == search.Code);
            }

            if (!string.IsNullOrWhiteSpace(search?.CodeGTE))
            {
                queryable = queryable.Where(x => x.Code.StartsWith(search.CodeGTE));
            }

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                queryable = queryable.Where(x => x.Code.Contains(search.FTS, StringComparison.CurrentCultureIgnoreCase) || 
                                               (x.Name != null && x.Name.Contains(search.FTS, StringComparison.CurrentCultureIgnoreCase)) ||
                                               (x.Description != null && x.Description.Contains(search.FTS, StringComparison.CurrentCultureIgnoreCase)));
            }

            if (!string.IsNullOrWhiteSpace(search?.ServiceType))
            {
                queryable = queryable.Where(x => x.ServiceType.Contains(search.ServiceType, StringComparison.CurrentCultureIgnoreCase));
            }

            if (search?.RequiresAppointment.HasValue == true)
            {
                queryable = queryable.Where(x => x.RequiresAppointment == search.RequiresAppointment.Value);
            }

            if (search?.MinPrice.HasValue == true)
            {
                queryable = queryable.Where(x => x.Price >= search.MinPrice.Value);
            }

            if (search?.MaxPrice.HasValue == true)
            {
                queryable = queryable.Where(x => x.Price <= search.MaxPrice.Value);
            }

            if (search?.CategoryId.HasValue == true)
            {
                queryable = queryable.Where(x => x.CategoryId == search.CategoryId.Value);
            }

            if (search?.IsActive.HasValue == true)
            {
                queryable = queryable.Where(x => x.IsActive == search.IsActive.Value);
            }

            if (search?.IsFeatured.HasValue == true)
            {
                queryable = queryable.Where(x => x.IsFeatured == search.IsFeatured.Value);
            }

            return queryable.ToList();
        }


        public virtual Service Get(int id)
        {
            var services = Get(new ServiceSearchObject());
            return services.FirstOrDefault(x => x.Id == id) ?? new Service()
            {
                Id = 1,
                Code = "CONSULT",
                Name = "Godišnji pregled",
                Description = "Sveobuhvatan godišnji zdravstveni pregled vašeg ljubimca",
                ShortDescription = "Kompletni zdravstveni pregled",
                Price = 75.00m,
                ServiceType = "Pregled",
                DurationMinutes = 45,
                RequiresAppointment = true,
                IsActive = true,
                CategoryId = 1
            };
        }
    }
}




