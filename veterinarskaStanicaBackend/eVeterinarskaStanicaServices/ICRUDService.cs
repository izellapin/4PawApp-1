using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using eVeterinarskaStanicaModel.Responses;

namespace eVeterinarskaStanicaServices
{
    public interface ICRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest> : IService<TResponse, TSearch>
        where TResponse : class
        where TSearch : class
        where TInsertRequest : class
        where TUpdateRequest : class
    {
        Task<ServiceResult<TResponse>> InsertAsync(TInsertRequest request);
        Task<ServiceResult<TResponse>> UpdateAsync(int id, TUpdateRequest request);
        Task<ServiceResult> DeleteAsync(int id);
    }
}
