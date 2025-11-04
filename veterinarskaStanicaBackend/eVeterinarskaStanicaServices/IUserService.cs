using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using eVeterinarskaStanicaServices.Database;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.Requests;
using eVeterinarskaStanicaModel.Responses;
using eVeterinarskaStanicaModel.SearchObjects;

namespace eVeterinarskaStanicaServices
{
    public interface IUserService
    {
        List<User> Get(UserSearchObject search);
        User Get(int id);
        Task<User?> GetUserByEmailAsync(string email);
        Task<User?> GetUserByUsernameAsync(string username);
        Task<ServiceResult<UserResponse>> InsertUserAsync(UserInsertRequest request);
        Task<ServiceResult<UserResponse>> UpdateUserAsync(int id, UserUpdateRequest request);
        Task<ServiceResult> DeleteUserAsync(int id);
        Task<ServiceResult> ActivateUserAsync(int id);
        Task<ServiceResult> DeactivateUserAsync(int id);
        Task<bool> UserExistsAsync(int id);
        Task<bool> EmailExistsAsync(string email);
        Task<bool> UsernameExistsAsync(string username);
        Task<bool> VerifyPasswordAsync(string email, string password);
    }

}
