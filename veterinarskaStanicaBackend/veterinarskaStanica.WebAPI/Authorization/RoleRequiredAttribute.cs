using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;
using eVeterinarskaStanicaModel;
using Microsoft.Extensions.Logging;

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
            
            // Log for debugging
            var logger = context.HttpContext.RequestServices.GetService<ILogger<RoleRequiredAttribute>>();
            logger?.LogInformation("RoleRequired check - Role claim: {RoleClaim}, Required roles: {RequiredRoles}", 
                roleClaim, string.Join(", ", _requiredRoles));
            
            if (string.IsNullOrEmpty(roleClaim))
            {
                logger?.LogWarning("Role claim is null or empty");
                context.Result = new ForbidResult();
                return;
            }

            // Try to parse role (case-insensitive)
            if (!Enum.TryParse<UserRole>(roleClaim, ignoreCase: true, out var userRole))
            {
                logger?.LogWarning("Failed to parse role claim '{RoleClaim}' as UserRole enum", roleClaim);
                context.Result = new ForbidResult();
                return;
            }

            logger?.LogInformation("Parsed user role: {UserRole}", userRole);

            // Check if user has required role
            if (!_requiredRoles.Contains(userRole))
            {
                logger?.LogWarning("User role {UserRole} is not in required roles: {RequiredRoles}", 
                    userRole, string.Join(", ", _requiredRoles));
                context.Result = new ForbidResult();
                return;
            }

            logger?.LogInformation("Authorization successful - User role {UserRole} is authorized", userRole);
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
