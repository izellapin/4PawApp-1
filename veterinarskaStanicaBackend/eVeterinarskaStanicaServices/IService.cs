using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;

namespace eVeterinarskaStanicaServices
{
    public interface IService<T, TSearch> where T : class where TSearch : class
    {
        Task<T?> GetByIdAsync(int id);
        Task<List<T>> GetAsync(TSearch search);
    }
}
