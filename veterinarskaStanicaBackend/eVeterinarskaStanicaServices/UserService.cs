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
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly IHashingService _hashingService;

        public UserService(ApplicationDbContext context, IHashingService hashingService)
        {
            _context = context;
            _hashingService = hashingService;
        }

        public List<User> Get(UserSearchObject search)
        {
            var query = _context.Users.AsQueryable();

            // Apply filters
            if (!string.IsNullOrEmpty(search.FirstName))
                query = query.Where(u => u.FirstName.Contains(search.FirstName));

            if (!string.IsNullOrEmpty(search.LastName))
                query = query.Where(u => u.LastName.Contains(search.LastName));

            if (!string.IsNullOrEmpty(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrEmpty(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            // FTS search across multiple fields
            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(u => u.FirstName.Contains(search.FTS) ||
                                        u.LastName.Contains(search.FTS) ||
                                        u.Email.Contains(search.FTS) ||
                                        u.Username.Contains(search.FTS) ||
                                        (u.LicenseNumber != null && u.LicenseNumber.Contains(search.FTS)) ||
                                        (u.Specialization != null && u.Specialization.Contains(search.FTS)) ||
                                        (u.Biography != null && u.Biography.Contains(search.FTS)));
            }

            if (search.Role.HasValue)
                query = query.Where(u => u.Role == search.Role.Value);

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            if (search.IsEmailVerified.HasValue)
                query = query.Where(u => u.IsEmailVerified == search.IsEmailVerified.Value);

            if (!string.IsNullOrEmpty(search.Specialization))
                query = query.Where(u => u.Specialization != null && u.Specialization.Contains(search.Specialization));

            if (search.MinYearsOfExperience.HasValue)
                query = query.Where(u => u.YearsOfExperience >= search.MinYearsOfExperience.Value);

            if (search.MaxYearsOfExperience.HasValue)
                query = query.Where(u => u.YearsOfExperience <= search.MaxYearsOfExperience.Value);

            if (search.CreatedFrom.HasValue)
                query = query.Where(u => u.DateCreated >= search.CreatedFrom.Value);

            if (search.CreatedTo.HasValue)
                query = query.Where(u => u.DateCreated <= search.CreatedTo.Value);

            // General search term
            if (!string.IsNullOrEmpty(search.SearchTerm))
            {
                query = query.Where(u => u.FirstName.Contains(search.SearchTerm) ||
                                        u.LastName.Contains(search.SearchTerm) ||
                                        u.Email.Contains(search.SearchTerm) ||
                                        u.Username.Contains(search.SearchTerm));
            }

            // Apply ordering
            if (!string.IsNullOrEmpty(search.OrderBy))
            {
                switch (search.OrderBy.ToLower())
                {
                    case "firstname":
                        query = search.IsDescending ? query.OrderByDescending(u => u.FirstName) : query.OrderBy(u => u.FirstName);
                        break;
                    case "lastname":
                        query = search.IsDescending ? query.OrderByDescending(u => u.LastName) : query.OrderBy(u => u.LastName);
                        break;
                    case "email":
                        query = search.IsDescending ? query.OrderByDescending(u => u.Email) : query.OrderBy(u => u.Email);
                        break;
                    case "datecreated":
                        query = search.IsDescending ? query.OrderByDescending(u => u.DateCreated) : query.OrderBy(u => u.DateCreated);
                        break;
                    default:
                        query = query.OrderBy(u => u.Id);
                        break;
                }
            }
            else
            {
                query = query.OrderBy(u => u.Id);
            }

            // Apply pagination
            return query
                .Skip(search.Skip)
                .Take(search.Take)
                .ToList();
        }

        public User Get(int id)
        {
            return _context.Users.Find(id);
        }





        public async Task<User?> GetUserByEmailAsync(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        }

        public async Task<User?> GetUserByUsernameAsync(string username)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
        }

        public async Task<ServiceResult<UserResponse>> InsertUserAsync(UserInsertRequest request)
        {
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Username = request.Username,
                PhoneNumber = request.PhoneNumber,
                Address = request.Address,
                Role = request.Role,
                LicenseNumber = request.LicenseNumber,
                Specialization = request.Specialization,
                YearsOfExperience = request.YearsOfExperience,
                Biography = request.Biography,
                DateCreated = DateTime.UtcNow,
                IsActive = true,
                IsEmailVerified = false
            };

            // Hash the password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                byte[] salt;
                user.PasswordHash = _hashingService.HashPassword(request.Password, out salt);
                user.PasswordSalt = Convert.ToBase64String(salt);
            }

            try
            {
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                return ServiceResult<UserResponse>.SuccessResult(MapToUserResponse(user));
            }
            catch (Exception ex)
            {
                return ServiceResult<UserResponse>.ErrorResult($"Error creating user: {ex.Message}");
            }
        }

        public async Task<ServiceResult<UserResponse>> UpdateUserAsync(int id, UserUpdateRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return ServiceResult<UserResponse>.ErrorResult("User not found");
            }

            // Update properties
            if (request.FirstName != null)
                user.FirstName = request.FirstName;
            if (request.LastName != null)
                user.LastName = request.LastName;
            if (request.Email != null)
                user.Email = request.Email;
            if (request.Username != null)
                user.Username = request.Username;
            if (request.PhoneNumber != null)
                user.PhoneNumber = request.PhoneNumber;
            if (request.Address != null)
                user.Address = request.Address;
            if (request.Role.HasValue)
                user.Role = request.Role.Value;
            if (request.IsActive.HasValue)
                user.IsActive = request.IsActive.Value;
            
            // Update veterinarian-specific fields
            if (request.LicenseNumber != null)
                user.LicenseNumber = request.LicenseNumber;
            if (request.Specialization != null)
                user.Specialization = request.Specialization;
            if (request.YearsOfExperience.HasValue)
                user.YearsOfExperience = request.YearsOfExperience.Value;
            if (request.Biography != null)
                user.Biography = request.Biography;
            if (request.WorkStartTime.HasValue)
                user.WorkStartTime = request.WorkStartTime.Value;
            if (request.WorkEndTime.HasValue)
                user.WorkEndTime = request.WorkEndTime.Value;
            if (request.WorkDays != null)
                user.WorkDays = request.WorkDays;

            // Update password if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                byte[] salt;
                user.PasswordHash = _hashingService.HashPassword(request.Password, out salt);
                user.PasswordSalt = Convert.ToBase64String(salt);
            }

            try
            {
                await _context.SaveChangesAsync();
                return ServiceResult<UserResponse>.SuccessResult(MapToUserResponse(user));
            }
            catch (Exception ex)
            {
                return ServiceResult<UserResponse>.ErrorResult($"Error updating user: {ex.Message}");
            }
        }

        public async Task<ServiceResult> DeleteUserAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return ServiceResult.ErrorResult("User not found");
            }

            try
            {
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error deleting user: {ex.Message}");
            }
        }

        public async Task<ServiceResult> ActivateUserAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return ServiceResult.ErrorResult("User not found");
            }

            try
            {
                user.IsActive = true;
                await _context.SaveChangesAsync();
                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error activating user: {ex.Message}");
            }
        }

        public async Task<ServiceResult> DeactivateUserAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return ServiceResult.ErrorResult("User not found");
            }

            try
            {
                user.IsActive = false;
                await _context.SaveChangesAsync();
                return ServiceResult.SuccessResult();
            }
            catch (Exception ex)
            {
                return ServiceResult.ErrorResult($"Error deactivating user: {ex.Message}");
            }
        }

        public async Task<bool> UserExistsAsync(int id)
        {
            return await _context.Users.AnyAsync(e => e.Id == id);
        }

        public async Task<bool> EmailExistsAsync(string email)
        {
            return await _context.Users.AnyAsync(u => u.Email == email);
        }

        public async Task<bool> UsernameExistsAsync(string username)
        {
            return await _context.Users.AnyAsync(u => u.Username == username);
        }

        public async Task<bool> VerifyPasswordAsync(string email, string password)
        {
            var user = await GetUserByEmailAsync(email);
            if (user == null || string.IsNullOrEmpty(user.PasswordHash) || string.IsNullOrEmpty(user.PasswordSalt))
                return false;

            return _hashingService.VerifyPassword(password, user.PasswordHash, user.PasswordSalt);
        }

        private static UserResponse MapToUserResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Username = user.Username,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                DateCreated = user.DateCreated,
                LastLoginDate = user.LastLoginDate,
                IsActive = user.IsActive,
                IsEmailVerified = user.IsEmailVerified,
                Role = user.Role.ToString(),
                LicenseNumber = user.LicenseNumber,
                Specialization = user.Specialization,
                YearsOfExperience = user.YearsOfExperience,
                Biography = user.Biography,
                WorkStartTime = user.WorkStartTime,
                WorkEndTime = user.WorkEndTime,
                WorkDays = user.WorkDays
            };
        }
    }
}
