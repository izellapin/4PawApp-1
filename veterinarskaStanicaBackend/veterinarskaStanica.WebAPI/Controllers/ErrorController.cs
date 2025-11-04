using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [ApiExplorerSettings(IgnoreApi = true)]
    public class ErrorController : ControllerBase
    {
        private readonly ILogger<ErrorController> _logger;

        public ErrorController(ILogger<ErrorController> logger)
        {
            _logger = logger;
        }

        [Route("/error")]
        [HttpGet]
        public IActionResult Error()
        {
            var context = HttpContext.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>();
            var exception = context?.Error;

            if (exception != null)
            {
                _logger.LogError(exception, "Unhandled exception occurred");
                
                return StatusCode(500, new
                {
                    error = "Internal Server Error",
                    message = exception.Message,
                    stackTrace = exception.StackTrace,
                    timestamp = DateTime.UtcNow
                });
            }

            return StatusCode(500, new { error = "Unknown error occurred" });
        }
    }
}




