using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;
using eVeterinarskaStanicaModel;

namespace veterinarskaStanica.WebAPI.Authorization
{
    public class RoleRequiredAttribute : Attribute, IAuthorizationFilter
    {
        private readonly UserRole[] _requiredRoles;

        public RoleRequiredAttribute(params UserRole[] requiredRoles)
        {
            _requiredRoles = requiredRoles;
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // Check if user is authenticated
            if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
            {
                context.Result = new UnauthorizedResult();
                return;
            }

            // Get user role from claims
            var roleClaim = context.HttpContext.User.FindFirst(ClaimTypes.Role)?.Value;
            
            if (string.IsNullOrEmpty(roleClaim) || !Enum.TryParse<UserRole>(roleClaim, out var userRole))
            {
                context.Result = new ForbidResult();
                return;
            }

            // Check if user has required role
            if (!_requiredRoles.Contains(userRole))
            {
                context.Result = new ForbidResult();
                return;
            }
        }
    }

    public class PermissionRequiredAttribute : Attribute, IAuthorizationFilter
    {
        private readonly string[] _requiredPermissions;

        public PermissionRequiredAttribute(params string[] requiredPermissions)
        {
            _requiredPermissions = requiredPermissions;
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // Check if user is authenticated
            if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
            {
                context.Result = new UnauthorizedResult();
                return;
            }

            // Get user permissions from claims
            var userPermissions = context.HttpContext.User
                .FindAll("permission")
                .Select(c => c.Value)
                .ToArray();

            // Check if user has all required permissions
            var hasAllPermissions = _requiredPermissions.All(permission => 
                userPermissions.Contains(permission));

            if (!hasAllPermissions)
            {
                context.Result = new ForbidResult();
                return;
            }
        }
    }

    // Convenience attributes for common scenarios
    public class AdminOnlyAttribute : RoleRequiredAttribute
    {
        public AdminOnlyAttribute() : base(UserRole.Admin) { }
    }

    public class StaffOnlyAttribute : RoleRequiredAttribute
    {
        public StaffOnlyAttribute() : base(UserRole.Admin, UserRole.Veterinarian, UserRole.VetTechnician, UserRole.Receptionist) { }
    }

    public class VeterinarianOnlyAttribute : RoleRequiredAttribute
    {
        public VeterinarianOnlyAttribute() : base(UserRole.Admin, UserRole.Veterinarian) { }
    }

    public class MobileUserAttribute : RoleRequiredAttribute
    {
        public MobileUserAttribute() : base(UserRole.PetOwner) { }
    }
}
