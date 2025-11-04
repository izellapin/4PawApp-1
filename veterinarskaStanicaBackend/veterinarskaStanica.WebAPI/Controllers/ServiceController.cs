using Microsoft.AspNetCore.Mvc;
using eVeterinarskaStanicaServices;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.SearchObjects;

namespace veterinarskaStanica.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServiceController : ControllerBase
    {
        private readonly iServiceService _serviceService;

        public ServiceController(iServiceService serviceService)
        {
            _serviceService = serviceService;
        }

        // GET: api/Service
        [HttpGet]
        public ActionResult<IEnumerable<Service>> GetServices([FromQuery] ServiceSearchObject? searchObject = null)
        {
            var search = searchObject ?? new ServiceSearchObject();
            var services = _serviceService.Get(search);
            return Ok(services);
        }

        // GET: api/Service/5
        [HttpGet("{id}")]
        public ActionResult<Service> GetService(int id)
        {
            var service = _serviceService.Get(id);

            if (service == null)
            {
                return NotFound();
            }

            return Ok(service);
        }
    }
}